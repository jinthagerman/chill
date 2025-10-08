import XCTest
@testable import Chill

/// Contract tests for ProfileService
/// Added in: 006-add-a-profile
@MainActor
final class ProfileServiceTests: XCTestCase {
    private var mockAuth: MockAuthClient!
    private var mockDatabase: MockDatabaseClient!
    private var service: ProfileService!
    
    override func setUp() async throws {
        try await super.setUp()
        mockAuth = MockAuthClient()
        mockDatabase = MockDatabaseClient()
        // service = ProfileService(authClient: mockAuth, databaseClient: mockDatabase)
    }
    
    override func tearDown() {
        mockAuth = nil
        mockDatabase = nil
        service = nil
        super.tearDown()
    }
    
    // MARK: - Contract Test 1: Aggregate all sources
    
    func testLoadProfileAggregatesAllSources() async throws {
        // Given: Valid user session with metadata
        let userID = UUID()
        let session = AuthClientSession(
            userID: userID,
            email: "john@example.com",
            accessTokenExpiresAt: Date().addingTimeInterval(3600),
            refreshToken: "token",
            isVerified: true,
            raw: nil
        )
        mockAuth.currentSession = session
        mockAuth.userMetadata = ["display_name": "John"]
        mockDatabase.savedVideosCount = 42
        
        // When: Loading profile
        // let profile = try await service.loadProfile(for: userID)
        
        // Then: All fields populated
        // XCTAssertEqual(profile.displayName, "John")
        // XCTAssertEqual(profile.savedVideosCount, 42)
        // XCTAssertEqual(profile.email, "john@example.com")
        // XCTAssertEqual(profile.userID, userID)
        // XCTAssertTrue(profile.isVerified)
        
        XCTFail("ProfileService not implemented yet - test must fail (RED state)")
    }
    
    // MARK: - Contract Test 2: Default display name from email
    
    func testLoadProfileDefaultsDisplayName() async throws {
        // Given: No display_name in metadata
        let userID = UUID()
        let session = AuthClientSession(
            userID: userID,
            email: "test@example.com",
            accessTokenExpiresAt: Date().addingTimeInterval(3600),
            refreshToken: "token",
            isVerified: true,
            raw: nil
        )
        mockAuth.currentSession = session
        mockAuth.userMetadata = [:]
        mockDatabase.savedVideosCount = 0
        
        // When: Loading profile
        // let profile = try await service.loadProfile(for: userID)
        
        // Then: Display name derived from email prefix
        // XCTAssertEqual(profile.displayName, "test")
        
        XCTFail("ProfileService not implemented yet - test must fail (RED state)")
    }
    
    // MARK: - Contract Test 3: Handle stats query failure gracefully
    
    func testLoadProfileHandlesStatsQueryFailure() async throws {
        // Given: Stats query fails
        let userID = UUID()
        let session = AuthClientSession(
            userID: userID,
            email: "test@example.com",
            accessTokenExpiresAt: Date().addingTimeInterval(3600),
            refreshToken: "token",
            isVerified: true,
            raw: nil
        )
        mockAuth.currentSession = session
        mockAuth.userMetadata = ["display_name": "Test"]
        mockDatabase.statsQueryShouldFail = true
        
        // When: Loading profile (should not throw despite stats failure)
        // let profile = try await service.loadProfile(for: userID)
        
        // Then: Profile loads with 0 count, doesn't throw
        // XCTAssertEqual(profile.savedVideosCount, 0)
        // XCTAssertEqual(profile.displayName, "Test")
        
        XCTFail("ProfileService not implemented yet - test must fail (RED state)")
    }
    
    // MARK: - Contract Test 4: Network error propagates
    
    func testLoadProfileThrowsOnNetworkError() async {
        // Given: Network unavailable
        let userID = UUID()
        mockAuth.networkError = URLError(.notConnectedToInternet)
        
        // When/Then: Loading profile throws
        // do {
        //     _ = try await service.loadProfile(for: userID)
        //     XCTFail("Expected network error to be thrown")
        // } catch let error as ProfileError {
        //     XCTAssertEqual(error, .networkUnavailable)
        // } catch {
        //     XCTFail("Expected ProfileError.networkUnavailable, got \(error)")
        // }
        
        XCTFail("ProfileService not implemented yet - test must fail (RED state)")
    }
    
    // MARK: - Contract Test 5: Refresh stats returns current count
    
    func testRefreshStatsReturnsCurrentCount() async throws {
        // Given: User has 10 saved videos
        let userID = UUID()
        mockDatabase.savedVideosCount = 10
        
        // When: Refreshing stats
        // let stats = try await service.refreshStats(for: userID)
        
        // Then: Correct count returned
        // XCTAssertEqual(stats.savedVideosCount, 10)
        
        XCTFail("ProfileService not implemented yet - test must fail (RED state)")
    }
    
    // MARK: - Contract Test 6: Stats query failure throws
    
    func testRefreshStatsThrowsOnQueryFailure() async {
        // Given: Database query fails
        let userID = UUID()
        mockDatabase.statsQueryShouldFail = true
        mockDatabase.statsQueryError = ProfileError.loadFailed
        
        // When/Then: Refreshing stats throws
        // do {
        //     _ = try await service.refreshStats(for: userID)
        //     XCTFail("Expected loadFailed error to be thrown")
        // } catch let error as ProfileError {
        //     XCTAssertEqual(error, .loadFailed)
        // } catch {
        //     XCTFail("Expected ProfileError.loadFailed, got \(error)")
        // }
        
        XCTFail("ProfileService not implemented yet - test must fail (RED state)")
    }
}

// MARK: - Mock Auth Client

private final class MockAuthClient {
    var currentSession: AuthClientSession?
    var userMetadata: [String: Any] = [:]
    var networkError: Error?
}

// MARK: - Mock Database Client

private final class MockDatabaseClient {
    var savedVideosCount: Int = 0
    var statsQueryShouldFail: Bool = false
    var statsQueryError: Error?
}
