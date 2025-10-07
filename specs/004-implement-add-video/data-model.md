# Data Model: Add Video via URL Modal

**Feature**: 004-implement-add-video  
**Date**: 2025-10-04  
**Status**: Complete

## Overview

This document defines the data entities, relationships, validation rules, and state transitions for the Add Video via URL Modal feature.

---

## Entities

### 1. VideoSubmissionRequest

**Purpose**: Tracks user-initiated video URL submissions, including offline queued requests awaiting retry.

**Storage**: SwiftData local persistence

**Fields**:
| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| `id` | UUID | Primary key, unique | Unique identifier for submission |
| `url` | String | Required, max 2048 chars | Original URL as entered by user |
| `normalizedURL` | String | Required, indexed | Normalized URL for duplicate detection |
| `submittedAt` | Date | Required | Timestamp of submission |
| `status` | SubmissionStatus | Required | Current state (pending/processing/completed/failed) |
| `retryCount` | Int | Default 0, max 3 | Number of retry attempts |
| `lastError` | String? | Optional | Most recent error message for diagnostics |
| `userID` | String | Required | Authenticated user identifier |
| `metadata` | VideoMetadata? | Optional | Cached metadata from LoadifyEngine |

**Relationships**:
- None (self-contained submission record)
- References existing VideoCardEntity on successful completion

**Validation Rules**:
- `url` must match supported platform pattern (Facebook, YouTube, Twitter)
- `normalizedURL` must be computed from `url` via normalization function
- `retryCount` increments on each failed attempt, max 3 before giving up
- `status` transitions follow state machine (see State Transitions)

**State Transitions**:
```
pending → processing → completed (success path)
pending → processing → failed (error path, retry eligible if retryCount < 3)
failed → processing (retry attempt)
processing → failed (timeout/network error)
completed (terminal state, cleanup after 7 days)
```

**SwiftData Model**:
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
    var metadata: VideoMetadata?
    
    init(url: String, normalizedURL: String, userID: String) {
        self.id = UUID()
        self.url = url
        self.normalizedURL = normalizedURL
        self.submittedAt = Date()
        self.status = .pending
        self.retryCount = 0
        self.userID = userID
    }
}

enum SubmissionStatus: String, Codable {
    case pending      // Created, awaiting processing
    case processing   // LoadifyEngine fetch in progress
    case completed    // Successfully added to library
    case failed       // Error occurred, may retry
}
```

---

### 2. VideoMetadata

**Purpose**: Structured metadata extracted from video URLs via LoadifyEngine.

**Storage**: Embedded in VideoSubmissionRequest, then persisted to VideoCardEntity on success

**Fields**:
| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| `title` | String | Required, max 200 chars | Video title |
| `description` | String? | Optional, max 1000 chars | Video description/summary |
| `thumbnailURL` | String | Required | URL to video thumbnail image |
| `creator` | String | Required, max 100 chars | Video creator/channel name |
| `platform` | VideoPlatform | Required | Source platform (facebook/youtube/twitter) |
| `duration` | Int? | Optional, seconds | Video duration in seconds |
| `publishedDate` | Date? | Optional | Original publication date |

**Validation Rules**:
- `title` must not be empty after LoadifyEngine extraction
- `thumbnailURL` must be valid HTTP/HTTPS URL
- `creator` defaults to "Unknown creator" if missing (per spec)
- `platform` must match detected platform from URL validation

**Codable Struct**:
```swift
struct VideoMetadata: Codable {
    var title: String
    var description: String?
    var thumbnailURL: String
    var creator: String
    var platform: VideoPlatform
    var duration: Int?
    var publishedDate: Date?
    
    enum VideoPlatform: String, Codable {
        case facebook
        case youtube
        case twitter
    }
}
```

---

### 3. URLValidationResult

**Purpose**: Result of URL format and platform validation (ephemeral, not persisted).

**Storage**: In-memory only (AddVideoViewModel state)

**Fields**:
| Field | Type | Description |
|-------|------|-------------|
| `isValid` | Bool | True if URL matches supported platform pattern |
| `platform` | VideoPlatform? | Detected platform (facebook/youtube/twitter) |
| `errorMessage` | String? | User-facing error message if invalid |
| `normalizedURL` | String? | Normalized URL for duplicate check |

**Validation Logic**:
```swift
struct URLValidationResult {
    var isValid: Bool
    var platform: VideoPlatform?
    var errorMessage: String?
    var normalizedURL: String?
    
    static func validate(_ url: String) -> URLValidationResult {
        // Apply platform regex patterns
        // Return isValid=true with platform + normalizedURL
        // Or isValid=false with errorMessage
    }
}
```

**Error Messages**:
- Invalid format: "Please enter a valid video URL"
- Unsupported platform: "Only Facebook, YouTube, and Twitter videos are supported"
- Empty input: (no error, button disabled)

---

### 4. AddVideoEvent

**Purpose**: Telemetry event for analytics tracking modal interactions (non-persisted, sent to analytics).

**Storage**: Not persisted locally, sent directly to analytics service

**Fields**:
| Field | Type | Description |
|-------|------|-------------|
| `eventType` | EventType | Type of event (open/submit/cancel/error) |
| `timestamp` | Date | Event occurrence time |
| `outcome` | EventOutcome? | Result (success/failure/cancelled) |
| `errorType` | ErrorType? | Category of error if applicable |
| `platform` | VideoPlatform? | Detected platform (anonymized) |
| `isDuplicate` | Bool | True if duplicate warning shown |

**Privacy Constraints**:
- NO URL content logged (per spec FR-014)
- NO user identifiers beyond session hash
- Aggregated for metrics only

**Event Types**:
```swift
enum EventType: String {
    case modalOpened      // User tapped FAB
    case urlSubmitted     // User tapped "Add Video"
    case modalCancelled   // User dismissed modal
    case validationError  // Invalid URL format
    case submissionError  // LoadifyEngine or network failure
}

enum EventOutcome: String {
    case success
    case failure
    case cancelled
}

enum ErrorType: String {
    case invalidFormat
    case unsupportedPlatform
    case networkTimeout
    case metadataExtractionFailed
    case duplicateWarning
    case offlineQueued
}
```

---

## Relationships

```
VideoSubmissionRequest
    └─ contains → VideoMetadata (embedded)
    └─ creates → VideoCardEntity (on completion)

AddVideoViewModel
    └─ produces → URLValidationResult (ephemeral)
    └─ manages → VideoSubmissionRequest (via service)
    └─ emits → AddVideoEvent (to analytics)

VideoSubmissionQueue
    └─ queries → VideoSubmissionRequest (pending/failed)
    └─ retries → VideoSubmissionRequest (increments retryCount)
```

---

## Computed Properties

### URL Normalization

**Purpose**: Convert varied URL formats to canonical form for duplicate detection.

**Algorithm**:
1. Convert to lowercase
2. Remove tracking parameters (?utm_*, ?fbclid=, etc.)
3. Strip www., m., mobile. prefixes
4. Expand shortened URLs (youtu.be → youtube.com/watch?v=)
5. Remove trailing slashes

**Implementation**:
```swift
func normalizeURL(_ url: String) -> String {
    var normalized = url.lowercased()
    
    // Remove query parameters
    if let index = normalized.firstIndex(of: "?") {
        let baseURL = String(normalized[..<index])
        let params = String(normalized[normalized.index(after: index)...])
        // Keep essential params (v=, watch?v=), remove tracking
        let essentialParams = params.split(separator: "&")
            .filter { $0.hasPrefix("v=") }
            .joined(separator: "&")
        normalized = essentialParams.isEmpty ? baseURL : "\(baseURL)?\(essentialParams)"
    }
    
    // Remove prefixes
    normalized = normalized
        .replacingOccurrences(of: "https://", with: "")
        .replacingOccurrences(of: "http://", with: "")
        .replacingOccurrences(of: "www.", with: "")
        .replacingOccurrences(of: "m.", with: "")
        .replacingOccurrences(of: "mobile.", with: "")
    
    // Expand short URLs
    normalized = normalized
        .replacingOccurrences(of: "youtu.be/", with: "youtube.com/watch?v=")
        .replacingOccurrences(of: "fb.watch/", with: "facebook.com/watch/?v=")
    
    return normalized.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
}
```

---

## Lifecycle

### Submission Lifecycle

1. **User Input**:
   - User types/pastes URL into input field
   - Real-time validation (debounced 300ms) → URLValidationResult
   - Duplicate check (if valid) → isDuplicate flag

2. **Submission**:
   - Create VideoSubmissionRequest with status=.pending
   - Persist to SwiftData
   - Attempt immediate processing if online

3. **Processing**:
   - Update status to .processing
   - Call LoadifyEngine.extractMetadata(url)
   - On success: populate metadata, update status to .completed
   - On failure: capture error, update status to .failed, increment retryCount

4. **Retry (if failed)**:
   - On app launch or connectivity restored
   - Query pending/failed requests with retryCount < 3
   - Retry processing
   - Exponential backoff: 1s, 2s, 4s

5. **Cleanup**:
   - Delete completed requests after 7 days
   - Delete failed requests with retryCount >= 3 after 24 hours

---

## Validation Summary

| Field | Required | Format | Range | Default |
|-------|----------|--------|-------|---------|
| VideoSubmissionRequest.url | ✓ | URL string | 1-2048 chars | - |
| VideoSubmissionRequest.normalizedURL | ✓ | Computed | - | - |
| VideoSubmissionRequest.status | ✓ | Enum | pending/processing/completed/failed | pending |
| VideoSubmissionRequest.retryCount | ✓ | Int | 0-3 | 0 |
| VideoMetadata.title | ✓ | String | 1-200 chars | - |
| VideoMetadata.creator | ✓ | String | 1-100 chars | "Unknown creator" |
| VideoMetadata.thumbnailURL | ✓ | URL string | Valid HTTP/HTTPS | - |
| URLValidationResult.isValid | ✓ | Bool | - | false |

---

**Status**: Data model complete, ready for contract generation
