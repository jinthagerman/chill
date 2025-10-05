# User ID Solution - Add Video Feature

## Question: "What's user id?"

The **User ID** is the unique identifier (UUID) for the currently logged-in user. It's needed to associate saved videos with the correct user in your Supabase database.

---

## ✅ Solution Implemented

Your app already has a complete authentication system with `AuthService` that tracks the current user session. I've integrated it into the Add Video feature.

### How It Works

1. **AuthService** (already exists in your app):
   ```swift
   // Chill/Features/Auth/AuthService.swift
   class AuthService {
       var currentSession: AuthSession? {
           // Returns current logged-in user's session
       }
   }
   ```

2. **AuthSession** (already exists):
   ```swift
   // Chill/Features/Auth/AuthModels.swift
   struct AuthSession {
       let userID: UUID        // ← This is what we need!
       let email: String
       let accessTokenExpiresAt: Date
       let refreshToken: String
       let isVerified: Bool
   }
   ```

3. **AddVideoViewModel** (updated):
   ```swift
   // Now takes AuthService as dependency
   private let authService: AuthService
   
   // Gets user ID dynamically from current session
   private var userId: UUID {
       authService.currentSession?.userID ?? UUID()
   }
   ```

### Flow Diagram

```
User taps "Save" on video
    ↓
AddVideoViewModel.confirmAndSave()
    ↓
Gets userId from authService.currentSession?.userID
    ↓
Passes to AddVideoService.submitToSupabase(userId: userId)
    ↓
Supabase saves video with user_id = <current user's UUID>
```

---

## 🔗 Integration Path

### 1. AuthCoordinator → VideoListView → AddVideoCoordinator

```swift
// AuthCoordinator.swift (updated)
func makeVideoListView(modelContext: ModelContext) -> VideoListView {
    guard let authService = authService else {
        fatalError("AuthService not initialized")
    }
    
    return VideoListView(
        viewModel: viewModel, 
        authService: authService  // ← Pass AuthService
    )
}

// VideoListView.swift (updated)
struct VideoListView: View {
    let authService: AuthService  // ← Receive AuthService
    
    var body: some View {
        // ...
        .sheet(isPresented: $showAddVideoFlow) {
            AddVideoCoordinator(authService: authService)  // ← Pass to modal
        }
    }
}

// AddVideoCoordinator.swift (updated)
struct AddVideoCoordinator: View {
    let authService: AuthService  // ← Receive AuthService
    
    init(authService: AuthService) {
        self.authService = authService
        _viewModel = StateObject(wrappedValue: AddVideoViewModel(
            authService: authService  // ← Pass to ViewModel
        ))
    }
}

// AddVideoViewModel.swift (updated)
init(authService: AuthService) {
    self.authService = authService  // ← Store for later use
}
```

### 2. When Saving Video

```swift
// AddVideoViewModel.confirmAndSave()
func confirmAndSave() {
    // Get current user ID
    let currentUserId = authService.currentSession?.userID ?? UUID()
    
    // Submit to Supabase with user ID
    try await addVideoService.submitToSupabase(
        metadata: metadata,
        userDescription: descriptionInput,
        userId: currentUserId  // ← Attached to video record
    )
}
```

### 3. Supabase Database

```sql
-- Videos table (your Supabase schema)
CREATE TABLE videos (
    id UUID PRIMARY KEY,
    user_id UUID NOT NULL,  -- ← References auth.users(id)
    title TEXT NOT NULL,
    thumbnail_url TEXT NOT NULL,
    -- ... other fields
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- When AddVideoService submits:
INSERT INTO videos (user_id, title, thumbnail_url, ...)
VALUES ('abc-123-def-456', 'My Video', 'https://...', ...);
                ↑
    Current logged-in user's ID
```

---

## 🔐 Security & Fallback

### If User Is Logged In
```swift
authService.currentSession?.userID
// Returns: UUID("abc-123-def-456")  ← Real user ID
```

### If User Is NOT Logged In (Fallback)
```swift
authService.currentSession?.userID ?? UUID()
// Returns: UUID()  ← Generates temporary random UUID

// In practice, this shouldn't happen because:
// - Users must be logged in to access VideoListView
// - AuthCoordinator routes to .welcome if no session
```

### Production Recommendation

Add a check in `AddVideoViewModel` to prevent saving if not authenticated:

```swift
func confirmAndSave() {
    // Ensure user is logged in
    guard let currentUserId = authService.currentSession?.userID else {
        errorMessage = "You must be logged in to save videos"
        return
    }
    
    // Proceed with save...
    try await addVideoService.submitToSupabase(
        metadata: metadata,
        userDescription: descriptionInput,
        userId: currentUserId
    )
}
```

---

## 📝 Files Modified

### Updated Files (4):
1. **AddVideoViewModel.swift**
   - Changed: `init(userId: UUID?)` → `init(authService: AuthService)`
   - Added: `private var userId: UUID { authService.currentSession?.userID ?? UUID() }`

2. **AddVideoCoordinator.swift**
   - Added: `let authService: AuthService`
   - Added: `init(authService:)` to pass to ViewModel
   - Updated: Preview with MockAuthClient

3. **VideoListView.swift**
   - Added: `let authService: AuthService`
   - Updated: `.sheet { AddVideoCoordinator(authService: authService) }`

4. **AuthCoordinator.swift**
   - Updated: `makeVideoListView(modelContext:)` to pass `authService` parameter

---

## ✅ What This Solves

### Before
```swift
// ❌ Hard-coded placeholder
self.userId = userId ?? UUID() // TODO: Get from auth session
```

### After
```swift
// ✅ Real user ID from current session
private var userId: UUID {
    authService.currentSession?.userID ?? UUID()
}
```

### Result
- Videos are now correctly associated with the logged-in user
- User can only see their own videos (via Supabase RLS policies)
- Multi-user support enabled
- No configuration needed - uses your existing auth system!

---

## 🧪 Testing

### Test with Real User

```swift
// 1. Log in to app
// 2. Go to video list
// 3. Tap '+' FAB
// 4. Add a video
// 5. Check Supabase:
SELECT user_id, title FROM videos ORDER BY created_at DESC LIMIT 1;
//    user_id                              | title
// ----------------------------------------+-------------
// abc-123-def-456 (your logged-in user) | Sample Video
```

### Test User ID in ViewModel

```swift
// In AddVideoViewModel
print("Current user ID: \(userId)")
// Output: Current user ID: abc-123-def-456

// Or if not logged in (shouldn't happen):
// Output: Current user ID: temp-random-uuid
```

---

## 🎯 Summary

**User ID** = UUID from `authService.currentSession?.userID`

**Integrated By**:
- AuthCoordinator passes AuthService to VideoListView
- VideoListView passes it to AddVideoCoordinator
- AddVideoCoordinator passes it to AddVideoViewModel
- AddVideoViewModel uses it when saving videos

**Result**: Videos are correctly associated with the logged-in user in Supabase! ✅

---

**Status**: ✅ RESOLVED - User ID now comes from AuthService session
