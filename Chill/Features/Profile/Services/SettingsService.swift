import Foundation
import Combine
import Supabase

/// Protocol for SettingsService
/// Added in: 006-add-a-profile
protocol SettingsServiceType {
    func loadVideoPreferences() async throws -> VideoPreferences
    func updateVideoPreferences(_ preferences: VideoPreferences) async throws
    var preferencesPublisher: AnyPublisher<VideoPreferences, Never> { get }
}

/// Service responsible for loading and persisting user video preferences
/// Settings are stored in Supabase user metadata with last-write-wins conflict resolution
/// Added in: 006-add-a-profile
@MainActor
final class SettingsService: SettingsServiceType {
    private let client: SupabaseClient
    private let preferencesSubject: CurrentValueSubject<VideoPreferences, Never>
    private let analytics: ((ProfileEventPayload) -> Void)?
    
    init(client: SupabaseClient, analytics: ((ProfileEventPayload) -> Void)? = nil) {
        self.client = client
        self.analytics = analytics
        // Initialize with default preferences
        self.preferencesSubject = CurrentValueSubject(.default)
        
        // Attempt to load preferences on init (fire and forget)
        Task {
            if let prefs = try? await self.loadVideoPreferences() {
                self.preferencesSubject.send(prefs)
            }
        }
    }
    
    var preferencesPublisher: AnyPublisher<VideoPreferences, Never> {
        preferencesSubject.eraseToAnyPublisher()
    }
    
    /// Load video preferences from user metadata
    func loadVideoPreferences() async throws -> VideoPreferences {
        do {
            // Fetch current user
            let user = try await client.auth.user()
            let metadata = user.userMetadata
            
            // Parse video_preferences from metadata
            if let prefsDict = metadata["video_preferences"] as? [String: Any] {
                return parsePreferences(from: prefsDict)
            } else if let prefsData = metadata["video_preferences"] as? Data {
                // Handle case where it's stored as Data
                let decoder = JSONDecoder()
                return try decoder.decode(VideoPreferences.self, from: prefsData)
            } else {
                // No preferences set, return defaults
                return .default
            }
        } catch let error as ProfileError {
            throw error
        } catch {
            // Map errors
            throw mapError(error)
        }
    }
    
    /// Update video preferences in user metadata
    func updateVideoPreferences(_ preferences: VideoPreferences) async throws {
        let startTime = Date()
        
        do {
            // Create simple dictionary
            let prefsDict: [String: AnyJSON] = [
                "quality": .string(preferences.quality.rawValue),
                "autoplay": .bool(preferences.autoplay)
            ]
            
            // Update user metadata
            let attributes = UserAttributes(
                data: ["video_preferences": .object(prefsDict)]
            )
            
            _ = try await client.auth.update(user: attributes)
            
            // Publish the change
            preferencesSubject.send(preferences)
            
            // Track success
            logAnalyticsEvent(
                settingKey: "video_preferences",
                result: .success,
                startTime: startTime
            )
        } catch {
            // Track failure
            logAnalyticsEvent(
                settingKey: "video_preferences",
                result: .failure,
                errorCode: String(describing: error),
                startTime: startTime
            )
            
            throw ProfileError.updateFailed
        }
    }
    
    // MARK: - Analytics
    
    private func logAnalyticsEvent(
        settingKey: String,
        result: EventResult,
        errorCode: String? = nil,
        startTime: Date
    ) {
        let latencyMs = Int(Date().timeIntervalSince(startTime) * 1000)
        
        let payload = ProfileEventPayload(
            eventType: .settingsChanged,
            result: result,
            settingKey: settingKey,
            settingValue: nil,
            errorCode: errorCode,
            latencyMs: latencyMs
        )
        
        analytics?(payload)
    }
    
    // MARK: - Helper Methods
    
    private func parsePreferences(from dict: [String: Any]) -> VideoPreferences {
        // Parse quality
        let qualityString = dict["quality"] as? String ?? "auto"
        let quality = VideoQuality(rawValue: qualityString) ?? .auto
        
        // Parse autoplay
        let autoplay = dict["autoplay"] as? Bool ?? true
        
        return VideoPreferences(quality: quality, autoplay: autoplay)
    }
    
    private func mapError(_ error: Error) -> ProfileError {
        // Check for network errors
        if let urlError = error as? URLError {
            switch urlError.code {
            case .notConnectedToInternet, .networkConnectionLost:
                return .networkUnavailable
            default:
                return .updateFailed
            }
        }
        
        // Check for Supabase auth errors
        if let authError = error as? Supabase.AuthError {
            switch authError {
            case .sessionMissing:
                return .unauthorized
            default:
                return .updateFailed
            }
        }
        
        // Default to updateFailed
        return .updateFailed
    }
}
