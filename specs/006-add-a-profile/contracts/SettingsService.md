# Contract: Settings Service

**Feature**: `006-add-a-profile`  
**Version**: 1.0  
**Date**: 2025-10-07

## Purpose

This contract defines the behavior of the SettingsService responsible for loading and persisting user video preferences. Settings are stored in Supabase user metadata and use last-write-wins conflict resolution.

---

## Settings Service Contract

### Service Definition

```swift
protocol SettingsServiceType {
    func loadVideoPreferences() async throws -> VideoPreferences
    func updateVideoPreferences(_ preferences: VideoPreferences) async throws
    var preferencesPublisher: AnyPublisher<VideoPreferences, Never> { get }
}
```

---

### loadVideoPreferences Method

**Contract**: System MUST load video preferences from user metadata

**Output**:
- `VideoPreferences` struct with current settings
- Returns default preferences if none set
- Throws `ProfileError` on failure

**Behavior**:
1. Fetch current user metadata from Supabase
2. Parse `video_preferences` JSON field
3. If missing or invalid, return default preferences
4. Return VideoPreferences struct

**Error Conditions**:
- Network unavailable → throws `.networkUnavailable`
- Session expired → throws `.unauthorized`
- Parse error → return defaults (don't throw)

**Contract Tests**:
```swift
func testLoadVideoPreferencesReturnsStoredValues() async throws {
    // Given: User has saved preferences
    mockAuth.userMetadata = [
        "video_preferences": [
            "quality": "high",
            "autoplay": false
        ]
    ]
    
    // When: Loading preferences
    let prefs = try await service.loadVideoPreferences()
    
    // Then: Correct values returned
    XCTAssertEqual(prefs.quality, .high)
    XCTAssertEqual(prefs.autoplay, false)
}

func testLoadVideoPreferencesReturnsDefaultsWhenNotSet() async throws {
    // Given: No preferences in metadata
    mockAuth.userMetadata = [:]
    
    // When: Loading preferences
    let prefs = try await service.loadVideoPreferences()
    
    // Then: Default values returned
    XCTAssertEqual(prefs.quality, .auto)
    XCTAssertEqual(prefs.autoplay, true)
}

func testLoadVideoPreferencesReturnsDefaultsOnParseError() async throws {
    // Given: Invalid JSON in metadata
    mockAuth.userMetadata = ["video_preferences": "invalid"]
    
    // When: Loading preferences
    let prefs = try await service.loadVideoPreferences()
    
    // Then: Defaults returned, no error thrown
    XCTAssertEqual(prefs, VideoPreferences.default)
}

func testLoadVideoPreferencesThrowsOnNetworkError() async {
    // Given: Network unavailable
    mockAuth.networkError = URLError(.notConnectedToInternet)
    
    // When/Then: Loading throws
    await assertThrowsError(
        try await service.loadVideoPreferences()
    ) { error in
        XCTAssertEqual(error as? ProfileError, .networkUnavailable)
    }
}
```

---

### updateVideoPreferences Method

**Contract**: System MUST persist video preferences to user metadata

**Input**:
- `preferences: VideoPreferences` - New settings to save

**Behavior**:
1. Validate preferences (quality is valid enum value)
2. Serialize to JSON
3. Update Supabase user_metadata via auth.updateUser()
4. Publish change to preferencesPublisher
5. Return on success, throw on failure

**Error Conditions**:
- Network unavailable → throws `.networkUnavailable`
- Session expired → throws `.unauthorized`
- Update fails → throws `.updateFailed`

**Last-Write-Wins**:
- No conflict detection
- Most recent update wins
- No merge logic needed

**Contract Tests**:
```swift
func testUpdateVideoPreferencesPersistsChanges() async throws {
    // Given: New preferences
    let newPrefs = VideoPreferences(quality: .medium, autoplay: false)
    
    // When: Updating preferences
    try await service.updateVideoPreferences(newPrefs)
    
    // Then: Supabase metadata updated
    let saved = mockAuth.userMetadata["video_preferences"] as! [String: Any]
    XCTAssertEqual(saved["quality"] as? String, "medium")
    XCTAssertEqual(saved["autoplay"] as? Bool, false)
}

func testUpdateVideoPreferencesPublishesChange() async throws {
    // Given: Subscriber listening
    var publishedPrefs: VideoPreferences?
    let cancellable = service.preferencesPublisher.sink { prefs in
        publishedPrefs = prefs
    }
    
    let newPrefs = VideoPreferences(quality: .low, autoplay: true)
    
    // When: Updating preferences
    try await service.updateVideoPreferences(newPrefs)
    
    // Then: Change published
    XCTAssertEqual(publishedPrefs, newPrefs)
    cancellable.cancel()
}

func testUpdateVideoPreferencesThrowsOnFailure() async {
    // Given: Update will fail
    mockAuth.updateError = AuthClientError(
        status: 500,
        code: "server_error",
        message: "Failed"
    )
    
    // When/Then: Update throws
    await assertThrowsError(
        try await service.updateVideoPreferences(.default)
    ) { error in
        XCTAssertEqual(error as? ProfileError, .updateFailed)
    }
}

func testUpdateVideoPreferencesLastWriteWins() async throws {
    // Given: Concurrent updates from two devices
    let device1Prefs = VideoPreferences(quality: .high, autoplay: true)
    let device2Prefs = VideoPreferences(quality: .low, autoplay: false)
    
    // When: Both try to update (device2 finishes last)
    try await service.updateVideoPreferences(device1Prefs)
    try await service.updateVideoPreferences(device2Prefs)
    
    // Then: device2 preferences win
    let final = try await service.loadVideoPreferences()
    XCTAssertEqual(final, device2Prefs)
}
```

---

### preferencesPublisher

**Contract**: System MUST publish settings changes to subscribers

**Behavior**:
- Emits current preferences on subscribe
- Emits new preferences whenever updated
- Never completes (hot stream)

**Contract Tests**:
```swift
func testPreferencesPublisherEmitsCurrentValueOnSubscribe() {
    // Given: Service with existing preferences
    service.currentPreferences = VideoPreferences(quality: .high, autoplay: false)
    
    var received: VideoPreferences?
    let cancellable = service.preferencesPublisher.sink { prefs in
        received = prefs
    }
    
    // Then: Current value emitted immediately
    XCTAssertEqual(received?.quality, .high)
    cancellable.cancel()
}
```

---

## Integration Scenarios

### Scenario 1: First-Time User (No Preferences Set)
```swift
func testFirstTimeUserGetsDefaults() async throws {
    // Given: New user with no metadata
    mockAuth.userMetadata = [:]
    
    // When: Loading preferences
    let prefs = try await service.loadVideoPreferences()
    
    // Then: Defaults returned
    XCTAssertEqual(prefs.quality, .auto)
    XCTAssertEqual(prefs.autoplay, true)
}
```

### Scenario 2: Settings Survive App Restart
```swift
func testSettingsSurviveAppRestart() async throws {
    // Given: User sets preferences
    let customPrefs = VideoPreferences(quality: .medium, autoplay: false)
    try await service.updateVideoPreferences(customPrefs)
    
    // When: App restarts (simulate new service instance)
    let newService = SettingsService(auth: mockAuth)
    let loaded = try await newService.loadVideoPreferences()
    
    // Then: Preferences persisted
    XCTAssertEqual(loaded, customPrefs)
}
```

---

## Summary

**Service Responsibility**: Load and persist video preferences

**Storage**: Supabase user_metadata JSON field

**Conflict Resolution**: Last-write-wins (no conflict detection)

**Test Coverage**:
- 8+ contract tests for load/update operations
- 2+ integration tests for persistence
- Error scenario coverage
- Publisher behavior validation
