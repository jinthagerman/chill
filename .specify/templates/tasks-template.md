# Tasks: [FEATURE NAME]

**Input**: Design documents from `/specs/[###-feature-name]/`
**Prerequisites**: plan.md (required), research.md, data-model.md, contracts/

## Execution Flow (main)
```
1. Load plan.md from feature directory
   → If not found: ERROR "No implementation plan found"
   → Extract: tech stack, libraries, structure
2. Load optional design documents:
   → data-model.md: Extract entities → model tasks
   → contracts/: Each file → contract test task
   → research.md: Extract decisions → setup tasks
3. Generate tasks by category:
   → Setup: project scaffolding, assets, CI updates
   → Tests: XCTest coverage, snapshots, UI automation
   → Core: SwiftUI views, view models, persistence layers
   → Integration: analytics, background sync, security reviews
   → Polish: accessibility sweeps, performance, release documentation
4. Apply task rules:
   → Different files = mark [P] for parallel
   → Same file = sequential (no [P])
   → Tests before implementation (TDD)
5. Number tasks sequentially (T001, T002...)
6. Generate dependency graph
7. Create parallel execution examples
8. Validate task completeness:
   → All contracts or acceptance criteria have tests?
   → All states/entities have supporting code tasks?
   → All release toggles, instrumentation, and support tasks covered?
9. Return: SUCCESS (tasks ready for execution)
```

## Format: `[ID] [P?] Description`
- **[P]**: Can run in parallel (different files, no dependencies)
- Include exact file paths in descriptions

## Path Conventions
- **iOS app**: Production Swift and SwiftUI code lives under `Chill/Chill/`; shared utilities belong in feature-specific subfolders.
- **Unit tests**: Place XCTest coverage in `ChillTests/` and snapshot/Golden tests in dedicated subfolders.
- **UI tests**: Automate flows with `ChillUITests/` using `XCTestCase` + `XCUIApplication`.
- **Design tokens**: Centralize colors, typography, and spacing in a reusable module (e.g., `Chill/Chill/DesignSystem/`).
- Update paths to match the plan’s Structure Decision before finalizing tasks.

## Phase 3.1: Setup
- [ ] T001 Confirm feature scaffolding in `Chill/Chill/` (view, view model, persistence folders) per implementation plan.
- [ ] T002 Register design tokens or assets required by the feature and document updates in the design system notes.
- [ ] T003 [P] Update build settings, lint rules, and CI workflows to cover new targets or schemes.

## Phase 3.2: Tests First (TDD) ⚠️ MUST COMPLETE BEFORE 3.3
**CRITICAL: These tests MUST be written and MUST FAIL before ANY implementation**
- [ ] T004 [P] XCTest coverage for view model logic in `ChillTests/` capturing success, empty, and error states.
- [ ] T005 [P] Snapshot or SwiftUI preview tests asserting accessibility labels and Dynamic Type scaling.
- [ ] T006 [P] Persistence tests exercising local storage migrations or schema changes.
- [ ] T007 [P] UI test in `ChillUITests/` validating the end-to-end happy path with offline fallback steps.

## Phase 3.3: Core Implementation (ONLY after tests are failing)
- [ ] T008 [P] Implement SwiftUI view hierarchy with states defined in the plan and bind to design tokens.
- [ ] T009 [P] Build the view model/business logic layer using Swift Concurrency, matching the state diagram.
- [ ] T010 [P] Integrate persistence layer updates (SwiftData/Core Data) to satisfy offline requirements.
- [ ] T011 Wire up feature toggles or configuration flags controlling rollout behavior.
- [ ] T012 Finalize error presentation and empty-state copy aligned with design guidelines.

## Phase 3.4: Integration
- [ ] T013 Instrument logs, metrics, and traces for the new flows while redacting sensitive values.
- [ ] T014 Update analytics schemas/dashboards and ensure alerts cover new critical paths.
- [ ] T015 Validate background refresh or sync jobs needed for offline resilience.
- [ ] T016 Review security posture (Keychain usage, permission prompts) and document outcomes.

## Phase 3.5: Polish
- [ ] T017 [P] Harden edge-case tests (accessibility rotor, background transitions, localization) in `ChillTests/`.
- [ ] T018 Measure performance (launch time, critical interaction latency) and capture results in the plan’s metrics section.
- [ ] T019 [P] Update runbooks: release notes, rollout plan, and operational handoff docs.
- [ ] T020 Resolve code smells or tech debt raised during review; log follow-up tickets if deferring.
- [ ] T021 Complete manual test script, attach screenshots, and record QA sign-off.

## Dependencies
- Tests (T004-T007) before implementation (T008-T012)
- T008 and T009 block integration work (T013-T016)
- Offline validation (T015) depends on persistence tasks (T010)
- Implementation before polish (T017-T021)

## Parallel Example
```
# Launch T004-T007 together:
Task: "XCTest coverage for view model logic in ChillTests/"
Task: "Snapshot tests asserting accessibility"
Task: "Persistence tests for local storage migrations"
Task: "UI test validating offline fallback"
```

## Notes
- [P] tasks = different files, no dependencies
- Verify tests fail before implementing
- Commit after each task
- Avoid: vague tasks, same file conflicts
- Ensure observability tickets accompany feature work; redactions happen before merge.
- Capture release toggles and rollback notes while tasks are underway, not retroactively.

## Task Generation Rules
*Applied during main() execution*

1. **From Contracts**:
   - Each contract file → contract test task [P]
   - Each endpoint → implementation task
   
2. **From Data Model**:
   - Each entity → model creation task [P]
   - Relationships → service layer tasks
   
3. **From User Stories**:
   - Each story → integration test [P]
   - Quickstart scenarios → validation tasks

4. **Ordering**:
   - Setup → Tests → Models → Services → Endpoints → Polish
   - Dependencies block parallel execution
   
5. **Constitution Alignment**:
   - Add instrumentation tasks (logs, metrics, dashboards) per Observability principle.
   - Include offline persistence and migration work for Calm State & Offline Resilience.
   - Reserve tasks for release notes, toggles, and incident prep under Release Confidence & Support.

## Validation Checklist
*GATE: Checked by main() before returning*

- [ ] All contracts have corresponding tests or acceptance harnesses
- [ ] All entities/state machines have model or view model tasks
- [ ] All tests come before implementation
- [ ] Parallel tasks truly independent
- [ ] Each task specifies exact file path or scheme
- [ ] No task modifies same file as another [P] task
- [ ] Observability, offline resilience, and release support tasks exist for every critical flow
