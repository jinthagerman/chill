# Implementation Plan: Split Login and Signup Screens with Enhanced UX

**Branch**: `005-split-login-and` | **Date**: 2025-10-07 | **Spec**: [spec.md](./spec.md)  
**Input**: Feature specification from `/specs/005-split-login-and/spec.md`

## Execution Flow (/plan command scope)
```
1. Load feature spec from Input path ✅
   → Spec loaded successfully
2. Fill Technical Context ✅
   → Project Type: iOS mobile app (Swift/SwiftUI)
   → Structure Decision: Single app with feature-based modules
3. Fill the Constitution Check section ✅
   → No constitution file with specific requirements found - using Swift/iOS best practices
4. Evaluate Constitution Check section ✅
   → No violations detected
   → Update Progress Tracking: Initial Constitution Check ✅
5. Execute Phase 0 → research.md ✅
   → All technical decisions documented in research.md
6. Execute Phase 1 → contracts, data-model.md, quickstart.md, AGENTS.md ✅
   → Generated data-model.md (navigation and error models)
   → Generated contracts/ (AuthNavigation.md, ErrorMapping.md)
   → Generated quickstart.md (12 test scenarios)
   → Updated .cursor/rules/specify-rules.mdc via update-agent-context.sh
7. Re-evaluate Constitution Check section ✅
   → No new violations introduced
   → Design follows iOS/Swift best practices
   → Update Progress Tracking: Post-Design Constitution Check ✅
8. Plan Phase 2 → Describe task generation approach ✅
9. STOP - Ready for /tasks command ✅
```

**IMPORTANT**: The /plan command STOPS at step 9. Phases 2-4 are executed by other commands:
- Phase 2: /tasks command creates tasks.md
- Phase 3-4: Implementation execution (manual or via tools)

## Summary

This feature refactors the existing authentication UI to split the combined login/signup interface (currently using a segmented control) into three separate, dedicated screens:

1. **Initial Choice Screen**: Entry point with "Sign In" and "Create Account" buttons
2. **Login Screen**: Dedicated screen for returning users with email/password fields
3. **Signup Screen**: Dedicated screen for new users with email/password/confirm password/consent fields

**Key improvements**:
- Clearer user experience by separating flows
- Enhanced error messaging with specific, actionable messages mapped from Supabase error codes
- Password manager integration via proper `textContentType` hints for autofill/autosave
- Improved accessibility with proper semantic labels
- Navigation improvements with back support and state clearing

**Technical Approach**:
- Refactor existing `AuthView` into three separate SwiftUI views
- Introduce navigation coordinator to manage screen transitions
- Extend `AuthViewModel` to support new navigation states
- Update `AuthService` error mapping to include duplicate email error
- Maintain existing password reset flow unchanged
- Preserve all analytics, network monitoring, and session management

## Technical Context

**Language/Version**: Swift 6 (Xcode 16), SwiftUI  
**Primary Dependencies**: 
  - `supabase-swift` SDK for authentication
  - Combine for reactive state management
  - SwiftUI for UI framework
  
**Storage**: 
  - Keychain (via Supabase SDK) for secure credential storage
  - System password manager integration via `textContentType` APIs
  
**Testing**: 
  - XCTest for unit tests
  - Snapshot testing via `SnapshotTesting` library
  - Contract tests for AuthService
  
**Target Platform**: iOS 15+ (inferred from existing codebase)

**Project Type**: Single iOS app with feature-based module structure

**Performance Goals**: 
  - < 100ms view transition between auth screens
  - Instant form validation feedback
  - No UI blocking during async authentication operations
  
**Constraints**: 
  - Must preserve existing AuthService, AuthViewModel analytics
  - Must maintain compatibility with existing password reset flow
  - Must not break existing session management
  - Navigation must feel native (standard iOS patterns)
  
**Scale/Scope**: 
  - 3 new view files (choice, login, signup screens)
  - 1 navigation coordinator
  - Updates to AuthViewModel for navigation state
  - ~15-20 new unit tests
  - ~10 snapshot tests for UI validation

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

Since no project-specific constitution file was found with enforceable rules, we'll follow iOS/Swift development best practices:

**✅ PASS - Following Swift/iOS Best Practices**:

1. **Feature Module Organization**: Keep auth feature self-contained in `Chill/Features/Auth/`
2. **SwiftUI View Composition**: Break down complex views into smaller, reusable components
3. **MVVM Pattern**: Maintain existing ViewModel pattern for business logic separation
4. **Test Coverage**: Unit tests for ViewModel, snapshot tests for Views
5. **Accessibility**: Proper `accessibilityLabel`, `accessibilityIdentifier`, `accessibilityHint` usage
6. **Type Safety**: Leverage Swift's strong typing and enums for state management
7. **Dependency Injection**: Protocol-based service injection (existing `AuthServiceType`)
8. **Error Handling**: Structured error types with user-friendly mappings

**No violations detected** - Design aligns with existing codebase patterns.

## Project Structure

### Documentation (this feature)
```
specs/005-split-login-and/
├── plan.md              # This file (/plan command output)
├── spec.md              # Feature specification (already exists)
├── research.md          # Phase 0 output (/plan command)
├── data-model.md        # Phase 1 output (/plan command)
├── quickstart.md        # Phase 1 output (/plan command)
├── contracts/           # Phase 1 output (/plan command)
│   ├── AuthNavigation.md     # Navigation state contract
│   └── ErrorMapping.md       # Error message mapping contract
└── tasks.md             # Phase 2 output (/tasks command - NOT created by /plan)
```

### Source Code (repository root)

This is an iOS mobile app with a feature-based module structure:

```
Chill/
├── App/
│   ├── AuthCoordinator.swift          # [MODIFY] Add navigation coordinator
│   └── AuthConfiguration.swift        # [UNCHANGED]
│
├── Features/
│   └── Auth/
│       ├── Views/
│       │   ├── AuthView.swift                    # [REMOVE] Legacy combined view
│       │   ├── AuthChoiceView.swift             # [NEW] Initial choice screen
│       │   ├── AuthLoginView.swift              # [NEW] Dedicated login screen
│       │   ├── AuthSignupView.swift             # [NEW] Dedicated signup screen
│       │   └── AuthNavigationCoordinator.swift  # [NEW] Navigation flow manager
│       │
│       ├── ViewModels/
│       │   └── AuthViewModel.swift      # [MODIFY] Add navigation state support
│       │
│       ├── Services/
│       │   └── AuthService.swift        # [MODIFY] Add duplicate email error mapping
│       │
│       └── Models/
│           ├── AuthModels.swift         # [MODIFY] Add AuthNavigationState enum
│           └── AuthAnalytics.swift      # [UNCHANGED]
│
└── Resources/
    └── [existing localization files]

ChillTests/
└── Auth/
    ├── AuthViewModelTests.swift         # [MODIFY] Add navigation state tests
    ├── AuthServiceTests.swift           # [MODIFY] Add error mapping tests
    ├── AuthFlowContractTests.swift      # [MODIFY] Add navigation contract tests
    ├── AuthFlowViewSnapshotTests.swift  # [MODIFY] Add snapshot tests for new views
    └── AuthNavigationTests.swift        # [NEW] Navigation coordinator tests
```

**Structure Decision**: Single iOS app with feature-based modules. Auth feature is self-contained within `Chill/Features/Auth/` following existing project patterns. Views organized in `Views/` subfolder, ViewModels in `ViewModels/`, Services in `Services/`, and Models in `Models/`.

## Phase 0: Outline & Research ✅

**Status**: Complete - See `research.md`

**Key Decisions Made**:
1. **Navigation**: Custom coordinator with AnyView (iOS 15 compatible)
2. **Password Manager**: Use `.textContentType(.username/.password/.newPassword)` appropriately
3. **Error Codes**: Complete mapping table from Supabase codes to user messages
4. **State Management**: ViewModel-driven with `@Published navigationState`
5. **Accessibility**: Full VoiceOver support with proper labels and hints

**Output**: `/specs/005-split-login-and/research.md`

---

## Phase 1: Design & Contracts ✅

**Status**: Complete

**Artifacts Generated**:

1. **Data Model** (`data-model.md`):
   - `AuthNavigationState` enum with `.choice`, `.login`, `.signup`, `.resetRequest`, `.resetVerify`
   - Extended `AuthError` with `.duplicateEmail` case
   - Form state management patterns
   - State transition diagram
   - Validation rules and invariants

2. **Contracts** (`contracts/`):
   - `AuthNavigation.md`: Navigation state transitions contract with 15+ tests
   - `ErrorMapping.md`: Backend error → user message mapping contract with 10+ tests

3. **Quickstart Guide** (`quickstart.md`):
   - 12 comprehensive test scenarios covering:
     - Initial choice screen
     - Login/signup navigation
     - Error handling (invalid credentials, duplicate email, password mismatch)
     - Back navigation and state clearing
     - Password manager integration
     - Accessibility with VoiceOver
     - Offline handling
     - Stress testing
   - Success criteria and acceptance sign-off
   - Rollback plan

4. **Agent Context** (`.cursor/rules/specify-rules.mdc`):
   - Updated via `update-agent-context.sh cursor`
   - Added Swift 6 / SwiftUI context
   - Preserved existing manual additions

**Key Design Decisions**:
- Three-screen flow: Choice → Login/Signup → Back to Choice
- Navigation state as source of truth in ViewModel
- Form state cleared on return to choice
- Comprehensive error mapping including new duplicate email case
- Password manager integration via native iOS APIs
- Full accessibility support

---

## Phase 2: Task Planning Approach ✅

**Status**: Complete - Ready for `/tasks` command


**Task Generation Strategy**:
- Load `.specify/templates/tasks-template.md` as base
- Generate tasks from Phase 1 design docs (contracts, data model, quickstart)
- Follow TDD approach: Write failing tests first, then implementation

**Task Categories**:

1. **Model Updates** (3-4 tasks, [P] = parallel):
   - Add `AuthNavigationState` enum to `AuthModels.swift`
   - Add `.duplicateEmail` case to `AuthError` enum
   - Add `AuthField` enum for focus management
   - Update `AuthViewModel` to use `navigationState` property

2. **Service Layer** (2 tasks):
   - Update `AuthService.mapClientError()` to handle `user_already_exists` code
   - Add contract tests for duplicate email error mapping

3. **View Components** (6-8 tasks, some [P]):
   - Create `AuthChoiceView.swift` (choice screen)
   - Create `AuthLoginView.swift` (dedicated login screen)
   - Create `AuthSignupView.swift` (dedicated signup screen)
   - Update `AuthCoordinator.swift` to use navigation state
   - Remove legacy `AuthView.swift` (combined view)
   - Add snapshot tests for each new view

4. **Navigation Logic** (3-4 tasks):
   - Add navigation methods to `AuthViewModel` (navigateToLogin, navigateToSignup, navigateToChoice)
   - Add state clearing logic in navigation methods
   - Add contract tests for navigation transitions (per AuthNavigation.md)
   - Add integration tests for complete navigation flows

5. **Error Messaging** (2-3 tasks):
   - Update `AuthViewModel.message(for:)` to handle `.duplicateEmail`
   - Add client-side password mismatch validation
   - Add contract tests for error mapping (per ErrorMapping.md)

6. **Password Manager Integration** (2 tasks):
   - Configure `.textContentType()` appropriately in all views
   - Add manual test documentation for password manager behavior

7. **Accessibility** (2 tasks, [P]):
   - Add accessibility identifiers to all new views
   - Add accessibility labels and hints per quickstart.md

8. **Integration Testing** (3-4 tasks):
   - Implement quickstart scenarios 1-8 as automated tests
   - Add UI tests for navigation flow
   - Add snapshot tests for error states

**Estimated Output**: 28-32 numbered, ordered tasks in tasks.md

**IMPORTANT**: This phase is executed by the /tasks command, NOT by /plan

---

## Phase 3+: Future Implementation
*These phases are beyond the scope of the /plan command*

**Phase 3**: Task execution (/tasks command creates tasks.md)  
**Phase 4**: Implementation (execute tasks.md following TDD principles)  
**Phase 5**: Validation (run tests, execute quickstart.md, verify all scenarios pass)

---

## Complexity Tracking
*Fill ONLY if Constitution Check has violations that must be justified*

No complexity deviations identified. This feature is a straightforward UI refactoring that:
- Maintains existing architectural patterns
- Extends (not replaces) existing models
- Follows iOS/Swift best practices
- Uses standard SwiftUI navigation patterns
- No new dependencies introduced

---

## Progress Tracking
*This checklist is updated during execution flow*

**Phase Status**:
- [x] Phase 0: Research complete (/plan command)
  - ✅ research.md created with all technical decisions
- [x] Phase 1: Design complete (/plan command)
  - ✅ data-model.md created
  - ✅ contracts/AuthNavigation.md created
  - ✅ contracts/ErrorMapping.md created
  - ✅ quickstart.md created with 12 test scenarios
  - ✅ .cursor/rules/specify-rules.mdc updated
- [x] Phase 2: Task planning complete (/plan command - describe approach only)
  - ✅ Task generation strategy documented
  - ✅ 28-32 tasks estimated
  - ✅ Dependency graph defined
- [ ] Phase 3: Tasks generated (/tasks command)
- [ ] Phase 4: Implementation complete
- [ ] Phase 5: Validation passed

**Gate Status**:
- [x] Initial Constitution Check: PASS
  - ✅ No constitution violations
  - ✅ Follows iOS/Swift best practices
- [x] Post-Design Constitution Check: PASS
  - ✅ Design maintains patterns from existing codebase
  - ✅ No new complexity introduced
- [x] All NEEDS CLARIFICATION resolved
  - ✅ Navigation pattern selected
  - ✅ Password manager approach clarified
  - ✅ Error mapping complete
- [x] Complexity deviations documented
  - ✅ No deviations - design is straightforward refactoring

---

## Summary

**Planning Phase Complete** ✅

The implementation plan for splitting login and signup screens is ready for task generation.

**Key Deliverables**:
1. ✅ Technical research with all decisions documented
2. ✅ Data model design with navigation state and error extensions
3. ✅ Contracts defining navigation and error mapping behavior
4. ✅ Quickstart guide with 12 comprehensive test scenarios
5. ✅ Agent context updated for Cursor IDE
6. ✅ Task generation strategy defined

**Next Command**: `/tasks`

This will generate the detailed, ordered task list (`tasks.md`) following the TDD approach defined in Phase 2.

**Estimated Timeline**:
- Task generation: ~5 minutes
- Implementation: ~2-3 days (28-32 tasks)
- Testing & validation: ~1 day
- Total: ~3-4 days

**Branch**: `005-split-login-and`  
**Specification**: `specs/005-split-login-and/spec.md`  
**Planning Docs**: `specs/005-split-login-and/` (research, data-model, contracts, quickstart, plan)

---
*Based on iOS/Swift Best Practices - No project constitution found*
