-- Migration: Update video collaboration model to support single-list membership with collaborators

-- Drop existing policies that relied on videos.user_id
drop policy if exists "Users can view own videos" on public.videos;
drop policy if exists "Users can insert own videos" on public.videos;
drop policy if exists "Users can update own videos" on public.videos;
drop policy if exists "Users can delete own videos" on public.videos;

-- Drop indexes that reference videos.user_id
drop index if exists videos_user_original_url_idx;
drop index if exists videos_user_date_added_idx;

-- Create canonical list per owner
create table if not exists public.video_lists (
    owner_id uuid primary key references auth.users(id) on delete cascade,
    name text,
    created_at timestamptz not null default timezone('utc', now())
);

comment on table public.video_lists is 'Canonical saved-video list for each user.';
comment on column public.video_lists.owner_id is 'Owner of the list; matches auth.users.id and is unique per user.';
comment on column public.video_lists.name is 'Optional user-facing label for the list.';
comment on column public.video_lists.created_at is 'UTC timestamp when the list was created.';

-- Each user belongs to exactly one list (their own or another''s)
create table if not exists public.video_list_members (
    user_id uuid primary key references auth.users(id) on delete cascade,
    list_owner_id uuid not null references public.video_lists(owner_id) on delete cascade,
    role text not null default 'editor' check (role in ('owner','editor')),
    added_at timestamptz not null default timezone('utc', now()),
    added_by uuid references auth.users(id)
);

comment on table public.video_list_members is 'Membership mapping ensuring each user belongs to exactly one saved-video list.';
comment on column public.video_list_members.user_id is 'User who belongs to a saved-video list (owner or collaborator).';
comment on column public.video_list_members.list_owner_id is 'Owner that defines the saved-video list membership for the user.';
comment on column public.video_list_members.role is 'Access level granted within the list (owner or editor).';
comment on column public.video_list_members.added_at is 'UTC timestamp when the user was added to the list.';
comment on column public.video_list_members.added_by is 'User who performed the invite or membership change.';

alter table public.video_list_members
    add constraint video_list_members_list_user_key unique (list_owner_id, user_id);

create index if not exists video_list_members_owner_idx
    on public.video_list_members (list_owner_id);

-- Seed lists for any existing users referenced by videos
insert into public.video_lists (owner_id)
select distinct user_id from public.videos
where user_id is not null
on conflict (owner_id) do nothing;

-- Seed membership rows for owners
insert into public.video_list_members (user_id, list_owner_id, role, added_by)
select owner_id, owner_id, 'owner', owner_id
from public.video_lists
on conflict (user_id) do nothing;

-- Extend videos table for list ownership and attribution
alter table public.videos
    add column list_owner_id uuid,
    add column added_by_user_id uuid;

-- Populate new columns from historical data
update public.videos
set list_owner_id = coalesce(user_id, list_owner_id),
    added_by_user_id = coalesce(user_id, added_by_user_id);

-- Enforce constraints after backfill
alter table public.videos
    alter column list_owner_id set not null,
    alter column added_by_user_id set not null;

alter table public.videos
    add constraint videos_list_owner_fk foreign key (list_owner_id)
        references public.video_lists(owner_id) on delete cascade,
    add constraint videos_added_by_user_fk foreign key (added_by_user_id)
        references auth.users(id) on delete restrict;

alter table public.videos
    add constraint videos_added_by_member_fk foreign key (list_owner_id, added_by_user_id)
        references public.video_list_members(list_owner_id, user_id);

alter table public.videos
    alter column added_by_user_id set default auth.uid();

-- Drop legacy user_id column now that list_owner_id tracks ownership
alter table public.videos
    drop column user_id;

-- Re-establish indexes with list-based ownership
create unique index if not exists videos_list_owner_original_url_idx
    on public.videos (list_owner_id, original_url);

create index if not exists videos_list_owner_date_added_idx
    on public.videos (list_owner_id, date_added desc);

-- Add helpful comments for new columns
comment on column public.videos.list_owner_id is 'Owner whose canonical list contains this video.';
comment on column public.videos.added_by_user_id is 'User who added the video to the list.';

-- Ensure RLS is enabled on new tables
alter table public.video_lists enable row level security;
alter table public.video_list_members enable row level security;

-- Policies for video lists and membership
create policy "List owners manage list"
on public.video_lists
for all
using (auth.uid() = owner_id)
with check (auth.uid() = owner_id);

create policy "Members view their list"
on public.video_lists
for select
using (
    auth.uid() = owner_id
    or auth.uid() in (
        select user_id
        from public.video_list_members
        where list_owner_id = public.video_lists.owner_id
    )
);

create policy "Members view membership"
on public.video_list_members
for select
using (auth.uid() = user_id or auth.uid() = list_owner_id);

create policy "Owners manage membership"
on public.video_list_members
for all
using (auth.uid() = list_owner_id)
with check (auth.uid() = list_owner_id);

-- RLS policies for videos based on membership
create policy "Members read videos"
on public.videos
for select
using (
    auth.uid() in (
        select user_id
        from public.video_list_members
        where list_owner_id = public.videos.list_owner_id
    )
);

create policy "Editors insert videos"
on public.videos
for insert
with check (
    exists (
        select 1
        from public.video_list_members
        where list_owner_id = public.videos.list_owner_id
          and user_id = auth.uid()
          and role in ('owner', 'editor')
    )
);

create policy "Editors update videos"
on public.videos
for update
using (
    exists (
        select 1
        from public.video_list_members
        where list_owner_id = public.videos.list_owner_id
          and user_id = auth.uid()
          and role in ('owner', 'editor')
    )
)
with check (
    exists (
        select 1
        from public.video_list_members
        where list_owner_id = public.videos.list_owner_id
          and user_id = auth.uid()
          and role in ('owner', 'editor')
    )
);

create policy "Editors delete videos"
on public.videos
for delete
using (
    exists (
        select 1
        from public.video_list_members
        where list_owner_id = public.videos.list_owner_id
          and user_id = auth.uid()
          and role in ('owner', 'editor')
    )
);

-- Function and trigger to auto-provision lists for new users
create or replace function public.handle_user_video_list()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
    insert into public.video_lists (owner_id)
    values (new.id)
    on conflict (owner_id) do nothing;

    insert into public.video_list_members (user_id, list_owner_id, role, added_by)
    values (new.id, new.id, 'owner', new.id)
    on conflict (user_id) do update
        set list_owner_id = excluded.list_owner_id,
            role = 'owner',
            added_by = excluded.added_by,
            added_at = timezone('utc', now());

    return new;
end;
$$;

drop trigger if exists handle_user_video_list on auth.users;
create trigger handle_user_video_list
after insert on auth.users
for each row
execute procedure public.handle_user_video_list();

-- Backfill lists for any existing auth users without lists
insert into public.video_lists (owner_id)
select id from auth.users
on conflict (owner_id) do nothing;

insert into public.video_list_members (user_id, list_owner_id, role, added_by)
select u.id, u.id, 'owner', u.id
from auth.users u
where not exists (
    select 1
    from public.video_list_members m
    where m.user_id = u.id
)
on conflict (user_id) do nothing;
