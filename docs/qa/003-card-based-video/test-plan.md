# QA Test Plan: Card-Based Video List (003)

**Feature**: My Videos - Card-Based List  
**Branch**: `003-card-based-video`  
**Test Date**: TBD  
**Tester**: _____________  
**Build**: _____________

## Test Environment Setup

### Prerequisites
- [ ] iOS device or simulator running iOS 18.0+
- [ ] Xcode 16 with Swift 6 toolchain
- [ ] Supabase project configured with test credentials
- [ ] Test account with at least 5 saved videos
- [ ] Network Link Conditioner or simulator network toggle

### Configuration
- [ ] `SupabaseConfig.plist` contains valid credentials
- [ ] `video_cards_view` migration applied
- [ ] Test data populated in `public.videos` table
- [ ] User authenticated with valid session

## Test Scenarios

### 1. Initial Load (Happy Path)

**Steps**:
1. Launch app (fresh install or logged out state)
2. Sign in with test credentials
3. Observe navigation to "My Videos" screen
4. Wait for cards to load

**Expected Results**:
- [ ] Loading indicator appears immediately
- [ ] Cards load within 4 seconds on Wi-Fi
- [ ] Each card displays: thumbnail, title, creator, platform, duration
- [ ] Cards ordered by most recent first (updated_at desc)
- [ ] FAB (Add Video button) visible in bottom-right corner
- [ ] Analytics event `video_list.viewed` logged in console

**Acceptance**: ✅ PASS / ❌ FAIL  
**Notes**: ___________________________________

---

### 2. Empty State

**Steps**:
1. Sign in with account that has no saved videos
2. Navigate to "My Videos" screen

**Expected Results**:
- [ ] Empty state icon (video.slash) displayed
- [ ] Message: "No videos yet. Add your first video to get started."
- [ ] FAB still visible and accessible
- [ ] No loading spinner after initial load
- [ ] No error state shown

**Acceptance**: ✅ PASS / ❌ FAIL  
**Notes**: ___________________________________

---

### 3. Offline - First Launch (No Cache)

**Steps**:
1. Disable network (airplane mode or Link Conditioner)
2. Launch app and sign in (use cached credentials)
3. Navigate to "My Videos" screen

**Expected Results**:
- [ ] Error state displayed with exclamation triangle icon
- [ ] Message: "Couldn't load videos. Check your connection and try again."
- [ ] "Try Again" button visible
- [ ] Tapping retry shows loading state (but fails again)
- [ ] No crash or freeze

**Acceptance**: ✅ PASS / ❌ FAIL  
**Notes**: ___________________________________

---

### 4. Offline - With Cached Cards

**Steps**:
1. Load videos while online (establish cache)
2. Disable network
3. Force-quit and relaunch app
4. Navigate to "My Videos" screen

**Expected Results**:
- [ ] Cached cards displayed immediately
- [ ] Orange offline banner at top: "Showing cached videos. Connect to see updates."
- [ ] Cards remain scrollable and readable
- [ ] FAB still accessible
- [ ] No error state shown

**Acceptance**: ✅ PASS / ❌ FAIL  
**Notes**: ___________________________________

---

### 5. Network Reconnection

**Steps**:
1. Start offline with cached cards displayed
2. Enable network (disable airplane mode)
3. Observe reconnection behavior

**Expected Results**:
- [ ] Green toast appears at top: "Back online"
- [ ] Toast auto-dismisses after ~3 seconds
- [ ] Offline banner disappears
- [ ] Cards refresh with latest data
- [ ] Reconnect log message appears in console (INFO level)

**Acceptance**: ✅ PASS / ❌ FAIL  
**Notes**: ___________________________________

---

### 6. Real-time Updates (Subscription)

**Steps**:
1. Load "My Videos" screen on device A
2. From device B or web, add/update/delete a video
3. Observe device A screen

**Expected Results**:
- [ ] New video appears in list automatically (within 5 seconds)
- [ ] Updated video reflects new metadata
- [ ] Deleted video removed from list
- [ ] No full-screen refresh required
- [ ] UI remains responsive during updates

**Acceptance**: ✅ PASS / ❌ FAIL  
**Notes**: ___________________________________

---

### 7. Dynamic Type Support

**Steps**:
1. Open iOS Settings → Accessibility → Display & Text Size
2. Set text size to smallest (XS)
3. Return to "My Videos" screen
4. Set text size to largest (XXXL)
5. Return to "My Videos" screen again

**Expected Results**:
- [ ] All text scales appropriately at XS size
- [ ] All text scales appropriately at XXXL size
- [ ] No text truncation at large sizes
- [ ] Card layouts remain readable
- [ ] Touch targets maintain 44pt minimum
- [ ] No layout breakage or overlapping elements

**Acceptance**: ✅ PASS / ❌ FAIL  
**Notes**: ___________________________________

---

### 8. VoiceOver Navigation

**Steps**:
1. Enable VoiceOver (Settings → Accessibility → VoiceOver)
2. Navigate to "My Videos" screen
3. Swipe through elements with VoiceOver rotor

**Expected Results**:
- [ ] Screen title "My Videos" announced
- [ ] Each card has combined label: "{title}, {creator}, {duration}"
- [ ] FAB announced as "Add Video"
- [ ] Loading state announces "Loading your videos..."
- [ ] Error/offline states announce correctly
- [ ] All interactive elements reachable via swipe
- [ ] No unlabeled buttons or images

**Acceptance**: ✅ PASS / ❌ FAIL  
**Notes**: ___________________________________

---

### 9. Cache Persistence

**Steps**:
1. Load videos while online
2. Force-quit app completely
3. Wait 5 minutes
4. Relaunch app (still online)
5. Navigate to "My Videos" screen

**Expected Results**:
- [ ] Cards load from network (not just cache)
- [ ] Fresh data displayed
- [ ] Cache updated with latest
- [ ] No stale data shown

**Acceptance**: ✅ PASS / ❌ FAIL  
**Notes**: ___________________________________

---

### 10. Thumbnail Handling

**Steps**:
1. Add videos with valid HTTPS thumbnails
2. Add videos with missing/null thumbnails
3. Add videos with HTTP (non-secure) thumbnails
4. Observe "My Videos" list

**Expected Results**:
- [ ] Valid HTTPS thumbnails load and display correctly
- [ ] Missing thumbnails show placeholder image
- [ ] HTTP thumbnails fall back to placeholder
- [ ] No broken image icons or crashes
- [ ] Aspect ratio maintained (16:9) for all cards

**Acceptance**: ✅ PASS / ❌ FAIL  
**Notes**: ___________________________________

---

### 11. Duration Formatting

**Steps**:
1. Add videos with various durations:
   - 30 seconds (0:30)
   - 5 minutes 15 seconds (5:15)
   - 1 hour 23 minutes 45 seconds (83:45)
2. Observe duration pills on cards

**Expected Results**:
- [ ] Short durations show as M:SS (e.g., 0:30)
- [ ] Medium durations show as M:SS (e.g., 5:15)
- [ ] Long durations show as MMM:SS (e.g., 83:45)
- [ ] No `--:--` or invalid formats
- [ ] Duration pill readable on all thumbnail backgrounds

**Acceptance**: ✅ PASS / ❌ FAIL  
**Notes**: ___________________________________

---

### 12. Analytics Privacy

**Steps**:
1. Enable verbose logging in Xcode console
2. Navigate to "My Videos" screen
3. Review all logged events

**Expected Results**:
- [ ] Single `video_list.viewed` event logged
- [ ] No user IDs, emails, or PII in logs
- [ ] No video titles or metadata in analytics
- [ ] Reconnect events show INFO severity (no user data)
- [ ] Log messages human-readable for debugging

**Acceptance**: ✅ PASS / ❌ FAIL  
**Notes**: ___________________________________

---

### 13. Memory & Performance

**Steps**:
1. Load "My Videos" with 100+ cached cards
2. Scroll through entire list rapidly
3. Monitor Xcode memory debugger
4. Return to top and scroll again

**Expected Results**:
- [ ] Smooth scrolling (60fps on device)
- [ ] No memory leaks detected
- [ ] Memory usage stable (no continuous growth)
- [ ] Thumbnail images recycled properly
- [ ] No ANR (Application Not Responding) warnings

**Acceptance**: ✅ PASS / ❌ FAIL  
**Notes**: ___________________________________

---

### 14. Error Recovery

**Steps**:
1. Start with working "My Videos" screen
2. Invalidate auth session (sign out from another device)
3. Trigger a refresh or subscription event
4. Observe behavior

**Expected Results**:
- [ ] Graceful error handling (no crash)
- [ ] User redirected to auth screen if session invalid
- [ ] Cached cards preserved for next login
- [ ] Clear error message if shown
- [ ] No data loss

**Acceptance**: ✅ PASS / ❌ FAIL  
**Notes**: ___________________________________

---

### 15. Localization Strings

**Steps**:
1. Review all screens/states in "My Videos" feature
2. Verify no hardcoded English strings in UI

**Expected Results**:
- [ ] "My Videos" title uses localized string
- [ ] "Loading your videos..." uses localized string
- [ ] "No videos yet..." uses localized string
- [ ] "Couldn't load videos..." uses localized string
- [ ] "Back online" toast uses localized string
- [ ] "Add Video" button uses localized string
- [ ] All strings found in `Localizable.strings`

**Acceptance**: ✅ PASS / ❌ FAIL  
**Notes**: ___________________________________

---

## Regression Tests

### Existing Features (Ensure No Breakage)

- [ ] Welcome screen still displays correctly
- [ ] Auth flow (login/signup) works as before
- [ ] SavedLinks feature remains functional (if coexisting)
- [ ] Sign out returns to welcome screen
- [ ] No new crashes in other modules

---

## QA Sign-Off

### Test Summary

| Category | Pass | Fail | Blocked | Notes |
|----------|------|------|---------|-------|
| Happy Path | [ ] | [ ] | [ ] | |
| Error Handling | [ ] | [ ] | [ ] | |
| Offline Support | [ ] | [ ] | [ ] | |
| Accessibility | [ ] | [ ] | [ ] | |
| Performance | [ ] | [ ] | [ ] | |
| Privacy/Analytics | [ ] | [ ] | [ ] | |
| Regression | [ ] | [ ] | [ ] | |

### Overall Assessment

**Status**: ⬜ APPROVED FOR RELEASE / ⬜ BLOCKED - FIXES REQUIRED

**Critical Issues**: _________________________________

**Non-Critical Issues**: _________________________________

**Recommendations**: _________________________________

### Sign-Off

**QA Tester**: _________________ **Date**: _________

**Engineering Lead**: _________________ **Date**: _________

**Product Owner**: _________________ **Date**: _________

---

## Screenshots

Screenshots should be captured and stored in `docs/qa/003-card-based-video/screenshots/`:

- `01-loading-state.png` - Initial loading spinner
- `02-loaded-cards.png` - Cards displayed successfully
- `03-empty-state.png` - No videos message
- `04-error-state.png` - Connection error with retry
- `05-offline-banner.png` - Offline mode with cached cards
- `06-reconnect-toast.png` - Back online notification
- `07-dynamic-type-xl.png` - Large text size view
- `08-voiceover-labels.png` - VoiceOver inspector showing labels
- `09-placeholder-thumbnail.png` - Card with fallback image
- `10-duration-formats.png` - Various duration pill examples

**Screenshots captured**: [ ] YES / [ ] NO  
**Stored in correct directory**: [ ] YES / [ ] NO
