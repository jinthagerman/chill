import Foundation
import Combine

/// ViewModel for ProfileView - manages profile loading state and user actions
/// Added in: 006-add-a-profile
@MainActor
final class ProfileViewModel: ObservableObject {
    @Published var loadingState: ProfileLoadingState = .idle
    @Published var errorMessage: String?
    
    private let profileService: ProfileServiceType
    private let authService: AuthServiceType
    private var cancellables = Set<AnyCancellable>()
    private let analytics: ((ProfileEventPayload) -> Void)?
    
    init(profileService: ProfileServiceType, 
         authService: AuthServiceType,
         analytics: ((ProfileEventPayload) -> Void)? = nil) {
        self.profileService = profileService
        self.authService = authService
        self.analytics = analytics
    }
    
    /// Load user profile from service
    func loadProfile() async {
        let startTime = Date()
        
        // Transition to loading state
        loadingState = .loading
        errorMessage = nil
        
        // Get current user ID from auth session
        guard let session = authService.currentSession else {
            loadingState = .error(.unauthorized)
            errorMessage = ProfileError.unauthorized.userMessage
            
            // Track failure
            logAnalyticsEvent(
                type: .profileViewed,
                result: .failure,
                errorCode: "unauthorized",
                startTime: startTime
            )
            return
        }
        
        do {
            // Load profile from service
            let profile = try await profileService.loadProfile(for: session.userID)
            
            // Update to loaded state
            loadingState = .loaded(profile)
            errorMessage = nil
            
            // Track success
            logAnalyticsEvent(
                type: .profileViewed,
                result: .success,
                startTime: startTime
            )
        } catch let error as ProfileError {
            // Handle profile errors
            loadingState = .error(error)
            errorMessage = error.userMessage
            
            // Track failure
            logAnalyticsEvent(
                type: .profileViewed,
                result: .failure,
                errorCode: String(describing: error),
                startTime: startTime
            )
        } catch {
            // Handle unexpected errors
            loadingState = .error(.unknown)
            errorMessage = ProfileError.unknown.userMessage
            
            // Track failure
            logAnalyticsEvent(
                type: .profileViewed,
                result: .failure,
                errorCode: "unknown",
                startTime: startTime
            )
        }
    }
    
    /// Refresh profile stats (saved videos count)
    func refreshStats() async {
        guard let session = authService.currentSession else { return }
        
        do {
            let savedVideosCount = try await profileService.refreshStats(for: session.userID)
            
            // Update the loaded profile with new stats
            if case let .loaded(profile) = loadingState {
                let updatedProfile = UserProfile(
                    userID: profile.userID,
                    email: profile.email,
                    displayName: profile.displayName,
                    accountCreatedAt: profile.accountCreatedAt,
                    isVerified: profile.isVerified,
                    lastLoginAt: profile.lastLoginAt,
                    savedVideosCount: savedVideosCount
                )
                loadingState = .loaded(updatedProfile)
            }
        } catch {
            // Stats refresh failure is non-critical, just log it
            print("Failed to refresh stats: \(error)")
        }
    }
    
    /// Sign out the current user
    func signOut() async throws {
        let startTime = Date()
        
        do {
            try await authService.signOut()
            
            // Track success
            logAnalyticsEvent(
                type: .signedOut,
                result: .success,
                startTime: startTime
            )
            
            // Auth coordinator will handle navigation after session cleared
        } catch {
            // Track failure
            logAnalyticsEvent(
                type: .signedOut,
                result: .failure,
                errorCode: String(describing: error),
                startTime: startTime
            )
            throw error
        }
    }
    
    // MARK: - Analytics
    
    private func logAnalyticsEvent(
        type: ProfileEventType,
        result: EventResult,
        settingKey: String? = nil,
        settingValue: String? = nil,
        errorCode: String? = nil,
        startTime: Date
    ) {
        let latencyMs = Int(Date().timeIntervalSince(startTime) * 1000)
        
        let payload = ProfileEventPayload(
            eventType: type,
            result: result,
            settingKey: settingKey,
            settingValue: settingValue,
            errorCode: errorCode,
            latencyMs: latencyMs
        )
        
        analytics?(payload)
    }
}
