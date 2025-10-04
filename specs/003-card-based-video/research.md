# Phase 0 Research — Card-Based Video List

## Supabase GraphQL Access Pattern
- **Decision**: Use supabase-swift GraphQL client to query the curated `public.video_cards_view` with typed DTOs generated via schema introspection.
- **Rationale**: Matches clarification to rely on a view, keeps business logic server-side, and lets us project only card fields (title, creator, duration, thumbnail, added_at). supabase-swift already manages session tokens and integrates with Combine/async sequences.
- **Alternatives Considered**:
  - REST RPC via edge function — rejected: adds latency and extra plumbing while GraphQL view already exposes shape.
  - Direct PostgREST table access — rejected: would bypass curated joins and require client-side filtering.

## Offline Cache Strategy
- **Decision**: Persist video card summaries in a lightweight SwiftData model (`VideoCardEntity`) keyed by Supabase UUID with updated_at timestamp for cache invalidation.
- **Rationale**: Constitution demands offline resilience; SwiftData integrates with SwiftUI, supports async fetch, and keeps offline footprint minimal. Timestamp allows subscription deltas to merge cleanly.
- **Alternatives Considered**:
  - In-memory cache only — rejected: would clear on app relaunch and break offline browsing requirement.
  - Core Data manual stack — rejected: SwiftData already wraps Core Data with less boilerplate for the same benefits.

## GraphQL Subscription Handling
- **Decision**: Use supabase-swift `RealtimeChannel` with exponential backoff disabled (per clarification: rely on defaults) and wrap in an actor to queue deltas while offline.
- **Rationale**: Aligns with "no additional throttling" guidance while ensuring thread-safe updates to SwiftData. Actor isolates concurrency and avoids duplicate application of patches.
- **Alternatives Considered**:
  - Custom WebSocket client — rejected: unnecessary complexity, lacks built-in auth refresh.
  - Polling fallback — rejected: contradicts requirement to keep list fresh via subscription.

## UI Composition + Accessibility
- **Decision**: Implement `VideoListView` using `ScrollView` + `LazyVStack` of `VideoCardView` components respecting Chill spacing tokens, with VoiceOver labels derived from card metadata and localized static strings.
- **Rationale**: Scroll + Lazy stack handles potentially large lists; componentization supports reusable previews and snapshot tests; ensures Dynamic Type scaling and rotor navigation.
- **Alternatives Considered**:
  - `List` component — rejected: default separators and inset styling clash with design, customization overhead higher.
  - Single monolithic view — rejected: harder to test and violates MVVM separation guidance.

## Observability Scope
- **Decision**: Emit a single `video_list.viewed` analytic event (no identifiers) and log subscription reconnect attempts with severity INFO using the existing logging facade.
- **Rationale**: Meets clarification to limit analytics while still providing operational signal for reconnect loops. INFO logs avoid alert fatigue.
- **Alternatives Considered**:
  - Additional impression events — rejected per "page view only" guidance.
  - No logging — rejected because reconnect issues would be invisible to support.
