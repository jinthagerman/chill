import XCTest
import SnapshotTesting
import SwiftUI
@testable import Chill

/// Snapshot tests for Profile views
/// Added in: 006-add-a-profile
@MainActor
final class ProfileViewSnapshotTests: XCTestCase {
    
    // MARK: - Test 1: ProfileHeaderView appearance
    
    func testProfileHeaderViewAppearance() {
        let profile = UserProfile(
            userID: UUID(),
            email: "user@example.com",
            displayName: "John Doe",
            accountCreatedAt: Date(timeIntervalSince1970: 1672531200), // Jan 1, 2023
            isVerified: true,
            lastLoginAt: Date(timeIntervalSince1970: 1704067200), // Jan 1, 2024
            savedVideosCount: 42
        )
        
        let view = ProfileHeaderView(profile: profile)
            .frame(width: 375)
        
        assertSnapshot(of: view, as: .image)
    }
    
    // MARK: - Test 2: VideoPreferencesView appearance
    
    func testVideoPreferencesViewAppearance() {
        @State var preferences = VideoPreferences.default
        
        let view = VideoPreferencesView(
            preferences: $preferences,
            onSave: { _ in }
        )
        .frame(width: 375)
        
        assertSnapshot(of: view, as: .image)
    }
    
    // MARK: - Test 3: AccountSecurityView appearance
    
    func testAccountSecurityViewAppearance() {
        let view = AccountSecurityView(
            onChangePassword: { }
        )
        .frame(width: 375)
        
        assertSnapshot(of: view, as: .image)
    }
    
    // MARK: - Test 4: ChangePasswordView appearance
    
    func testChangePasswordViewAppearance() {
        let mockAuth = MockAuthService()
        let viewModel = ChangePasswordViewModel(authService: mockAuth)
        
        let view = ChangePasswordView(viewModel: viewModel)
            .frame(width: 375, height: 667)
        
        assertSnapshot(of: view, as: .image)
    }
    
    // MARK: - Test 5: ProfileView with error state
    
    func testProfileViewWithError() {
        let mockAuth = MockAuthService()
        let mockProfileService = MockProfileService()
        mockProfileService.shouldFail = true
        mockProfileService.errorToThrow = ProfileError.loadFailed
        
        let viewModel = ProfileViewModel(
            profileService: mockProfileService,
            authService: mockAuth
        )
        viewModel.loadingState = .error(.loadFailed)
        
        let mockSettingsService = MockSettingsService()
        
        let view = ProfileView(
            viewModel: viewModel,
            settingsService: mockSettingsService,
            authService: mockAuth
        )
        .frame(width: 375, height: 667)
        
        assertSnapshot(of: view, as: .image)
    }
}

// MARK: - Mock Services

@MainActor
private final class MockAuthService: ObservableObject, AuthServiceType {
    private let subject = CurrentValueSubject<AuthSession?, Never>(nil)
    
    var sessionPublisher: AnyPublisher<AuthSession?, Never> {
        subject.eraseToAnyPublisher()
    }
    
    var currentSession: AuthSession? {
        subject.value
    }
    
    func signUp(email: String, password: String, consent: Bool) async throws -> AuthSession {
        throw AuthError.unknown
    }
    
    func signIn(email: String, password: String) async throws -> AuthSession {
        throw AuthError.unknown
    }
    
    func signOut() async throws {
    }
    
    func requestPasswordReset(email: String) async throws {
    }
    
    func verifyResetCode(email: String, code: String, newPassword: String) async throws -> AuthSession {
        throw AuthError.unknown
    }
    
    func changePassword(currentPassword: String, newPassword: String) async throws {
    }
}

@MainActor
private final class MockProfileService: ProfileServiceType {
    var shouldFail: Bool = false
    var errorToThrow: Error?
    
    func loadProfile(for userID: UUID) async throws -> UserProfile {
        if shouldFail {
            throw errorToThrow ?? ProfileError.loadFailed
        }
        
        return UserProfile(
            userID: userID,
            email: "user@example.com",
            displayName: "John Doe",
            accountCreatedAt: Date(timeIntervalSince1970: 1672531200),
            isVerified: true,
            lastLoginAt: Date(timeIntervalSince1970: 1704067200),
            savedVideosCount: 42
        )
    }
    
    func refreshStats(for userID: UUID) async throws -> Int {
        return 42
    }
}

@MainActor
private final class MockSettingsService: SettingsServiceType {
    private let subject = CurrentValueSubject<VideoPreferences, Never>(.default)
    
    var preferencesPublisher: AnyPublisher<VideoPreferences, Never> {
        subject.eraseToAnyPublisher()
    }
    
    func loadVideoPreferences() async throws -> VideoPreferences {
        return .default
    }
    
    func updateVideoPreferences(_ preferences: VideoPreferences) async throws {
        subject.send(preferences)
    }
}
