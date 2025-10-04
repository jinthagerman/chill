-- Migration: Create video_cards_view for card-based video list feature
-- This view exposes a curated GraphQL-friendly shape of saved videos
-- with RLS automatically enforced via the underlying videos table.

create or replace view public.video_cards_view as
select
    v.id,
    v.title,
    v.creator_username as creator_name,
    v.platform as platform_name,
    v.length_seconds as duration_seconds,
    v.thumbnail_url,
    v.updated_at
from
    public.videos v
order by
    v.updated_at desc;

comment on view public.video_cards_view is 'Curated view of saved videos for card-based list UI. RLS enforced via underlying videos table.';

-- Grant read access to authenticated users (RLS on videos table applies)
grant select on public.video_cards_view to authenticated;

-- Note: Row-level security is inherited from the underlying videos table.
-- The policy "Users can view own videos" ensures users only see their own cards.
