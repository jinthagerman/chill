create extension if not exists "pgcrypto";

create table if not exists public.videos (
    id uuid primary key default gen_random_uuid(),
    user_id uuid not null references auth.users(id) on delete cascade,
    original_url text not null,
    download_url text,
    title text,
    description text,
    length_seconds integer check (length_seconds >= 0),
    thumbnail_url text,
    creator_username text,
    creator_profile_image_url text,
    platform text not null check (char_length(btrim(platform)) > 0),
    platform_video_id text,
    tags text[] not null default '{}'::text[],
    metadata jsonb not null default '{}'::jsonb,
    file_size_bytes bigint check (file_size_bytes >= 0),
    is_downloaded boolean not null default false,
    has_watched boolean not null default false,
    download_error text,
    note text,
    date_added timestamptz not null default timezone('utc', now()),
    last_accessed_at timestamptz,
    updated_at timestamptz not null default timezone('utc', now())
);

comment on table public.videos is 'Videos saved by users for later viewing or download.';
comment on column public.videos.original_url is 'Source URL where the video was discovered.';
comment on column public.videos.download_url is 'URL to the locally cached or proxied download location.';
comment on column public.videos.length_seconds is 'Duration of the video in whole seconds.';
comment on column public.videos.creator_username is 'Display name or handle of the video creator on the origin platform.';
comment on column public.videos.creator_profile_image_url is 'URL pointing to the avatar/profile image of the video creator.';
comment on column public.videos.platform is 'Platform identifier for where the video originated (e.g. youtube, tiktok).';
comment on column public.videos.platform_video_id is 'Identifier provided by the origin platform for this video.';
comment on column public.videos.tags is 'Optional free-form tags for user organization.';
comment on column public.videos.metadata is 'Arbitrary structured metadata captured at save time (resolution, captions, etc.).';
comment on column public.videos.file_size_bytes is 'Estimated size of the downloaded asset if available.';
comment on column public.videos.is_downloaded is 'Tracks whether the asset has been successfully downloaded locally.';
comment on column public.videos.has_watched is 'Tracks whether the user has marked the video as already watched.';
comment on column public.videos.download_error is 'Latest error message captured when a download fails.';
comment on column public.videos.note is 'Optional user-authored note about the saved video.';
comment on column public.videos.date_added is 'UTC timestamp when the video was saved to the library.';
comment on column public.videos.last_accessed_at is 'UTC timestamp when the user last opened or played this saved video.';
comment on column public.videos.updated_at is 'UTC timestamp managed by trigger whenever the record changes.';

create unique index if not exists videos_user_original_url_idx
    on public.videos (user_id, original_url);

create index if not exists videos_user_date_added_idx
    on public.videos (user_id, date_added desc);

create index if not exists videos_platform_idx
    on public.videos (platform);

create or replace function public.set_current_timestamp_updated_at()
returns trigger
language plpgsql
as $$
begin
    new.updated_at = timezone('utc', now());
    return new;
end;
$$;

create trigger set_videos_updated_at
before update on public.videos
for each row
execute procedure public.set_current_timestamp_updated_at();

alter table public.videos enable row level security;

create policy "Users can view own videos"
on public.videos
for select
using (auth.uid() = user_id);

create policy "Users can insert own videos"
on public.videos
for insert
with check (auth.uid() = user_id);

create policy "Users can update own videos"
on public.videos
for update
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

create policy "Users can delete own videos"
on public.videos
for delete
using (auth.uid() = user_id);
