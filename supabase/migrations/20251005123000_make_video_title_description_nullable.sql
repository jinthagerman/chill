-- Migration: Allow NULL values for title and description on public.videos.
-- Context: App metadata is optional and should not block inserts when absent.

alter table public.videos
    alter column title drop not null,
    alter column description drop not null;
