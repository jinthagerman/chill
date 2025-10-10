import XCTest
import Combine
@testable import Chill

/// Unit tests for ProfileViewModel
/// Added in: 006-add-a-profile
@MainActor
final class ProfileViewModelTests: XCTestCase {
    private var mockProfileService: MockProfileService!
    private var mockAuthService: MockAuthService!
    private var viewModel: ProfileViewModel!
    
    override func setUp() async throws {
        try await super.setUp()
        mockProfileService = MockProfileService()
        mockAuthService = MockAuthService()
        // viewModel = ProfileViewModel(
        //     profileService: mockProfileService,
        //     authService: mockAuthService
        // )
    }
    
    override func tearDown() {
        mockProfileService = nil
        mockAuthService = nil
        viewModel = nil
        super.tearDown()
    }
    
    // MARK: - Contract Test 1: Initial state is idle
    
    func testInitialStateIsIdle() {
        // Then: ViewModel starts in idle state
        // XCTAssertEqual(viewModel.loadingState, .idle)
        // XCTAssertNil(viewModel.errorMessage)
        
        XCTFail("ProfileViewModel not implemented yet - test must fail (RED state)")
    }
    
    // MARK: - Contract Test 2: State transitions to loading
    
    func testLoadProfileTransitionsToLoading() async {
        // Given: Profile service will succeed
        mockProfileService.loadProfileDelay = 0.1
        
        // When: Loading profile
        // Task {
        //     await viewModel.loadProfile()
        // }
        
        // Then: State changes to loading
        // try? await Task.sleep(nanoseconds: 10_000_000) // 0.01 seconds
        // XCTAssertEqual(viewModel.loadingState, .loading)
        
        XCTFail("ProfileViewModel not implemented yet - test must fail (RED state)")
    }
    
    // MARK: - Contract Test 3: Success loads profile data
    
    func testLoadProfileSuccess() async {
        // Given: Profile service returns data
        let expectedProfile = UserProfile(
            userID: UUID(),
            email: "test@example.com",
            displayName: "Test User",
            accountCreatedAt: Date(),
            isVerified: true,
            lastLoginAt: Date(),
            savedVideosCount: 10
        )
        mockProfileService.profileToReturn = expectedProfile
        
        // When: Loading profile
        // await viewModel.loadProfile()
        
        // Then: State changes to loaded with profile
        // if case let .loaded(profile) = viewModel.loadingState {
        //     XCTAssertEqual(profile.email, expectedProfile.email)
        //     XCTAssertEqual(profile.displayName, expectedProfile.displayName)
        // } else {
        //     XCTFail("Expected loaded state, got \(viewModel.loadingState)")
        // }
        // XCTAssertNil(viewModel.errorMessage)
        
        XCTFail("ProfileViewModel not implemented yet - test must fail (RED state)")
    }
    
    // MARK: - Contract Test 4: Failure shows error
    
    func testLoadProfileFailure() async {
        // Given: Profile service will fail
        mockProfileService.shouldFail = true
        mockProfileService.errorToThrow = ProfileError.loadFailed
        
        // When: Loading profile
        // await viewModel.loadProfile()
        
        // Then: State changes to error with message
        // if case let .error(error) = viewModel.loadingState {
        //     XCTAssertEqual(error, .loadFailed)
        // } else {
        //     XCTFail("Expected error state, got \(viewModel.loadingState)")
        // }
        // XCTAssertNotNil(viewModel.errorMessage)
        
        XCTFail("ProfileViewModel not implemented yet - test must fail (RED state)")
    }
    
    // MARK: - Contract Test 5: Retry after error
    
    func testRetryAfterError() async {
        // Given: First load fails, second succeeds
        mockProfileService.shouldFail = true
        mockProfileService.errorToThrow = ProfileError.loadFailed
        
        // await viewModel.loadProfile()
        // XCTAssertTrue(viewModel.loadingState.isError)
        
        // When: Retry with success
        mockProfileService.shouldFail = false
        mockProfileService.profileToReturn = UserProfile(
            userID: UUID(),
            email: "test@example.com",
            displayName: "Test",
            accountCreatedAt: Date(),
            isVerified: true,
            lastLoginAt: nil,
            savedVideosCount: 0
        )
        
        // await viewModel.loadProfile()
        
        // Then: State changes to loaded
        // XCTAssertTrue(viewModel.loadingState.isLoaded)
        // XCTAssertNil(viewModel.errorMessage)
        
        XCTFail("ProfileViewModel not implemented yet - test must fail (RED state)")
    }
    
    // MARK: - Contract Test 6: Sign out clears session
    
    func testSignOut() async throws {
        // When: Sign out called
        // try await viewModel.signOut()
        
        // Then: Auth service sign out was called
        // XCTAssertTrue(mockAuthService.didSignOut)
        
        XCTFail("ProfileViewModel not implemented yet - test must fail (RED state)")
    }
}

// MARK: - Mock Profile Service

private final class MockProfileService {
    var shouldFail: Bool = false
    var errorToThrow: Error?
    var profileToReturn: UserProfile?
    var loadProfileDelay: TimeInterval = 0
    
    func loadProfile(for userID: UUID) async throws -> UserProfile {
        if loadProfileDelay > 0 {
            try await Task.sleep(nanoseconds: UInt64(loadProfileDelay * 1_000_000_000))
        }
        
        if shouldFail {
            throw errorToThrow ?? ProfileError.loadFailed
        }
        
        guard let profile = profileToReturn else {
            throw ProfileError.loadFailed
        }
        
        return profile
    }
}

// MARK: - Mock Auth Service

@MainActor
private final class MockAuthService: AuthServiceType {
    import Combine
    
    private let subject = CurrentValueSubject<AuthSession?, Never>(nil)
    
    var sessionPublisher: AnyPublisher<AuthSession?, Never> {
        subject.eraseToAnyPublisher()
    }
    
    var currentSession: AuthSession? {
        subject.value
    }
    
    var didSignOut: Bool = false
    var signOutShouldFail: Bool = false
    
    func signUp(email: String, password: String, consent: Bool) async throws -> AuthSession {
        throw AuthError.unknown
    }
    
    func signIn(email: String, password: String) async throws -> AuthSession {
        throw AuthError.unknown
    }
    
    func signOut() async throws {
        if signOutShouldFail {
            throw AuthError.unknown
        }
        didSignOut = true
    }
    
    func requestPasswordReset(email: String) async throws {
        throw AuthError.unknown
    }
    
    func verifyResetCode(email: String, code: String, newPassword: String) async throws -> AuthSession {
        throw AuthError.unknown
    }
    
    func changePassword(currentPassword: String, newPassword: String) async throws {
        throw AuthError.unknown
    }
}

// MARK: - Helper Extensions

extension ProfileLoadingState {
    var isError: Bool {
        if case .error = self { return true }
        return false
    }
    
    var isLoaded: Bool {
        if case .loaded = self { return true }
        return false
    }
}
