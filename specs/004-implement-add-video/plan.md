
# Implementation Plan: Add Video via URL Modal

**Branch**: `004-implement-add-video` | **Date**: 2025-10-04 | **Spec**: [/Users/jin/Code/Chill/specs/004-implement-add-video/spec.md](/Users/jin/Code/Chill/specs/004-implement-add-video/spec.md)
**Input**: Feature specification from `/Users/jin/Code/Chill/specs/004-implement-add-video/spec.md`

## Execution Flow (/plan command scope)
```
1. Load feature spec from Input path
   → If not found: ERROR "No feature spec at {path}"
2. Fill Technical Context (scan for NEEDS CLARIFICATION)
   → Detect Project Type from file system structure or context (mobile=app+api)
   → Set Structure Decision based on project type
3. Fill the Constitution Check section based on the content of the constitution document.
4. Evaluate Constitution Check section below
   → If violations exist: Document in Complexity Tracking
   → If no justification possible: ERROR "Simplify approach first"
   → Update Progress Tracking: Initial Constitution Check
5. Execute Phase 0 → research.md
   → If NEEDS CLARIFICATION remain: ERROR "Resolve unknowns"
6. Execute Phase 1 → contracts, data-model.md, quickstart.md, agent context update
7. Re-evaluate Constitution Check section
   → If new violations: Refactor design, return to Phase 1
   → Update Progress Tracking: Post-Design Constitution Check
8. Plan Phase 2 → Describe task generation approach (DO NOT create tasks.md)
9. STOP - Ready for /tasks command
```

**IMPORTANT**: The /plan command STOPS at step 9. Phases 2-4 are executed by other commands:
- Phase 2: /tasks command creates tasks.md
- Phase 3-4: Implementation execution (manual or via tools)

## Summary
Implement a SwiftUI modal flow that allows authenticated users to add videos to their library by pasting URLs from supported social platforms. The system validates URLs in real-time, automatically extracts metadata using LoadifyEngine.xcframework (from Loadify-iOS project), warns about duplicates while allowing submission, and gracefully handles offline scenarios by queuing submissions. The modal maintains Chill's calm design language with smooth animations, full accessibility support, and clear error messaging.

**✅ PLATFORM CLARIFIED**: Initial spec stated "Facebook + YouTube + Twitter", but LoadifyEngine does NOT support YouTube. **Final decision: Facebook + Twitter only**. This provides a focused MVP using LoadifyEngine's proven capabilities, with future expansion to TikTok + Instagram possible.

## Technical Context
**Language/Version**: Swift 6 (Xcode 16)  
**Primary Dependencies**: SwiftUI, Combine, LoadifyEngine.xcframework, supabase-swift SDK, Chill design tokens  
**Storage**: Supabase Postgres (video library storage) + local SwiftData cache for offline queue  
**Testing**: XCTest, SwiftSnapshotTesting  
**Target Platform**: iOS 18+  
**Project Type**: mobile (single iOS app module)  
**Performance Goals**: URL validation <100ms, metadata fetch <3s, modal animations 60fps  
**Constraints**: Offline-capable with queuing, MVVM separation, real-time validation, no client-side rate limiting  
**Scale/Scope**: Single modal component, 3 platform validators, LoadifyEngine integration, one new feature slice

## Constitution Check
*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- [x] **SwiftUI Experience Integrity** → Modal presentation via SwiftUI sheet with MVVM separation (`AddVideoView` / `AddVideoViewModel`), design token conformance, VoiceOver labels for all interactive elements, Dynamic Type support, and reduced motion respect.
- [x] **Calm State & Offline Resilience** → Loading/error/warning states defined; offline detection queues submissions to SwiftData; validation preserves user input on failure; smooth modal animations with backdrop fade.
- [x] **Observability With Privacy Guarantees** → Analytics track modal lifecycle (open, submit, success/failure) without URL content; structured logging for LoadifyEngine failures and duplicate warnings; no PII captured.
- [x] **Test-First Delivery** → Failing tests planned: URL validation unit tests, LoadifyEngine integration mocks, duplicate detection tests, snapshot tests for modal states, offline queuing integration tests.
- [x] **Release Confidence & Support** → Feature accessible via existing '+' FAB in VideoList; rollback via hiding modal presentation; support documentation for LoadifyEngine errors and platform-specific validation failures.

## Project Structure

### Documentation (this feature)
```
specs/004-implement-add-video/
├── plan.md              # This file (/plan command output)
├── research.md          # Phase 0 output (/plan command)
├── data-model.md        # Phase 1 output (/plan command)
├── quickstart.md        # Phase 1 output (/plan command)
├── contracts/           # Phase 1 output (/plan command)
│   └── ui-contract.md   # Modal interaction contract
└── tasks.md             # Phase 2 output (/tasks command - NOT created by /plan)
```

### Source Code (repository root)
```
Chill/
├── Chill/
│   ├── App/
│   ├── Features/
│   │   ├── Auth/
│   │   ├── SavedLinks/
│   │   ├── VideoList/
│   │   │   ├── VideoListView.swift
│   │   │   ├── VideoListViewModel.swift
│   │   │   ├── VideoCardView.swift
│   │   │   ├── VideoListCoordinator.swift
│   │   │   ├── VideoCardEntity.swift
│   │   │   └── VideoListService.swift
│   │   ├── AddVideo/                    # NEW: Add video modal feature
│   │   │   ├── AddVideoView.swift       # Modal UI
│   │   │   ├── AddVideoViewModel.swift  # Business logic
│   │   │   ├── URLValidator.swift       # Platform-specific validation
│   │   │   ├── VideoSubmissionQueue.swift  # Offline queue
│   │   │   └── AddVideoService.swift    # LoadifyEngine integration
│   │   └── Welcome/
│   ├── Resources/
│   │   ├── Config/
│   │   └── Localizable.strings          # Modal copy
│   └── Support/
│       └── DesignSystem/
│           └── DesignTokens.swift
├── LoadifyEngine.xcframework/           # Existing - metadata extraction
├── ChillTests/
│   ├── Auth/
│   ├── SavedLinks/
│   ├── Support/
│   ├── VideoList/
│   └── AddVideo/                         # NEW: Add video tests
│       ├── AddVideoViewModelTests.swift
│       ├── URLValidatorTests.swift
│       ├── AddVideoServiceTests.swift
│       ├── VideoSubmissionQueueTests.swift
│       └── AddVideoViewSnapshotTests.swift
└── ChillUITests/

supabase/
└── migrations/
    └── 005_add_video_submissions.sql     # NEW: Submission tracking table
```

**Structure Decision**: Mobile SwiftUI app with feature directories under `Chill/Chill/Features`. New `AddVideo` module mirrors existing MVVM pattern with View, ViewModel, Service, and supporting types. Modal is presented from `VideoListView` when FAB is tapped. LoadifyEngine.xcframework already integrated for metadata extraction.

## Phase 0: Outline & Research
1. **Extract unknowns from Technical Context** above:
   - LoadifyEngine API for Facebook and Twitter metadata extraction
   - URL validation patterns for each platform (including mobile variants and shortened links)
   - SwiftUI sheet presentation best practices with keyboard management
   - SwiftData offline queue implementation for failed submissions
   - Duplicate detection strategy against existing video library

2. **Generate and dispatch research agents**:
   ```
   Task: "Research LoadifyEngine API for Facebook and Twitter metadata extraction"
   Task: "Find URL validation regex patterns for Facebook and Twitter including mobile and shortened variants"
   Task: "Best practices for SwiftUI modal sheet presentation with keyboard handling"
   Task: "SwiftData offline queue implementation patterns for network requests"
   Task: "Duplicate detection strategies for video URLs with normalization"
   ```

3. **Consolidate findings** in `research.md` using format:
   - Decision: [what was chosen]
   - Rationale: [why chosen]
   - Alternatives considered: [what else evaluated]

**Output**: research.md with all LoadifyEngine integration, validation patterns, and offline queue decisions documented

## Phase 1: Design & Contracts
*Prerequisites: research.md complete*

1. **Extract entities from feature spec** → `data-model.md`:
   - `VideoSubmissionRequest`: URL, timestamp, user ID, status (pending/processing/complete/failed), retry count
   - `VideoMetadata`: Title, description, thumbnail URL, creator, platform, duration, published date (from LoadifyEngine)
   - `URLValidationResult`: Is valid, platform detected, error message, normalized URL
   - `AddVideoEvent`: Event type (open/submit/cancel/error), timestamp, outcome, error type (for analytics)

2. **Generate UI contract** from functional requirements:
   - Modal presentation contract: trigger (FAB tap), dismissal (success/cancel/backdrop), state preservation
   - Input validation contract: real-time feedback, validation rules per platform, error display
   - Submission contract: loading state, success/failure handling, offline queuing
   - Accessibility contract: VoiceOver labels, Dynamic Type, keyboard navigation
   - Output to `/contracts/ui-contract.md`

3. **Extract test scenarios** from user stories:
   - Each acceptance scenario → integration test
   - Each edge case → unit test
   - Snapshot tests for modal states (empty, valid input, error, loading, duplicate warning)
   - Mock LoadifyEngine for predictable metadata testing

4. **Update agent file incrementally** (O(1) operation):
   - Run `.specify/scripts/bash/update-agent-context.sh cursor`
   - Add: LoadifyEngine.xcframework, AddVideo feature module, SwiftUI modal patterns
   - Preserve manual additions between markers
   - Update recent changes

**Output**: data-model.md, /contracts/ui-contract.md, quickstart.md, updated AGENTS.md

## Phase 2: Task Planning Approach
*This section describes what the /tasks command will do - DO NOT execute during /plan*

**Task Generation Strategy**:
- Load `.specify/templates/tasks-template.md` as base
- Generate tasks from Phase 1 design docs (contracts, data model, quickstart)
- URL validation tasks: one per platform (Facebook, Twitter) [P]
- Data model tasks: entities and SwiftData models [P]
- Service tasks: LoadifyEngine integration, duplicate detection, offline queue
- ViewModel tasks: AddVideoViewModel with state machine
- View tasks: AddVideoView with modal presentation, validation UI, error states
- Integration tasks: Connect to VideoListView FAB, Supabase submission
- Test tasks: Unit tests for each component, snapshot tests, integration tests

**Ordering Strategy**:
- TDD order: Tests before implementation (validation tests → validators, etc.)
- Dependency order: Models → Services → ViewModel → View
- Mark [P] for parallel execution (independent validators, independent tests)

**Estimated Output**: 30-35 numbered, ordered tasks in tasks.md

**IMPORTANT**: This phase is executed by the /tasks command, NOT by /plan

## Phase 3+: Future Implementation
*These phases are beyond the scope of the /plan command*

**Phase 3**: Task execution (/tasks command creates tasks.md)  
**Phase 4**: Implementation (execute tasks.md following constitutional principles)  
**Phase 5**: Validation (run tests, execute quickstart.md, performance validation)

## Complexity Tracking
*No constitutional violations detected*

## Progress Tracking
*This checklist is updated during execution flow*

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

**Artifacts Generated**:
- [x] research.md - LoadifyEngine, URL validation, offline queue, duplicate detection
- [x] data-model.md - VideoSubmissionRequest, VideoMetadata, URLValidationResult, AddVideoEvent
- [x] contracts/ui-contract.md - Modal interaction contract with validation and submission flows
- [x] quickstart.md - Manual testing guide with comprehensive test scenarios
- [x] .cursor/rules/specify-rules.mdc - Updated with AddVideo feature context

---
**Status**: Planning complete. Ready for /tasks command to generate implementation tasks.
