import Foundation

// MARK: - Analytics Models

/// Track profile-related user actions for analytics
/// Added in: 006-add-a-profile
enum ProfileEventType: String {
    case profileViewed = "profile_viewed"
    case settingsChanged = "settings_changed"
    case passwordChanged = "password_changed"
    case signedOut = "signed_out"
}

/// Result of an event (success or failure)
/// Added in: 006-add-a-profile
enum EventResult: String {
    case success
    case failure
}

/// Analytics payload for profile events
/// Added in: 006-add-a-profile
struct ProfileEventPayload {
    let eventType: ProfileEventType
    let result: EventResult
    let settingKey: String?  // e.g., "video_quality", "autoplay"
    let settingValue: String?
    let errorCode: String?
    let latencyMs: Int
}
