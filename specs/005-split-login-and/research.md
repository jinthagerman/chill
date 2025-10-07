# Research: Split Login and Signup Screens

**Feature**: `005-split-login-and`  
**Date**: 2025-10-07  
**Status**: Complete

## Navigation Pattern Selection

### Decision: Custom Navigation Coordinator with AnyView

**Rationale**:
- Existing codebase uses `AuthCoordinator` pattern (seen in `App/AuthCoordinator.swift`)
- Need iOS 15+ compatibility (NavigationStack requires iOS 16+)
- Auth flows benefit from programmatic navigation control
- Easier to manage state clearing and back navigation behavior
- Consistent with existing project patterns

**Implementation Approach**:
```swift
enum AuthNavigationState: Equatable {
    case choice
    case login
    case signup(consentAccepted: Bool)
    case resetRequest
    case resetVerify(pendingEmail: String)
}

// In AuthViewModel or coordinator
@Published var navigationState: AuthNavigationState = .choice
```

**Alternatives Considered**:
- **NavigationStack (iOS 16+)**: Rejected due to iOS 15 compatibility requirement
- **NavigationView with NavigationLink**: Rejected because declarative links don't suit programmatic auth flows
- **Sheet presentation**: Rejected as auth is not modal content, needs proper navigation hierarchy

---

## Password Manager Integration

### Decision: Use Appropriate textContentType for Each Context

**Login Screen**:
```swift
TextField("Email", text: $email)
    .textContentType(.username)      // Triggers credential suggestions
    
SecureField("Password", text: $password)
    .textContentType(.password)      // Shows saved passwords
```

**Signup Screen**:
```swift
TextField("Email", text: $email)
    .textContentType(.username)      // Associates new credential
    
SecureField("Password", text: $password)
    .textContentType(.newPassword)   // Triggers strong password generation
    
SecureField("Confirm Password", text: $confirmPassword)
    .textContentType(.newPassword)   // Validates password match
```

**Rationale**:
- `.username` on both enables password manager association
- `.password` vs `.newPassword` changes iOS autofill behavior
- `.newPassword` triggers strong password generator in iOS password manager
- System handles saving automatically after successful authentication
- No custom prompts needed (per spec clarification: "OS default behavior")

**Best Practices**:
- Always pair `.username` with `.password` or `.newPassword`
- Use `.emailAddress` for keyboard type, `.username` for autofill
- Set `.submitLabel(.next)` for proper keyboard return key
- Disable autocorrection for email fields

**References**:
- Apple Documentation: [UITextContentType](https://developer.apple.com/documentation/uikit/uitextcontenttype)
- WWDC 2018: "Automatic Strong Passwords and Security Code AutoFill"

---

## Supabase Error Codes Mapping

### Decision: Comprehensive Error Code Dictionary

Based on existing `AuthService.swift` implementation (lines 176-205) and Supabase documentation:

| Supabase Error Code | User-Friendly Message | Spec Requirement |
|---------------------|----------------------|------------------|
| `invalid_credentials` | "That email or password looks incorrect" | FR-023 |
| `email_not_confirmed` | "Verify your email before signing in" | FR-024 |
| `email_not_verified` | "Verify your email before signing in" | FR-024 |
| `over_email_send_rate_limit` | "Too many attempts. Please try again shortly." | FR-026 |
| `over_request_rate_limit` | "Too many attempts. Please try again shortly." | FR-026 |
| `over_sms_send_rate_limit` | "Too many attempts. Please try again shortly." | FR-026 |
| `otp_expired` | "That code isn't right. Double-check and try again." | FR-027 |
| `otp_disabled` | "That code isn't right. Double-check and try again." | FR-027 |
| `otp_invalid` | "That code isn't right. Double-check and try again." | FR-027 |
| `user_already_exists` | "An account with this email already exists. Try logging in instead." | FR-028 |
| `weak_password` | "Please choose a stronger password." | New |
| `session_not_found` | "That email or password looks incorrect" | FR-023 |
| `session_expired` | "That email or password looks incorrect" | FR-023 |
| Network errors (URLError) | "We can't reach the server. Check your connection and try again." | FR-025 |
| Unknown/unmapped | "Something went wrong. Please try again." | FR-029 |

**Additional Error for Signup**:
- **Password mismatch (client-side)**: "Passwords don't match" (FR-014) - validated before API call

**Implementation Note**:
- Existing `mapClientError()` function in `AuthService.swift` already handles most mappings
- Need to add `user_already_exists` case (currently not mapped)
- HTTP status codes fallback: 401/403 → invalid credentials, 429 → rate limited

**Rationale**:
- Security: Don't distinguish between "email not found" vs "wrong password"
- Clarity: Specific messages for actionable errors (unverified email, rate limits)
- Consistency: Same message for conceptually similar errors (all OTP errors)

---

## SwiftUI View State Management

### Decision: ViewModel-Driven State with Coordinator Pattern

**State Ownership**:
- **Navigation State**: In `AuthViewModel` as `@Published var navigationState`
- **Form State**: In each view as `@State`, bound to ViewModel properties via `Binding`
- **View Coordination**: Via `AuthViewModel` methods that update `navigationState`

**State Clearing Strategy**:
```swift
// In AuthViewModel
func navigateToChoice() {
    // Clear form fields
    email = ""
    password = ""
    confirmPassword = ""
    errorMessage = nil
    statusBanner = nil
    
    // Update navigation
    navigationState = .choice
}
```

**Pattern**:
```swift
// In AuthChoiceView
Button("Sign In") {
    viewModel.navigateToLogin()
}

Button("Create Account") {
    viewModel.navigateToSignup()
}

// In AuthLoginView / AuthSignupView
.navigationBarBackButtonHidden(false)
.onDisappear {
    // State clearing handled by ViewModel when navigation changes
}
```

**Rationale**:
- Centralized state management in ViewModel (existing pattern)
- Clear separation of concerns: View renders, ViewModel manages state
- Easy to test navigation logic
- Natural integration with existing `@Published` properties

**Alternatives Considered**:
- **@StateObject coordinator**: Rejected to maintain consistency with existing ViewModel pattern
- **@EnvironmentObject**: Rejected as auth state shouldn't be environment-wide
- **@Binding propagation**: Rejected due to complexity and tight coupling

---

## Accessibility Implementation

### Decision: Comprehensive Accessibility Support

**Labels and Identifiers**:
```swift
// For UI testing
.accessibilityIdentifier("auth_choice_signin")
.accessibilityIdentifier("auth_choice_signup")
.accessibilityIdentifier("auth_email")
.accessibilityIdentifier("auth_password")
.accessibilityIdentifier("auth_confirm_password")
.accessibilityIdentifier("auth_consent")
.accessibilityIdentifier("auth_submit")
.accessibilityIdentifier("auth_error_message")

// For VoiceOver
.accessibilityLabel("Sign In")
.accessibilityHint("Navigate to login screen")

// Error messages
.accessibilityLabel("Error")
.accessibilityAddTraits(.isStaticText)
```

**VoiceOver Navigation**:
- Use `.accessibilityAddTraits(.isHeader)` for screen titles
- Use `.accessibilityAddTraits(.isButton)` for buttons (automatic for Button())
- Error messages should be `.isStaticText` and announced immediately via state change
- Form fields should have clear labels read before input

**Focus Management**:
- Use `@FocusState` to manage field focus
- Auto-focus email field when screen appears
- Move focus to next field on keyboard "Next" action
- Clear focus when navigating away

**Dynamic Type Support**:
- Use `.font(.body)`, `.font(.title)` for automatic scaling
- Test with largest accessibility size (Settings → Accessibility → Display & Text Size)
- Ensure touch targets remain >= 44x44 points

**Best Practices**:
- Test with VoiceOver enabled (triple-tap home/side button)
- Test with large text sizes
- Ensure color contrast meets WCAG AA (4.5:1 for text)
- Provide text labels for icon-only buttons

**References**:
- Apple HIG: [Accessibility](https://developer.apple.com/design/human-interface-guidelines/accessibility)
- WWDC 2019: "Accessibility in SwiftUI"

---

## iOS 15 Compatibility Verification

### Decision: Maintain iOS 15 Support

**Confirmed Compatible APIs**:
- ✅ SwiftUI views and modifiers (iOS 14+)
- ✅ `@StateObject`, `@Published` (iOS 14+)
- ✅ `@FocusState` (iOS 15+)
- ✅ `.submitLabel()` (iOS 15+)
- ✅ `Task { }` (iOS 15+ with Swift Concurrency)
- ✅ `async/await` (iOS 15+)
- ✅ `.textContentType()` (iOS 10+)

**Avoid**:
- ❌ `NavigationStack` (iOS 16+) - Use custom navigation instead
- ❌ `.navigationDestination()` (iOS 16+)
- ❌ `.scrollContentBackground()` (iOS 16+)

**Testing Strategy**:
- Build target: iOS 15.0 minimum deployment
- Test on iOS 15 simulator to verify no runtime issues
- Ensure no `@available(iOS 16, *)` APIs used

---

## Summary of Decisions

| Area | Decision | Key Rationale |
|------|----------|---------------|
| **Navigation** | Custom coordinator with AnyView | iOS 15 compatibility, matches existing patterns |
| **Password Manager** | `.textContentType(.username/.password/.newPassword)` | Native iOS behavior, per spec clarification |
| **Error Mapping** | Comprehensive Supabase code dictionary | Security + clarity balance |
| **State Management** | ViewModel-driven with `@Published` | Consistency with existing code |
| **Accessibility** | Full labels, hints, VoiceOver support | WCAG compliance, iOS HIG |
| **iOS Version** | iOS 15+ minimum | Verified API compatibility |

All research items resolved. Ready for Phase 1: Design & Contracts.
