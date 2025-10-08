# Contract: Profile Service

**Feature**: `006-add-a-profile`  
**Version**: 1.0  
**Date**: 2025-10-07

## Purpose

This contract defines the behavior of the ProfileService responsible for loading user profile data and aggregating information from multiple sources (auth session, user metadata, video statistics).

---

## Profile Service Contract

### Service Definition

```swift
protocol ProfileServiceType {
    func loadProfile(for userID: UUID) async throws -> UserProfile
    func refreshStats(for userID: UUID) async throws -> (savedVideosCount: Int)
}
```

### loadProfile Method

**Contract**: System MUST aggregate user data from multiple sources

**Input**:
- `userID: UUID` - The authenticated user's ID

**Output**:
- `UserProfile` struct containing all display fields
- Throws `ProfileError` on failure

**Behavior**:
1. Fetch user metadata from Supabase auth
2. Query saved videos count from videos table
3. Derive display name from metadata or email
4. Aggregate into UserProfile struct
5. Return complete profile

**Error Conditions**:
- Network unavailable → throws `.networkUnavailable`
- User not found → throws `.loadFailed`
- Session expired → throws `.unauthorized`
- Stats query fails → use 0 as default, don't throw

**Contract Tests**:
```swift
func testLoadProfileAggregatesAllSources() async throws {
    // Given: Valid user session with metadata
    let userID = UUID()
    mockAuth.currentSession = AuthClientSession(...)
    mockAuth.userMetadata = ["display_name": "John"]
    mockDatabase.savedVideosCount = 42
    
    // When: Loading profile
    let profile = try await service.loadProfile(for: userID)
    
    // Then: All fields populated
    XCTAssertEqual(profile.displayName, "John")
    XCTAssertEqual(profile.savedVideosCount, 42)
    XCTAssertNotNil(profile.email)
}

func testLoadProfileDefaultsDisplayName() async throws {
    // Given: No display_name in metadata
    mockAuth.userMetadata = [:]
    mockAuth.email = "test@example.com"
    
    // When: Loading profile
    let profile = try await service.loadProfile(for: userID)
    
    // Then: Display name derived from email
    XCTAssertEqual(profile.displayName, "test")
}

func testLoadProfileHandlesStatsQueryFailure() async throws {
    // Given: Stats query fails
    mockDatabase.statsQueryError = DatabaseError.timeout
    
    // When: Loading profile
    let profile = try await service.loadProfile(for: userID)
    
    // Then: Profile loads with 0 count, doesn't throw
    XCTAssertEqual(profile.savedVideosCount, 0)
}

func testLoadProfileThrowsOnNetworkError() async {
    // Given: Network unavailable
    mockAuth.networkError = URLError(.notConnectedToInternet)
    
    // When/Then: Loading profile throws
    await assertThrowsError(
        try await service.loadProfile(for: userID)
    ) { error in
        XCTAssertEqual(error as? ProfileError, .networkUnavailable)
    }
}
```

---

## refreshStats Method

**Contract**: System MUST query current saved videos count

**Input**:
- `userID: UUID` - The authenticated user's ID

**Output**:
- Tuple with `savedVideosCount: Int`
- Throws `ProfileError` on failure

**Behavior**:
1. Execute COUNT query on videos table
2. Filter by user_id
3. Return count

**Error Conditions**:
- Network unavailable → throws `.networkUnavailable`
- Query timeout → throws `.loadFailed`

**Contract Tests**:
```swift
func testRefreshStatsReturnsCurrentCount() async throws {
    // Given: User has 10 saved videos
    mockDatabase.savedVideosCount = 10
    
    // When: Refreshing stats
    let stats = try await service.refreshStats(for: userID)
    
    // Then: Correct count returned
    XCTAssertEqual(stats.savedVideosCount, 10)
}

func testRefreshStatsThrowsOnQueryFailure() async {
    // Given: Database query fails
    mockDatabase.statsQueryError = DatabaseError.connectionLost
    
    // When/Then: Refreshing stats throws
    await assertThrowsError(
        try await service.refreshStats(for: userID)
    ) { error in
        XCTAssertEqual(error as? ProfileError, .loadFailed)
    }
}
```

---

## Summary

**Service Responsibility**: Load and aggregate user profile data

**Data Sources**:
- Supabase auth (session data, user metadata)
- Videos table (saved count via query)

**Error Handling**:
- Network errors propagate to caller
- Stats query failures use safe defaults
- Session expiration detected and surfaced

**Test Coverage**:
- 6+ contract tests for profile loading
- 2+ tests for stats refresh
- Error scenario coverage
