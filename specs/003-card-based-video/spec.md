# Feature Specification: Card-Based Video List

**Feature Branch**: `003-card-based-video`  
**Created**: 2025-10-04  
**Status**: Draft  
**Input**: User description: "Card-based video list that fetches from supabase"

## Execution Flow (main)
```
1. User opens the video library surface from the Chill app home.
2. System requests the latest video collection from a curated Supabase GraphQL view that already exposes the card-ready fields.
3. While data is loading, the interface shows a non-blocking, localized progress indicator on the list canvas.
4. Once data arrives, cards render with title, preview imagery, creator context, localized UI chrome, and a clear action affordance.
5. If the response is empty, the interface displays an encouraging empty state with guidance to return later.
6. If the request fails, the interface surfaces a recoverable error message with a retry action and support pathway.
7. A Supabase GraphQL subscription keeps the list fresh; revisiting the surface re-establishes the live feed if needed.
8. A floating '+' button remains pinned bottom-right for future add actions without functional behavior in this release.
```

---
## Clarifications
### Session 2025-10-04
- Q: Which Supabase data source should the video list read from, and which fields can we rely on being populated? → A: Query view via Supabase GraphQL
- Q: Who should initially receive the card-based video list experience? → A: All authenticated Chill users
- Q: When a user taps a video card, what should happen? → A: No action yet; informational only
- Q: How should users trigger a data refresh for the video list? → A: Maintain a Supabase GraphQL subscription
- Q: If the user loses connectivity after initial load, how should the video list behave? → A: Allow offline browsing of cached cards and queue updates until reconnection
- Q: What localization support is required for the card list UI and copy? → A: Localizable UI strings; video metadata remains source language
- Q: Which analytics events must we capture for the card list launch? → A: Page view only; defer further instrumentation
- Q: If a video record is missing key fields (e.g., thumbnail or creator name), what should the card display? → A: Use generic thumbnail and “Unknown creator” label
- Q: If the Supabase GraphQL subscription disconnects, how should the app inform users and recover? → A: Show transient toast and auto-retry silently
- Q: What performance target should govern initial card load over mobile connections? → A: Ensure content appears within 4 seconds
- Q: Do we need explicit throttling on refreshes or reconnects? → A: No; rely on Supabase defaults
- Q: What’s the minimal success metric for determining if the card list launch is delivering value? → A: No success metrics defined for launch

## ⚡ Quick Guidelines
- Maintain the Chill card design language, including spacing, typography tokens, and motion guidelines for list transitions.
- Provide equal access for voice-over and switch-control users; every card must expose a descriptive label beyond the visual thumbnail.
- Ensure the list behaves calmly: do not snap-scroll, avoid jitter while new cards appear, and prioritize perceived performance.
- Protect user privacy by limiting telemetry to aggregated engagement metrics and never logging specific video playback intentions.
- Prepare rollout guards so the feature can be enabled for a small cohort before wide release.

### Section Requirements
- Mandatory artefacts for planning: validated user scenarios, functional requirements, key entity definitions, and release checklist entries.
- Optional enhancements (filters, personalization, downloads) should be captured separately once the foundational browsing experience is stable.
- Remove any workstream that depends on unresolved clarifications until answers are received.

### For AI Generation

---

## User Scenarios & Testing *(mandatory)*

### Primary User Story
As an authenticated Chill user, I want to open the video library and browse a vertically scrolling set of rich video cards (large thumbnail, title, source, duration) sourced from the curated Supabase catalog so that I can quickly choose something meaningful to watch, with interface copy matching my device language while video metadata stays in its source language.

### Acceptance Scenarios
1. **Given** any authenticated Chill user opens the video library with an online connection, **When** the system retrieves data from the Supabase catalog, **Then** the user sees a list of styled video cards (full-bleed thumbnail, title, source line, duration badge) while card taps remain non-interactive, and interface labels reflect the user’s locale.
2. **Given** the Supabase GraphQL view request fails, **When** the error state is triggered, **Then** the user sees a friendly message explaining the issue and can attempt a retry without leaving the screen.

### Edge Cases
- What happens when the catalog returns zero items because no videos are scheduled? The interface should present an empty state that reassures users and offers guidance or alternative actions.
- Cards with missing thumbnails SHOULD use a branded placeholder image, and creator gaps MUST display “Unknown creator” to avoid blank metadata.
- If connectivity is lost after cards render, the interface must retain cached cards, display an offline indicator, and queue Supabase subscription updates until reconnection.
- How should the interface reassure users when tapping a card currently does nothing (e.g., tooltip or disabled cursor state), and should that message be localized?
- If the Supabase GraphQL subscription disconnects, surface a transient toast to inform the user while the client retries in the background.

## Requirements *(mandatory)*

### Audience & Access
- Primary audience: All authenticated Chill users regardless of tenure or saved-video history.

### Functional Requirements
- **FR-001**: System MUST present the video library as a scrollable collection of visually distinct cards that align with Chill design tokens.
- **FR-002**: System MUST request the current video catalog from the approved Supabase GraphQL view when the video list surface becomes active, ensuring GraphQL authentication and row-level security constraints are satisfied.
- **FR-003**: System MUST display a loading indicator or skeleton treatment while awaiting the catalog response, ensuring the first batch of cards appears within 4 seconds on typical mobile connections.
- **FR-004**: System MUST display an empty-state message with supportive guidance when the catalog response contains no videos.
- **FR-005**: System MUST surface a user-friendly error state with retry guidance when the catalog request fails or times out.
- **FR-006**: System MUST record anonymized page-view events when the list surface becomes visible while adhering to Chill privacy standards; additional instrumentation will be evaluated post-launch.
- **FR-007**: System MUST maintain a Supabase GraphQL subscription that streams card updates in near real time, re-subscribes when the view regains focus, and queues deltas while offline.
- **FR-008**: Until playback flows launch, card taps MUST be ignored without triggering navigation, playback, or incidental analytics events.
- **FR-009**: System MUST rely on Supabase client default reconnect and throttling behavior without introducing additional rate limits.

### UI Composition
- Present a "My Videos" header with leading title and trailing avatar button for future profile access.
- Render each video as a large rounded card with full-bleed thumbnail, overlaid title, source line (creator — platform), and a duration pill anchored bottom-right.
- Use consistent vertical spacing between cards and maintain Calm design token padding on the page edges.
- Reserve a floating action button with '+' icon in the lower-right corner for future add/upload scenarios (visually present but non-interactive for this release).

### Success Measurement
- No quantitative success metrics are required for the initial launch; the team will evaluate value through qualitative feedback and system stability.

### Key Entities *(include if feature involves data)*
- **Video Catalog Item**: Represents the remote video record, including identifier, title, description snippet, creator metadata, thumbnail reference, and any action link; sourced from a Supabase-maintained GraphQL view tuned for card display.
- **Video Card Display Model**: Presentation-ready subset of catalog attributes (title, creator label, duration badge, thumbnail accessibility text) used to render UI components.
- **Video List Session**: Tracks a user’s interaction with the list (load timestamp, refresh count, engagement events) for analytics while respecting privacy constraints.

---

## Review & Acceptance Checklist
*GATE: Automated checks run during main() execution*

### Content Quality
- [x] No implementation details (languages, frameworks, APIs)
- [x] Focused on user value and business needs
- [x] Written for non-technical stakeholders
- [x] All mandatory sections completed

### Requirement Completeness
- [ ] No [NEEDS CLARIFICATION] markers remain
- [x] Requirements are testable and unambiguous  
- [ ] Success criteria are measurable
- [ ] Scope is clearly bounded
- [ ] Dependencies and assumptions identified

### Constitution Alignment
- [x] SwiftUI Experience Integrity: Accessibility, design-system expectations, and MVVM view/view-model boundaries are described.
- [ ] Calm State & Offline Resilience: Offline flows, persistence guarantees, and error states are documented.
- [ ] Observability With Privacy Guarantees: Logging, metrics, and privacy constraints are defined.
- [ ] Test-First Delivery: Expected failing tests and coverage strategy are enumerated.
- [ ] Release Confidence & Support: Rollout gating, toggles, and support handoffs are covered.

---

## Execution Status
*Updated by main() during processing*

- [x] User description parsed
- [x] Key concepts extracted
- [x] Ambiguities marked
- [x] User scenarios defined
- [x] Requirements generated
- [x] Entities identified
- [ ] Review checklist passed

---
