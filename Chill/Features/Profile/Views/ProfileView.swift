import SwiftUI
import Combine

/// Main profile page view composing all sections
/// Added in: 006-add-a-profile
struct ProfileView: View {
    @ObservedObject var viewModel: ProfileViewModel
    let settingsService: SettingsServiceType
    let authService: AuthServiceType
    let onDismiss: () -> Void  // Added: Navigation back callback
    let onSignOut: () async -> Void  // Added: Sign out callback
    @State private var videoPreferences: VideoPreferences = .default
    @State private var showingChangePassword = false
    
    var body: some View {
        NavigationView {
            Group {
                switch viewModel.loadingState {
                case .idle, .loading:
                    loadingView
                    
                case .loaded(let profile):
                    loadedView(profile: profile)
                    
                case .error(let error):
                    errorView(error: error)
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: onDismiss) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                            Text("Videos")
                        }
                    }
                    .accessibilityLabel("Back to videos")
                    .accessibilityIdentifier("profile_back_button")
                }
            }
            .onAppear {
                Task {
                    await viewModel.loadProfile()
                    if let prefs = try? await settingsService.loadVideoPreferences() {
                        videoPreferences = prefs
                    }
                }
            }
            .sheet(isPresented: $showingChangePassword) {
                ChangePasswordView(
                    viewModel: ChangePasswordViewModel(
                        authService: authService
                    )
                )
            }
        }
    }
    
    // MARK: - Loading View
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle())
                .scaleEffect(1.5)
            
            Text("Loading profile...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - Loaded View
    
    private func loadedView(profile: UserProfile) -> some View {
        ScrollView {
            VStack(spacing: 0) {
                // Profile header (account info)
                ProfileHeaderView(profile: profile)
                
                // Settings section
                VStack(alignment: .leading, spacing: 16) {
                    // "Settings" header
                    Text("Settings")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.primary)
                        .padding(.horizontal, 20)
                    
                    // Settings list
                    VStack(spacing: 0) {
                        // Video preferences
                        VideoPreferencesView(
                            preferences: $videoPreferences,
                            onSave: { prefs in
                                try? await settingsService.updateVideoPreferences(prefs)
                            }
                        )
                        
                        // Account security / Change Password
                        AccountSecurityView(
                            onChangePassword: {
                                showingChangePassword = true
                            }
                        )
                    }
                }
                .padding(.vertical, 10)
                
                // Spacer at bottom for better scrolling
                Spacer(minLength: 100)
            }
        }
        .background(Color(.systemBackground))
    }
    
    // MARK: - Error View
    
    private func errorView(error: ProfileError) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundColor(.orange)
            
            Text(error.userMessage)
                .font(.headline)
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button(action: retry) {
                HStack {
                    Image(systemName: "arrow.clockwise")
                    Text("Retry")
                        .fontWeight(.semibold)
                }
                .padding()
                .background(Color.accentColor)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
        }
        .padding()
    }
    
    // MARK: - Helper Functions
    
    private func retry() {
        Task {
            await viewModel.loadProfile()
        }
    }
    
    private func signOut() {
        Task {
            // Call coordinator's signOut which handles both auth service and route change
            await onSignOut()
        }
    }
}

// MARK: - Preview

#Preview {
    @Previewable @StateObject var mockAuth = MockAuthService()
    let mockProfileService = MockProfileService()
    let mockSettingsService = MockSettingsService()
    
    ProfileView(
        viewModel: ProfileViewModel(
            profileService: mockProfileService,
            authService: mockAuth
        ),
        settingsService: mockSettingsService,
        authService: mockAuth,
        onDismiss: { },
        onSignOut: { }
    )
}

// MARK: - Mock Auth Service for Preview

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

// MARK: - Mock Services for Preview

@MainActor
private final class MockProfileService: ProfileServiceType {
    func loadProfile(for userID: UUID) async throws -> UserProfile {
        UserProfile(
            userID: userID,
            email: "user@example.com",
            displayName: "John Doe",
            accountCreatedAt: Date().addingTimeInterval(-86400 * 365),
            isVerified: true,
            lastLoginAt: Date().addingTimeInterval(-3600),
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
