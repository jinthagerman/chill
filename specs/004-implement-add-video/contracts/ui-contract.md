# UI Contract: Add Video Modal

**Feature**: 004-implement-add-video  
**Date**: 2025-10-04  
**Contract Type**: UI Interaction  
**Status**: Complete

## Overview

This contract defines the behavior, state transitions, and interaction patterns for the Add Video modal UI component. It serves as the specification for UI tests and implementation validation.

---

## Modal Presentation Contract

### Trigger

**Action**: User taps the floating '+' button in VideoListView

**Preconditions**:
- User is authenticated
- VideoListView is visible and active
- FAB (+) button is enabled and visible

**Postconditions**:
- Modal appears with slide-up animation (0.3s duration)
- Backdrop fades in behind modal (opacity 0.3)
- URL input field receives focus automatically
- Keyboard appears immediately
- Modal is positioned at `.medium` detent (above keyboard)

**Expected Behavior**:
```swift
// Given
let videoListView = VideoListView()
let fabButton = videoListView.fabButton

// When
fabButton.tap()

// Then
XCTAssertTrue(addVideoModal.isPresented)
XCTAssertTrue(urlInputField.isFocused)
XCTAssertTrue(keyboard.isVisible)
XCTAssertEqual(modal.animation.duration, 0.3)
```

---

### Dismissal

**Dismissal Methods**:
1. User taps "Cancel" button
2. User taps backdrop outside modal
3. User swipes down on modal (drag indicator)
4. Successful submission completes

**Postconditions** (all dismissal types):
- Modal slides down with animation (0.3s duration)
- Backdrop fades out
- Keyboard dismisses
- Focus returns to VideoListView
- Modal state resets for next presentation

**State Preservation** (Cancel/Backdrop/Swipe dismissal):
- Input text is discarded (per spec FR-008)
- No submission is created
- No analytics event for partial entry

**State Transition** (Success dismissal):
- Input text is cleared
- Submission is persisted
- VideoListView refreshes to show new video card
- Success analytics event emitted

---

## Input Validation Contract

### Real-Time Validation

**Trigger**: User types or pastes text into URL input field

**Debounce**: 300ms after last keystroke

**Validation Sequence**:
1. Check if input is empty → disable "Add Video" button, no error shown
2. Apply platform regex patterns (Facebook, YouTube, Twitter)
3. Update validation icon:
   - Valid: Green checkmark (✓)
   - Invalid: Orange warning (⚠️)
   - Empty: No icon
4. Display error message below input field (if invalid)

**Validation States**:

| Input State | Button Enabled | Icon | Error Message |
|-------------|----------------|------|---------------|
| Empty | ❌ | None | None |
| Invalid format | ❌ | ⚠️ | "Please enter a valid video URL" |
| Unsupported platform | ❌ | ⚠️ | "Only Facebook, YouTube, and Twitter videos are supported" |
| Valid | ✅ | ✓ | None |
| Valid + Duplicate | ✅ | ⚠️ | "⚠️ Already in your library" |

**Expected Behavior**:
```swift
// Given
let viewModel = AddVideoViewModel()
let inputField = addVideoModal.urlInputField

// When: Empty input
inputField.text = ""

// Then
XCTAssertFalse(addVideoModal.submitButton.isEnabled)
XCTAssertNil(addVideoModal.validationIcon)

// When: Invalid URL
inputField.text = "not-a-url"
wait(for: 0.3) // debounce

// Then
XCTAssertFalse(addVideoModal.submitButton.isEnabled)
XCTAssertEqual(addVideoModal.validationIcon, .warning)
XCTAssertEqual(addVideoModal.errorMessage, "Please enter a valid video URL")

// When: Valid YouTube URL
inputField.text = "https://youtube.com/watch?v=dQw4w9WgXcQ"
wait(for: 0.3) // debounce

// Then
XCTAssertTrue(addVideoModal.submitButton.isEnabled)
XCTAssertEqual(addVideoModal.validationIcon, .checkmark)
XCTAssertNil(addVideoModal.errorMessage)
```

---

### Duplicate Detection

**Trigger**: Valid URL detected, after validation completes

**Check**: Query existing VideoCardEntity for normalized URL match

**Behavior** (Duplicate Found):
- Display warning icon (⚠️) instead of checkmark
- Show warning message: "⚠️ Already in your library"
- Keep "Add Video" button enabled (per spec FR-013)
- Allow user to proceed with submission

**Behavior** (No Duplicate):
- Display checkmark (✓)
- No warning message
- "Add Video" button enabled

**Expected Behavior**:
```swift
// Given
let existingVideo = VideoCardEntity(url: "youtube.com/watch?v=abc123")
modelContext.insert(existingVideo)

// When
inputField.text = "https://youtu.be/abc123" // Same video, different format
wait(for: 0.3)

// Then
XCTAssertTrue(addVideoModal.submitButton.isEnabled) // Still enabled
XCTAssertEqual(addVideoModal.validationIcon, .warning)
XCTAssertEqual(addVideoModal.warningMessage, "⚠️ Already in your library")
```

---

## Submission Contract

### Happy Path (Online, Valid URL)

**Trigger**: User taps "Add Video" button with valid URL

**Preconditions**:
- Input field contains valid URL
- Network connectivity available
- "Add Video" button enabled

**Sequence**:
1. Disable input field and buttons
2. Display loading overlay with spinner
3. Show status message: "Adding video..."
4. Create VideoSubmissionRequest with status=.pending
5. Call LoadifyEngine.extractMetadata(url)
6. After 3 seconds, update status: "Fetching video details..."
7. On success:
   - Update VideoSubmissionRequest with metadata, status=.completed
   - Create VideoCardEntity in library
   - Dismiss modal
   - Show video card in VideoListView
8. On failure:
   - Update status=.failed, capture error
   - Display error message inline
   - Re-enable input field and buttons
   - Keep modal open for retry

**Timeout**: 10 seconds

**Expected Behavior**:
```swift
// Given
inputField.text = "https://youtube.com/watch?v=valid123"
wait(for: 0.3)

// When
submitButton.tap()

// Then (immediately)
XCTAssertFalse(inputField.isEnabled)
XCTAssertFalse(submitButton.isEnabled)
XCTAssertTrue(loadingOverlay.isVisible)
XCTAssertEqual(statusMessage.text, "Adding video...")

// Then (after 3 seconds)
wait(for: 3.0)
XCTAssertEqual(statusMessage.text, "Fetching video details...")

// Then (on success)
wait(for: mockLoadifyEngine.responseDelay)
XCTAssertEqual(submissionRequest.status, .completed)
XCTAssertFalse(modal.isPresented)
XCTAssertTrue(videoList.contains(newVideoCard))
```

---

### Error Paths

#### Network Timeout

**Trigger**: LoadifyEngine takes > 10s or network unreachable

**Behavior**:
- Hide loading overlay
- Display error message: "Request timed out. Please try again."
- Re-enable input field and buttons
- Keep modal open
- Update VideoSubmissionRequest status=.failed

**Expected Behavior**:
```swift
// Given
mockLoadifyEngine.delay = 11.0 // Exceeds 10s timeout

// When
submitButton.tap()
wait(for: 11.0)

// Then
XCTAssertFalse(loadingOverlay.isVisible)
XCTAssertEqual(errorMessage.text, "Request timed out. Please try again.")
XCTAssertTrue(inputField.isEnabled)
XCTAssertTrue(submitButton.isEnabled)
```

---

#### Metadata Extraction Failure

**Trigger**: LoadifyEngine returns error (unsupported platform, parsing failure)

**Behavior**:
- Hide loading overlay
- Display error message: "Unable to fetch video details. Please check the URL."
- Re-enable input field and buttons
- Keep modal open
- Update VideoSubmissionRequest status=.failed

**Expected Behavior**:
```swift
// Given
mockLoadifyEngine.shouldFail = true
mockLoadifyEngine.error = .parsingFailure

// When
submitButton.tap()
wait(for: mockLoadifyEngine.responseDelay)

// Then
XCTAssertEqual(errorMessage.text, "Unable to fetch video details. Please check the URL.")
XCTAssertTrue(submitButton.isEnabled)
```

---

#### Offline Submission

**Trigger**: User taps "Add Video" while offline

**Behavior**:
- Display info message: "No internet connection. Video will be added when you're back online."
- Create VideoSubmissionRequest with status=.pending
- Dismiss modal (submission queued)
- Show pending indicator in VideoListView
- Retry automatically when connectivity restored

**Expected Behavior**:
```swift
// Given
connectivityMonitor.isConnected = false

// When
submitButton.tap()

// Then
XCTAssertEqual(infoMessage.text, "No internet connection. Video will be added when you're back online.")
XCTAssertEqual(submissionRequest.status, .pending)
wait(for: 1.0)
XCTAssertFalse(modal.isPresented)
XCTAssertTrue(videoList.hasPendingSubmission)

// When
connectivityMonitor.isConnected = true
wait(for: 2.0)

// Then
XCTAssertEqual(submissionRequest.status, .completed)
XCTAssertTrue(videoList.contains(newVideoCard))
```

---

## Accessibility Contract

### VoiceOver Support

**Modal Announcement**:
- On presentation: "Add video from URL. Enter video URL input field, Facebook, YouTube, or Twitter video link."
- Focus automatically moves to input field

**Input Field**:
- Label: "Video URL"
- Hint: "Enter a video URL from Facebook, YouTube, or Twitter"
- Value: Current text content
- Traits: Updates keyboard

**Validation Feedback**:
- Valid: Announce "Valid URL"
- Invalid: Announce error message immediately
- Duplicate: Announce "Already in your library"

**Buttons**:
- Cancel: "Cancel, button. Dismiss without saving."
- Add Video (enabled): "Add Video, button. Submit video URL."
- Add Video (disabled): "Add Video, button, dimmed. Enter a valid URL to enable."

**Loading State**:
- Announce: "Adding video, please wait"
- Update: "Fetching video details" (after 3s)

**Expected Behavior**:
```swift
// When modal presents
XCTAssertEqual(voiceOver.announcement, "Add video from URL")
XCTAssertTrue(inputField.hasAccessibilityFocus)

// When validation completes (valid)
inputField.text = "https://youtube.com/watch?v=abc"
wait(for: 0.3)
XCTAssertEqual(voiceOver.announcement, "Valid URL")

// When validation completes (invalid)
inputField.text = "invalid-url"
wait(for: 0.3)
XCTAssertEqual(voiceOver.announcement, "Please enter a valid video URL")
```

---

### Dynamic Type

**Scaling Behavior**:
- All text scales according to user's font size preference
- Modal height adjusts to accommodate larger text
- Minimum modal height maintains visibility above keyboard
- Buttons remain tappable (minimum 44x44pt)

**Expected Behavior**:
```swift
// Given
dynamicType.preferredContentSize = .accessibilityExtraExtraExtraLarge

// When
modal.present()

// Then
XCTAssertGreaterThan(modal.height, modal.minimumHeight)
XCTAssertTrue(submitButton.frame.height >= 44)
XCTAssertTrue(cancelButton.frame.height >= 44)
```

---

### Reduced Motion

**Animation Adjustments**:
- Modal presentation: Fade in/out (no slide animation)
- Loading spinner: Simple opacity pulse (no rotation)
- Validation icon: Instant appearance (no transition)
- Backdrop: Instant opacity change (no fade animation)

**Expected Behavior**:
```swift
// Given
UIAccessibility.isReduceMotionEnabled = true

// When
fabButton.tap()

// Then
XCTAssertEqual(modal.animation, .opacity)
XCTAssertNil(modal.animation.translation)
```

---

## State Machine

```
[Idle]
  ↓ (user taps FAB)
[Presented - Empty Input]
  ↓ (user types)
[Validating] → (debounce 300ms)
  ↓
[Valid] or [Invalid]
  ↓ (user taps "Add Video" from Valid)
[Submitting]
  ↓
[Success] → [Dismissed]
  or
[Error] → [Valid/Invalid] (retry)
  or
[Offline Queued] → [Dismissed]
```

---

## Performance Contract

| Interaction | Target | Maximum |
|-------------|--------|---------|
| Modal presentation animation | 0.3s | 0.5s |
| URL validation (per keystroke) | <50ms | 100ms |
| Duplicate check | <200ms | 500ms |
| LoadifyEngine metadata fetch | <2s typical | 10s timeout |
| Modal dismissal animation | 0.3s | 0.5s |
| Frame rate (animations) | 60fps | 30fps |

---

## Test Scenarios

### Unit Tests
- ✓ Modal presentation triggers on FAB tap
- ✓ Input field receives focus on modal appear
- ✓ Validation debounces correctly (300ms)
- ✓ Submit button disabled when input empty/invalid
- ✓ Duplicate check runs for valid URLs
- ✓ Error messages display for all error types
- ✓ Offline submission queues request
- ✓ Modal dismisses on cancel/success

### Snapshot Tests
- ✓ Modal appearance (empty state)
- ✓ Valid URL with checkmark icon
- ✓ Invalid URL with error message
- ✓ Duplicate warning display
- ✓ Loading state with spinner
- ✓ Error state with retry
- ✓ Accessibility size XL
- ✓ Dark mode appearance

### Integration Tests
- ✓ End-to-end submission (online)
- ✓ End-to-end submission (offline → online)
- ✓ Duplicate detection against existing library
- ✓ LoadifyEngine integration (mocked)
- ✓ VoiceOver navigation flow

---

**Status**: UI contract complete, ready for test generation
