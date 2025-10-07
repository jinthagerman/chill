# Research: Add Video via URL Modal

**Feature**: 004-implement-add-video  
**Date**: 2025-10-04  
**Status**: Complete

## Research Areas

### 1. LoadifyEngine API for Metadata Extraction

**Decision**: Use LoadifyClient().fetchVideoDetails(for: String) async throws → LoadifyResponse

**Source**: LoadifyEngine.xcframework from /Users/jin/Code/Loadify-iOS (integrated in Chill project)

**Rationale**:
- LoadifyEngine.xcframework already integrated in project at `/Users/jin/Code/Chill/LoadifyEngine.xcframework`
- Built with Swift 6.0, supports iOS 17.0+
- Supports TikTok, Instagram, Facebook, Twitter (X) natively
- Returns structured LoadifyResponse with platform, user details, video details
- Handles mobile variants and shortened URLs automatically
- Built-in per-platform rate limiting
- Mock mode available for testing (`LoadifyClient(isMockEnabled: true)`)

**API Structure**:
```swift
import LoadifyEngine

// Initialize client
let client = LoadifyClient(isMockEnabled: false)

// Fetch video details
let response = try await client.fetchVideoDetails(for: urlString)

// Response structure
struct LoadifyResponse {
    let platform: Platform  // .instagram, .facebook, .tiktok, .twitter
    let user: UserDetails?  // Optional user info
    let video: VideoDetails // Required video info
    
    struct VideoDetails {
        let url: String        // Direct video URL
        let size: Double?      // Video file size (optional)
        let thumbnail: String  // Thumbnail URL
    }
    
    struct UserDetails {
        let name: String?               // Creator name
        let profileImage: String?       // Profile image URL
        let profileImageSmall: String?  // Small profile image URL
    }
}

enum Platform: String {
    case instagram
    case facebook
    case tiktok
    case twitter
}
```

**Error Handling**:
- Throws `TiTokError.invalidTikTokURL` for invalid TikTok URLs
- Throws general Swift errors for network/parsing failures
- Has built-in mock responses for testing: `.mockTikTok`, `.mockInstagram`, `.mockFacebook`, `.mockTwitter`

**Alternatives Considered**:
- Manual API integration per platform → Rejected: Requires API keys, rate limiting complexity, maintenance burden
- Web scraping → Rejected: Fragile, legal concerns, unreliable
- Third-party service (Embedly, Iframely) → Rejected: Additional cost, privacy concerns, network dependency

**Implementation Notes**:
- Typical response time: 1-2 seconds
- Show progress indicator after 3 seconds per spec requirement
- Cache metadata locally to avoid duplicate fetches
- Map LoadifyResponse to Chill's VideoMetadata model
- Handle optional user.name with fallback to "Unknown creator"
- **CLARIFIED (2025-10-04)**: Initial spec stated "Facebook + YouTube + Twitter", but LoadifyEngine does NOT support YouTube. Final decision: **Facebook + Twitter only** (subset of LoadifyEngine capabilities). This aligns with the original intent for supporting 2 major platforms while using LoadifyEngine's proven extraction capabilities.
- Future enhancement: TikTok and Instagram support can be added later (both supported by LoadifyEngine)

---

### 2. URL Validation Patterns

**Decision**: Platform-specific regex validators with normalization

**Rationale**:
- Real-time validation requires fast, client-side checks
- Each platform has distinct URL patterns
- Normalization prevents duplicate detection issues
- Shortened URLs (youtu.be, fb.watch, t.co) need special handling

**Platform Patterns** (Facebook + Twitter only):

**Facebook**:
```swift
// Standard: facebook.com/{user}/videos/{id}
// Watch: facebook.com/watch/?v={id}
// Short: fb.watch/{id}
// Mobile: m.facebook.com/...
let facebookPattern = #"^(https?://)?(www\.|m\.)?(facebook\.com/([\w.]+/videos/|watch/\?v=)|fb\.watch/)[\w-]+"#
```

**Twitter**:
```swift
// Standard: twitter.com/{user}/status/{id}
// X.com: x.com/{user}/status/{id}
// Mobile: mobile.twitter.com/...
let twitterPattern = #"^(https?://)?(www\.|mobile\.)?(twitter\.com|x\.com)/[\w]+/status/\d+"#
```

**Normalization Strategy**:
- Convert to lowercase
- Remove tracking parameters (?utm_*, ?fbclid=, etc.)
- Expand shortened URLs to canonical form for duplicate detection
- Strip www., m., mobile. prefixes

**Validation Strategy**:
- Validate against Facebook and Twitter patterns only
- Reject all other platforms with clear error message: "Only Facebook and Twitter videos are supported"
- Future: Can add TikTok/Instagram patterns when those platforms are enabled

**Alternatives Considered**:
- Single universal regex → Rejected: Too permissive, false positives
- URL scheme detection only → Rejected: Doesn't catch invalid paths
- Server-side validation only → Rejected: Requires round-trip, poor UX for real-time feedback

---

### 3. SwiftUI Modal Sheet Presentation with Keyboard Management

**Decision**: Use `.sheet(isPresented:)` with `.interactiveDismissDisabled(false)` and `.presentationDetents([.medium])`

**Rationale**:
- Native SwiftUI sheet provides expected modal behavior
- `.presentationDetents([.medium])` keeps modal compact, above keyboard
- `.interactiveDismissDisabled(false)` allows swipe-to-dismiss per spec
- `@FocusState` automatically manages keyboard and input focus
- Backdrop tap dismissal works automatically

**Implementation Pattern**:
```swift
@State private var showAddVideo = false
@FocusState private var urlFieldFocused: Bool

var body: some View {
    VideoListView()
        .sheet(isPresented: $showAddVideo) {
            AddVideoView(onDismiss: { showAddVideo = false })
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
}

// In AddVideoView
TextField("Enter video URL", text: $viewModel.urlInput)
    .focused($urlFieldFocused)
    .onAppear { urlFieldFocused = true }
```

**Keyboard Handling**:
- `@FocusState` triggers keyboard automatically when modal appears
- Modal resizes to stay above keyboard on smaller devices
- Keyboard toolbar with "Done" button for explicit dismissal
- Preserve input when keyboard dismisses

**Alternatives Considered**:
- Custom modal overlay → Rejected: Reinvents platform behavior, accessibility issues
- `.fullScreenCover` → Rejected: Too prominent for single-field input
- `.alert` with TextField → Rejected: Limited styling, poor multi-line support

---

### 4. SwiftData Offline Queue Implementation

**Decision**: Use `@Model` class with `status` enum for pending submissions

**Rationale**:
- SwiftData provides persistent storage with minimal boilerplate
- Query pending submissions on app launch for retry
- Automatic sync with SwiftUI views via `@Query`
- Supports concurrent submissions with unique constraints

**Data Model**:
```swift
@Model
class VideoSubmissionRequest {
    @Attribute(.unique) var id: UUID
    var url: String
    var normalizedURL: String
    var submittedAt: Date
    var status: SubmissionStatus
    var retryCount: Int
    var lastError: String?
    var userID: String
    
    enum SubmissionStatus: String, Codable {
        case pending
        case processing
        case completed
        case failed
    }
}
```

**Queue Strategy**:
- On submission: Create pending request, attempt immediate submission
- On failure: Update status to failed, preserve request
- On app launch: Query all pending/failed requests, retry if online
- On success: Update status to completed, sync to video library
- Cleanup: Delete completed requests after successful sync (retention: 7 days)

**Connectivity Detection**:
```swift
import Network

class ConnectivityMonitor: ObservableObject {
    @Published var isConnected = true
    private let monitor = NWPathMonitor()
    
    func startMonitoring() {
        monitor.pathUpdateHandler = { path in
            DispatchQueue.main.async {
                self.isConnected = path.status == .satisfied
            }
        }
        monitor.start(queue: DispatchQueue.global())
    }
}
```

**Alternatives Considered**:
- UserDefaults array → Rejected: No type safety, manual serialization, size limits
- File-based queue → Rejected: Manual persistence, concurrency issues
- Core Data → Rejected: More boilerplate than SwiftData, legacy API

---

### 5. Duplicate Detection Strategy

**Decision**: Normalize URLs and check against existing VideoCardEntity.url field

**Rationale**:
- Simple equality check after normalization
- Existing video library uses SwiftData `VideoCardEntity`
- Normalization handles different URL formats for same video
- Warning message doesn't block submission (per spec)

**Detection Algorithm**:
```swift
func checkForDuplicate(url: String) async -> Bool {
    let normalized = normalizeURL(url)
    let descriptor = FetchDescriptor<VideoCardEntity>(
        predicate: #Predicate { $0.url == normalized }
    )
    let results = try? modelContext.fetch(descriptor)
    return !(results?.isEmpty ?? true)
}

func normalizeURL(_ url: String) -> String {
    var normalized = url.lowercased()
    // Remove tracking parameters
    if let index = normalized.firstIndex(of: "?") {
        normalized = String(normalized[..<index])
    }
    // Remove mobile/www prefixes
    normalized = normalized
        .replacingOccurrences(of: "m.youtube", with: "youtube")
        .replacingOccurrences(of: "www.", with: "")
        .replacingOccurrences(of: "mobile.", with: "")
    // Convert short URLs to canonical form
    normalized = normalized
        .replacingOccurrences(of: "youtu.be/", with: "youtube.com/watch?v=")
        .replacingOccurrences(of: "fb.watch/", with: "facebook.com/watch/?v=")
    return normalized
}
```

**Warning Display**:
- Check on URL validation (debounced 500ms after typing stops)
- Show warning icon and message: "⚠️ Already in your library"
- Keep "Add Video" button enabled (per spec)
- Log duplicate attempt for analytics (without URL content)

**Alternatives Considered**:
- Video ID extraction and comparison → Rejected: Platform-specific, complex
- Hash-based deduplication → Rejected: Doesn't help user recognize duplicate
- Block duplicate submissions → Rejected: Spec allows re-adding with updated metadata

---

## Architecture Decisions

### MVVM Structure

**AddVideoView** (SwiftUI View):
- Presents modal UI
- Binds to ViewModel published properties
- Handles keyboard focus state
- Displays validation feedback and errors

**AddVideoViewModel** (ObservableObject):
- Manages URL input state
- Orchestrates validation, duplicate check, submission
- Coordinates with services (URLValidator, AddVideoService, VideoSubmissionQueue)
- Publishes UI state (loading, error, validation result)

**URLValidator** (Stateless Service):
- Platform detection
- Regex validation
- URL normalization

**AddVideoService** (Service):
- LoadifyEngine integration
- Metadata extraction
- Supabase submission
- Error handling

**VideoSubmissionQueue** (Service):
- SwiftData persistence
- Retry logic
- Connectivity monitoring

### State Machine

```
Idle → Validating → Valid/Invalid
Valid → Submitting → Success/Error
Error → Idle (retry)
Success → Dismissed
```

---

## Performance Considerations

- **Real-time validation**: Debounce 300ms to avoid excessive regex checks
- **Metadata fetch**: Show progress after 3s (per spec), timeout at 10s
- **Modal animations**: 60fps target, use `.animation(.easeInOut(duration: 0.3))`
- **Offline queue**: Background processing, batch retry (max 5 concurrent)
- **Duplicate check**: Index VideoCardEntity.url for fast lookups

---

## Accessibility Considerations

- **VoiceOver labels**: 
  - Modal: "Add video from URL"
  - Input: "Video URL input field, enter Facebook, YouTube, or Twitter video link"
  - Validation: Announce "Valid URL" / "Invalid URL format"
  - Error: Announce error message immediately
- **Dynamic Type**: All text scales, modal adjusts height
- **Reduced Motion**: Respect `.accessibilityReduceMotion`, use opacity fades instead of slides
- **Color Contrast**: Validation icons (checkmark green, warning orange) meet WCAG AA

---

## Open Questions (Resolved)

All questions resolved via /clarify session:
- ✅ Platform support: Facebook, YouTube, Twitter
- ✅ Metadata handling: Auto-fetch via LoadifyEngine
- ✅ Duplicate strategy: Warn and allow
- ✅ Batch support: Single URL only
- ✅ Rate limiting: None (client-side)

---

**Status**: Research complete, ready for Phase 1 (Design & Contracts)
