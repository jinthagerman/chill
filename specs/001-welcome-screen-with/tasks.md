# Tasks: Welcome Screen With Login and Signup

**Input**: Design documents from `/Users/jin/Code/Chill/specs/001-welcome-screen-with/`
**Prerequisites**: plan.md, research.md, data-model.md, contracts/ui-contract.md, quickstart.md

## Phase 3.1: Setup
- [X] T001 Scaffold `Chill/Chill/Features/Welcome/` module structure and add placeholder Swift files (`WelcomeView.swift` with inline previews, `WelcomeViewModel.swift`, `WelcomeContent.swift`) plus empty `Assets/WelcomeBackground.imageset` registered in `Chill.xcodeproj`.
- [X] T002 Create `Chill/Chill/Support/DesignSystem/Spacing.swift` (or update existing) with spacing constants referenced by the welcome layout; wire into target membership.
- [X] T003 Connect `ContentView` directly to `WelcomeView`, ensuring the welcome experience renders by default without feature flags.

## Phase 3.2: Tests First (TDD) ⚠️ MUST COMPLETE BEFORE 3.3
- [X] T004 [P] Author failing `ChillTests/Welcome/WelcomeViewModelTests.swift` verifying `WelcomeViewModel` emits inactive CTA metadata, accessibility notice text, and future-ready state transitions.
- [X] T005 [P] Add failing snapshot coverage in `ChillTests/Welcome/WelcomeViewSnapshotTests.swift` asserting helper text visibility, enabled button appearance, Dynamic Type layout, and reduced-motion rendering per UI contract.
- [X] T006 [P] Create failing UI automation in `ChillUITests/Welcome/WelcomeFlowUITests.swift` confirming welcome screen presentation, tap no-op behavior, and VoiceOver hint accessibility identifiers.

## Phase 3.3: Core Implementation (ONLY after tests are failing)
- [X] T007 Implement `Chill/Chill/Features/Welcome/WelcomeContent.swift` with localized copy, helper text, and accessibility message sourced from `LocalizedStringKey` assets.
- [X] T008 Implement `Chill/Chill/Features/Welcome/WelcomeViewModel.swift` providing `primaryButtons`, `buttonState`, and `welcomeAccessibilityNotice` while deferring navigation callbacks.
- [X] T009 Implement `Chill/Chill/Features/Welcome/WelcomeView.swift` SwiftUI hierarchy using design tokens, helper text, ScrollView support, Dynamic Type sizing, and reduced-motion handling.
- [X] T010 Update `Chill/Chill/ContentView.swift` (or app entry point) to present `WelcomeView()` by default and ensure previews compile.

## Phase 3.4: Integration & Compliance
- [X] T011 Document analytics deferral by adding a backlog note to `/Users/jin/Code/Chill/specs/001-welcome-screen-with/research.md` or dedicated tracking file, confirming no telemetry code exists in the feature.
- [X] T012 Add manual QA guidance to `quickstart.md` and create `specs/001-welcome-screen-with/rollout-notes.md` detailing launch checks and rollback communication (no feature flag toggling required).

## Phase 3.5: Polish
- [X] T013 [P] Expand accessibility assertions in `ChillTests/Welcome/WelcomeViewSnapshotTests.swift` for VoiceOver labels and helper hints, and capture simulator screenshots for documentation.
- [X] T014 Measure performance (initial render timing) using Instruments; append results and remediation notes to `research.md` under a Performance heading.
- [X] T015 [P] Localize welcome copy placeholders by adding keys to `Chill/Chill/Resources/Localizable.strings` (en) and updating `WelcomeContent` initializers to reference them.
- [X] T016 Final code review pass resolving warnings and preparing PR description referencing spec and plan.

## Dependencies
- T001 → T002 → T003 (scaffolding before tokens before ContentView wiring)
- Tests (T004–T006) must run and fail before implementation (T007–T010)
- T007 & T008 unblock T009; T009 plus T003 unblock T010
- T010 precedes documentation/integration tasks (T011–T012)
- Polish tasks (T013–T016) depend on completion of prior phases

## Parallel Execution Example
```
# After setup (T001–T003), execute tests in parallel:
Task: "T004 Write failing WelcomeViewModel tests"
Task: "T005 Write failing snapshot coverage"
Task: "T006 Write failing UI automation"

# During polish, run localization and accessibility tightening together:
Task: "T013 Strengthen accessibility assertions"
Task: "T015 Localize welcome copy"
```

## Notes
- [P] tasks operate on distinct files (`ChillTests/Welcome/*.swift`, `ChillUITests/Welcome/*.swift`, `Localizable.strings`) and can run concurrently when prerequisites met.
- Maintain TDD: ensure T004–T006 fail before starting T007.
- Verify no analytics/logging slips into production code during implementation (per Observability principle).
- Validate welcome experience behavior on both fresh install and return visits.
