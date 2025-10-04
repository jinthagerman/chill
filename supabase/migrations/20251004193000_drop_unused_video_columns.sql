-- Migration: Drop unused columns from public.videos to align with simplified schema.

alter table public.videos
    drop column if exists download_error,
    drop column if exists is_downloaded,
    drop column if exists tags,
    drop column if exists last_accessed_at,
    drop column if exists file_size_bytes,
    drop column if exists platform_video_id;

comment on column public.videos.metadata is 'Arbitrary structured metadata captured at save time (resolution, captions, etc.).';
comment on column public.videos.has_watched is 'Tracks whether the user has marked the video as already watched.';
comment on column public.videos.note is 'Optional user-authored note about the saved video.';
