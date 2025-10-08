# Quickstart: Profile Page for Settings and Account Info

**Feature**: `006-add-a-profile`  
**Date**: 2025-10-07  
**Purpose**: Validate the profile page implementation

---

## Prerequisites

1. **Development Environment**:
   - Xcode 16+ with Swift 6
   - iOS 15+ Simulator or device
   - Supabase project configured

2. **Test Data**:
   - Authenticated test account: `test@example.com`
   - Account with saved videos (at least 5)
   - Valid session token

3. **Build & Run**:
   ```bash
   cd /path/to/Chill
   xcodebuild -scheme Chill -destination 'platform=iOS Simulator,name=iPhone 17' build
   # Or: Open Chill.xcodeproj in Xcode and Run (⌘R)
   ```

---

## Test Scenarios

### Scenario 1: Access Profile from Avatar Icon

**Objective**: Verify profile page is accessible from top-right avatar

**Steps**:
1. Launch app and log in
2. Navigate to video list (main screen)
3. Locate avatar icon in top-right corner
4. Tap avatar icon

**Expected**:
- ✅ Avatar icon visible in top-right corner
- ✅ Icon is tappable (clear touch target)
- ✅ Tapping navigates to profile page
- ✅ Smooth transition animation

**Validation**:
```swift
func testProfileAccessibleFromAvatar() {
    app.launch()
    loginTestUser()
    
    XCTAssertTrue(app.images["profile_avatar"].exists)
    app.images["profile_avatar"].tap()
    
    XCTAssertTrue(app.staticTexts["Profile"].exists)
}
```

---

### Scenario 2: View Account Information

**Objective**: Verify all account information displays correctly

**Steps**:
1. On profile page, view Account Information section
2. Check all displayed fields

**Expected**:
- ✅ Email address displayed
- ✅ Display name shown (or email prefix if not set)
- ✅ Account creation date shown (formatted, e.g., "Joined October 2025")
- ✅ Verification status shown ("Verified" or "Unverified")
- ✅ Last login date shown (relative time, e.g., "2 hours ago")
- ✅ Saved videos count shown (e.g., "42 videos saved")

**Validation**:
```swift
func testAccountInformationDisplayed() {
    navigateToProfile()
    
    XCTAssertTrue(app.staticTexts[testEmail].exists)
    XCTAssertTrue(app.staticTexts["Verified"].exists)
    XCTAssertTrue(app.staticTexts.matching(identifier: "account_created").element.exists)
    XCTAssertTrue(app.staticTexts.matching(identifier: "last_login").element.exists)
    XCTAssertTrue(app.staticTexts.matching(identifier: "saved_videos_count").element.exists)
}
```

---

### Scenario 3: Change Video Quality Setting

**Objective**: Verify video quality preference can be changed

**Steps**:
1. On profile page, locate Video Preferences section
2. Find video quality setting (currently "Auto")
3. Tap to change to "High"
4. Observe feedback

**Expected**:
- ✅ Video quality options visible (Auto, High, Medium, Low)
- ✅ Current selection highlighted
- ✅ Tapping option changes selection immediately
- ✅ Brief confirmation message shown ("Setting saved")
- ✅ Change persists (navigate away and return)

**Validation**:
```swift
func testVideoQualitySettingChange() async {
    navigateToProfile()
    
    // Tap video quality setting
    app.buttons["video_quality_setting"].tap()
    
    // Select "High"
    app.buttons["quality_high"].tap()
    
    // Verify change applied
    XCTAssertTrue(app.staticTexts["High"].exists)
    
    // Navigate away and back
    app.buttons["Back"].tap()
    navigateToProfile()
    
    // Verify persisted
    XCTAssertTrue(app.staticTexts["High"].exists)
}
```

---

### Scenario 4: Toggle Autoplay Setting

**Objective**: Verify autoplay can be toggled on/off

**Steps**:
1. On profile page, locate autoplay toggle in Video Preferences
2. Toggle autoplay off
3. Observe feedback

**Expected**:
- ✅ Autoplay toggle visible and labeled clearly
- ✅ Current state shown (On or Off)
- ✅ Tapping toggles state immediately
- ✅ Visual feedback (toggle animates)
- ✅ Change persists across app restarts

**Validation**:
```swift
func testAutoplayToggle() async {
    navigateToProfile()
    
    let toggle = app.switches["autoplay_toggle"]
    XCTAssertTrue(toggle.exists)
    
    let initialState = toggle.value as? String == "1"
    toggle.tap()
    
    // Verify toggled
    let newState = toggle.value as? String == "1"
    XCTAssertNotEqual(initialState, newState)
}
```

---

### Scenario 5: Change Password Successfully

**Objective**: Verify password can be changed with valid credentials

**Steps**:
1. On profile page, navigate to Account Security section
2. Tap "Change Password"
3. Enter current password: `TestPassword123!`
4. Enter new password: `NewPassword123!`
5. Enter confirm password: `NewPassword123!`
6. Tap Submit

**Expected**:
- ✅ Password change modal appears
- ✅ Three password fields visible (current, new, confirm)
- ✅ Submit button disabled until all fields valid
- ✅ Success message shown: "Password updated successfully"
- ✅ Modal dismisses automatically
- ✅ Session remains active (no re-login needed)

**Validation**:
```swift
func testPasswordChangeSuccess() async {
    navigateToProfile()
    app.buttons["change_password"].tap()
    
    app.secureTextFields["current_password"].tap()
    app.secureTextFields["current_password"].typeText("OldPass123!")
    
    app.secureTextFields["new_password"].tap()
    app.secureTextFields["new_password"].typeText("NewPass123!")
    
    app.secureTextFields["confirm_password"].tap()
    app.secureTextFields["confirm_password"].typeText("NewPass123!")
    
    app.buttons["submit_password_change"].tap()
    
    // Verify success
    XCTAssertTrue(app.staticTexts["Password updated successfully"].exists)
    
    // Verify modal dismissed
    XCTAssertFalse(app.secureTextFields["current_password"].exists)
}
```

---

### Scenario 6: Password Change with Wrong Current Password

**Objective**: Verify error handling for incorrect current password

**Steps**:
1. On password change modal, enter wrong current password
2. Enter valid new password
3. Tap Submit

**Expected**:
- ✅ Error message shown: "Current password is incorrect."
- ✅ Modal stays open (doesn't dismiss)
- ✅ Fields remain populated
- ✅ User can correct and retry

**Validation**:
```swift
func testPasswordChangeWrongCurrentPassword() async {
    navigateToPasswordChange()
    
    fillPasswordFields(current: "wrong", new: "New123!", confirm: "New123!")
    app.buttons["submit_password_change"].tap()
    
    // Verify error shown
    XCTAssertTrue(app.staticTexts["Current password is incorrect."].exists)
    
    // Verify modal still open
    XCTAssertTrue(app.secureTextFields["current_password"].exists)
}
```

---

### Scenario 7: Password Change with Mismatched Passwords

**Objective**: Verify client-side validation for password mismatch

**Steps**:
1. On password change modal, enter valid current password
2. Enter new password: `NewPass123!`
3. Enter confirm password: `Different123!` (different)
4. Tap Submit

**Expected**:
- ✅ Error message shown: "Passwords don't match"
- ✅ No API call made (client-side validation)
- ✅ Modal stays open
- ✅ User can correct

**Validation**:
```swift
func testPasswordChangeMismatch() {
    navigateToPasswordChange()
    
    fillPasswordFields(current: "Old123!", new: "New123!", confirm: "Different123!")
    app.buttons["submit_password_change"].tap()
    
    XCTAssertTrue(app.staticTexts["Passwords don't match"].exists)
}
```

---

### Scenario 8: Profile Page Loads Within 3 Seconds

**Objective**: Verify performance requirement (NFR-001)

**Steps**:
1. Clear app cache
2. Log in with test account
3. Measure time from avatar tap to profile fully displayed

**Expected**:
- ✅ Profile page appears within 3 seconds
- ✅ Loading indicator shown during fetch
- ✅ Content progressively loaded (basic info first, stats after)

**Validation**:
```swift
func testProfileLoadPerformance() async {
    let start = Date()
    navigateToProfile()
    
    // Wait for profile to fully load
    XCTAssertTrue(app.staticTexts["saved_videos_count"].waitForExistence(timeout: 3.0))
    
    let elapsed = Date().timeIntervalSince(start)
    XCTAssertLessThan(elapsed, 3.0, "Profile load exceeded 3 second target")
}
```

---

### Scenario 9: Offline Profile Access

**Objective**: Verify offline behavior with cached data

**Steps**:
1. Load profile page while online (populates cache)
2. Navigate away
3. Enable airplane mode
4. Navigate back to profile page

**Expected**:
- ✅ Cached profile data displayed immediately
- ✅ Staleness indicator shown: "Last updated: X minutes ago"
- ✅ Settings changes blocked with message: "You're offline"
- ✅ Retry button available when online again

**Validation**:
```swift
func testOfflineProfileAccess() {
    // Load while online
    navigateToProfile()
    let displayedEmail = app.staticTexts[testEmail].label
    app.buttons["Back"].tap()
    
    // Go offline
    setNetworkStatus(.offline)
    
    // Navigate back
    navigateToProfile()
    
    // Verify cached data shown
    XCTAssertTrue(app.staticTexts[displayedEmail].exists)
    XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'Last updated'")).element.exists)
}
```

---

### Scenario 10: Sign Out from Profile

**Objective**: Verify sign out functionality

**Steps**:
1. On profile page, scroll to bottom
2. Tap "Sign Out" button
3. Confirm action (if confirmation dialog shown)

**Expected**:
- ✅ Sign out button visible and clearly labeled
- ✅ Tapping initiates sign out
- ✅ User redirected to welcome/auth screen
- ✅ Session cleared
- ✅ Next launch requires login

**Validation**:
```swift
func testSignOutFromProfile() async {
    navigateToProfile()
    
    app.buttons["sign_out"].tap()
    
    // Verify redirected to auth
    XCTAssertTrue(app.buttons["Sign In"].waitForExistence(timeout: 2.0))
    
    // Verify session cleared
    // (Would need to verify via AuthService.currentSession in unit test)
}
```

---

### Scenario 11: Accessibility with VoiceOver

**Objective**: Verify screen reader compatibility

**Steps**:
1. Enable VoiceOver (Settings → Accessibility → VoiceOver)
2. Navigate to profile page
3. Swipe through all elements

**Expected**:
- ✅ Avatar icon announced: "Profile, button"
- ✅ Email field announced: "Email: test@example.com"
- ✅ Each setting announced with current value
- ✅ Video quality announced: "Video quality, Auto, button"
- ✅ Autoplay toggle announced: "Autoplay, On, switch"
- ✅ Sign out button announced: "Sign Out, button"

**Validation** (Manual):
- All interactive elements have accessibility labels
- All values read correctly by VoiceOver
- Logical reading order top to bottom

---

### Scenario 12: Settings Persist Across App Restart

**Objective**: Verify settings survive app termination

**Steps**:
1. On profile page, change video quality to "High"
2. Toggle autoplay to Off
3. Force quit app (swipe up from app switcher)
4. Relaunch app
5. Navigate to profile page

**Expected**:
- ✅ Video quality still shows "High"
- ✅ Autoplay still shows "Off"
- ✅ No reset to defaults

**Validation**:
```swift
func testSettingsPersistAcrossRestart() async {
    // Set preferences
    navigateToProfile()
    setVideoQuality(.high)
    setAutoplay(false)
    
    // Terminate and relaunch
    app.terminate()
    app.launch()
    loginTestUser()
    navigateToProfile()
    
    // Verify persisted
    XCTAssertTrue(app.staticTexts["High"].exists)
    XCTAssertEqual(app.switches["autoplay_toggle"].value as? String, "0")
}
```

---

## Success Criteria

### Functional Requirements Met

- ✅ FR-001-003: Profile access requires authentication
- ✅ FR-004-009: All account information displayed
- ✅ FR-010-018: Settings management working (video prefs + password change)
- ✅ FR-019-022: Account actions (password change, sign out)
- ✅ FR-023-026: Error handling and navigation
- ✅ FR-027-029: Navigation and layout

### Non-Functional Requirements

- ⚡ Profile loads within 3 seconds (NFR-001)
- ♿ VoiceOver fully functional (NFR-002)
- 🔒 No sensitive data exposed (NFR-003)

---

## Rollback Plan

If critical issues are discovered:

1. **Immediate**: Revert to previous branch
   ```bash
   git checkout main
   git revert <commit-hash>
   ```

2. **Identify**: Check which scenario failed
3. **Fix**: Address specific issue in feature branch
4. **Re-test**: Run full quickstart again
5. **Re-deploy**: Merge when all scenarios pass

---

## Acceptance

**Sign-off Required**:
- [ ] All 12 scenarios executed and passed
- [ ] No regressions in existing features
- [ ] Analytics events firing correctly
- [ ] Performance meets 3-second target
- [ ] Accessibility verified with VoiceOver
- [ ] Settings persist across devices

**Approved by**: _________________  
**Date**: _________________

---

## Next Steps

After acceptance:
1. Run `/tasks` to generate implementation task list
2. Begin TDD implementation following tasks.md
3. Execute contract tests first (should fail initially)
4. Implement features to make tests pass
5. Return to this quickstart for final validation
