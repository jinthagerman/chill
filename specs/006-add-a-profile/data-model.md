# Data Model: Profile Page for Settings and Account Info

**Feature**: `006-add-a-profile`  
**Date**: 2025-10-07

## Overview

This feature introduces profile and settings data models built on top of the existing authentication system. No new database tables are required; all data is stored in Supabase user metadata or queried from existing tables.

---

## Profile Data Model

### UserProfile (DOMAIN MODEL)

**Purpose**: Aggregated view of user account information for display on profile page

**Type**: Swift Struct

**Definition**:
```swift
struct UserProfile: Equatable {
    let userID: UUID
    let email: String
    let displayName: String
    let accountCreatedAt: Date
    let isVerified: Bool
    let lastLoginAt: Date?
    let savedVideosCount: Int
}
```

**Data Sources**:
- `userID`, `email`, `accountCreatedAt`, `isVerified`: From existing `AuthSession`
- `displayName`: From Supabase `user_metadata.display_name` or derived from email
- `lastLoginAt`: From Supabase `user_metadata.last_login_at`
- `savedVideosCount`: COUNT query on videos table filtered by user_id

**Relationships**:
- One-to-one with authenticated user session
- Read-only aggregation (no direct mutations)
- Refreshed on profile page load

**Validation Rules**:
- `email` must be valid email format (inherited from auth)
- `displayName` defaults to email prefix if not set
- `savedVideosCount` must be >= 0
- `accountCreatedAt` must be in the past

---

## Settings Models

### VideoQuality (ENUM)

**Purpose**: Represents video playback quality preference

**Definition**:
```swift
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
```

**Storage**: Supabase `user_metadata.video_quality`  
**Default**: `.auto`

---

### VideoPreferences (STRUCT)

**Purpose**: Aggregates all video-related user preferences

**Definition**:
```swift
struct VideoPreferences: Equatable, Codable {
    var quality: VideoQuality
    var autoplay: Bool
    
    static var `default`: VideoPreferences {
        VideoPreferences(quality: .auto, autoplay: true)
    }
}
```

**Storage**: Supabase `user_metadata.video_preferences` (JSON)

**Validation Rules**:
- `quality` must be one of four enum values
- `autoplay` is boolean (no validation needed)

**Behavior**:
- Changes persist immediately to Supabase
- Applied to video playback throughout app
- Last-write-wins for concurrent updates

---

### PasswordChangeRequest (STRUCT)

**Purpose**: Encapsulates password change validation state

**Definition**:
```swift
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
```

**Lifecycle**: Ephemeral - created for validation, not persisted

**Security**:
- Strings cleared from memory after use
- Never logged or stored
- Current password verified via Supabase before update

---

## Error Models

### ProfileError (ENUM)

**Purpose**: Profile-specific errors for user-facing messages

**Definition**:
```swift
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
```

**Mapping to User Messages**:
```swift
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
```

---

## State Models

### ProfileLoadingState (ENUM)

**Purpose**: Represents the loading/error state of the profile page

**Definition**:
```swift
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
```

**State Transitions**:
```
idle → loading → loaded(UserProfile)
                ↓
              error(ProfileError) → loading (retry)
```

---

## Analytics Models

### ProfileEventType (ENUM)

**Purpose**: Track profile-related user actions for analytics

**Definition**:
```swift
enum ProfileEventType: String {
    case profileViewed = "profile_viewed"
    case settingsChanged = "settings_changed"
    case passwordChanged = "password_changed"
    case signedOut = "signed_out"
}
```

### ProfileEventPayload (STRUCT)

```swift
struct ProfileEventPayload {
    let eventType: ProfileEventType
    let result: EventResult  // .success | .failure
    let settingKey: String?  // e.g., "video_quality", "autoplay"
    let settingValue: String?
    let errorCode: String?
    let latencyMs: Int
}
```

---

## Relationships Diagram

```
AuthSession (existing)
├── userID ──────────┐
├── email           │
├── created_at      │
└── email_confirmed_at
                     │
UserProfile ←────────┘
├── userID (from session)
├── email (from session)
├── displayName (from user_metadata or derived)
├── accountCreatedAt (from session.created_at)
├── isVerified (from session.email_confirmed_at)
├── lastLoginAt (from user_metadata.last_login_at)
└── savedVideosCount (from COUNT videos WHERE user_id)

VideoPreferences
├── quality: VideoQuality
└── autoplay: Bool
    ↓
Stored in user_metadata.video_preferences

PasswordChangeRequest (ephemeral)
├── currentPassword
├── newPassword
└── confirmPassword
```

---

## Data Flow

### Profile Load Flow
```
1. User taps avatar icon
2. ProfileViewModel.loadProfile() called
3. State changes: .idle → .loading
4. Fetch UserProfile:
   a. Read from cached AuthSession (email, created_at, verified)
   b. Fetch user_metadata (display_name, last_login_at, video_preferences)
   c. Query saved videos count
5. Aggregate into UserProfile struct
6. State changes: .loading → .loaded(UserProfile)
7. UI updates to display data
```

### Settings Change Flow
```
1. User toggles autoplay or changes video quality
2. VideoPreferences updated in memory
3. Call SettingsService.updateVideoPreferences(new preferences)
4. Service updates Supabase user_metadata via auth.updateUser()
5. On success: show brief confirmation
6. On failure: revert to previous value, show error
7. Analytics event logged
```

### Password Change Flow
```
1. User taps "Change Password"
2. Present ChangePasswordView modal
3. User fills: current password, new password, confirm
4. Validate PasswordChangeRequest.isValid
5. Call AuthService.changePassword(current, new)
6. Service reauthenticates with current password
7. If valid, updates password via Supabase
8. On success: dismiss modal, show banner "Password updated"
9. On failure: show error in modal, don't dismiss
10. Analytics event logged
```

---

## Data Invariants

### Critical Invariants (Must Hold)

1. **Authentication Required**: Profile page MUST NOT be accessible without valid session
2. **Email Immutability**: Email cannot be changed from profile page (Supabase primary identifier)
3. **Settings Atomicity**: Each setting change is independent (video quality doesn't affect autoplay)
4. **Password Security**: Current password MUST be verified before allowing change
5. **Stats Accuracy**: Saved videos count MUST match actual videos table count
6. **Last Login Freshness**: Updated on every successful authentication

### Validation Checks

```swift
// Before allowing profile access
guard let session = authService.currentSession else {
    coordinator.route = .auth
    return
}

// Before saving video preferences
guard VideoQuality.allCases.contains(newQuality) else {
    throw ProfileError.updateFailed
}

// Before password change
guard passwordChangeRequest.isValid else {
    throw ProfileError.invalidPasswordChange
}
```

---

## Testing Considerations

### Unit Test Scenarios

1. **Profile data aggregation**:
   - UserProfile correctly constructed from session + metadata + stats
   - Display name defaults to email prefix when not set
   - Saved videos count handles query errors gracefully

2. **Settings persistence**:
   - Video quality changes persist to user_metadata
   - Autoplay toggle updates correctly
   - Failed saves revert to previous value

3. **Password change validation**:
   - PasswordChangeRequest.isValid works correctly
   - Validation error messages accurate
   - Current password required

4. **State management**:
   - ProfileLoadingState transitions correctly
   - Error states handled
   - Retry mechanism works

### Integration Test Scenarios

1. Complete profile load with real Supabase session
2. Settings change persists and survives app restart
3. Password change with valid/invalid credentials
4. Offline behavior (display cached data, block updates)

---

## Summary

**New Models**:
- `UserProfile` struct (aggregated view)
- `VideoPreferences` struct (settings)
- `VideoQuality` enum
- `PasswordChangeRequest` struct (ephemeral)
- `ProfileError` enum
- `ProfileLoadingState` enum
- `ProfileEventType` enum
- `ProfileEventPayload` struct

**Data Sources**:
- Supabase auth session (existing)
- Supabase user_metadata (video preferences, display name, last login)
- Videos table (saved count query)

**Storage Strategy**:
- Settings: user_metadata JSON in Supabase
- Profile stats: Computed on demand, cached locally
- Passwords: Supabase auth (encrypted at rest)

**Key Characteristics**:
- No new database tables required
- Leverages existing auth infrastructure
- Simple last-write-wins conflict resolution
- All state transitions testable via ViewModel methods
