# Auth Flow Contract — Supabase Login & Signup

## Actors
- **Visitor**: Unauthenticated app user interacting with welcome screen.
- **Returning Member**: Previously authenticated user returning to the app.
- **Supabase Auth**: External identity provider handling sign up, login, OTP reset, and session refresh.

## Screens & States
| Screen | Purpose | Entry Conditions | Exit Conditions |
|--------|---------|-----------------|-----------------|
| Welcome CTA | Present “Log In” / “Sign Up” options | Visitor | User chooses CTA → Auth Form |
| Auth Form (Login) | Collect email/password, show errors | Visitor selects “Log In” | Success → Authenticated Shell; Failure → Form with error |
| Auth Form (Signup) | Collect email/password/consent | Visitor selects “Sign Up” | Success (verified) → Authenticated Shell; Success (unverified) → Await Verification state; Failure → Form with error |
| Password Reset Request | Collect email for OTP | Visitor selects “Forgot password?” | Success → Reset Verify; Failure → Form error |
| Password Reset Verify | Collect OTP + new password | Visitor completed request | Success → Authenticated Shell; Failure → Stay on screen |
| Await Verification | Communicate pending email confirmation | Signup success but unverified | On refresh after verification → Authenticated Shell |

## Interaction Contract
| Interaction | Request | Supabase Response | UI Behavior |
|-------------|---------|-------------------|-------------|
| Sign Up | `signUp(email,password)` | 200 (session + user), 200 (pending email confirmation), error codes | Show success toast; navigate to SavedLinksView if verified, otherwise wait state; map errors to friendly copy |
| Log In | `signIn(email,password)` | 200 (session), 400/401 (invalid), network errors | Transition to SavedLinksView or show inline error |
| Refresh Session | automatic | 200 (new token) | Silent; ensure SavedLinksView remains visible; log failure and prompt re-login if refresh fails |
| Logout | `signOut()` | 200 | Clear session, return to welcome |
| Password Reset Request | `resetPasswordForEmail` (OTP) | 200 (email sent) | Show check email message, move to verify screen |
| Password Reset Verify | `verifyOTP(type: 'recovery', token, password)` | 200 (session) | Sign user in, show success state |

## Error Handling
- Map Supabase error codes to categories: `invalid_credentials`, `email_not_confirmed`, `rate_limited`, `otp_expired`, `network_unavailable`, `unknown`.
- Provide retry guidance and support contact where appropriate.

## Telemetry Events
- `auth_sign_up` `{ result, errorCategory, latencyMs }`
- `auth_sign_in` `{ result, errorCategory, latencyMs }`
- `auth_password_reset` `{ phase: request|verify, result, errorCategory }`

## Accessibility Requirements
- Form fields labeled for VoiceOver, helper text describing inactive state and verification requirements.
- OTP entry supports one-time-code autofill and readable contrast.
- Error banners announced via accessibility focus change.

## Open Questions
- Confirm analytics dashboard owners and event schema versioning.
- Define copy tone for verification pending and error states with content design.
