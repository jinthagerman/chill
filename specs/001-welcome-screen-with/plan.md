# Implementation Plan: Welcome Screen With Login and Signup

**Branch**: `001-welcome-screen-with` | **Date**: 2025-10-04 | **Spec**: [/Users/jin/Code/Chill/specs/001-welcome-screen-with/spec.md](/Users/jin/Code/Chill/specs/001-welcome-screen-with/spec.md)
**Input**: Feature specification from `/Users/jin/Code/Chill/specs/001-welcome-screen-with/spec.md`

## Execution Flow (/plan command scope)
```
1. Load feature spec from Input path
   → If not found: ERROR "No feature spec at {path}"
2. Fill Technical Context (scan for NEEDS CLARIFICATION)
   → Detect Project Type from file system structure or context (mobile = iOS SwiftUI app)
   → Set Structure Decision based on project type
3. Fill the Constitution Check section referencing /memory/constitution.md commitments.
4. Evaluate Constitution Check section below
   → If violations exist: Document in Complexity Tracking
   → If no justification possible: ERROR "Simplify approach first"
   → Update Progress Tracking: Initial Constitution Check
5. Execute Phase 0 → research.md (document decisions on interaction, content, accessibility, observability)
   → If NEEDS CLARIFICATION remain: ERROR "Resolve unknowns"
6. Execute Phase 1 → contracts/, data-model.md, quickstart.md, agent context update
7. Re-evaluate Constitution Check section
   → If new violations: Refactor design, return to Phase 1
   → Update Progress Tracking: Post-Design Constitution Check
8. Plan Phase 2 → Describe task generation approach (DO NOT create tasks.md)
9. STOP - Ready for /tasks command
```

**IMPORTANT**: The /plan command STOPS at step 7. Phases 2-4 are executed by other commands:
- Phase 2: /tasks command creates tasks.md
- Phase 3-4: Implementation execution (manual or via tools)

## Summary
Create a SwiftUI welcome surface that introduces Chill, displays marketing copy and imagery, and shows enabled "Log In" and "Sign Up" buttons that presently perform no navigation. The UI must be accessible, offline-safe, and telemetry-free until authentication capabilities ship.

## Technical Context
**Language/Version**: Swift 6 toolchain (Xcode 16)  
**Primary Dependencies**: SwiftUI, Chill design tokens (Assets.xcassets, shared spacing/typography helpers)  
**Storage**: N/A (stateless presentation)  
**Testing**: XCTest with SwiftUI snapshot tests and view-model units (UI automation deferred until authentication is wired)  
**Target Platform**: iOS 18.0+ (matches `IPHONEOS_DEPLOYMENT_TARGET` 26.0)  
**Project Type**: mobile (single iOS app target)  
**Performance Goals**: Maintain 60 fps during animations; initial render under 200 ms on A16-class devices  
**Constraints**: Must support Dynamic Type up to XXXL, VoiceOver, reduced motion, and operate fully offline  
**Scale/Scope**: Single-screen entry surface with two CTAs and future-ready hooks for authentication enablement

## Constitution Check
- [x] **SwiftUI Experience Integrity** → Dedicated `WelcomeView` + `WelcomeViewModel` keep rendering in SwiftUI with MVVM boundaries, Dynamic Type testing, VoiceOver copy, and shared tokens.
- [x] **Calm State & Offline Resilience** → State diagram limited to default/large type/reduced motion; no network calls; helper copy explains inactive CTAs.
- [x] **Observability With Privacy Guarantees** → No analytics emitted; backlog ticket documented for future activation before logging is introduced.
- [x] **Test-First Delivery** → Plan includes failing UI snapshot + view model unit tests written before implementation.
- [x] **Release Confidence & Support** → Release readiness captured via manual QA checklist and documentation; rollout can ship directly once validation passes (no feature flag).

## Project Structure

### Documentation (this feature)
```
specs/001-welcome-screen-with/
├── plan.md
├── spec.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/
│   └── ui-contract.md
└── tasks.md  # generated via /tasks (future)
```

### Source Code (repository root)
```
Chill/
└── Chill/
    ├── App/
    │   └── ChillApp.swift
    ├── Features/
    │   └── Welcome/
    │       ├── WelcomeView.swift
    │       ├── WelcomeViewModel.swift
    │       ├── WelcomeContent.swift
    │       ├── WelcomeView+Preview.swift
    │       └── Assets/
    │           └── WelcomeBackground.imageset
    └── Support/
        └── DesignSystem/
            ├── Colors.swift
            └── Typography.swift

ChillTests/
└── Welcome/
    ├── WelcomeViewModelTests.swift
    └── WelcomeViewSnapshotTests.swift

ChillUITests/
└── Welcome/
    └── WelcomeFlowUITests.swift
```

**Structure Decision**: Mobile app with SwiftUI MVVM slices. Introduce `Features/Welcome` namespace under `Chill/Chill` for composable onboarding surfaces and mirror test directories in `ChillTests` and `ChillUITests`.

## Phase 0: Outline & Research
1. Map clarifications to research tasks (button behavior, messaging ownership, accessibility guarantees, analytics postponement).
2. Produce `research.md` capturing decisions, rationale, and rejected alternatives for interaction, content management, accessibility, and observability (completed).
3. Use research outcomes to seed Technical Context and Constitution checklist; confirm no remaining unknowns.

## Phase 1: Design & Contracts
1. Translate spec into `data-model.md`, defining `WelcomeViewModel`, supporting types, and future authentication hooks (completed).
2. Document UI interaction contract in `/contracts/ui-contract.md` since no backend APIs are involved; ensure behavior table covers tap/no-op expectations (completed).
3. Outline accessibility, manual QA, and simulator workflow in `quickstart.md` (completed).
4. Update agent context via `.specify/scripts/bash/update-agent-context.sh codex` to record SwiftUI/mobile stack details (completed; re-run post-plan if new tech surfaces).

## Phase 2: Task Planning Approach
- Derive tasks from contract scenarios (render default state, large type layout, reduced motion behavior).
- Create unit tests for `WelcomeViewModel` states before wiring view.
- Author snapshot tests validating enabled-but-inactive buttons; defer UI automation until Supabase authentication is implemented.
- Sequence: establish design tokens updates → implement view model → build view hierarchy → wire ContentView entry → add previews/tests → polish accessibility copy → finalize documentation.
- Mark parallelizable tasks (`[P]`) for asset preparation and localization scaffolding.

## Phase 3+: Future Implementation
- Phase 3 (`/tasks`): generate executable task list from this plan.
- Phase 4: execute tasks with test-first discipline; ensure documentation reflects launch copy and support guidance.
- Phase 5: validate via Xcode tests, preview audit, and manual accessibility checklist before rollout.

## Complexity Tracking
*(No constitutional deviations identified.)*

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|

## Progress Tracking

**Phase Status**:
- [x] Phase 0: Research complete (/plan command)
- [x] Phase 1: Design complete (/plan command)
- [x] Phase 2: Task planning complete (/plan command - describe approach only)
- [ ] Phase 3: Tasks generated (/tasks command)
- [ ] Phase 4: Implementation complete
- [ ] Phase 5: Validation passed

**Gate Status**:
- [x] Initial Constitution Check: PASS
- [x] Post-Design Constitution Check: PASS
- [x] All NEEDS CLARIFICATION resolved
- [x] Complexity deviations documented

---
*Based on Constitution v1.1.0 - See `/Users/jin/Code/Chill/.specify/memory/constitution.md`*
