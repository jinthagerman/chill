# Tasks: Card-Based Video List

**Input**: Design documents from `/specs/003-card-based-video/`
**Prerequisites**: plan.md, research.md, data-model.md, contracts/, quickstart.md

## Task List

- [X] T001 Create feature module skeleton under `Chill/Chill/Features/VideoList/` (folders: Views, ViewModels, Services, Cache, Components) and matching test module `ChillTests/VideoList/`.
- [X] T002 Add placeholder asset reference and configuration keys in `Chill/Chill/Resources/VideoListConfig.swift` plus ensure `SupabaseConfig.plist` includes GraphQL view name.
- [X] T003 (Not required) Feature flag removed; ensure configuration reflects always-on video list.
- [X] T004 [P] Implement failing GraphQL contract decoding test in `ChillTests/VideoList/Contracts/VideoCardsGraphQLTests.swift` covering query and subscription payloads.
- [X] T005 [P] Add failing SwiftData cache persistence tests in `ChillTests/VideoList/Cache/VideoCardEntityTests.swift` validating upsert, stale filtering, and purge heuristics.
- [X] T006 [P] Create failing view-model state tests in `ChillTests/VideoList/ViewModel/VideoListViewModelTests.swift` for loading, empty, error, and offline transitions.
- [X] T007 [P] Produce failing snapshot tests in `ChillTests/VideoList/Snapshots/VideoCardSnapshotTests.swift` for Dynamic Type sizes and placeholder imagery.
- [X] T008 [P] Author failing integration test in `ChillTests/VideoList/Integration/VideoListOfflineIntegrationTests.swift` simulating network drop with cached cards.
- [X] T009 [P] Add failing UI test in `ChillUITests/VideoList/MyVideosFlowTests.swift` covering navigation, loader timing, and reconnect toast.
- [X] T010 Define SwiftData model `VideoCardEntity` and persistence helpers in `Chill/Chill/Features/VideoList/Cache/VideoCardEntity.swift`.
- [X] T011 Implement Supabase GraphQL service in `Chill/Chill/Features/VideoList/Services/VideoCardsService.swift` with query + subscription actor wrapper.
- [X] T012 Build `VideoListViewModel` in `Chill/Chill/Features/VideoList/ViewModels/VideoListViewModel.swift` handling state machine, offline queue, analytics, and logging.
- [X] T013 Compose `VideoCardView` and `VideoListView` in `Chill/Chill/Features/VideoList/Views/` applying design tokens, FAB, and accessibility labels.
- [X] T014 Wire navigation entry point in `Chill/Chill/App/AuthCoordinator.swift` so authenticated users can access `VideoListView`.
- [X] T015 Implement offline cache hydration/purge routine in `Chill/Chill/Features/VideoList/Cache/VideoCardCacheManager.swift` leveraging `VideoListConfig.cachePurgeDays`.
- [X] T016 Add page-view analytics and reconnect INFO logging in `VideoListViewModel` using telemetry facade.
- [X] T017 Verify Supabase read access for `video_cards_view`; add migration or docs in `supabase/migrations/` if policies need update.
- [X] T018 [P] Localize static strings (loader, empty, offline, toast) in `Chill/Chill/Resources/Localization/` and add placeholder translations.
- [X] T019 [P] Run accessibility audit (VoiceOver rotor, Dynamic Type) and document outcomes in `specs/003-card-based-video/quickstart.md` results section.
- [X] T020 [P] Update release notes and support playbook in `docs/releases/003-card-based-video.md` with rollout + rollback steps.
- [X] T021 [P] Execute quickstart steps, capture screenshots, and store assets in `docs/qa/003-card-based-video/` plus record QA sign-off.

## Dependencies
- T001 → T002 → T003 → (T004-T009 in parallel) → T010 → T011 → T012 → T013 → T014 → T015 → T016 → T017
- Polish tasks T018-T021 run after T017 (can execute in parallel).

## Parallel Execution Examples
```
# Example 1: run contract and state tests together
Tasks: T004, T005, T006, T007, T008, T009

# Example 2: localization & release docs together
Tasks: T018, T019, T020, T021
```

## Notes
- All [P] tasks operate on distinct files; avoid conflicts.
- Ensure failing tests (T004-T009) exist before starting implementation tasks.
- Redact identifiers in telemetry per Observability principle.
- Validate offline cache migrations before release.
