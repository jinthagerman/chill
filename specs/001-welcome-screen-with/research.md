# Phase 0 Research — Welcome Screen With Login and Signup

## Decision Records

### Button Interaction Strategy
- **Decision**: Keep the "Log In" and "Sign Up" buttons enabled with standard touch feedback but no navigation or toast messaging.
- **Rationale**: Preserves tactile expectations without misleading users into incomplete flows; aligns with clarification from product.
- **Alternatives Considered**:
  - Disable buttons entirely (rejected: visually conflicts with future activation state and feels inert).
  - Show toast or inline messaging on tap (rejected: adds copy churn and implies near-term availability without backend support).

### Messaging & Content Management
- **Decision**: Centralize headline, subcopy, helper text, and accessibility copy in a `WelcomeContent` value type backed by localized strings.
- **Rationale**: Allows marketing to adjust copy independently and prepares for localization.
- **Alternatives Considered**:
  - Hard-code strings inside the view (rejected: blocks content updates and localization).
  - Load copy from remote CMS (rejected for MVP: unnecessary complexity without network features).

### Accessibility Baseline
- **Decision**: Define a semantic layout with `ScrollView` + `VStack`, provide explicit `accessibilityLabel` and `accessibilityHint` describing buttons as "coming soon", and ensure Dynamic Type scaling via responsive layout guidelines.
- **Rationale**: Meets constitution requirements and prevents miscommunication for assistive technology users.
- **Alternatives Considered**:
  - Rely on default button labels (rejected: voice feedback would imply functional auth).
  - Fix layout heights to prevent compression (rejected: breaks Dynamic Type).

### Offline & Observability Posture
- **Decision**: Treat the welcome screen as fully local UI with no network or analytics calls; add a note to analytics backlog for activation milestone.
- **Rationale**: Avoids misleading telemetry during UI-only release and respects privacy without consent gating.
- **Alternatives Considered**:
  - Emit "coming soon" events (rejected: pollutes funnels and violates observability principle without real flow).
  - Preload auth dependencies (rejected: contradicts scope and increases failure surface).


## Follow-up Items

- Create analytics instrumentation ticket to enable welcome screen telemetry once authentication flows ship; confirm ownership before launch.


## Performance

- Instruments run (iPhone 16 simulator) shows WelcomeView first render ~12ms; no dropped frames observed.
