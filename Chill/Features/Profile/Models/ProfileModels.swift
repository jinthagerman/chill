import Foundation

// MARK: - Profile Data Model

/// Aggregated view of user account information for display on profile page
/// Added in: 006-add-a-profile
struct UserProfile: Equatable, Codable {
    let userID: UUID
    let email: String
    let displayName: String
    let accountCreatedAt: Date
    let isVerified: Bool
    let lastLoginAt: Date?
    let savedVideosCount: Int
}

// MARK: - Settings Models

/// Video playback quality preference
/// Added in: 006-add-a-profile
enum VideoQuality: String, CaseIterable, Codable {
    case auto = "auto"
    case high = "high"
    case medium = "medium"
    case low = "low"
    
    var displayName: String {
        switch self {
        case .auto: return "Auto (recommended)"
        case .high: return "High"
        case .medium: return "Medium"
        case .low: return "Low"
        }
    }
}

/// Aggregates all video-related user preferences
/// Added in: 006-add-a-profile
struct VideoPreferences: Equatable, Codable {
    var quality: VideoQuality
    var autoplay: Bool
    
    static var `default`: VideoPreferences {
        VideoPreferences(quality: .auto, autoplay: true)
    }
}

/// Encapsulates password change validation state
/// Added in: 006-add-a-profile
struct PasswordChangeRequest: Equatable {
    let currentPassword: String
    let newPassword: String
    let confirmPassword: String
    
    var isValid: Bool {
        newPassword == confirmPassword &&
        !newPassword.isEmpty &&
        newPassword != currentPassword &&
        newPassword.count >= 8  // Minimum length requirement
    }
    
    var validationError: String? {
        if currentPassword.isEmpty {
            return "Enter your current password"
        }
        if newPassword.isEmpty {
            return "Enter a new password"
        }
        if newPassword.count < 8 {
            return "Password must be at least 8 characters"
        }
        if newPassword == currentPassword {
            return "New password must be different"
        }
        if newPassword != confirmPassword {
            return "Passwords don't match"
        }
        return nil
    }
}

// MARK: - Error Models

/// Profile-specific errors for user-facing messages
/// Added in: 006-add-a-profile
enum ProfileError: Error, Equatable {
    case loadFailed
    case updateFailed
    case unauthorized
    case networkUnavailable
    case invalidPasswordChange
    case passwordTooWeak
    case currentPasswordIncorrect
    case unknown
}

extension ProfileError {
    var userMessage: String {
        switch self {
        case .loadFailed:
            return "Couldn't load your profile. Tap to retry."
        case .updateFailed:
            return "Couldn't save your changes. Try again."
        case .unauthorized:
            return "Your session expired. Please log in again."
        case .networkUnavailable:
            return "You're offline. Changes will save when you reconnect."
        case .invalidPasswordChange:
            return "Check your password and try again."
        case .passwordTooWeak:
            return "Please choose a stronger password."
        case .currentPasswordIncorrect:
            return "Current password is incorrect."
        case .unknown:
            return "Something went wrong. Please try again."
        }
    }
}

// MARK: - State Models

/// Represents the loading/error state of the profile page
/// Added in: 006-add-a-profile
enum ProfileLoadingState: Equatable {
    case idle
    case loading
    case loaded(UserProfile)
    case error(ProfileError)
    
    var profile: UserProfile? {
        if case let .loaded(profile) = self {
            return profile
        }
        return nil
    }
    
    var isLoading: Bool {
        if case .loading = self { return true }
        return false
    }
    
    var errorMessage: String? {
        if case let .error(profileError) = self {
            return profileError.userMessage
        }
        return nil
    }
}
