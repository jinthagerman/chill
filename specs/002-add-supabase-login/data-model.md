# Phase 1 Data Model — Supabase Login and Signup

## View Models & Services

### AuthService (protocol)
- **Responsibilities**: Wrap Supabase Auth client calls for sign up, sign in, sign out, session refresh, and OTP reset flows.
- **Key Methods**:
  - `signUp(email:password:consent:) async throws -> AuthSession`
  - `signIn(email:password:) async throws -> AuthSession`
  - `requestPasswordReset(email:) async throws`
  - `verifyResetCode(email:code:newPassword:) async throws -> AuthSession`
  - `signOut() async throws`
  - `sessionPublisher: AsyncStream<AuthSession?>`
- **Notes**: Implementation must sanitize errors into domain-specific types for presentation.

### AuthViewModel
- **State**:
  - `mode: AuthMode` (`.login`, `.signup`, `.resetRequest`, `.resetVerify`)
  - `email: String`
  - `password: String`
  - `confirmPassword: String`
  - `otpCode: String`
  - `isProcessing: Bool`
  - `errorMessage: String?`
  - `session: AuthSession?`
- **Derived Values**:
  - `canSubmit` (validates fields, connectivity, consent)
  - `ctaLabel` (contextual button text)
  - `statusBanner` (email verification / offline / success state)
- **Actions**:
  - `submit()` routes to sign up or login based on mode
  - `startReset()` triggers OTP email
  - `confirmReset()` consumes code and sets new password
  - `handleSessionChange()` updates root navigation to `SavedLinksView`

### AuthSession (struct)
- `userID: UUID`
- `email: String`
- `accessTokenExpiresAt: Date`
- `refreshToken: String`
- `isVerified: Bool`
- `rawSupabaseData: Any` (opaque storage for advanced use; not exposed to UI)

### AuthMode (enum)
- `.login`
- `.signup(consentAccepted: Bool)`
- `.resetRequest`
- `.resetVerify(pendingEmail: String)`

## UI Surfaces

### AuthFlowView
- Displays welcome CTA handoff, segmented control or tabs between Login/Sign Up, and OTP reset screens.
- Integrates with design tokens for spacing, typographic hierarchy, and the liquid-glass buttons.

### SavedLinksView (placeholder)
- Blank authenticated landing screen shown after successful login/signup or when a valid session exists on launch.
- Serves as scaffolding for future saved links functionality; currently displays minimal placeholder content.

### Toast/Banner Model
- `AuthBanner` struct capturing message type (`success`, `error`, `info`), copy, and optional retry closure.

## Payloads & Telemetry

### AuthEventPayload
- `eventType: AuthEventType` (`sign_up`, `sign_in`, `password_reset`)
- `result: AuthEventResult` (`success`, `failure`)
- `supabaseErrorCode: String?` (bucketized)
- `latencyMs: Int`
- `networkStatus: NetworkReachability`

### NetworkReachability
- `.wifi`
- `.cellular`
- `.offline`

## Persistence Considerations
- Supabase SDK manages secure storage of tokens. AuthService must expose hooks to clear tokens on logout.
- Local caching (e.g., `pendingEmail`) remains in-memory; do not persist across launches without consent.

## State Transitions
- Signup → success: show confirmation if `isVerified == false`; route to wait screen or `SavedLinksView` if verified.
- Login → success: update root navigation to `SavedLinksView`.
- Reset request → OTP sent: transition to `.resetVerify` with pending email.
- Reset verify → success: automatically sign in user and transition to `SavedLinksView`.
- App launch → existing session: bypass welcome screen and render `SavedLinksView` immediately.

## Error Taxonomy
- `AuthError.networkUnavailable`
- `AuthError.invalidCredentials`
- `AuthError.emailUnverified`
- `AuthError.rateLimited`
- `AuthError.otpIncorrect`
- `AuthError.unknown`
