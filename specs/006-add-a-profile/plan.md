# Implementation Plan: Profile Page for Settings and Account Info

**Branch**: `006-add-a-profile` | **Date**: 2025-10-07 | **Spec**: [spec.md](./spec.md)  
**Input**: Feature specification from `/specs/006-add-a-profile/spec.md`

## Execution Flow (/plan command scope)
```
1. Load feature spec from Input path ✅
   → Spec loaded successfully from /specs/006-add-a-profile/spec.md
2. Fill Technical Context ✅
   → Project Type: iOS mobile app (Swift 6/SwiftUI)
   → Structure Decision: Feature-based modules in Chill/Features/
3. Fill the Constitution Check section ✅
   → No specific constitution found - using iOS/Swift best practices
4. Evaluate Constitution Check section ✅
   → No violations detected
   → Update Progress Tracking: Initial Constitution Check ✅
5. Execute Phase 0 → research.md ✅
   → All technical decisions documented in research.md
   → No NEEDS CLARIFICATION remain (all resolved via /clarify)
6. Execute Phase 1 → contracts, data-model.md, quickstart.md ✅
   → Generated data-model.md (8 new models)
   → Generated contracts/ (ProfileService, SettingsService, PasswordChange)
   → Generated quickstart.md (12 test scenarios)
   → Updated .cursor/rules/specify-rules.mdc via update-agent-context.sh
7. Re-evaluate Constitution Check section ✅
   → No new violations introduced
   → Design follows iOS/Swift best practices
   → Update Progress Tracking: Post-Design Constitution Check ✅
8. Plan Phase 2 → Describe task generation approach ✅
9. STOP - Ready for /tasks command ✅
```

**IMPORTANT**: The /plan command STOPS at step 7. Phases 2-4 are executed by other commands:
- Phase 2: /tasks command creates tasks.md
- Phase 3-4: Implementation execution (manual or via tools)

## Summary

This feature adds a dedicated profile page for authenticated users to view their account information and manage settings. The page displays user details (email, display name, account stats) and provides two settings categories: Video Preferences (quality, autoplay) and Account Security (password change). Access is via a user avatar icon in the top-right corner.

**Key improvements**:
- Centralized location for account information and settings
- Video playback preferences (quality selection, autoplay toggle)
- Secure password change functionality
- Clear organization with scannable sections
- Full accessibility support

## Technical Context

**Language/Version**: Swift 6 (Xcode 16), SwiftUI  
**Primary Dependencies**: 
  - `supabase-swift` SDK for authentication and data persistence
  - Combine for reactive state management
  - SwiftUI for UI framework
  
**Storage**: 
  - Supabase Postgres (remote) for user profile data and settings
  - Keychain (via Supabase SDK) for secure credential storage
  
**Testing**: 
  - XCTest for unit tests
  - Snapshot testing via `SnapshotTesting` library
  - Contract tests for profile and settings services
  
**Target Platform**: iOS 15+ (existing codebase target)

**Project Type**: iOS mobile app with feature-based module structure

**Performance Goals**: 
  - < 3 seconds profile page load time
  - Instant setting change feedback
  - No UI blocking during async operations
  
**Constraints**: 
  - Must preserve existing auth session management
  - Must handle offline scenarios gracefully
  - Last-write-wins for concurrent settings updates
  - Password change must require current password verification
  
**Scale/Scope**: 
  - 1 new feature module (Profile)
  - 3-4 new view files (profile page, settings sections, password change)
  - 2 new service files (profile service, settings service)
  - ~20-25 new unit tests
  - ~8-10 snapshot tests for UI validation

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

Since no project-specific constitution file was found with enforceable rules, we'll follow iOS/Swift development best practices:

**✅ PASS - Following Swift/iOS Best Practices**:

1. **Feature Module Organization**: Keep profile feature self-contained in `Chill/Features/Profile/`
2. **SwiftUI View Composition**: Break down complex views into smaller, reusable components
3. **MVVM Pattern**: Maintain existing ViewModel pattern for business logic separation
4. **Test Coverage**: Unit tests for ViewModel and Services, snapshot tests for Views
5. **Accessibility**: Proper `accessibilityLabel`, `accessibilityIdentifier`, `accessibilityHint` usage
6. **Type Safety**: Leverage Swift's strong typing and enums for settings and state management
7. **Dependency Injection**: Protocol-based service injection (following existing patterns)
8. **Error Handling**: Structured error types with user-friendly mappings
9. **Security**: Secure password change with current password verification

**No violations detected** - Design aligns with existing codebase patterns.

## Project Structure

### Documentation (this feature)
```
specs/006-add-a-profile/
├── plan.md              # This file (/plan command output)
├── spec.md              # Feature specification (already exists)
├── research.md          # Phase 0 output (/plan command)
├── data-model.md        # Phase 1 output (/plan command)
├── quickstart.md        # Phase 1 output (/plan command)
├── contracts/           # Phase 1 output (/plan command)
└── tasks.md             # Phase 2 output (/tasks command - NOT created by /plan)
```

### Source Code (repository root)

This is an iOS mobile app with a feature-based module structure:

```
Chill/
├── App/
│   ├── AuthCoordinator.swift          # [UNCHANGED]
│   └── AuthConfiguration.swift        # [UNCHANGED]
│
├── Features/
│   ├── Profile/                       # [NEW] Profile feature module
│   │   ├── Views/
│   │   │   ├── ProfileView.swift                 # [NEW] Main profile page
│   │   │   ├── ProfileHeaderView.swift           # [NEW] Account info section
│   │   │   ├── VideoPreferencesView.swift        # [NEW] Video settings section
│   │   │   ├── AccountSecurityView.swift         # [NEW] Security settings section
│   │   │   └── ChangePasswordView.swift          # [NEW] Password change flow
│   │   │
│   │   ├── ViewModels/
│   │   │   ├── ProfileViewModel.swift            # [NEW] Profile state management
│   │   │   └── ChangePasswordViewModel.swift     # [NEW] Password change logic
│   │   │
│   │   ├── Services/
│   │   │   ├── ProfileService.swift              # [NEW] Profile data fetching
│   │   │   └── SettingsService.swift             # [NEW] Settings persistence
│   │   │
│   │   └── Models/
│   │       ├── ProfileModels.swift               # [NEW] Profile entities, settings enums
│   │       └── ProfileAnalytics.swift            # [NEW] Analytics events
│   │
│   ├── Auth/                          # [EXISTING]
│   ├── VideoList/                     # [MODIFY] Add avatar button
│   └── [other features]
│
└── Resources/
    └── [existing localization files]

ChillTests/
└── Profile/                           # [NEW] Profile test suite
    ├── ProfileViewModelTests.swift
    ├── ProfileServiceTests.swift
    ├── SettingsServiceTests.swift
    ├── ChangePasswordViewModelTests.swift
    ├── ProfileContractTests.swift
    └── ProfileViewSnapshotTests.swift
```

**Structure Decision**: iOS mobile app with feature-based modules. Profile feature is self-contained within `Chill/Features/Profile/` following existing project patterns. Views organized in `Views/` subfolder, ViewModels in `ViewModels/`, Services in `Services/`, and Models in `Models/`.

## Phase 0: Outline & Research ✅

**Status**: Complete - See `research.md`

**Key Decisions Made**:
1. **Settings Storage**: Supabase user_metadata (no new tables needed)
2. **Profile Data**: Combine auth session + stats query for efficiency
3. **Password Change**: In-place update with modal flow, requires current password
4. **User Avatar**: SF Symbol `person.circle.fill` (simple, native)
5. **Display Name**: Store in user_metadata, default to email prefix
6. **Video Stats**: COUNT query on existing videos table
7. **Last Login**: Timestamp in user_metadata, updated on auth
8. **Offline**: Cache profile data, show staleness indicator

**Output**: `/specs/006-add-a-profile/research.md`

## Phase 1: Design & Contracts ✅

**Status**: Complete

**Artifacts Generated**:

1. **Data Model** (`data-model.md`):
   - `UserProfile` struct (aggregated account info)
   - `VideoPreferences` struct with `VideoQuality` enum
   - `PasswordChangeRequest` struct for validation
   - `ProfileError` enum for error handling
   - `ProfileLoadingState` enum for UI state
   - Analytics models for tracking

2. **Contracts** (`contracts/`):
   - `ProfileService.md`: Profile data loading contract with 6+ tests
   - `SettingsService.md`: Settings persistence contract with 8+ tests
   - `PasswordChange.md`: Password change security contract with 6+ tests

3. **Quickstart Guide** (`quickstart.md`):
   - 12 comprehensive test scenarios covering:
     - Profile access via avatar icon
     - Account information display
     - Video quality and autoplay settings changes
     - Password change (success and error cases)
     - Performance validation (3-second load)
     - Offline behavior
     - Sign out functionality
     - Accessibility with VoiceOver
     - Settings persistence
   - Success criteria and acceptance sign-off
   - Rollback plan

4. **Agent Context** (`.cursor/rules/specify-rules.mdc`):
   - Updated via `update-agent-context.sh cursor`
   - Added Swift 6 / SwiftUI context
   - Preserved existing manual additions

**Key Design Decisions**:
- Profile as aggregated view (no new tables)
- Settings in user_metadata (leverages Supabase)
- Password change with security validation
- Last-write-wins for concurrent updates
- Offline caching with staleness indicators

**Output**: data-model.md, /contracts/*, quickstart.md, agent context updated

## Phase 2: Task Planning Approach ✅

**Status**: Complete - Ready for `/tasks` command

**Task Generation Strategy**:
- Load `.specify/templates/tasks-template.md` as base
- Generate tasks from Phase 1 design docs (contracts, data model, quickstart)
- Follow TDD approach: Write failing tests first, then implementation

**Task Categories**:

1. **Model Creation** (4-5 tasks, [P] = parallel):
   - Add `UserProfile` struct to `ProfileModels.swift`
   - Add `VideoPreferences` and `VideoQuality` enum
   - Add `PasswordChangeRequest` validation struct
   - Add `ProfileError` and `ProfileLoadingState` enums
   - Add `ProfileEventType` and `ProfileEventPayload` for analytics

2. **Service Layer** (4-5 tasks):
   - Create `ProfileService` with loadProfile() method
   - Add contract tests for ProfileService (6 tests)
   - Create `SettingsService` with load/update methods
   - Add contract tests for SettingsService (8 tests)
   - Add password change tests to AuthService (6 tests)

3. **ViewModel Layer** (3-4 tasks):
   - Create `ProfileViewModel` with loading state management
   - Create `ChangePasswordViewModel` with validation logic
   - Add unit tests for ProfileViewModel
   - Add unit tests for ChangePasswordViewModel

4. **View Components** (6-7 tasks, some [P]):
   - Create `ProfileView` (main container)
   - Create `ProfileHeaderView` (account info display)
   - Create `VideoPreferencesView` (settings section)
   - Create `AccountSecurityView` (password change button)
   - Create `ChangePasswordView` (modal)
   - Add avatar icon to VideoListView navigation
   - Add snapshot tests for each view (5 tests)

5. **Integration** (3-4 tasks):
   - Wire profile navigation to avatar icon
   - Implement sign out from profile
   - Add integration tests for complete flows (12 quickstart scenarios)
   - Add offline behavior and caching

6. **Analytics & Polish** (2-3 tasks, [P]):
   - Add analytics tracking for profile events
   - Add accessibility labels and identifiers
   - Performance optimization (< 3 second load)

**Ordering Strategy**:
- TDD order: Tests before implementation
- Dependency order: Models → Services → ViewModels → Views
- Mark [P] for parallel execution (independent files)

**Estimated Output**: 28-32 numbered, ordered tasks in tasks.md

**IMPORTANT**: This phase is executed by the /tasks command, NOT by /plan

## Phase 3+: Future Implementation
*These phases are beyond the scope of the /plan command*

**Phase 3**: Task execution (/tasks command creates tasks.md)  
**Phase 4**: Implementation (execute tasks.md following constitutional principles)  
**Phase 5**: Validation (run tests, execute quickstart.md, performance validation)

## Complexity Tracking

*Fill ONLY if Constitution Check has violations that must be justified*

No complexity deviations identified. This feature is a straightforward addition that:
- Follows existing feature module patterns
- Uses established auth infrastructure
- No new dependencies introduced
- Leverages Supabase user_metadata (already in use)
- Standard iOS/SwiftUI patterns throughout


## Progress Tracking
*This checklist is updated during execution flow*

**Phase Status**:
- [x] Phase 0: Research complete (/plan command)
  - ✅ research.md created with all technical decisions
- [x] Phase 1: Design complete (/plan command)
  - ✅ data-model.md created
  - ✅ contracts/ProfileService.md created
  - ✅ contracts/SettingsService.md created
  - ✅ contracts/PasswordChange.md created
  - ✅ quickstart.md created with 12 test scenarios
  - ✅ .cursor/rules/specify-rules.mdc updated
- [x] Phase 2: Task planning complete (/plan command - describe approach only)
  - ✅ Task generation strategy documented
  - ✅ 28-32 tasks estimated
  - ✅ Dependency graph defined
- [x] Phase 3: Tasks generated (/tasks command)
  - ✅ tasks.md created with 35 ordered tasks (T001-T035)
  - ✅ TDD workflow enforced (tests before implementation)
  - ✅ Parallel execution markers [P] applied
  - ✅ Dependencies mapped in graph
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
  - ✅ Settings scope defined (video + security)
  - ✅ Navigation entry point specified (avatar icon)
  - ✅ Profile fields clarified (display name, stats, last login)
  - ✅ Performance target set (3 seconds)
  - ✅ Conflict resolution defined (last-write-wins)
- [x] Complexity deviations documented
  - ✅ No deviations - design follows existing patterns

---

## Summary

**Planning Phase Complete** ✅

The implementation plan for the profile page feature is ready for task generation.

**Key Deliverables**:
1. ✅ Technical research with all decisions documented
2. ✅ Data model design with profile, settings, and error models
3. ✅ Contracts defining service behavior and test requirements
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

**Branch**: `006-add-a-profile`  
**Specification**: `specs/006-add-a-profile/spec.md`  
**Planning Docs**: `specs/006-add-a-profile/` (research, data-model, contracts, quickstart, plan)

---
*Based on iOS/Swift Best Practices - No project constitution found*
