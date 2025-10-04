# Data Model — Card-Based Video List

## 1. Remote View: `public.video_cards_view`
- **Primary Key**: `id` (uuid, stable per saved video)
- **Fields**:
  - `id` (uuid, not null)
  - `title` (text, not null)
  - `creator_name` (text, nullable → fallback to "Unknown creator")
  - `platform_name` (text, not null, e.g., "YouTube")
  - `duration_seconds` (int, not null, ≥0)
  - `thumbnail_url` (text, nullable → use placeholder asset)
  - `updated_at` (timestamptz, not null)
- **Indexes/Filters**: view already filters by list membership via RLS; ensure GraphQL selects ordered by `updated_at desc`.

## 2. Local Cache: `VideoCardEntity` (SwiftData)
- **Primary Key**: `id: UUID`
- **Attributes**:
  - `title: String` (non-empty)
  - `creatorDisplayName: String` (defaults to "Unknown creator")
  - `platformDisplayName: String`
  - `durationSeconds: Int` (≥0)
  - `thumbnailURL: URL?`
  - `updatedAt: Date`
  - `syncedAt: Date` (last time record synced locally)
- **Derived Properties**:
  - `durationLabel` (formatted mm:ss)
  - `accessibilityLabel` ("{title}, {creatorDisplayName}, {durationLabel}")
- **Relationships**: none (flat list)
- **Persistence Rules**:
  - Upsert by primary key on each GraphQL payload.
  - Remove entries not returned in payload when `updated_at` older than server-provided TTL (configurable).

## 3. View Model State
- **Enum `VideoListLoadState`**:
  - `.loading` (initial, triggered on appear)
  - `.loaded(cards: [VideoCard])`
  - `.empty(message: String)`
  - `.error(message: String, retryToken: UUID)`
  - `.offline(cards: [VideoCard], message: String)`
- **Transitions**:
  - `loading → loaded` on successful fetch with ≥1 card.
  - `loading → empty` when fetch returns 0 cards.
  - `loading → error` on fetch failure while offline cache empty.
  - `loaded → offline` on connectivity loss; revert to `loaded` when subscription reconnects and new data arrives.
  - Any state → `loading` when user triggers retry (manual or reconnection event).

## 4. DTO Mapping
- **`VideoCardDTO`** (GraphQL decoding struct)
  - Mirrors remote fields (`id`, `title`, `creator_name`, `platform_name`, `duration_seconds`, `thumbnail_url`, `updated_at`).
  - Provides `displayModel` computed property to map into `VideoCard` domain struct.

- **`VideoCard` Domain Struct**
  - Fields aligned with cache entity but immutable; used by SwiftUI for rendering.
  - Conforms to `Identifiable`, `Hashable`.

## 5. Validation Rules
- Reject GraphQL rows missing `title` or `platform_name` (log warning, skip caching).
- Clamp `duration_seconds` to `0...12 * 60 * 60` (guard unrealistic values).
- Normalize `thumbnail_url` to https; otherwise treat as missing and use placeholder.
- Ensure `updated_at` monotonic: ignore payloads older than current cache entry to avoid stale overwrites.

## 6. Configuration Values
- `VideoListConfig.placeholderImageName` — required asset key for fallback thumbnail.
- `VideoListConfig.cachePurgeDays` (default 90) — remove cards not touched within this window.
- `VideoListConfig.graphQLViewName` — defaults to `public.video_cards_view` for testing overrides.
