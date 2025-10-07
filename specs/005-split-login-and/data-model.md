# Data Model: Split Login and Signup Screens

**Feature**: `005-split-login-and`  
**Date**: 2025-10-07

## Overview

This feature extends the existing authentication data model with navigation state support. No new entities are introduced; instead, we enhance existing models to support the split-screen navigation flow.

---

## Navigation State Model

### AuthNavigationState (NEW)

**Purpose**: Represents the current screen in the authentication flow

**Type**: Swift Enum

**Definition**:
```swift
enum AuthNavigationState: Equatable, Hashable {
    case choice
    case login
    case signup(consentAccepted: Bool)
    case resetRequest
    case resetVerify(pendingEmail: String)
}
```

**States**:
- `choice`: Initial screen with "Sign In" and "Create Account" buttons
- `login`: Dedicated login screen for returning users
- `signup(consentAccepted: Bool)`: Signup screen with terms consent state
- `resetRequest`: Password reset email entry (existing)
- `resetVerify(pendingEmail: String)`: OTP verification screen (existing)

**Relationships**:
- Owned by `AuthViewModel` as `@Published` property
- Drives view rendering in parent container
- Updated by navigation methods in `AuthViewModel`

**State Transitions**:
```
choice ───→ login ───→ resetRequest ───→ resetVerify
  │                                            │
  └──→ signup                                  │
                                               │
       All states ←──────────────────────────┘
                  (back navigation)
```

**Validation Rules**:
- `choice` is the entry state (cannot navigate back)
- `signup` must track consent state independently
- `resetVerify` must carry pending email from `resetRequest`

---

## Extended Existing Models

### AuthMode (MODIFY)

**Current Definition** (in `AuthModels.swift`):
```swift
enum AuthMode: Equatable, Hashable {
    case login
    case signup(consentAccepted: Bool)
    case resetRequest
    case resetVerify(pendingEmail: String)
}
```

**Change**: This enum will be **deprecated/replaced** by `AuthNavigationState` which adds the `.choice` case.

**Migration Path**:
1. Add `AuthNavigationState` alongside `AuthMode`
2. Update `AuthViewModel` to use `navigationState: AuthNavigationState` instead of `mode: AuthMode`
3. Keep `mode` as computed property for backward compatibility during transition
4. Update views to check `navigationState` instead of `mode`

**Rationale**: Clearer naming (`navigationState` vs `mode`) and explicit choice state.

---

### AuthError (EXTEND)

**Current Definition** (in `AuthModels.swift`):
```swift
enum AuthError: Error, Equatable {
    case networkUnavailable
    case invalidCredentials
    case emailUnverified
    case rateLimited
    case otpIncorrect
    case unknown
}
```

**Extension**: Add new error case for duplicate email

**Updated Definition**:
```swift
enum AuthError: Error, Equatable {
    case networkUnavailable
    case invalidCredentials
    case emailUnverified
    case rateLimited
    case otpIncorrect
    case duplicateEmail    // NEW
    case unknown
}
```

**Mapping** (in `AuthService.swift`):
```swift
case "user_already_exists":
    return .duplicateEmail
```

**User-Facing Message** (in `AuthViewModel.swift`):
```swift
case AuthError.duplicateEmail:
    return "An account with this email already exists. Try logging in instead."
```

---

## Form State Model

### AuthFormState (CONCEPTUAL - Managed by ViewModel)

**Purpose**: Represents user input in auth forms

**Properties**:
```swift
// In AuthViewModel
@Published var email: String = ""
@Published var password: String = ""
@Published var confirmPassword: String = ""
@Published var otpCode: String = ""
```

**Validation Rules**:
- `email`: Must contain "@" and "." (basic format check)
- `password`: Must not be empty
- `confirmPassword`: Must match `password` (only for signup)
- `otpCode`: Must be 6 digits (only for reset verify)

**State Clearing**:
```swift
// When navigating to .choice
func clearFormState() {
    email = ""
    password = ""
    confirmPassword = ""
    otpCode = ""
    errorMessage = nil
    statusBanner = nil
}
```

**Persistence**: None - all fields cleared on navigation back to choice

---

## View State Models

### Focus Management

**Type**: Swift enum for `@FocusState`

```swift
enum AuthField: Hashable {
    case email
    case password
    case confirmPassword
    case otp
}
```

**Usage**:
```swift
@FocusState private var focusedField: AuthField?

TextField("Email", text: $email)
    .focused($focusedField, equals: .email)
```

**Focus Flow**:
- **Login**: email → password → submit
- **Signup**: email → password → confirmPassword → submit
- **Reset Request**: email → submit
- **Reset Verify**: otp → password → submit

---

## Relationships Diagram

```
AuthViewModel
├── navigationState: AuthNavigationState
│   ├── .choice
│   ├── .login
│   ├── .signup(consentAccepted: Bool)
│   ├── .resetRequest
│   └── .resetVerify(pendingEmail: String)
│
├── Form State (Published properties)
│   ├── email: String
│   ├── password: String
│   ├── confirmPassword: String
│   └── otpCode: String
│
├── Error State
│   ├── errorMessage: String?
│   └── statusBanner: AuthBanner?
│
└── Session
    └── session: AuthSession?

AuthService
├── Errors
│   └── AuthError (extended with .duplicateEmail)
│
└── Methods
    ├── signIn(email, password) throws -> AuthSession
    ├── signUp(email, password, consent) throws -> AuthSession
    └── [existing methods unchanged]
```

---

## Data Flow

### Login Flow
```
1. User on .choice screen
2. Taps "Sign In" → navigationState = .login
3. Enters email/password in form state
4. Taps submit → AuthViewModel.performLogin()
5. AuthService.signIn() → AuthSession or AuthError
6. Success: session updated, navigate to app
7. Failure: errorMessage populated, stay on .login
```

### Signup Flow
```
1. User on .choice screen
2. Taps "Create Account" → navigationState = .signup(consentAccepted: false)
3. Enters email/password/confirmPassword, checks consent
4. Client validates: password == confirmPassword
5. Taps submit → AuthViewModel.performSignup()
6. AuthService.signUp() → AuthSession or AuthError
7. Duplicate email: AuthError.duplicateEmail → "Account exists" message
8. Success: session updated OR verification banner shown
```

### Navigation Back Flow
```
1. User on .login or .signup
2. Taps back button / swipe gesture
3. navigationState = .choice
4. AuthViewModel.clearFormState() called
5. Form fields, errors, banners cleared
6. User sees clean .choice screen
```

---

## State Invariants

### Critical Invariants (Must Hold)

1. **Choice Screen Isolation**: `.choice` state MUST clear all form data and errors
2. **Password Confirmation**: `confirmPassword` only relevant when `navigationState == .signup`
3. **Consent State**: Consent boolean carried within `.signup` enum case
4. **Email Preservation**: `pendingEmail` carried through reset flow in `.resetVerify`
5. **Error Exclusivity**: Only one of `errorMessage` OR `statusBanner` shown at a time
6. **Navigation Stack**: Can always navigate back to `.choice` except from `.choice` itself

### Validation Checks

```swift
// Before allowing submit on signup
guard navigationState == .signup else { return }
guard password == confirmPassword else {
    errorMessage = "Passwords don't match"
    return
}
guard case let .signup(consentAccepted) = navigationState,
      consentAccepted else {
    errorMessage = "You must accept the terms to continue."
    return
}
```

---

## Testing Considerations

### Unit Test Scenarios

1. **Navigation state transitions**:
   - `choice → login → choice` clears form state
   - `choice → signup → choice` clears form state
   - Consent state preserved within signup flow

2. **Error mapping**:
   - Supabase `user_already_exists` → `AuthError.duplicateEmail`
   - `duplicateEmail` → "Account exists" message

3. **Form validation**:
   - Password mismatch detected before API call
   - Empty fields disable submit button
   - Email format validation

4. **State clearing**:
   - All fields cleared when returning to choice
   - Errors cleared when returning to choice
   - Banners cleared when returning to choice

### Integration Test Scenarios

1. Complete signup flow with duplicate email
2. Login → Forgot Password → Reset → Login
3. Signup → Back → Login → Back → Signup
4. Rapid navigation changes (stress test state management)

---

## Summary

**New Models**:
- `AuthNavigationState` enum with `.choice` case

**Extended Models**:
- `AuthError` with `.duplicateEmail` case

**Unchanged Models**:
- `AuthSession` (no changes)
- `AuthBanner` (no changes)
- `AuthEventPayload` (no changes)

**Key Characteristics**:
- Navigation state is the source of truth for UI rendering
- Form state tied to ViewModel, cleared on navigation to choice
- Error mapping extended for duplicate email scenario
- All state transitions testable via ViewModel methods
