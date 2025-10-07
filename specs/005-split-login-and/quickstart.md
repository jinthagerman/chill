# Quickstart: Split Login and Signup Screens

**Feature**: `005-split-login-and`  
**Date**: 2025-10-07  
**Purpose**: Validate the split authentication flow implementation

---

## Prerequisites

1. **Development Environment**:
   - Xcode 16+ with Swift 6
   - iOS 15+ Simulator or device
   - Supabase project configured in `AuthConfiguration.swift`

2. **Test Data**:
   - Existing test account: `test@example.com` / `TestPassword123!`
   - New email for signup testing: `newuser@example.com`

3. **Build & Run**:
   ```bash
   cd /path/to/Chill
   xcodebuild -scheme Chill -destination 'platform=iOS Simulator,name=iPhone 15' build
   # Or: Open Chill.xcodeproj in Xcode and Run (⌘R)
   ```

---

## Test Scenarios

### Scenario 1: Initial Choice Screen

**Objective**: Verify the new choice screen appears as entry point

**Steps**:
1. Launch the app (fresh install or logged out state)
2. Navigate to authentication flow

**Expected**:
- ✅ See a screen with two buttons: "Sign In" and "Create Account"
- ✅ No segmented control visible
- ✅ No back button (this is the entry point)
- ✅ Clean screen with no errors or form fields

**Validation**:
```swift
// Automated test
func testChoiceScreenAppears() {
    app.launch()
    
    XCTAssertTrue(app.buttons["Sign In"].exists)
    XCTAssertTrue(app.buttons["Create Account"].exists)
    XCTAssertFalse(app.segmentedControls.firstMatch.exists) // Old UI removed
}
```

---

### Scenario 2: Navigate to Login Screen

**Objective**: Verify transition to dedicated login screen

**Steps**:
1. From choice screen, tap "Sign In" button
2. Observe the transition

**Expected**:
- ✅ Navigate to login screen
- ✅ See only email and password fields
- ✅ See "Forgot password?" link
- ✅ See back button in navigation bar
- ✅ No signup-specific fields (confirm password, consent checkbox)

**Validation**:
```swift
func testNavigateToLogin() {
    app.launch()
    app.buttons["Sign In"].tap()
    
    XCTAssertTrue(app.textFields["Email"].exists)
    XCTAssertTrue(app.secureTextFields["Password"].exists)
    XCTAssertTrue(app.buttons["Forgot password?"].exists)
    XCTAssertFalse(app.secureTextFields["Confirm password"].exists)
    XCTAssertFalse(app.switches["Consent"].exists)
}
```

---

### Scenario 3: Login with Valid Credentials

**Objective**: Verify successful login flow

**Steps**:
1. On login screen, enter email: `test@example.com`
2. Enter password: `TestPassword123!`
3. Tap submit button

**Expected**:
- ✅ Show loading state briefly
- ✅ No error messages
- ✅ Navigate to main app (authenticated state)
- ✅ Session persisted

**Validation**:
```swift
func testSuccessfulLogin() async {
    viewModel.navigationState = .login
    viewModel.email = "test@example.com"
    viewModel.password = "TestPassword123!"
    
    await viewModel.submit()
    
    XCTAssertNotNil(viewModel.session)
    XCTAssertNil(viewModel.errorMessage)
}
```

---

### Scenario 4: Login with Invalid Credentials

**Objective**: Verify error message for authentication failure

**Steps**:
1. On login screen, enter email: `test@example.com`
2. Enter password: `WrongPassword`
3. Tap submit button

**Expected**:
- ✅ Show error message: "That email or password looks incorrect"
- ✅ Error displayed in red below form
- ✅ Fields remain populated (user can fix password)
- ✅ No navigation (stay on login screen)

**Validation**:
```swift
func testLoginWithInvalidCredentials() async {
    service.mockError = AuthError.invalidCredentials
    viewModel.navigationState = .login
    viewModel.email = "test@example.com"
    viewModel.password = "wrong"
    
    await viewModel.submit()
    
    XCTAssertEqual(viewModel.errorMessage, "That email or password looks incorrect")
    XCTAssertEqual(viewModel.navigationState, .login)
}
```

---

### Scenario 5: Navigate to Signup Screen

**Objective**: Verify transition to dedicated signup screen

**Steps**:
1. From choice screen, tap "Create Account" button
2. Observe the transition

**Expected**:
- ✅ Navigate to signup screen
- ✅ See email, password, confirm password fields
- ✅ See terms consent checkbox
- ✅ See back button in navigation bar
- ✅ Consent is unchecked by default
- ✅ Submit button disabled until all fields valid + consent checked

**Validation**:
```swift
func testNavigateToSignup() {
    app.launch()
    app.buttons["Create Account"].tap()
    
    XCTAssertTrue(app.textFields["Email"].exists)
    XCTAssertTrue(app.secureTextFields["Password"].exists)
    XCTAssertTrue(app.secureTextFields["Confirm password"].exists)
    XCTAssertTrue(app.switches["Consent"].exists)
    XCTAssertFalse(app.buttons["Create Account"].isEnabled) // Initially disabled
}
```

---

### Scenario 6: Signup with Password Mismatch

**Objective**: Verify client-side password validation

**Steps**:
1. On signup screen, enter email: `newuser@example.com`
2. Enter password: `Password123!`
3. Enter confirm password: `Password456!` (different)
4. Check consent checkbox
5. Tap submit button

**Expected**:
- ✅ Show error message: "Passwords don't match"
- ✅ No API call made
- ✅ Stay on signup screen
- ✅ Fields remain populated

**Validation**:
```swift
func testSignupWithPasswordMismatch() async {
    viewModel.navigationState = .signup(consentAccepted: true)
    viewModel.email = "newuser@example.com"
    viewModel.password = "Password123!"
    viewModel.confirmPassword = "Password456!"
    
    await viewModel.submit()
    
    XCTAssertEqual(viewModel.errorMessage, "Passwords don't match")
    XCTAssertEqual(viewModel.navigationState, .signup(consentAccepted: true))
}
```

---

### Scenario 7: Signup with Duplicate Email

**Objective**: Verify duplicate email error handling

**Steps**:
1. On signup screen, enter email: `test@example.com` (already exists)
2. Enter password: `NewPassword123!`
3. Enter confirm password: `NewPassword123!`
4. Check consent checkbox
5. Tap submit button

**Expected**:
- ✅ Show error message: "An account with this email already exists. Try logging in instead."
- ✅ Stay on signup screen
- ✅ User can navigate back and choose login instead

**Validation**:
```swift
func testSignupWithDuplicateEmail() async {
    service.mockError = AuthError.duplicateEmail
    viewModel.navigationState = .signup(consentAccepted: true)
    viewModel.email = "test@example.com"
    viewModel.password = "NewPassword123!"
    viewModel.confirmPassword = "NewPassword123!"
    
    await viewModel.submit()
    
    XCTAssertEqual(
        viewModel.errorMessage,
        "An account with this email already exists. Try logging in instead."
    )
}
```

---

### Scenario 8: Back Navigation Clears State

**Objective**: Verify form state is cleared when navigating back

**Steps**:
1. Navigate to login screen
2. Enter email: `test@example.com`
3. Enter password: `password`
4. Cause an error (wrong password)
5. Tap back button

**Expected**:
- ✅ Return to choice screen
- ✅ Email field cleared
- ✅ Password field cleared
- ✅ Error message cleared
- ✅ Navigate to login again shows empty fields

**Validation**:
```swift
func testBackNavigationClearsState() {
    viewModel.navigationState = .login
    viewModel.email = "test@example.com"
    viewModel.password = "password"
    viewModel.errorMessage = "Some error"
    
    viewModel.navigateToChoice()
    
    XCTAssertEqual(viewModel.navigationState, .choice)
    XCTAssertEqual(viewModel.email, "")
    XCTAssertEqual(viewModel.password, "")
    XCTAssertNil(viewModel.errorMessage)
}
```

---

### Scenario 9: Password Manager Integration (Manual Test)

**Objective**: Verify iOS password manager integration

**Steps**:
1. Navigate to login screen
2. Tap on email field

**Expected (if saved credentials exist)**:
- ✅ See QuickType bar suggestion with saved credentials
- ✅ Tapping suggestion fills both email and password
- ✅ Can proceed to login

**Steps (Signup)**:
1. Navigate to signup screen
2. Tap on password field

**Expected**:
- ✅ See "Strong Password" suggestion in QuickType bar
- ✅ Tapping generates a strong password
- ✅ Password automatically filled in both password and confirm password fields
- ✅ After successful signup, iOS offers to save password

**Note**: This is a manual test as it depends on device/simulator password manager state.

---

### Scenario 10: Accessibility with VoiceOver (Manual Test)

**Objective**: Verify screen reader compatibility

**Steps**:
1. Enable VoiceOver (Settings → Accessibility → VoiceOver)
2. Navigate through authentication flow

**Expected**:
- ✅ "Sign In" button announced as "Sign In, button"
- ✅ "Create Account" button announced as "Create Account, button"
- ✅ Email field announced as "Email, text field"
- ✅ Password field announced as "Password, secure text field"
- ✅ Error messages announced immediately when they appear
- ✅ Submit button announced with hint about what it does

**Validation** (Accessibility Inspector):
```swift
// Check accessibility labels are set
XCTAssertEqual(signInButton.accessibilityLabel, "Sign In")
XCTAssertEqual(emailField.accessibilityLabel, "Email address")
XCTAssertNotNil(submitButton.accessibilityHint)
```

---

### Scenario 11: Offline Handling

**Objective**: Verify offline state handling

**Steps**:
1. Navigate to login screen
2. Enter valid credentials
3. Disable network (Airplane mode or Network Link Conditioner)
4. Tap submit button

**Expected**:
- ✅ Show banner: "You're offline. Try again once you're connected."
- ✅ Submit button disabled
- ✅ No API call attempted
- ✅ Re-enabling network re-enables submit

**Validation**:
```swift
func testOfflineHandling() async {
    viewModel.updateNetworkStatus(.offline)
    viewModel.navigationState = .login
    viewModel.email = "test@example.com"
    viewModel.password = "password"
    
    await viewModel.submit()
    
    XCTAssertEqual(
        viewModel.statusBanner?.message,
        "You're offline. Try again once you're connected."
    )
    XCTAssertFalse(viewModel.canSubmit)
}
```

---

### Scenario 12: Rapid Navigation (Stress Test)

**Objective**: Verify state management under rapid navigation

**Steps**:
1. From choice, tap "Sign In"
2. Immediately tap back
3. Tap "Create Account"
4. Immediately tap back
5. Repeat 5 times rapidly

**Expected**:
- ✅ No crashes
- ✅ No UI glitches
- ✅ Always land on correct screen
- ✅ State always cleared when returning to choice
- ✅ No memory leaks

**Validation**:
```swift
func testRapidNavigation() {
    for _ in 0..<10 {
        viewModel.navigateToLogin()
        XCTAssertEqual(viewModel.navigationState, .login)
        
        viewModel.navigateToChoice()
        XCTAssertEqual(viewModel.navigationState, .choice)
        XCTAssertEqual(viewModel.email, "")
        
        viewModel.navigateToSignup()
        XCTAssertEqual(viewModel.navigationState, .signup(consentAccepted: false))
        
        viewModel.navigateToChoice()
        XCTAssertEqual(viewModel.navigationState, .choice)
    }
}
```

---

## Success Criteria

### Functional Requirements Met

- ✅ FR-001: Initial choice screen present
- ✅ FR-002: "Sign In" and "Create Account" buttons visible
- ✅ FR-003-008: Navigation and state clearing work
- ✅ FR-009-011: Login screen correct
- ✅ FR-012-015: Signup screen correct
- ✅ FR-016-021: Password manager integration
- ✅ FR-022-031: Error messaging
- ✅ FR-032-035: Form validation
- ✅ FR-036-039: State management

### Non-Functional Requirements

- ⚡ View transitions < 100ms (imperceptible)
- 🔒 No credential leakage in error messages
- ♿ VoiceOver fully functional
- 📱 iOS 15+ compatibility verified
- 🧪 All tests passing (unit + integration + snapshot)

---

## Rollback Plan

If critical issues are discovered:

1. **Immediate**: Revert to previous branch
   ```bash
   git checkout main
   git revert <commit-hash>
   ```

2. **Identify**: Check which scenario failed
3. **Fix**: Address specific issue in feature branch
4. **Re-test**: Run full quickstart again
5. **Re-deploy**: Merge when all scenarios pass

---

## Acceptance

**Sign-off Required**:
- [ ] All 12 scenarios executed and passed
- [ ] No regressions in existing password reset flow
- [ ] Analytics events still firing correctly
- [ ] Performance acceptable (< 100ms transitions)
- [ ] Accessibility verified with VoiceOver

**Approved by**: _________________  
**Date**: _________________

---

## Next Steps

After acceptance:
1. Run `/tasks` to generate implementation task list
2. Begin TDD implementation following tasks.md
3. Execute contract tests first (should fail initially)
4. Implement features to make tests pass
5. Return to this quickstart for final validation
