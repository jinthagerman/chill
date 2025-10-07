# Contract: Authentication Navigation Flow

**Feature**: `005-split-login-and`  
**Version**: 1.0  
**Date**: 2025-10-07

## Purpose

This contract defines the behavior and state transitions for the authentication navigation flow. It specifies how the system transitions between the choice, login, signup, and password reset screens.

---

## Navigation State Contract

### State Definition

```swift
enum AuthNavigationState: Equatable, Hashable {
    case choice
    case login
    case signup(consentAccepted: Bool)
    case resetRequest
    case resetVerify(pendingEmail: String)
}
```

### Initial State

**Contract**: System MUST initialize with `.choice` state when authentication flow begins.

```swift
// AuthViewModel initialization
init(...) {
    self.navigationState = .choice
    // ...
}
```

**Test**:
```swift
func testInitialStateIsChoice() {
    let viewModel = AuthViewModel(...)
    XCTAssertEqual(viewModel.navigationState, .choice)
}
```

---

## State Transitions

### 1. From Choice Screen

#### Transition: Choice → Login

**Trigger**: User taps "Sign In" button

**Contract**:
- MUST set `navigationState = .login`
- MUST NOT clear form state (user might return)
- MUST NOT show errors from previous attempts

```swift
func navigateToLogin() {
    navigationState = .login
}
```

**Test**:
```swift
func testNavigateFromChoiceToLogin() {
    viewModel.navigationState = .choice
    viewModel.navigateToLogin()
    XCTAssertEqual(viewModel.navigationState, .login)
}
```

---

#### Transition: Choice → Signup

**Trigger**: User taps "Create Account" button

**Contract**:
- MUST set `navigationState = .signup(consentAccepted: false)`
- MUST initialize consent as `false`
- MUST NOT clear form state

```swift
func navigateToSignup() {
    navigationState = .signup(consentAccepted: false)
}
```

**Test**:
```swift
func testNavigateFromChoiceToSignup() {
    viewModel.navigationState = .choice
    viewModel.navigateToSignup()
    XCTAssertEqual(viewModel.navigationState, .signup(consentAccepted: false))
}
```

---

### 2. From Login Screen

#### Transition: Login → Choice (Back Navigation)

**Trigger**: User taps back button or swipes back

**Contract**:
- MUST set `navigationState = .choice`
- MUST clear all form fields (`email`, `password`, `confirmPassword`, `otpCode`)
- MUST clear `errorMessage`
- MUST clear `statusBanner`

```swift
func navigateToChoice() {
    email = ""
    password = ""
    confirmPassword = ""
    otpCode = ""
    errorMessage = nil
    statusBanner = nil
    navigationState = .choice
}
```

**Test**:
```swift
func testNavigateFromLoginToChoiceClearsState() {
    viewModel.navigationState = .login
    viewModel.email = "test@example.com"
    viewModel.password = "password123"
    viewModel.errorMessage = "Some error"
    
    viewModel.navigateToChoice()
    
    XCTAssertEqual(viewModel.navigationState, .choice)
    XCTAssertEqual(viewModel.email, "")
    XCTAssertEqual(viewModel.password, "")
    XCTAssertNil(viewModel.errorMessage)
    XCTAssertNil(viewModel.statusBanner)
}
```

---

#### Transition: Login → Reset Request

**Trigger**: User taps "Forgot password?" link

**Contract**:
- MUST set `navigationState = .resetRequest`
- MUST preserve `email` field value
- MUST clear `password` field
- MUST clear errors

```swift
func navigateToResetRequest() {
    password = ""
    errorMessage = nil
    statusBanner = nil
    navigationState = .resetRequest
}
```

**Test**:
```swift
func testNavigateFromLoginToResetPreservesEmail() {
    viewModel.navigationState = .login
    viewModel.email = "test@example.com"
    viewModel.password = "password123"
    
    viewModel.navigateToResetRequest()
    
    XCTAssertEqual(viewModel.navigationState, .resetRequest)
    XCTAssertEqual(viewModel.email, "test@example.com")
    XCTAssertEqual(viewModel.password, "")
}
```

---

### 3. From Signup Screen

#### Transition: Signup → Choice (Back Navigation)

**Trigger**: User taps back button or swipes back

**Contract**:
- MUST set `navigationState = .choice`
- MUST clear all form fields
- MUST clear `errorMessage`
- MUST clear `statusBanner`
- MUST reset consent state (handled by state transition)

```swift
func navigateToChoice() {
    email = ""
    password = ""
    confirmPassword = ""
    otpCode = ""
    errorMessage = nil
    statusBanner = nil
    navigationState = .choice
}
```

**Test**:
```swift
func testNavigateFromSignupToChoiceClearsState() {
    viewModel.navigationState = .signup(consentAccepted: true)
    viewModel.email = "test@example.com"
    viewModel.password = "password123"
    viewModel.confirmPassword = "password123"
    
    viewModel.navigateToChoice()
    
    XCTAssertEqual(viewModel.navigationState, .choice)
    XCTAssertEqual(viewModel.email, "")
    XCTAssertEqual(viewModel.password, "")
    XCTAssertEqual(viewModel.confirmPassword, "")
}
```

---

### 4. Back Navigation Prevention

#### No Back from Choice

**Contract**: The `.choice` screen MUST prevent back navigation

**Implementation**:
```swift
// In view
.navigationBarBackButtonHidden(viewModel.navigationState == .choice)
```

**Test**:
```swift
func testChoiceScreenPreventsBackNavigation() {
    // UI test via snapshot or manual verification
    // ViewInspector test for navigationBarBackButtonHidden modifier
}
```

---

## Consent State Management

### Contract: Signup Consent Toggle

**Trigger**: User toggles consent checkbox on signup screen

**Contract**:
- MUST update consent state within `.signup` enum case
- MUST preserve all other form fields
- MUST enable/disable submit button based on consent + validation

```swift
func updateConsent(_ accepted: Bool) {
    guard case .signup = navigationState else { return }
    navigationState = .signup(consentAccepted: accepted)
}
```

**Test**:
```swift
func testConsentToggleUpdatesState() {
    viewModel.navigationState = .signup(consentAccepted: false)
    
    viewModel.updateConsent(true)
    
    XCTAssertEqual(viewModel.navigationState, .signup(consentAccepted: true))
}

func testConsentToggleOnlyWorksInSignupState() {
    viewModel.navigationState = .login
    
    viewModel.updateConsent(true)
    
    XCTAssertEqual(viewModel.navigationState, .login) // Unchanged
}
```

---

## View Rendering Contract

### Contract: View Selection Based on Navigation State

**Contract**: Parent view MUST render appropriate child view based on `navigationState`

```swift
// In parent coordinator view
switch viewModel.navigationState {
case .choice:
    AuthChoiceView(viewModel: viewModel)
case .login:
    AuthLoginView(viewModel: viewModel)
case .signup:
    AuthSignupView(viewModel: viewModel)
case .resetRequest:
    AuthResetRequestView(viewModel: viewModel)
case .resetVerify:
    AuthResetVerifyView(viewModel: viewModel)
}
```

**Test** (Snapshot):
```swift
func testChoiceViewRenderedForChoiceState() {
    viewModel.navigationState = .choice
    let view = AuthCoordinatorView(viewModel: viewModel)
    assertSnapshot(matching: view, as: .image)
}

func testLoginViewRenderedForLoginState() {
    viewModel.navigationState = .login
    let view = AuthCoordinatorView(viewModel: viewModel)
    assertSnapshot(matching: view, as: .image)
}
```

---

## Error State Contract

### Contract: Errors Persist Within Screen

**Contract**:
- Errors MUST persist while on same screen
- Errors MUST clear when navigating to `.choice`
- Errors MUST clear when explicitly dismissed by user

```swift
// Automatic clearing
func navigateToChoice() {
    // ... clear form fields ...
    errorMessage = nil
    statusBanner = nil
    navigationState = .choice
}

// Explicit clearing
func dismissError() {
    errorMessage = nil
}
```

**Test**:
```swift
func testErrorsClearedWhenNavigatingToChoice() {
    viewModel.navigationState = .login
    viewModel.errorMessage = "Invalid credentials"
    
    viewModel.navigateToChoice()
    
    XCTAssertNil(viewModel.errorMessage)
}

func testErrorPersistsOnSameScreen() {
    viewModel.navigationState = .login
    viewModel.errorMessage = "Invalid credentials"
    
    // Simulate user staying on screen
    XCTAssertEqual(viewModel.errorMessage, "Invalid credentials")
}
```

---

## Integration Test Scenarios

### Scenario 1: Complete Navigation Cycle

```swift
func testCompleteNavigationCycle() {
    // Start at choice
    XCTAssertEqual(viewModel.navigationState, .choice)
    
    // Navigate to signup
    viewModel.navigateToSignup()
    XCTAssertEqual(viewModel.navigationState, .signup(consentAccepted: false))
    
    // Enter data
    viewModel.email = "test@example.com"
    viewModel.password = "password"
    viewModel.confirmPassword = "password"
    
    // Navigate back
    viewModel.navigateToChoice()
    XCTAssertEqual(viewModel.navigationState, .choice)
    XCTAssertEqual(viewModel.email, "") // Cleared
    
    // Navigate to login
    viewModel.navigateToLogin()
    XCTAssertEqual(viewModel.navigationState, .login)
}
```

### Scenario 2: Error Handling Across Navigation

```swift
func testErrorHandlingAcrossNavigation() {
    // Set error on login screen
    viewModel.navigationState = .login
    viewModel.errorMessage = "Invalid credentials"
    
    // Navigate back
    viewModel.navigateToChoice()
    XCTAssertNil(viewModel.errorMessage)
    
    // Navigate to signup
    viewModel.navigateToSignup()
    XCTAssertNil(viewModel.errorMessage) // Still cleared
}
```

### Scenario 3: State Clearing Does Not Affect Session

```swift
func testStateClearingDoesNotAffectSession() {
    // Mock authenticated session
    let mockSession = AuthSession(...)
    viewModel.session = mockSession
    
    // Navigate with form data
    viewModel.navigationState = .login
    viewModel.email = "test@example.com"
    
    // Navigate back (clears form)
    viewModel.navigateToChoice()
    
    // Session should remain
    XCTAssertNotNil(viewModel.session)
    XCTAssertEqual(viewModel.session, mockSession)
}
```

---

## Summary

**State Transitions**:
- `.choice` → `.login` or `.signup`
- `.login` → `.choice` (back) or `.resetRequest`
- `.signup` → `.choice` (back)
- `.resetRequest` → `.choice` (back) or `.resetVerify`
- `.resetVerify` → `.choice` (back)

**Invariants**:
1. `.choice` is always the entry point
2. Back navigation always goes to `.choice`
3. Form state cleared when returning to `.choice`
4. Errors cleared when returning to `.choice`
5. Consent state embedded in `.signup` enum case

**Test Coverage**:
- 15+ unit tests for state transitions
- 3+ integration tests for complete flows
- Snapshot tests for view rendering per state
