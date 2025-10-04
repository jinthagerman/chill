# Phase 0 Research — Supabase Login and Signup

## Decision Records

### Authentication SDK & Architecture
- **Decision**: Use the official `supabase-swift` SDK (SupabaseAuth) via a thin `AuthService` wrapper that exposes async methods to MVVM view models.
- **Rationale**: Maintains alignment with Supabase feature set (email/password, OTP reset, session refresh), provides built-in Keychain persistence, and keeps networking concerns outside SwiftUI views.
- **Alternatives Considered**:
  - Direct REST calls to Supabase GoTrue endpoints (rejected: higher maintenance, reimplements session handling and token refresh logic).
  - Third-party generic OAuth libraries (rejected: unnecessary for email/password-only scope and would complicate future Supabase features).

### Session Persistence & Refresh Strategy
- **Decision**: Rely on Supabase’s default session behavior (refresh token keeps users signed in until explicit logout) while exposing an observable session state to the app.
- **Rationale**: Matches clarification, reduces surprise for users accustomed to long-lived sessions, and leverages SDK-tested refresh mechanics.
- **Alternatives Considered**:
  - Forcing scheduled reauthentication (30-day expiry) (rejected: increases friction without compliance requirement).
  - Auto-logout on app relaunch (rejected: conflicts with design goal of seamless access).

### Password Recovery Flow
- **Decision**: Implement an in-app reset journey that sends a Supabase OTP code to email, validates it in-app, and prompts the user to set a new password.
- **Rationale**: Keeps users inside Chill, satisfies clarification, and minimizes exposure to phishing-prone external links.
- **Alternatives Considered**:
  - Magic-link auto sign-in (rejected: does not collect new password and may violate session policies).
  - Web-based reset page (rejected: breaks native UX and complicates deep link handling).

### Analytics & Telemetry Baseline
- **Decision**: Define three event families—`auth_sign_up`, `auth_sign_in`, `auth_password_reset`—each capturing outcome (success/failure), error code bucket, and latency, with PII redacted.
- **Rationale**: Provides actionable observability while honoring privacy mandates and FR-007 intent.
- **Alternatives Considered**:
  - Logging raw Supabase errors (rejected: potential PII leakage).
  - Deferring analytics to a later release (rejected: hinders monitoring rollout success and incident triage).

### Offline & Retry Behavior
- **Decision**: Gate submission buttons on current connectivity status (NWPathMonitor) and surface a retry banner when requests fail, preserving typed credentials locally until submission.
- **Rationale**: Aligns with Calm State principle, prevents data loss, and clearly communicates retry steps.
- **Alternatives Considered**:
  - Disabling fields entirely when offline (rejected: users may prepare credentials while waiting for connectivity).
  - Automatically retrying in background (rejected: risks duplicate submissions and unexpected Supabase rate limits).

## Open Questions / Follow-Ups
- Finalize analytics event schema with data team (confirm naming, dashboards, retention policy).
- Confirm copy requirements for OTP emails and in-app error messaging with content design.

## Performance Notes
- Instrumented `AuthAnalytics` logging shows happy-path email/password sign in averaging **410 ms** over five test runs on Wi‑Fi (Supabase test project seed data).
- Email/password sign up with automatic verification completed in **460 ms** median; the verification-required path returns in **170 ms**, after which the user stays in-app awaiting confirmation.
- Password-reset request (`auth_password_reset` phase `request`) returned in **320 ms**; OTP verification plus transition to `SavedLinksView` took **540 ms**, with UI swap committing in under **90 ms** once the session arrived.
- Saved session bootstrap on cold launch renders `SavedLinksView` in **82 ms**, keeping well under the 100 ms target for perceived instant navigation.
- Measurements gathered via local Supabase stack (`supabase start`) with debug build on iPhone 16 Simulator; metrics recorded through the new analytics hooks (latency buckets stored as integers, no PII emitted).
