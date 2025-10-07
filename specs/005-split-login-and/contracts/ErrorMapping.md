# Contract: Error Message Mapping

**Feature**: `005-split-login-and`  
**Version**: 1.0  
**Date**: 2025-10-07

## Purpose

This contract defines the mapping between backend error codes (from Supabase) and user-friendly error messages displayed in the UI. It ensures consistent, actionable error communication across all authentication screens.

---

## Error Type Definition

### AuthError Enum

```swift
enum AuthError: Error, Equatable {
    case networkUnavailable
    case invalidCredentials
    case emailUnverified
    case rateLimited
    case otpIncorrect
    case duplicateEmail    // NEW in this feature
    case unknown
}
```

---

## Backend Error Code Mapping

### Contract: Supabase Error → AuthError

**Service Layer Responsibility**: `AuthService.mapClientError(_:)`

| Supabase Code | HTTP Status | AuthError | Spec Req |
|---------------|-------------|-----------|----------|
| `invalid_credentials` | 401 | `.invalidCredentials` | FR-023 |
| `email_not_confirmed` | 400 | `.emailUnverified` | FR-024 |
| `email_not_verified` | 400 | `.emailUnverified` | FR-024 |
| `over_email_send_rate_limit` | 429 | `.rateLimited` | FR-026 |
| `over_request_rate_limit` | 429 | `.rateLimited` | FR-026 |
| `over_sms_send_rate_limit` | 429 | `.rateLimited` | FR-026 |
| `otp_expired` | 400 | `.otpIncorrect` | FR-027 |
| `otp_disabled` | 400 | `.otpIncorrect` | FR-027 |
| `otp_invalid` | 400 | `.otpIncorrect` | FR-027 |
| `user_already_exists` | 422 | `.duplicateEmail` | FR-028 (NEW) |
| `weak_password` | 400 | `.unknown` | Fallback to FR-029 |
| `session_not_found` | 401 | `.invalidCredentials` | FR-023 |
| `session_expired` | 401 | `.invalidCredentials` | FR-023 |
| URLError (any) | N/A | `.networkUnavailable` | FR-025 |
| (unmapped) | Any | `.unknown` | FR-029 |

### Implementation

```swift
// In AuthService.swift
private func mapClientError(_ error: AuthClientError) -> AuthError {
    if let code = error.code?.lowercased() {
        switch code {
        case "invalid_credentials":
            sessionSubject.send(nil)
            return .invalidCredentials
            
        case "email_not_confirmed", "email_not_verified":
            return .emailUnverified
            
        case "over_email_send_rate_limit", 
             "over_request_rate_limit", 
             "over_sms_send_rate_limit":
            return .rateLimited
            
        case "otp_expired", "otp_disabled", "otp_invalid":
            return .otpIncorrect
            
        case "user_already_exists":  // NEW
            return .duplicateEmail
            
        case "session_not_found", "session_expired":
            sessionSubject.send(nil)
            return .invalidCredentials
            
        default:
            break
        }
    }
    
    // Fallback to HTTP status
    switch error.status {
    case 401, 403:
        sessionSubject.send(nil)
        return .invalidCredentials
    case 429:
        return .rateLimited
    default:
        return .unknown
    }
}
```

### Contract Tests

```swift
func testMapInvalidCredentialsError() {
    let error = AuthClientError(
        status: 401,
        code: "invalid_credentials",
        message: "Invalid login credentials"
    )
    let mapped = service.normalize(error)
    XCTAssertEqual(mapped as? AuthError, .invalidCredentials)
}

func testMapDuplicateEmailError() {  // NEW TEST
    let error = AuthClientError(
        status: 422,
        code: "user_already_exists",
        message: "User already registered"
    )
    let mapped = service.normalize(error)
    XCTAssertEqual(mapped as? AuthError, .duplicateEmail)
}

func testMapUnknownError() {
    let error = AuthClientError(
        status: 500,
        code: "server_error",
        message: "Internal server error"
    )
    let mapped = service.normalize(error)
    XCTAssertEqual(mapped as? AuthError, .unknown)
}

func testMapNetworkError() {
    let error = URLError(.notConnectedToInternet)
    let mapped = service.normalize(error)
    XCTAssertEqual(mapped as? AuthError, .networkUnavailable)
}
```

---

## User-Facing Message Mapping

### Contract: AuthError → User Message

**ViewModel Layer Responsibility**: `AuthViewModel.message(for:)`

| AuthError | User-Facing Message | Spec Req | Security Note |
|-----------|---------------------|----------|---------------|
| `.invalidCredentials` | "That email or password looks incorrect" | FR-023 | Intentionally vague |
| `.emailUnverified` | "Verify your email before signing in" | FR-024 | Actionable |
| `.networkUnavailable` | "We can't reach the server. Check your connection and try again." | FR-025 | Actionable |
| `.rateLimited` | "Too many attempts. Please try again shortly." | FR-026 | Temporary block |
| `.otpIncorrect` | "That code isn't right. Double-check and try again." | FR-027 | Reset flow only |
| `.duplicateEmail` | "An account with this email already exists. Try logging in instead." | FR-028 | Actionable (NEW) |
| `.unknown` | "Something went wrong. Please try again." | FR-029 | Generic fallback |

### Implementation

```swift
// In AuthViewModel.swift
private func message(for error: Error) -> String {
    switch error {
    case AuthError.networkUnavailable:
        return "We can't reach the server. Check your connection and try again."
        
    case AuthError.invalidCredentials:
        return "That email or password looks incorrect"
        
    case AuthError.emailUnverified:
        return "Verify your email before signing in"
        
    case AuthError.rateLimited:
        return "Too many attempts. Please try again shortly."
        
    case AuthError.otpIncorrect:
        return "That code isn't right. Double-check and try again."
        
    case AuthError.duplicateEmail:  // NEW
        return "An account with this email already exists. Try logging in instead."
        
    default:
        return "Something went wrong. Please try again."
    }
}
```

### Contract Tests

```swift
func testInvalidCredentialsMessage() {
    let message = viewModel.message(for: AuthError.invalidCredentials)
    XCTAssertEqual(message, "That email or password looks incorrect")
}

func testDuplicateEmailMessage() {  // NEW TEST
    let message = viewModel.message(for: AuthError.duplicateEmail)
    XCTAssertEqual(message, "An account with this email already exists. Try logging in instead.")
}

func testUnknownErrorMessage() {
    let message = viewModel.message(for: AuthError.unknown)
    XCTAssertEqual(message, "Something went wrong. Please try again.")
}
```

---

## Client-Side Validation Errors

### Contract: Pre-Submission Validation

**Responsibility**: `AuthViewModel` before calling `AuthService`

| Validation | Error Message | Spec Req |
|------------|---------------|----------|
| Passwords don't match | "Passwords don't match" | FR-014 |
| Missing consent | "You must accept the terms to continue." | FR-015 |
| Invalid email format | "Enter a valid email." | FR-032 |
| Empty required field | (Button disabled, no message) | FR-033 |
| Offline | "You're offline. Try again once you're connected." | FR-035 |

### Implementation

```swift
// Password mismatch (signup only)
func performSignup(consentAccepted: Bool) async {
    guard password == confirmPassword else {
        errorMessage = "Passwords don't match"
        return
    }
    
    guard consentAccepted else {
        errorMessage = "You must accept the terms to continue."
        return
    }
    
    // ... call service ...
}

// Email validation
func submit() async {
    guard email.isValidEmail else {
        errorMessage = "Enter a valid email."
        return
    }
    // ... proceed ...
}

// Offline check
func submit() async {
    guard networkStatus != .offline else {
        statusBanner = AuthBanner(
            type: .info, 
            message: "You're offline. Try again once you're connected."
        )
        return
    }
    // ... proceed ...
}
```

### Contract Tests

```swift
func testPasswordMismatchError() async {
    viewModel.navigationState = .signup(consentAccepted: true)
    viewModel.password = "password123"
    viewModel.confirmPassword = "different"
    
    await viewModel.submit()
    
    XCTAssertEqual(viewModel.errorMessage, "Passwords don't match")
}

func testMissingConsentError() async {
    viewModel.navigationState = .signup(consentAccepted: false)
    viewModel.email = "test@example.com"
    viewModel.password = "password123"
    viewModel.confirmPassword = "password123"
    
    await viewModel.submit()
    
    XCTAssertEqual(viewModel.errorMessage, "You must accept the terms to continue.")
}

func testOfflineMessage() async {
    viewModel.updateNetworkStatus(.offline)
    viewModel.navigationState = .login
    viewModel.email = "test@example.com"
    viewModel.password = "password"
    
    await viewModel.submit()
    
    XCTAssertEqual(viewModel.statusBanner?.message, "You're offline. Try again once you're connected.")
}
```

---

## Error Display Contract

### Contract: Error Persistence and Clearing

**Display Rules**:
1. Errors MUST be displayed in red text below form fields
2. Errors MUST persist until:
   - User corrects input and resubmits, OR
   - User navigates to different screen, OR
   - User explicitly dismisses (if dismiss button provided)
3. Errors MUST be cleared when navigating to `.choice` state
4. Only ONE of `errorMessage` OR `statusBanner` shown at a time

### Accessibility

```swift
// In view
if let error = viewModel.errorMessage {
    Text(error)
        .font(.body)
        .foregroundColor(.red)
        .padding(.horizontal)
        .accessibilityIdentifier("auth_error_message")
        .accessibilityLabel("Error")
        .accessibilityAddTraits(.isStaticText)
}
```

### Contract Tests

```swift
func testErrorDisplayedInView() {
    viewModel.errorMessage = "Invalid credentials"
    let view = AuthLoginView(viewModel: viewModel)
    // Snapshot test to verify red text appears
    assertSnapshot(matching: view, as: .image)
}

func testErrorClearedOnNavigation() {
    viewModel.navigationState = .login
    viewModel.errorMessage = "Invalid credentials"
    
    viewModel.navigateToChoice()
    
    XCTAssertNil(viewModel.errorMessage)
}
```

---

## Security Considerations

### Contract: Ambiguous Error Messages

**Rule**: Never reveal whether an email exists in the system during login

**Implementation**:
- Login failures → Always "That email or password looks incorrect"
- Never distinguish "email not found" vs "wrong password"
- Signup failures → Only show "email already exists" error (helps user, doesn't leak info about who has accounts)

**Rationale**:
- Login: Security risk to confirm email existence
- Signup: User benefit outweighs risk (they're trying to create account)

### Contract Tests

```swift
func testLoginDoesNotRevealEmailExistence() {
    // Mock: Email doesn't exist in system
    service.mockError = AuthClientError(
        status: 401,
        code: "invalid_credentials",
        message: "Email not found"
    )
    
    await viewModel.performLogin()
    
    // Should show generic message, not "email not found"
    XCTAssertEqual(
        viewModel.errorMessage, 
        "That email or password looks incorrect"
    )
}

func testSignupRevealsEmailExists() {
    // Mock: Email already exists
    service.mockError = AuthClientError(
        status: 422,
        code: "user_already_exists",
        message: "User already registered"
    )
    
    await viewModel.performSignup(consentAccepted: true)
    
    // Should show specific message for better UX
    XCTAssertEqual(
        viewModel.errorMessage,
        "An account with this email already exists. Try logging in instead."
    )
}
```

---

## Integration Test Scenarios

### Scenario 1: Complete Error Flow

```swift
func testCompleteErrorFlow() async {
    // Setup: Mock failed login
    service.mockError = AuthError.invalidCredentials
    viewModel.navigationState = .login
    viewModel.email = "test@example.com"
    viewModel.password = "wrong"
    
    // Attempt login
    await viewModel.submit()
    
    // Verify error shown
    XCTAssertEqual(viewModel.errorMessage, "That email or password looks incorrect")
    
    // User navigates back
    viewModel.navigateToChoice()
    
    // Verify error cleared
    XCTAssertNil(viewModel.errorMessage)
}
```

### Scenario 2: Multiple Error Types

```swift
func testMultipleErrorTypes() async {
    // Scenario A: Network error
    service.mockError = URLError(.notConnectedToInternet)
    await viewModel.performLogin()
    XCTAssertEqual(viewModel.errorMessage, "We can't reach the server. Check your connection and try again.")
    
    // Scenario B: Rate limit
    service.mockError = AuthError.rateLimited
    await viewModel.performLogin()
    XCTAssertEqual(viewModel.errorMessage, "Too many attempts. Please try again shortly.")
    
    // Scenario C: Unverified email
    service.mockError = AuthError.emailUnverified
    await viewModel.performLogin()
    XCTAssertEqual(viewModel.errorMessage, "Verify your email before signing in")
}
```

---

## Summary

**Error Mapping Layers**:
1. **Supabase → AuthError**: Service layer (`AuthService.mapClientError`)
2. **AuthError → User Message**: ViewModel layer (`AuthViewModel.message(for:)`)
3. **Client Validation → Message**: ViewModel layer (pre-submission checks)

**Key Principles**:
- Security: Ambiguous messages for login failures
- Clarity: Specific messages for actionable errors
- Consistency: Same error → same message everywhere
- Accessibility: Screen reader compatible

**New in This Feature**:
- `AuthError.duplicateEmail` case
- "An account with this email already exists" message
- "Passwords don't match" client-side validation

**Test Coverage**:
- 10+ unit tests for error mapping
- 5+ unit tests for message generation
- 3+ integration tests for error flows
- Snapshot tests for error display
