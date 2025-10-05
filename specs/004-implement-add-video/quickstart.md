# Quickstart: Add Video via URL Modal

**Feature**: 004-implement-add-video  
**Date**: 2025-10-04  
**Purpose**: Manual testing and validation guide for the Add Video modal feature

---

## Prerequisites

- Xcode 16+ with Swift 6 toolchain
- iOS 18+ Simulator or device
- Chill app installed and authenticated
- LoadifyEngine.xcframework integrated
- Active internet connection (for online tests)
- Test video URLs from Facebook, YouTube, Twitter

---

## Quick Validation (5 minutes)

### 1. Modal Presentation
```
1. Launch Chill app and authenticate
2. Navigate to "My Videos" list
3. Tap the blue '+' floating action button (bottom-right)

✓ Modal slides up smoothly
✓ URL input field is focused
✓ Keyboard appears automatically
✓ Placeholder text: "Enter video URL"
✓ "Cancel" and "Add Video" buttons visible
✓ "Add Video" button is disabled (empty input)
```

### 2. Real-Time Validation
```
1. Type partial URL: "youtube"
   ✓ No validation icon (too short)
   ✓ "Add Video" button remains disabled

2. Complete valid YouTube URL: "https://youtube.com/watch?v=dQw4w9WgXcQ"
   ✓ Green checkmark appears (after 300ms)
   ✓ "Add Video" button enabled

3. Change to invalid URL: "not-a-video-url"
   ✓ Orange warning icon appears
   ✓ Error message: "Please enter a valid video URL"
   ✓ "Add Video" button disabled

4. Enter unsupported platform: "https://vimeo.com/12345"
   ✓ Orange warning icon appears
   ✓ Error message: "Only Facebook, YouTube, and Twitter videos are supported"
```

### 3. Successful Submission
```
1. Enter valid YouTube URL: "https://www.youtube.com/watch?v=jNQXAC9IVRw"
2. Tap "Add Video"

✓ Loading overlay appears with spinner
✓ Status: "Adding video..."
✓ After 3s: "Fetching video details..."
✓ Modal dismisses on success
✓ New video card appears in "My Videos" list
✓ Card shows thumbnail, title, creator, duration
```

---

## Comprehensive Test Suite (30 minutes)

### Test 1: Modal Lifecycle

**Objective**: Verify modal presentation, focus, and dismissal

```
Steps:
1. Tap '+' FAB from VideoListView
2. Observe modal animation and focus
3. Tap backdrop outside modal
4. Observe modal dismissal

Expected:
- Modal slides up in 0.3s
- Input field focused, keyboard visible
- Backdrop tap dismisses modal
- Input text discarded on dismissal

Pass Criteria:
□ Modal animation smooth (60fps)
□ Auto-focus works
□ Backdrop dismissal works
□ No crash on dismissal
```

### Test 2: Platform-Specific URL Validation

**Objective**: Validate URL patterns for Facebook, YouTube, Twitter

```
Test URLs:

YouTube:
✓ https://youtube.com/watch?v=dQw4w9WgXcQ (standard)
✓ https://youtu.be/dQw4w9WgXcQ (short)
✓ https://m.youtube.com/watch?v=dQw4w9WgXcQ (mobile)
✓ https://www.youtube.com/embed/dQw4w9WgXcQ (embed)

Facebook:
✓ https://facebook.com/username/videos/123456789 (standard)
✓ https://facebook.com/watch/?v=123456789 (watch)
✓ https://fb.watch/abc123 (short)
✓ https://m.facebook.com/watch/?v=123456789 (mobile)

Twitter:
✓ https://twitter.com/username/status/1234567890 (standard)
✓ https://x.com/username/status/1234567890 (x.com)
✓ https://mobile.twitter.com/username/status/1234567890 (mobile)

Invalid:
✗ https://vimeo.com/12345 (unsupported)
✗ https://tiktok.com/@user/video/123 (unsupported)
✗ just-text-not-url (invalid format)

Pass Criteria:
□ All platform variants validated correctly
□ Unsupported platforms rejected with clear message
□ Invalid formats rejected
```

### Test 3: Duplicate Detection

**Objective**: Warn user about duplicate URLs while allowing submission

```
Setup:
1. Add a video with URL: "https://youtube.com/watch?v=testVideo123"
2. Return to VideoListView

Steps:
1. Tap '+' FAB
2. Enter same URL: "https://youtube.com/watch?v=testVideo123"
3. Observe warning message
4. Enter normalized variant: "https://youtu.be/testVideo123"
5. Observe same warning
6. Tap "Add Video" (should still be enabled)

Expected:
- Warning icon (⚠️) appears instead of checkmark
- Message: "⚠️ Already in your library"
- "Add Video" button remains enabled
- Submission proceeds if user continues

Pass Criteria:
□ Duplicate detected for exact URL
□ Duplicate detected for normalized variants (youtu.be, m.youtube, etc.)
□ Warning message clear and non-blocking
□ Button stays enabled (per spec)
```

### Test 4: LoadifyEngine Metadata Extraction

**Objective**: Verify metadata fetched correctly from LoadifyEngine

```
Steps:
1. Enter valid YouTube URL (known public video)
2. Tap "Add Video"
3. Wait for loading to complete
4. Navigate to video card in list
5. Inspect metadata

Expected Metadata:
- Title: Actual video title from YouTube
- Thumbnail: Valid image URL
- Creator: Channel name
- Duration: Correct length (if available)
- Platform: "youtube"

Pass Criteria:
□ Title extracted correctly
□ Thumbnail loads and displays
□ Creator name populated (or "Unknown creator" if missing)
□ Duration shown (if available)
□ No crashes during extraction
```

### Test 5: Error Handling

**Objective**: Test all error scenarios

#### 5a. Network Timeout
```
Setup: Enable Network Link Conditioner (100% packet loss)

Steps:
1. Enter valid URL
2. Tap "Add Video"
3. Wait 10 seconds

Expected:
- Loading indicator shows for 10s
- Error message: "Request timed out. Please try again."
- Input field and buttons re-enabled
- Modal stays open for retry

Pass Criteria:
□ Timeout occurs at 10s
□ Error message clear
□ Retry possible
```

#### 5b. Metadata Extraction Failure
```
Setup: Use URL that LoadifyEngine cannot parse (private/deleted video)

Steps:
1. Enter URL to private/deleted video
2. Tap "Add Video"
3. Observe error

Expected:
- Error message: "Unable to fetch video details. Please check the URL."
- Modal stays open
- Can retry with different URL

Pass Criteria:
□ Extraction failure handled gracefully
□ Error message helpful
□ No crash
```

#### 5c. Offline Submission
```
Setup: Disable device network (Airplane Mode)

Steps:
1. Enter valid URL
2. Tap "Add Video"
3. Observe offline behavior
4. Re-enable network after 30 seconds
5. Observe automatic retry

Expected:
- Info message: "No internet connection. Video will be added when you're back online."
- Modal dismisses
- Submission queued (visible in list with pending indicator)
- Auto-retry on reconnect
- Video added successfully after retry

Pass Criteria:
□ Offline detection works
□ Submission queued to SwiftData
□ Auto-retry on reconnect
□ Success after retry
```

### Test 6: Accessibility

**Objective**: Verify VoiceOver, Dynamic Type, Reduced Motion support

#### 6a. VoiceOver
```
Setup: Enable VoiceOver (Settings > Accessibility > VoiceOver)

Steps:
1. Navigate to '+' FAB with VoiceOver
2. Double-tap to activate
3. Verify modal announcement
4. Navigate through input field and buttons
5. Enter URL with on-screen keyboard
6. Verify validation announcements

Expected Announcements:
- FAB: "Add video, button"
- Modal: "Add video from URL"
- Input: "Video URL, text field, enter Facebook, YouTube, or Twitter video link"
- Valid: "Valid URL"
- Invalid: "Please enter a valid video URL"
- Submit button (disabled): "Add Video, button, dimmed"
- Submit button (enabled): "Add Video, button"

Pass Criteria:
□ All elements have descriptive labels
□ Focus order logical
□ State changes announced
□ Keyboard navigation works
```

#### 6b. Dynamic Type
```
Setup: Settings > Accessibility > Display & Text Size > Larger Text (XL)

Steps:
1. Open modal
2. Observe text scaling
3. Verify button sizes
4. Test functionality with large text

Expected:
- All text scales proportionally
- Modal height adjusts if needed
- Buttons maintain 44x44pt minimum
- No text truncation
- Fully functional

Pass Criteria:
□ Text scales correctly
□ Layout adapts
□ Buttons remain tappable
□ No overlapping elements
```

#### 6c. Reduced Motion
```
Setup: Settings > Accessibility > Motion > Reduce Motion (ON)

Steps:
1. Tap '+' FAB
2. Observe modal presentation
3. Submit video
4. Observe dismissal

Expected:
- Modal fades in (no slide animation)
- Backdrop opacity changes instantly
- Loading spinner pulses (no rotation)
- Dismissal fades out

Pass Criteria:
□ No sliding animations
□ Fade transitions only
□ Functionality intact
```

### Test 7: Edge Cases

#### 7a. Long URLs
```
Steps:
1. Paste extremely long URL (2000+ characters)
2. Observe input field behavior

Expected:
- Field accepts full URL
- Display truncates with ellipsis
- Validation still works
- Submission handles full URL

Pass Criteria:
□ No crash with long URLs
□ Validation works
□ Submission succeeds
```

#### 7b. Special Characters
```
Test URLs with:
- Unicode characters: https://youtube.com/watch?v=تجربة
- Emoji: https://youtube.com/watch?v=😀test
- Encoded parameters: https://youtube.com/watch?v=abc&t=1m30s

Expected:
- URLs handled correctly
- Validation passes
- LoadifyEngine processes successfully

Pass Criteria:
□ Special characters don't break validation
□ Submission succeeds
```

#### 7c. Rapid Submission
```
Steps:
1. Enter valid URL
2. Tap "Add Video" rapidly multiple times

Expected:
- Only one submission created
- Button disabled during processing
- No duplicate submissions

Pass Criteria:
□ Duplicate submission prevented
□ No crashes
```

#### 7d. App Backgrounding During Submission
```
Steps:
1. Enter valid URL
2. Tap "Add Video"
3. Immediately background app (swipe up)
4. Wait 5 seconds
5. Return to app

Expected:
- Submission continues in background
- Completes successfully
- Video appears in list on return

Pass Criteria:
□ Background processing works
□ State preserved
□ Success on return
```

---

## Smoke Test Script (2 minutes)

**Quick validation before releasing to QA**:

```bash
# 1. Modal opens
Tap '+' FAB → Modal appears ✓

# 2. Validation works
Type "youtube.com/watch?v=test" → Checkmark ✓

# 3. Submission works
Tap "Add Video" → Loading → Success → Video added ✓

# 4. Cancel works
Tap '+' FAB → Type URL → Tap "Cancel" → Modal closes ✓

# 5. Error handling works
Enter invalid URL → Error message shown ✓

All checks pass? → Feature ready for QA
```

---

## Performance Validation

**Metrics to verify**:

| Metric | Target | How to Measure |
|--------|--------|----------------|
| Modal animation | 60fps | Use Xcode Instruments > Core Animation |
| URL validation | <100ms | Add logging to URLValidator |
| Duplicate check | <200ms | Add logging to duplicate detection |
| LoadifyEngine fetch | <3s typical | Observe loading message timing |
| Modal dismissal | 0.3s | Visual observation |

**Tools**:
- Xcode Instruments (Time Profiler, Core Animation)
- Console logs for timing
- Manual stopwatch for user-facing delays

---

## Rollback Procedure

**If critical issues found**:

1. Remove FAB tap handler in VideoListView:
```swift
// Comment out FAB action
// .onTapGesture { showAddVideoModal = true }
```

2. Hide '+' FAB button:
```swift
// In VideoListView
// .overlay(alignment: .bottomTrailing) {
//     Button(action: { showAddVideoModal = true }) {
//         Image(systemName: "plus")
//     }
// }
```

3. Rebuild and redeploy

4. Existing video library unaffected

---

## Known Limitations (MVP)

- Single URL submission only (no batch)
- No URL preview before submission
- No edit metadata before saving
- No submission history view
- Three retry limit for failed submissions

**Future enhancements tracked separately**

---

## Troubleshooting

### Issue: Modal doesn't appear
**Check**: FAB button visible and enabled?  
**Fix**: Ensure VideoListView is active, user authenticated

### Issue: Validation always fails
**Check**: Regex patterns correct?  
**Fix**: Verify URLValidator platform patterns

### Issue: LoadifyEngine fails
**Check**: xcframework properly linked?  
**Fix**: Verify LoadifyEngine.xcframework in project, check imports

### Issue: Offline queue not retrying
**Check**: Connectivity monitoring enabled?  
**Fix**: Verify ConnectivityMonitor started in app initialization

---

**Status**: Quickstart complete, ready for manual testing
