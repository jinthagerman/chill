# Feature Specification: Split Login and Signup Screens with Enhanced UX

**Feature Branch**: `005-split-login-and`  
**Created**: 2025-10-07  
**Status**: Draft  
**Input**: User description: "Split login and signup into separate screens and provide more meaningful error message while supporting password autofill"

## Execution Flow (main)
```
1. Parse user description from Input
   → Feature clearly defined: Split auth screens, improve errors, add autofill
2. Extract key concepts from description
   → Actors: New users, returning users
   → Actions: Choose auth type, authenticate, view errors, use autofill, navigate back
   → Data: Email, password, consent status
   → Constraints: Must preserve existing functionality
3. For each unclear aspect:
   → Clarifications marked in Requirements section
4. Fill User Scenarios & Testing section
   → User flows clearly defined for both login and signup
5. Generate Functional Requirements
   → All requirements testable and specific
6. Identify Key Entities (if data involved)
   → No new entities, using existing auth models
7. Run Review Checklist
   → No implementation details included
8. Return: SUCCESS (spec ready for planning)
```

---

## ⚡ Quick Guidelines
- ✅ Focus on WHAT users need and WHY
- ❌ Avoid HOW to implement (no tech stack, APIs, code structure)
- 👥 Written for business stakeholders, not developers

---

## Clarifications

### Session 2025-10-07
- Q: Does the backend authentication service provide a specific error code for duplicate email addresses during signup? → A: Yes, backend returns a distinct error code (verified via Supabase implementation)
- Q: Should the system automatically save credentials to the device's password manager after successful signup, or should users be prompted to confirm first? → A: OS default - Rely entirely on the operating system's standard password manager behavior
- Q: What should happen when a user navigates back from the initial choice screen? → A: Stay on choice screen - There is nothing before authentication, so back navigation is prevented
- Q: When mismatched passwords are entered during signup, what specific error message should be displayed? → A: "Passwords don't match"
- Q: What text should appear on the choice screen buttons for login and signup? → A: "Sign In" and "Create Account"

---

## User Scenarios & Testing

### Primary User Story

**As a new user**, I want to select "Create Account" from an initial choice screen and proceed to a dedicated signup screen so I can clearly understand I'm creating a new account without confusion.

**As a returning user**, I want to select "Sign In" from an initial choice screen and proceed to a streamlined login screen so I can quickly authenticate without seeing irrelevant signup fields, and I want clear error messages so I understand what went wrong if authentication fails.

**As any user**, I want the system to integrate with my device's password manager so I can use saved credentials or securely generate and store new passwords, and I want to be able to go back to the choice screen if I selected the wrong option.

### Acceptance Scenarios

#### Initial Choice & Login Flow
1. **Given** a user launches the app and needs to authenticate, **When** they reach the authentication flow, **Then** they see an initial choice screen with "Sign In" and "Create Account" buttons
2. **Given** a returning user is on the choice screen, **When** they select "Sign In", **Then** they navigate to a dedicated login screen with email and password fields
3. **Given** a user is on the login screen, **When** they tap the email field, **Then** the system offers saved credentials from the device's password manager
4. **Given** a user enters invalid credentials, **When** they attempt to login, **Then** they see a specific error message (e.g., "That email or password looks incorrect") instead of a generic error
5. **Given** a user has not verified their email, **When** they attempt to login, **Then** they see "Verify your email before signing in" instead of a generic authentication error
6. **Given** a user is on the login screen, **When** they use the back navigation, **Then** they return to the initial choice screen

#### Signup Flow
7. **Given** a new user is on the choice screen, **When** they select "Create Account", **Then** they navigate to a dedicated signup screen with email, password, confirm password, and terms consent fields
8. **Given** a user is on the signup screen, **When** they tap the password field, **Then** the system offers to generate and save a strong password via the device's password manager
9. **Given** a user enters mismatched passwords, **When** they attempt to signup, **Then** they see the error message "Passwords don't match"
10. **Given** a user enters an already-registered email, **When** they attempt to signup, **Then** they see a clear error message indicating the email is already in use
11. **Given** a user successfully signs up, **When** the account is created, **Then** the operating system's password manager handles credential saving according to its standard behavior
12. **Given** a user is on the signup screen, **When** they use the back navigation, **Then** they return to the initial choice screen

#### Error Handling
13. **Given** a network error occurs during authentication, **When** the request fails, **Then** the user sees "We can't reach the server. Check your connection and try again." instead of a generic error
14. **Given** a user is rate-limited, **When** they attempt authentication, **Then** they see "Too many attempts. Please try again shortly." with information about when they can retry

### Edge Cases

- What happens when a user navigates back from login or signup to the choice screen? (Form state is cleared per FR-033/034/035/036)
- How does the system handle password manager integration when multiple credentials are saved for the same app? (OS handles credential selection)
- What happens if the password manager is disabled or unavailable on the device? (Manual entry still works; autofill simply unavailable)
- How does the system handle authentication errors not explicitly mapped to user-friendly messages? (Fallback message per FR-026)
- What happens when a user submits the form while offline? (Prevented per FR-032, with offline message displayed)
- How does the system differentiate between "invalid credentials" errors from the backend (wrong password vs. email not found)? (Both map to same user-friendly message per FR-020 for security)

## Requirements

### Functional Requirements

#### Screen Separation & Navigation
- **FR-001**: System MUST provide an initial choice screen where users select between signing in or creating an account
- **FR-002**: Choice screen MUST display two clearly labeled buttons: "Sign In" and "Create Account"
- **FR-003**: System MUST provide separate screens for login and signup flows instead of a combined segmented control interface
- **FR-004**: Users MUST be able to navigate back from login screen to the choice screen using standard back navigation
- **FR-005**: Users MUST be able to navigate back from signup screen to the choice screen using standard back navigation
- **FR-006**: The choice screen MUST prevent back navigation since it is the entry point of the authentication flow
- **FR-007**: Form fields MUST be cleared when navigating back to the choice screen
- **FR-008**: Error messages and banners MUST be cleared when navigating back to the choice screen

#### Login Screen
- **FR-009**: Login screen MUST display only email and password fields
- **FR-010**: Login screen MUST provide a "Forgot Password?" action that navigates to password reset flow
- **FR-011**: Login screen MUST NOT display signup-specific fields (password confirmation, terms consent)

#### Signup Screen
- **FR-012**: Signup screen MUST display email, password, confirm password, and terms consent fields
- **FR-013**: Signup screen MUST validate that password and confirm password fields match before allowing submission
- **FR-014**: When password and confirm password fields don't match, system MUST display error message: "Passwords don't match"
- **FR-015**: Signup screen MUST require explicit consent to terms and conditions before account creation

#### Password Autofill Support
- **FR-016**: Email field MUST be configured with appropriate content type hints for password manager integration
- **FR-017**: Password field on login screen MUST be configured to enable password manager credential suggestions
- **FR-018**: Password field on signup screen MUST be configured to enable password manager strong password generation
- **FR-019**: System MUST rely on the operating system's standard password manager behavior for credential saving (no custom prompts or override of OS defaults)
- **FR-020**: System MUST update saved credentials in device password manager after successful password reset following OS standard behavior
- **FR-021**: Password autofill MUST work correctly on both login and signup screens despite being separate views

#### Error Messaging
- **FR-022**: System MUST display specific error messages for each authentication failure type instead of generic "something went wrong" messages
- **FR-023**: System MUST map "invalid credentials" backend error to user-friendly message: "That email or password looks incorrect"
- **FR-024**: System MUST map "email unverified" backend error to user-friendly message: "Verify your email before signing in"
- **FR-025**: System MUST map "network unavailable" error to user-friendly message: "We can't reach the server. Check your connection and try again."
- **FR-026**: System MUST map "rate limited" backend error to user-friendly message: "Too many attempts. Please try again shortly."
- **FR-027**: System MUST map "OTP incorrect" error (password reset flow) to user-friendly message: "That code isn't right. Double-check and try again."
- **FR-028**: System MUST map "duplicate email" backend error to user-friendly message: "An account with this email already exists. Try logging in instead."
- **FR-029**: System MUST provide a fallback error message for unmapped error types: "Something went wrong. Please try again."
- **FR-030**: Error messages MUST be displayed prominently and persistently until the user takes corrective action or dismisses them
- **FR-031**: Error messages MUST be accessible to screen readers with appropriate semantic labels

#### Form Validation
- **FR-032**: System MUST validate email format before allowing submission
- **FR-033**: System MUST disable submission button when required fields are incomplete
- **FR-034**: System MUST show appropriate keyboard types for each field (email keyboard for email, secure entry for passwords)
- **FR-035**: System MUST preserve network status awareness and prevent submission when offline (existing behavior)

#### State Management
- **FR-036**: When navigating back from login or signup screens to the choice screen, all form fields MUST be cleared
- **FR-037**: Error messages MUST be cleared when navigating back to the choice screen
- **FR-038**: Banner notifications MUST be cleared when navigating back to the choice screen
- **FR-039**: The choice screen MUST NOT display any error messages or banners from previous authentication attempts

### Key Entities

No new entities are introduced. This feature uses existing authentication models:

- **User Credentials**: Email address and password used for authentication
- **Auth Session**: User session information including authentication tokens
- **Auth Error**: Error types returned from authentication operations
- **Form State**: Email, password, confirmation password, and consent values

---

## Review & Acceptance Checklist

### Content Quality
- [x] No implementation details (languages, frameworks, APIs)
- [x] Focused on user value and business needs
- [x] Written for non-technical stakeholders
- [x] All mandatory sections completed

### Requirement Completeness
- [x] No [NEEDS CLARIFICATION] markers remain
- [x] Requirements are testable and unambiguous  
- [x] Success criteria are measurable
- [x] Scope is clearly bounded
- [x] Dependencies and assumptions identified

### Assumptions
- Existing password reset flow remains unchanged
- Backend authentication API error codes are stable and distinguishable
- Device password managers follow standard autofill protocols
- Current analytics and network monitoring features remain intact

### Dependencies
- Backend authentication service must provide distinguishable error codes for different failure types
- Device operating system must support password manager integration APIs
- Existing authentication service implementation provides error mapping capabilities

---

## Execution Status

- [x] User description parsed
- [x] Key concepts extracted
- [x] Ambiguities marked (3 clarifications needed)
- [x] User scenarios defined
- [x] Requirements generated
- [x] Entities identified
- [x] Review checklist executed

---

## Success Metrics

While implementation details are outside the scope of this specification, the following outcomes indicate successful delivery:

- Users can navigate between dedicated login and signup screens
- Password managers successfully integrate with both login and signup flows
- Error messages are specific, actionable, and user-friendly
- Authentication failure rates decrease due to clearer error guidance
- User confusion between login and signup flows is eliminated
- Accessibility standards are maintained or improved

---

## Out of Scope

- Changes to password reset flow (remains on separate screens as currently implemented)
- Social authentication (OAuth, SSO)
- Biometric authentication
- Multi-factor authentication beyond email verification
- Custom password strength requirements
- "Remember me" functionality
- Session timeout customization
- Account deletion or data export features

---
