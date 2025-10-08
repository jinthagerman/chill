# Research: Profile Page for Settings and Account Info

**Feature**: `006-add-a-profile`  
**Date**: 2025-10-07  
**Status**: Complete

## Settings Storage Strategy

### Decision: Supabase User Metadata for Settings

**Rationale**:
- Supabase auth provides `user_metadata` field for storing user preferences
- Automatically synced with user session
- No additional database tables needed for simple key-value settings
- Last-write-wins built into Supabase auth update mechanism
- Consistent with existing auth infrastructure

**Implementation Approach**:
```swift
// Settings stored in Supabase user_metadata
{
  "video_quality": "auto" | "high" | "medium" | "low",
  "autoplay": true | false
}
```

**Alternatives Considered**:
- **Separate settings table in Postgres**: Rejected - overkill for 2 simple settings, adds query overhead
- **Local-only storage (UserDefaults)**: Rejected - doesn't sync across devices, contradicts spec requirement
- **Supabase app_metadata**: Rejected - requires admin privileges, user_metadata is appropriate for user-controlled settings

**References**:
- Supabase Documentation: [User Metadata](https://supabase.com/docs/guides/auth/managing-user-data#user-metadata)
- Existing pattern in `AuthService.swift` for session management

---

## Profile Data Retrieval

### Decision: Combine Auth Session + Stats Query

**Rationale**:
- Most profile data already in auth session (email, created_at, email_confirmed_at)
- Only need additional query for: last login timestamp, saved videos count
- Display name/username can be stored in user_metadata or derived from email
- Minimize API calls for performance

**Data Sources**:
1. **From Auth Session** (already available):
   - Email address
   - Account creation date (`created_at`)
   - Verification status (`email_confirmed_at`)
   
2. **From User Metadata** (single auth.update() call):
   - Display name
   - Video quality preference
   - Autoplay preference

3. **From Additional Query** (profile stats):
   - Last login timestamp (from auth.audit logs or custom tracking)
   - Total saved videos count (COUNT query on videos table)

**Performance Strategy**:
- Load auth session data immediately (already cached)
- Fetch stats in background with loading indicator
- Display basic info first, populate stats when ready
- Target: < 3 seconds total load time

**Alternatives Considered**:
- **Single GraphQL query**: Rejected - adds complexity, existing codebase uses REST
- **Cache everything locally**: Rejected - stats would be stale, contradicts "accurate data" requirement

---

## Password Change Flow

### Decision: In-Place Password Change with Supabase Auth API

**Rationale**:
- Supabase provides `auth.updateUser()` for password changes
- Requires reauthentication for security (pass current password)
- Standard iOS pattern: present modal sheet for password change
- Reuse existing `AuthService` for consistency

**Flow**:
```
1. User taps "Change Password" in Account Security section
2. Present ChangePasswordView as sheet modal
3. User enters: current password, new password, confirm new password
4. Validate: passwords match, meets requirements
5. Call AuthService.changePassword(current, new)
6. AuthService reauthenticates with current password
7. If valid, updates to new password via Supabase
8. Dismiss modal, show success message
9. Session remains active (no re-login needed)
```

**Security Considerations**:
- Current password required (prevent unauthorized changes)
- Password requirements enforced (reuse from signup)
- Failed attempts tracked for rate limiting (Supabase built-in)
- No password displayed in clear text
- Success/failure logged for audit

**Alternatives Considered**:
- **Email verification flow**: Rejected - too cumbersome for password change
- **Separate password change screen**: Rejected - modal is more conventional
- **Force re-login after change**: Rejected - poor UX, Supabase supports session continuation

---

## User Avatar/Icon Implementation

### Decision: SF Symbol with First Letter Fallback

**Rationale**:
- No custom avatar upload in current scope (future enhancement)
- Use `person.circle.fill` SF Symbol as default
- Display first letter of display name/email in circle if available
- Matches iOS native patterns
- Low implementation overhead

**Implementation**:
```swift
// In navigation bar
Image(systemName: "person.circle.fill")
    .font(.title2)
    .foregroundColor(.accentColor)
    .onTapGesture { 
        coordinator.presentProfile() 
    }
    .accessibilityLabel("Profile")
    .accessibilityIdentifier("profile_avatar")
```

**Future Enhancement**:
- Custom avatar upload (photo library, camera)
- Stored in Supabase storage bucket
- Thumbnail generation for performance

**Alternatives Considered**:
- **Text initials in circle**: Could implement now, but adds complexity
- **No icon, just "Profile" text button**: Rejected - less discoverable, takes more space
- **Gravatar integration**: Rejected - external dependency, privacy concerns

---

## Display Name Management

### Decision: Store in User Metadata, Default to Email Prefix

**Rationale**:
- Display name stored in `user_metadata.display_name`
- If not set, derive from email (part before @)
- Editable in future enhancement (not in current scope)
- Keeps user metadata as single source of truth

**Implementation**:
```swift
var displayName: String {
    metadata["display_name"] as? String 
        ?? email.split(separator: "@").first.map(String.init) 
        ?? "User"
}
```

**Alternatives Considered**:
- **Separate profile table**: Rejected - overkill for single field
- **Force user to set display name**: Rejected - friction, not in spec
- **Use full email as display name**: Rejected - poor UX, too long

---

## Video Stats Tracking

### Decision: Query Existing Videos Table

**Rationale**:
- Videos are already tracked (from 003-card-based-video feature)
- Simple COUNT query filtered by user_id
- No new tables needed
- Supabase GraphQL or PostgREST for query

**Query Pattern**:
```sql
SELECT COUNT(*) 
FROM videos 
WHERE user_id = $1
```

**Performance**:
- Index on user_id (likely already exists)
- Result cached for 1 minute (acceptable staleness)
- Falls back to 0 if query fails

**Alternatives Considered**:
- **Denormalized counter**: Rejected - adds write overhead, can drift
- **Local cache only**: Rejected - inaccurate across devices

---

## Last Login Tracking

### Decision: Update Timestamp on Each App Launch

**Rationale**:
- Store `last_login_at` in user_metadata
- Update via `auth.updateUser()` on successful auth
- No additional database table needed
- Acceptable accuracy (per-session, not per-action)

**Implementation**:
- Hook into existing `AuthService` session change handler
- Update last_login_at when session established
- Display formatted relative time ("2 hours ago", "Yesterday")

**Alternatives Considered**:
- **Supabase auth audit logs**: Rejected - requires complex query, not exposed in SDK
- **Separate tracking table**: Rejected - overkill for display-only field
- **Don't track**: Rejected - spec explicitly requires this field

---

## Offline Behavior

### Decision: Cache Last-Known Profile Data

**Rationale**:
- Profile data rarely changes - safe to cache
- Display cached data immediately
- Fetch fresh data in background
- Show "Last updated: X" indicator when offline
- Settings changes blocked when offline (show banner)

**Cache Strategy**:
- Store profile snapshot in UserDefaults
- Refresh on each successful fetch
- Max cache age: 24 hours
- Consistent with existing offline patterns in app

**Alternatives Considered**:
- **Always require network**: Rejected - poor UX
- **SwiftData for persistence**: Rejected - too heavy for this use case

---

## Summary of Decisions

| Area | Decision | Key Rationale |
|------|----------|---------------|
| **Settings Storage** | Supabase user_metadata | Built-in sync, no extra tables |
| **Profile Data** | Auth session + stats query | Leverage existing data sources |
| **Password Change** | Modal sheet with Supabase auth.updateUser() | Secure, standard pattern |
| **User Avatar** | SF Symbol person.circle.fill | Simple, iOS-native |
| **Display Name** | user_metadata with email fallback | Single source of truth |
| **Video Stats** | COUNT query on videos table | Reuse existing data |
| **Last Login** | user_metadata timestamp | Simple, sufficient accuracy |
| **Offline** | Cache with staleness indicator | Better UX, safe for read-only data |

All research items resolved. Ready for Phase 1: Design & Contracts.
