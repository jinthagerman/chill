# Feature Specification: Add Video via URL Modal

**Feature Branch**: `004-implement-add-video`  
**Created**: 2025-10-04  
**Status**: Draft  
**Input**: User description: "Implement add video via url modal flow"

## Execution Flow (main)
```
1. User taps the floating '+' button in the video list screen.
2. System presents "Save a video" modal with URL input field, optional description field, Cancel and Save buttons.
3. User pastes or types a video URL into the input field.
4. System validates the URL format in real-time (no visual feedback shown per design).
5. User taps "Save" button to submit the URL.
6. System shows loading state, fetches video metadata using LoadifyEngine.
7. On success, system presents "Confirm Video" screen showing:
   - Video thumbnail with play button overlay
   - Platform badge, title, and duration on thumbnail
   - Metadata rows: Title, Source, Length
   - "Confirm and Save" (primary) and "Edit Details" (secondary) buttons
8. User taps "Confirm and Save" to add video to library.
9. System saves video and returns to video list with new card visible.
10. On metadata fetch failure, system shows error on input modal with retry guidance.
11. User can dismiss at any time by tapping "Cancel" (input modal) or X button (confirmation screen).
```

---

## Clarifications
### Session 2025-10-04
- Q: Which video platforms should be supported initially? → A: Facebook + YouTube + Twitter
- Q: LoadifyEngine does NOT support YouTube. Which platforms should the feature actually support? → A: Facebook + Twitter only (subset of LoadifyEngine, matches original intent for 2 platforms)
- Q: Should the system extract video metadata automatically or require user input? → A: Auto-fetch using LoadifyEngine
- Q: What happens if the user submits a duplicate URL? → A: Warn user with "Already added" message but allow them to proceed if desired
- Q: Should the modal support adding multiple URLs at once? → A: Single URL only (simplest flow, one submission at a time)
- Q: What rate limiting should apply to video additions? → A: No client-side rate limiting (trust authenticated users, rely on backend throttling if needed)

## ⚡ Quick Guidelines
- Maintain the Chill calm design language: smooth modal transitions, clear focus states, and non-intrusive error messaging.
- Ensure the URL input field is immediately focused and keyboard-ready when the modal opens.
- Provide real-time validation feedback as users type or paste URLs to prevent submission errors.
- Support common URL formats including shortened links, mobile URLs, and embedded parameters.
- Keep users informed during processing with appropriate loading states and progress indicators.
- Design for accessibility: full VoiceOver support, Dynamic Type, and keyboard navigation.
- Preserve user input if validation fails or network errors occur, avoiding data loss frustration.
- Maintain offline resilience by queuing submissions when connectivity is lost and syncing when restored.

### Section Requirements
- Mandatory artefacts for planning: validated user scenarios, functional requirements, key entity definitions, and UI interaction contracts.
- Optional enhancements (URL preview, batch import, browser extension) should be captured separately once the core flow is stable.
- Remove any workstream that depends on unresolved clarifications until answers are received.

---

## User Scenarios & Testing *(mandatory)*

### Primary User Story
As an authenticated Chill user browsing my video list, I want to add a single video by pasting its URL so that I can save interesting content I discover elsewhere without leaving the app or manually entering metadata, with the modal dismissing after successful submission.

### Acceptance Scenarios
1. **Given** an authenticated user viewing the video list, **When** they tap the floating '+' button, **Then** a modal appears with a focused URL input field, placeholder text explaining supported platforms (Facebook, Twitter), and enabled "Cancel" and "Add Video" buttons.
2. **Given** the add video modal is open, **When** the user pastes a valid video URL and taps "Add Video", **Then** the system displays a loading indicator, submits the URL to the backend, and on success dismisses the modal while inserting the new video card into the list.
3. **Given** the user submits an invalid or unsupported URL, **When** the validation fails, **Then** the modal displays an inline error message below the input field explaining the issue and the "Add Video" button remains enabled for retry.
4. **Given** the add video modal is open with text in the input field, **When** the user taps "Cancel" or outside the modal, **Then** the modal dismisses without saving and any entered text is discarded.

### Edge Cases
- What happens when the user pastes a URL while offline? The system should display a message explaining connectivity is required and offer to retry when online.
- How does the modal handle extremely long URLs or malformed text? The input field should gracefully truncate display while preserving full content for validation.
- If the video metadata fetch takes longer than expected, what feedback does the user receive? A progress message should appear after 3 seconds explaining the delay.
- What happens if the user already has this video in their library? The system displays an "Already added" warning message below the input field but keeps the "Add Video" button enabled, allowing the user to proceed if desired (useful for re-saving videos with different metadata or timestamps).
- How does the modal behave when the keyboard is shown on smaller devices? The modal should resize to remain fully visible above the keyboard.
- What happens if the user submits a URL and immediately closes the app? The submission should be queued and completed when the app reopens.

## Requirements *(mandatory)*

### Audience & Access
- Primary audience: All authenticated Chill users with video library access.
- Feature activation: Tapping the '+' floating action button in the video list screen.

### Functional Requirements
- **FR-001**: System MUST present a modal interface when the user taps the floating '+' button, with a single URL input field immediately focused and keyboard visible, supporting one URL submission per modal instance.
- **FR-002**: System MUST validate URL format as the user types or pastes, providing real-time visual feedback (checkmark for valid, warning icon for invalid) without blocking input.
- **FR-003**: System MUST support URLs from Facebook and Twitter including mobile variants (m.facebook.com, mobile.twitter.com), shortened links (fb.watch, t.co), and embedded parameters.
- **FR-004**: System MUST disable the "Add Video" button when the input is empty or validation shows an invalid URL format.
- **FR-005**: System MUST display a loading state with progress indicator when the user submits a valid URL, preventing duplicate submissions during processing.
- **FR-006**: System MUST handle URL submission responses: on success, dismiss modal and refresh video list; on failure, show error message and retain user input for retry.
- **FR-007**: System MUST provide inline error messages for common failure scenarios: unsupported platform (only Facebook and Twitter supported), invalid URL format, network timeout, video not found, metadata extraction failure, duplicate URL warning, and backend rate limit if enforced server-side.
- **FR-008**: System MUST allow users to dismiss the modal at any time by tapping "Cancel", the backdrop, or using swipe-to-dismiss gesture without saving changes.
- **FR-009**: System MUST preserve calm UX with smooth modal animations (slide-up presentation, fade-in backdrop) respecting reduced motion preferences.
- **FR-010**: System MUST meet accessibility standards: VoiceOver announces modal purpose and input requirements, supports keyboard navigation, and respects Dynamic Type.
- **FR-011**: System MUST queue URL submissions when offline and automatically retry when connectivity is restored, notifying the user of pending submissions.
- **FR-012**: System MUST automatically fetch video metadata (title, thumbnail, creator, duration) using LoadifyEngine without requiring manual user entry.
- **FR-013**: System MUST detect duplicate URL submissions by checking existing library entries and display an "Already added" warning message while still allowing the user to proceed with adding the video if they choose to continue.
- **FR-014**: System MUST emit analytics events for modal opens, URL submissions, success/failure outcomes while protecting user privacy (no URL content logged).
- **FR-015**: System MUST NOT implement client-side rate limiting on video additions, trusting authenticated users and relying on backend throttling mechanisms if abuse prevention is required.

### UI Composition

**Input Modal ("Save a video")**:
- Modal sheet with rounded corners, drag indicator at top
- Title: "Save a video" (bold, left-aligned)
- URL input field: Light gray background, rounded, placeholder "Video URL"
- Description field: Light gray background, rounded, multi-line, placeholder "Description (optional)"
- Bottom action row: "Cancel" (light gray, rounded) and "Save" (black, rounded) buttons with equal width
- Save button disabled when URL field empty

**Confirmation Screen ("Confirm Video")**:
- Full-screen presentation with X close button (top-left)
- Title: "Confirm Video" (bold, centered at top)
- Large video preview card with:
  - Thumbnail image with rounded corners
  - Play button overlay (centered)
  - Platform badge overlay (top-left, e.g., "YouTube")
  - Video title overlay (bottom-left, white text)
  - Duration badge overlay (bottom-left below title, e.g., "15:30")
- Metadata section with rows:
  - "Title" label | Video title (right-aligned)
  - "Source" label | Platform name (right-aligned)
  - "Length" label | Duration (right-aligned)
- Bottom action buttons (full-width, stacked):
  - "Confirm and Save" (black, rounded, primary)
  - "Edit Details" (light gray, rounded, secondary)

### Key Entities *(include if feature involves data)*
- **Video Submission Request**: Represents a user-initiated video addition, including the submitted URL, timestamp, user identifier, and processing status for tracking and retry logic.
- **Video Metadata**: Extracted information from the video URL via LoadifyEngine including title, description, thumbnail URL, creator name, platform identifier, duration, and published date.
- **URL Validation Result**: Outcome of URL format and platform validation including validity status, error messages, and supported platform detection.
- **Add Video Event**: Telemetry construct capturing modal interactions (open, submit, cancel, error) with anonymized success metrics while excluding URL content for privacy.

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
- [x] Scope is clearly bounded
- [ ] Dependencies and assumptions identified

### Constitution Alignment
- [x] SwiftUI Experience Integrity: Accessibility, design-system expectations, and modal interaction patterns are described.
- [x] Calm State & Offline Resilience: Offline flows, queued submissions, and error recovery are documented.
- [x] Observability With Privacy Guarantees: Analytics events defined with privacy constraints (no URL content logged).
- [x] Test-First Delivery: Acceptance scenarios and edge cases provide test coverage strategy.
- [ ] Release Confidence & Support: Rollout strategy and support handoffs need clarification.

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
