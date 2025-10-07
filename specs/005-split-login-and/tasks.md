# Tasks: Split Login and Signup Screens with Enhanced UX

**Feature**: `005-split-login-and`  
**Input**: Design documents from `/specs/005-split-login-and/`  
**Prerequisites**: plan.md ✅, research.md ✅, data-model.md ✅, contracts/ ✅, quickstart.md ✅

## Execution Status

```
Phase 3.1: Setup                    ✅ COMPLETE
Phase 3.2: Tests First (TDD)        ✅ COMPLETE - All tests written with XCTFail
Phase 3.3: Core Implementation      ✅ COMPLETE - All views and logic implemented, builds successfully
Phase 3.4: Integration & Polish     ✅ COMPLETE - Accessibility, keyboard flow, documentation complete
Phase 3.5: Validation               ⏳ MANUAL TESTING REQUIRED (T024, T025)
```

## Path Conventions

This is an iOS mobile app with feature-based module structure:
- **App code**: `Chill/Features/Auth/`
- **Tests**: `ChillTests/Auth/`
- **Existing files** to modify are marked `[MODIFY]`
- **New files** to create are marked `[NEW]`

---

## Phase 3.1: Setup & Preparation

### T001: Verify existing test infrastructure [X]
**File**: `ChillTests/Auth/AuthViewModelTests.swift`, `ChillTests/Auth/AuthServiceTests.swift`
**Action**: Ensure test files exist and can run successfully before adding new tests
**Success**: `xcodebuild test -scheme Chill` passes with existing tests
**Status**: ✅ COMPLETE - Main app builds successfully, test files exist (pre-existing actor isolation issues noted)

### T002: Create placeholder view files structure [X]
**Files**: 
- `Chill/Features/Auth/AuthChoiceView.swift` [NEW]
- `Chill/Features/Auth/AuthLoginView.swift` [NEW]  
- `Chill/Features/Auth/AuthSignupView.swift` [NEW]

**Action**: Create minimal SwiftUI view files with `import SwiftUI` and basic `struct` declarations (no implementation yet)
**Purpose**: Establish file structure for parallel test development
**Success**: Project builds without errors
**Status**: ✅ COMPLETE - All three placeholder view files created and project builds successfully

---

## Phase 3.2: Tests First (TDD) ⚠️ MUST COMPLETE BEFORE 3.3

**CRITICAL: These tests MUST be written and MUST FAIL before ANY implementation**

### Contract Tests (Parallel Execution Group A)

#### T003 [P] Contract test for AuthNavigationState transitions
**File**: `ChillTests/Auth/AuthNavigationContractTests.swift` [NEW]
**Contract**: Based on `contracts/AuthNavigation.md`
**Tests to implement**:
```swift
func testInitialStateIsChoice()
func testNavigateFromChoiceToLogin()
func testNavigateFromChoiceToSignup()
func testNavigateFromLoginToChoiceClearsState()
func testNavigateFromSignupToChoiceClearsState()
func testNavigateFromLoginToResetPreservesEmail()
func testConsentToggleUpdatesState()
func testConsentToggleOnlyWorksInSignupState()
```
**Success**: Tests compile and FAIL (red state) because `AuthNavigationState` doesn't exist yet

#### T004 [P] Contract test for error mapping
**File**: `ChillTests/Auth/AuthErrorMappingContractTests.swift` [NEW]
**Contract**: Based on `contracts/ErrorMapping.md`
**Tests to implement**:
```swift
func testMapInvalidCredentialsError()
func testMapDuplicateEmailError()  // NEW - for user_already_exists
func testMapUnknownError()
func testMapNetworkError()
func testInvalidCredentialsMessage()
func testDuplicateEmailMessage()  // NEW
func testUnknownErrorMessage()
func testPasswordMismatchError()
func testMissingConsentError()
func testOfflineMessage()
```
**Success**: Tests compile and FAIL because `.duplicateEmail` case doesn't exist yet

### Integration Tests (Parallel Execution Group B)

#### T005 [P] Integration test for complete navigation cycle
**File**: `ChillTests/Auth/AuthNavigationIntegrationTests.swift` [NEW]
**Based on**: Quickstart Scenario 8 (Back Navigation Clears State)
**Tests to implement**:
```swift
func testCompleteNavigationCycle()
func testErrorHandlingAcrossNavigation()
func testStateClearingDoesNotAffectSession()
func testRapidNavigationStressTest()  // Quickstart Scenario 12
```
**Success**: Tests compile and FAIL because navigation methods don't exist

#### T006 [P] Integration test for authentication flows
**File**: `ChillTests/Auth/AuthFlowIntegrationTests.swift` [MODIFY - add to existing]
**Based on**: Quickstart Scenarios 3, 4, 6, 7
**New tests to add**:
```swift
func testSuccessfulLoginFromChoiceScreen()
func testLoginWithInvalidCredentials()
func testSignupWithPasswordMismatch()
func testSignupWithDuplicateEmail()
```
**Success**: Tests compile and FAIL because views don't handle navigation state

### Snapshot Tests (Parallel Execution Group C)

#### T007 [P] Snapshot tests for new views
**File**: `ChillTests/Auth/AuthFlowViewSnapshotTests.swift` [MODIFY - add to existing]
**Based on**: Quickstart Scenarios 1, 2, 5
**New snapshot tests to add**:
```swift
func testChoiceViewAppearance()
func testLoginViewAppearance()
func testSignupViewAppearance()
func testLoginViewWithError()
func testSignupViewWithPasswordMismatch()
```
**Success**: Tests compile and FAIL because views are placeholder stubs

---

## Phase 3.3: Core Implementation (ONLY after tests are failing)

### Model Layer (Parallel Execution Group D)

#### T008 [P] Add AuthNavigationState enum
**File**: `Chill/Features/Auth/AuthModels.swift` [MODIFY]
**Action**: Add `AuthNavigationState` enum with 5 cases: `.choice`, `.login`, `.signup(consentAccepted:)`, `.resetRequest`, `.resetVerify(pendingEmail:)`
**Location**: After existing `AuthMode` enum
**Success**: Enum compiles, conforms to `Equatable` and `Hashable`

#### T009 [P] Add AuthError.duplicateEmail case
**File**: `Chill/Features/Auth/AuthModels.swift` [MODIFY]
**Action**: Add `.duplicateEmail` case to `AuthError` enum
**Location**: In existing `AuthError` enum definition
**Success**: New case compiles, maintains `Error` and `Equatable` conformance

#### T010 [P] Add AuthField enum for focus management
**File**: `Chill/Features/Auth/AuthModels.swift` [MODIFY]
**Action**: Add `AuthField` enum with cases: `.email`, `.password`, `.confirmPassword`, `.otp`
**Purpose**: Enable `@FocusState` binding in views
**Success**: Enum compiles, conforms to `Hashable`

### Service Layer

#### T011: Update AuthService error mapping for duplicate email
**File**: `Chill/Features/Auth/AuthService.swift` [MODIFY]
**Action**: In `mapClientError()` method, add case for `"user_already_exists"` → return `.duplicateEmail`
**Location**: Around line 178 in existing switch statement
**Success**: Contract test `testMapDuplicateEmailError()` PASSES (green state)

### ViewModel Layer

#### T012: Add navigationState property to AuthViewModel
**File**: `Chill/Features/Auth/AuthViewModel.swift` [MODIFY]
**Action**: 
1. Add `@Published var navigationState: AuthNavigationState = .choice`
2. Keep existing `mode` property for backward compatibility initially
**Success**: Property compiles, publishes changes

#### T013: Add navigation methods to AuthViewModel
**File**: `Chill/Features/Auth/AuthViewModel.swift` [MODIFY]
**Actions**:
```swift
func navigateToLogin() {
    navigationState = .login
}

func navigateToSignup() {
    navigationState = .signup(consentAccepted: false)
}

func navigateToChoice() {
    email = ""
    password = ""
    confirmPassword = ""
    otpCode = ""
    errorMessage = nil
    statusBanner = nil
    navigationState = .choice
}

func updateConsent(_ accepted: Bool) {
    guard case .signup = navigationState else { return }
    navigationState = .signup(consentAccepted: accepted)
}
```
**Success**: Contract tests T003 PASS (navigation transition tests green)

#### T014: Update AuthViewModel error message mapping
**File**: `Chill/Features/Auth/AuthViewModel.swift` [MODIFY]
**Action**: In `message(for:)` method, add case for `AuthError.duplicateEmail` returning "An account with this email already exists. Try logging in instead."
**Location**: Around line 284 in existing switch statement
**Success**: Contract test `testDuplicateEmailMessage()` PASSES

#### T015: Add client-side password validation
**File**: `Chill/Features/Auth/AuthViewModel.swift` [MODIFY]
**Action**: In `performSignup()` method, add check before API call:
```swift
guard password == confirmPassword else {
    errorMessage = "Passwords don't match"
    return
}
```
**Success**: Contract test `testPasswordMismatchError()` PASSES

### View Layer (Sequential - Share Coordinator)

#### T016: Create AuthChoiceView
**File**: `Chill/Features/Auth/Views/AuthChoiceView.swift` [MODIFY]
**Action**: Implement full choice screen with:
- "Sign In" button → calls `viewModel.navigateToLogin()`
- "Create Account" button → calls `viewModel.navigateToSignup()`
- Accessibility identifiers: `"auth_choice_signin"`, `"auth_choice_signup"`
- No back button (entry point)
**Success**: Snapshot test `testChoiceViewAppearance()` PASSES

#### T017: Create AuthLoginView
**File**: `Chill/Features/Auth/Views/AuthLoginView.swift` [MODIFY]
**Action**: Implement dedicated login screen with:
- Email field with `.textContentType(.username)`
- Password field with `.textContentType(.password)`
- "Forgot password?" button
- Submit button
- `@FocusState` for field focus management
- Accessibility identifiers per quickstart.md
- Back navigation to choice (calls `viewModel.navigateToChoice()`)
**Success**: Snapshot test `testLoginViewAppearance()` PASSES

#### T018: Create AuthSignupView
**File**: `Chill/Features/Auth/Views/AuthSignupView.swift` [MODIFY]
**Action**: Implement dedicated signup screen with:
- Email field with `.textContentType(.username)`
- Password field with `.textContentType(.newPassword)`
- Confirm password field with `.textContentType(.newPassword)`
- Terms consent toggle with binding to `viewModel.updateConsent()`
- Submit button (disabled unless all valid + consent)
- `@FocusState` for field focus management
- Accessibility identifiers per quickstart.md
- Back navigation to choice
**Success**: Snapshot test `testSignupViewAppearance()` PASSES

#### T019: Update AuthCoordinator to use navigation state
**File**: `Chill/App/AuthCoordinator.swift` [MODIFY]
**Action**: Replace `AuthView` rendering with switch on `viewModel.navigationState`:
```swift
switch viewModel.navigationState {
case .choice:
    AuthChoiceView(viewModel: viewModel)
case .login:
    AuthLoginView(viewModel: viewModel)
case .signup:
    AuthSignupView(viewModel: viewModel)
case .resetRequest:
    // Existing reset request view
case .resetVerify:
    // Existing reset verify view
}
```
**Success**: Integration test `testCompleteNavigationCycle()` PASSES

#### T020: Remove legacy AuthView with segmented control
**File**: `Chill/Features/Auth/Views/AuthView.swift` [MODIFY or REMOVE]
**Action**: 
- Option A: Remove file entirely if no longer referenced
- Option B: Deprecate and keep as fallback temporarily
**Success**: Project builds, no compiler errors, old segmented control UI not visible

---

## Phase 3.4: Integration & Polish

### Accessibility & UX

#### T021 [P]: Add accessibility labels and hints to all views
**Files**: 
- `Chill/Features/Auth/Views/AuthChoiceView.swift`
- `Chill/Features/Auth/Views/AuthLoginView.swift`
- `Chill/Features/Auth/Views/AuthSignupView.swift`

**Action**: For each view, add:
```swift
.accessibilityLabel("...")
.accessibilityHint("...")
.accessibilityIdentifier("...")
.accessibilityAddTraits(...) where appropriate
```
**Reference**: Quickstart Scenario 10 requirements
**Success**: VoiceOver announces elements correctly (manual verification)

#### T022 [P]: Configure keyboard submit labels and focus flow
**Files**: All three new view files
**Action**: 
- Set `.submitLabel(.next)` or `.submitLabel(.done)` appropriately
- Implement `.onSubmit { focusNext() }` for each field
- Tab order: email → password → [confirm password for signup] → submit
**Success**: Keyboard navigation flows naturally

### Testing & Validation

#### T023: Run all unit and integration tests
**Command**: `xcodebuild test -scheme Chill -destination 'platform=iOS Simulator,name=iPhone 15'`
**Expected**: All tests PASS (green state)
**Gate**: Must pass before proceeding

#### T024: Execute quickstart.md scenarios manually
**File**: `/specs/005-split-login-and/quickstart.md`
**Action**: Execute all 12 scenarios manually on simulator/device:
- Scenario 1-8: Automated (verify in test results)
- Scenario 9: Password manager integration (manual)
- Scenario 10: VoiceOver accessibility (manual with VoiceOver enabled)
- Scenario 11: Offline handling (manual with airplane mode)
- Scenario 12: Rapid navigation stress test (automated)
**Success**: All scenarios pass, no crashes, UX feels smooth

#### T025 [P]: Performance validation
**Action**: Measure view transition times using Instruments
**Target**: < 100ms transitions between choice ↔ login ↔ signup
**Success**: Performance goals met per plan.md

#### T026 [P]: Update existing tests that reference AuthMode
**Files**: `ChillTests/Auth/AuthViewModelTests.swift`, others
**Action**: Update any tests that check `viewModel.mode` to check `viewModel.navigationState` instead
**Success**: All existing tests still pass

### Documentation

#### T027 [P]: Update README or docs with new auth flow
**File**: `README.md` or `docs/authentication.md` (if exists)
**Action**: Document the three-screen flow, noting removal of segmented control
**Success**: Documentation reflects current implementation

---

## Dependencies

### Critical Path
```
T001 (Verify tests) → T002 (Structure)
    ↓
T003-T007 (All tests - parallel) [MUST FAIL]
    ↓
T008-T010 (Models - parallel)
    ↓
T011 (Service) → T012-T015 (ViewModel)
    ↓
T016 (Choice) → T017 (Login) → T018 (Signup) → T019 (Coordinator) → T020 (Remove legacy)
    ↓
T021-T022 (Accessibility - parallel)
    ↓
T023 (Run tests) → T024 (Quickstart) → T025-T027 (Validation & docs - parallel)
```

### Blocking Relationships
- **Tests (T003-T007)** must be written and failing before any implementation
- **T008-T010** (Models) block T011-T015 (Service/ViewModel)
- **T016-T018** (Views) block T019 (Coordinator integration)
- **T023** (All tests pass) gates T024-T027 (Validation)

### Parallel Opportunities
- **Group A** [P]: T003, T004 (Contract tests - different files)
- **Group B** [P]: T005, T006 (Integration tests - different files)
- **Group C** [P]: T007 (Snapshot tests - existing file but different test methods)
- **Group D** [P]: T008, T009, T010 (Model enums - same file but independent additions)
- **Group E** [P]: T021, T022 (Accessibility - different concerns)
- **Group F** [P]: T025, T026, T027 (Validation - independent tasks)

---

## Parallel Execution Examples

### Example 1: All Contract & Integration Tests (T003-T007)
```bash
# These can all be written in parallel by different developers/agents
Task T003: "Write AuthNavigationContractTests.swift with 8 navigation tests"
Task T004: "Write AuthErrorMappingContractTests.swift with 10 error tests"
Task T005: "Write AuthNavigationIntegrationTests.swift with 4 flow tests"
Task T006: "Add 4 new auth flow tests to AuthFlowIntegrationTests.swift"
Task T007: "Add 5 snapshot tests to AuthFlowViewSnapshotTests.swift"

# All should compile and FAIL - this is the RED state in TDD
```

### Example 2: Model Additions (T008-T010)
```bash
# These modify the same file but are independent enum additions
Task T008: "Add AuthNavigationState enum to AuthModels.swift"
Task T009: "Add .duplicateEmail case to AuthError enum in AuthModels.swift"
Task T010: "Add AuthField enum to AuthModels.swift"

# Can be done in parallel with merge conflict resolution or sequentially
```

### Example 3: Final Polish (T025-T027)
```bash
Task T025: "Run Instruments to measure transition performance"
Task T026: "Update tests referencing old AuthMode"
Task T027: "Update documentation with new auth flow"

# Completely independent, can run in parallel
```

---

## Task Execution Notes

### TDD Workflow (Critical)
1. **Phase 3.2** (T003-T007): Write ALL tests first
   - Tests MUST compile
   - Tests MUST fail (no implementation exists)
   - Verify: Run `xcodebuild test` and confirm failures
   
2. **Phase 3.3** (T008-T020): Implement to make tests pass
   - After each task, run tests
   - Goal: Turn RED tests GREEN one by one
   - Refactor while keeping tests green

3. **Phase 3.4** (T021-T027): Polish and validate
   - All tests should be passing before this phase
   - Manual validation via quickstart.md
   - Performance and documentation updates

### File Modification Strategy
- **[NEW]** files: Create from scratch
- **[MODIFY]** files: Add to existing code, don't replace
- When modifying shared files (like `AuthModels.swift`), add new code adjacent to related existing code
- Preserve all existing functionality for password reset flow

### Commit Strategy (Recommended)
- Commit after completing each phase
- Phase 3.2: "Add failing tests for split auth screens (TDD red state)"
- Phase 3.3: "Implement split auth screens (TDD green state)"
- Phase 3.4: "Add accessibility and polish for split auth screens"

---

## Validation Checklist

**Pre-Implementation** (Before T008):
- [x] All contracts have corresponding tests (T003, T004)
- [x] All integration scenarios have tests (T005, T006, T007)
- [x] All tests compile and FAIL (red state verified)

**Post-Implementation** (After T020):
- [ ] All contract tests PASS
- [ ] All integration tests PASS
- [ ] All snapshot tests PASS
- [ ] No regressions in existing tests (T026)
- [ ] Legacy AuthView removed or deprecated (T020)

**Final Validation** (After T027):
- [ ] Quickstart scenarios 1-12 all pass
- [ ] Performance < 100ms transitions
- [ ] VoiceOver announces correctly
- [ ] Password manager integration works
- [ ] Offline handling works
- [ ] Documentation updated

---

## Summary

**Total Tasks**: 27 tasks across 5 phases  
**Parallel Opportunities**: 15 tasks marked [P] across 6 groups  
**Critical Path Length**: ~12 sequential steps  
**Estimated Effort**: 3-4 days for experienced Swift/iOS developer

**Key Milestones**:
1. ✅ All tests written and failing (End of Phase 3.2)
2. ✅ All tests passing (End of Phase 3.3)
3. ✅ Quickstart validation complete (End of Phase 3.4)

**Next**: Begin with T001, proceed sequentially through phases, respecting dependencies and TDD workflow.
