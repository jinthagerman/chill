# Tasks: Supabase Login and Signup

**Input**: Design documents from `/Users/jin/Code/Chill/specs/002-add-supabase-login/`
**Prerequisites**: plan.md, research.md, data-model.md, contracts/auth-flow.md, quickstart.md

## Phase 3.1: Setup
- [X] T001 Add the `supabase-swift` package to `Chill.xcodeproj` and commit dependency metadata (`Package.resolved`).
- [X] T002 Scaffold `Chill/Chill/Features/Auth/` and `Chill/Chill/Features/SavedLinks/` directories with placeholder Swift files plus `Chill/Chill/Resources/Config/SupabaseConfig.plist` for runtime keys.
- [X] T003 Create build-time configuration plumbing (scheme env or plist decoding) in `Chill/Chill/App/AuthConfiguration.swift` so Supabase URL/key load safely without hard-coding secrets.

## Phase 3.2: Tests First (TDD) ⚠️ MUST COMPLETE BEFORE 3.3
- [X] T004 [P] Author failing unit tests in `ChillTests/Auth/AuthServiceTests.swift` covering success/error mapping for sign up, login, logout, and OTP flows.
- [X] T005 [P] Author failing view-model tests in `ChillTests/Auth/AuthViewModelTests.swift` covering mode transitions, offline gating, and SavedLinks navigation triggers.
- [X] T006 [P] Add failing snapshot tests in `ChillTests/Auth/AuthFlowViewSnapshotTests.swift` asserting form layout, dynamic type, and error banners.
- [X] T007 [P] Add failing snapshot tests in `ChillTests/SavedLinks/SavedLinksViewSnapshotTests.swift` validating placeholder presentation for authenticated users.
- [X] T008 [P] Create contract verification tests in `ChillTests/Auth/AuthFlowContractTests.swift` ensuring interactions match `contracts/auth-flow.md` (screens + outcomes).

## Phase 3.3: Core Implementation (ONLY after tests are failing)
- [X] T009 Implement `AuthService` in `Chill/Chill/Features/Auth/AuthService.swift`, wiring supabase-swift calls, session publisher, and error normalization.
- [X] T010 Implement `AuthViewModel` in `Chill/Chill/Features/Auth/AuthViewModel.swift`, handling modes, form validation, offline awareness, and SavedLinks routing.
- [X] T011 Build `AuthView` (and supporting subviews) in `Chill/Chill/Features/Auth/AuthView.swift`, including login, signup, and OTP reset screens with accessibility hooks.
- [X] T012 Implement `SavedLinksView` placeholder in `Chill/Chill/Features/SavedLinks/SavedLinksView.swift` plus simple styling.
- [X] T013 Update `Chill/Chill/ContentView.swift` (or root coordinator) to detect Supabase session on launch and present `SavedLinksView` or `AuthView` accordingly.

## Phase 3.4: Integration
- [X] T014 Wire analytics emission for `auth_sign_up`, `auth_sign_in`, `auth_password_reset` in `Chill/Chill/Features/Auth/AuthAnalytics.swift`, redacting PII and logging latency/error buckets.
- [X] T015 Integrate reachability monitoring (e.g., `NWPathMonitor`) in `AuthService`/`AuthViewModel` to disable submissions offline and surface retry messaging.
- [X] T016 Implement secure token persistence & logout cleanup in `AuthService`, ensuring Keychain data clears on sign out and during error states.
- [X] T017 Add Supabase configuration bootstrap (URL/key loading, validation) in `Chill/Chill/App/AuthConfiguration.swift`, including graceful failure copy when misconfigured.

## Phase 3.5: Polish
- [X] T018 [P] Perform accessibility audit (VoiceOver, dynamic type, OTP autofill) and adjust copy/style in `AuthView.swift` & `SavedLinksView.swift`.
- [X] T019 Measure auth flow latency and SavedLinks presentation time; document results in `research.md` Performance section.
- [X] T020 [P] Update documentation (`quickstart.md`, rollout notes, PR notes) with Supabase auth steps, SavedLinks placeholder expectations, and analytics ownership.
- [X] T021 Compile manual QA script covering new account creation, existing session launch into SavedLinksView, and OTP reset; attach screenshots for release artifacts.

## Dependencies
- T001 → T002 → T003 (dependency + scaffolding before configuration plumbing)
- Tests (T004–T008) must fail before implementation tasks (T009–T013).
- T009 & T010 block UI work T011; T011 & T012 block navigation update T013.
- Integration tasks (T014–T017) depend on core implementation.
- Polish tasks (T018–T021) depend on all prior phases completing.

## Parallel Execution Example
```
# After setup, run test authoring in parallel:
Task: "T004 AuthService failing unit tests"
Task: "T005 AuthViewModel failing state tests"
Task: "T006 AuthFlow snapshot scaffolding"
Task: "T007 SavedLinks snapshot scaffold"
Task: "T008 Contract verification tests"

# During polish, run accessibility and docs updates together:
Task: "T018 Accessibility audit adjustments"
Task: "T020 Documentation refresh"
```

## Notes
- [P] tasks operate on different files with no shared writes; keep TDD discipline before touching implementation.
- Guard secrets: load Supabase keys from configuration files, never inline them.
- Ensure analytics are redacted and documented; coordinate with data team on schema follow-up from research.md.
- SavedLinksView is a placeholder but must be production-ready (accessibility + snapshot coverage) as the authenticated destination.
