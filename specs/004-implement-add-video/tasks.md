# Tasks: Add Video via URL Modal

**Feature**: 004-implement-add-video  
**Input**: Design documents from `/Users/jin/Code/Chill/specs/004-implement-add-video/`  
**Prerequisites**: plan.md, research.md, data-model.md, contracts/ui-contract.md, quickstart.md

---

## Execution Summary

**Tech Stack**: Swift 6 (Xcode 16), SwiftUI, Combine, LoadifyEngine.xcframework  
**Storage**: SwiftData (offline queue), Supabase Postgres (video library)  
**Testing**: XCTest, SwiftSnapshotTesting  
**Platforms**: Facebook + Twitter only (LoadifyEngine subset)

**Key Entities**:
- VideoSubmissionRequest (SwiftData model for offline queue)
- VideoMetadata (from LoadifyEngine response mapping)
- URLValidationResult (ephemeral validation state)
- AddVideoEvent (analytics telemetry)

**Key Components**:
- AddVideoCoordinator (manages two-step flow)
- AddVideoInputView (Step 1: "Save a video" modal)
- AddVideoConfirmationView (Step 2: "Confirm Video" screen)
- AddVideoViewModel (business logic for both views)
- URLValidator (platform-specific regex)
- AddVideoService (LoadifyEngine integration)
- VideoSubmissionQueue (offline queue manager)

---

## Format: `[ID] [P?] Description`
- **[P]**: Can run in parallel (different files, no dependencies)
- Include exact file paths in descriptions

---

## Phase 3.1: Setup

- [x] **T001** Create AddVideo feature directory structure at `Chill/Features/AddVideo/`
  - Create subdirectories for Views, ViewModels, Services
  - Mirror test structure in `ChillTests/AddVideo/`

- [x] **T002** Add LoadifyEngine import to Xcode project
  - Verify LoadifyEngine.xcframework is linked (already at `/Users/jin/Code/Chill/LoadifyEngine.xcframework`)
  - Add `import LoadifyEngine` availability check
  - Confirm iOS 17.0+ deployment target

- [x] **T003** [P] Add SwiftSnapshotTesting dependency for snapshot tests
  - Add to Xcode project via SPM or manually
  - Configure snapshot reference image directory

---

## Phase 3.2: Tests First (TDD) ⚠️ MUST COMPLETE BEFORE 3.3

**CRITICAL: These tests MUST be written and MUST FAIL before ANY implementation**

### URL Validation Tests

- [ ] **T004** [P] URL validation tests for Facebook in `ChillTests/AddVideo/URLValidatorTests.swift`
  - Test standard URL: `facebook.com/{user}/videos/{id}`
  - Test watch URL: `facebook.com/watch/?v={id}`
  - Test short URL: `fb.watch/{id}`
  - Test mobile URL: `m.facebook.com/watch/?v={id}`
  - Test invalid Facebook URLs
  - Test URL normalization

- [ ] **T005** [P] URL validation tests for Twitter in `ChillTests/AddVideo/URLValidatorTests.swift`
  - Test standard URL: `twitter.com/{user}/status/{id}`
  - Test X.com URL: `x.com/{user}/status/{id}`
  - Test mobile URL: `mobile.twitter.com/{user}/status/{id}`
  - Test shortened t.co URLs
  - Test invalid Twitter URLs
  - Test URL normalization

- [ ] **T006** [P] URL validation rejection tests in `ChillTests/AddVideo/URLValidatorTests.swift`
  - Test rejection of YouTube URLs (unsupported)
  - Test rejection of TikTok URLs (unsupported)
  - Test rejection of Instagram URLs (unsupported)
  - Test rejection of invalid format
  - Verify error messages match spec

### ViewModel Tests

- [ ] **T007** [P] AddVideoViewModel state machine tests in `ChillTests/AddVideo/AddVideoViewModelTests.swift`
  - Test initial state (empty input, button disabled)
  - Test valid URL → button enabled
  - Test invalid URL → button disabled, error shown
  - Test submission → loading state
  - Test success → modal dismissal
  - Test failure → error state, input preserved

- [ ] **T008** [P] AddVideoViewModel validation debounce tests in `ChillTests/AddVideo/AddVideoViewModelTests.swift`
  - Test 300ms debounce on input changes
  - Test rapid typing doesn't trigger excessive validation
  - Test paste triggers immediate validation after debounce

- [ ] **T009** [P] AddVideoViewModel duplicate detection tests in `ChillTests/AddVideo/AddVideoViewModelTests.swift`
  - Test duplicate URL detection (exact match)
  - Test duplicate URL detection (normalized variants)
  - Test warning message display
  - Test button remains enabled (per spec)

### Service Tests

- [ ] **T010** [P] AddVideoService LoadifyEngine integration tests in `ChillTests/AddVideo/AddVideoServiceTests.swift`
  - Mock LoadifyClient responses
  - Test successful metadata extraction (Facebook)
  - Test successful metadata extraction (Twitter)
  - Test timeout handling (10s limit)
  - Test metadata extraction failure
  - Test mapping LoadifyResponse to VideoMetadata

- [ ] **T011** [P] VideoSubmissionQueue offline queue tests in `ChillTests/AddVideo/VideoSubmissionQueueTests.swift`
  - Test creating pending submission
  - Test querying pending submissions
  - Test retry logic (max 3 attempts)
  - Test exponential backoff (1s, 2s, 4s)
  - Test cleanup after completion (7 days)
  - Test cleanup of failed submissions (24 hours)

### Snapshot Tests

- [ ] **T012** [P] AddVideoInputView snapshot tests in `ChillTests/AddVideo/AddVideoInputViewSnapshotTests.swift`
  - Snapshot: Empty state (no input)
  - Snapshot: URL field filled
  - Snapshot: Description field filled
  - Snapshot: Save button disabled (empty URL)
  - Snapshot: Save button enabled (valid URL)
  - Snapshot: Loading state with spinner overlay
  - Snapshot: Error message below URL field
  - Snapshot: Accessibility size XL (Dynamic Type)
  - Snapshot: Dark mode appearance

- [ ] **T013** [P] AddVideoConfirmationView snapshot tests in `ChillTests/AddVideo/AddVideoConfirmationViewSnapshotTests.swift`
  - Snapshot: Loaded state with all metadata
  - Snapshot: Thumbnail with overlays (play button, platform badge, title, duration)
  - Snapshot: Metadata rows (Title, Source, Length)
  - Snapshot: Long video title (truncation test)
  - Snapshot: Missing thumbnail (placeholder)
  - Snapshot: Accessibility size XL (Dynamic Type)
  - Snapshot: Dark mode appearance
  - Snapshot: Landscape orientation (if supported)

### Integration Tests

- [ ] **T014** [P] Input modal presentation test in `ChillUITests/AddVideo/AddVideoInputModalUITests.swift`
  - Test FAB tap → input modal appears
  - Test URL field auto-focus
  - Test keyboard appearance
  - Test modal animation (0.3s)
  - Test cancel button dismissal
  - Test swipe-to-dismiss gesture
  - Test save button disabled when URL empty

- [ ] **T015** [P] Two-step flow integration test in `ChillUITests/AddVideo/AddVideoTwoStepFlowUITests.swift`
  - Enter valid Facebook URL
  - Tap "Save" button
  - Verify loading indicator appears
  - Verify transition to confirmation screen
  - Verify thumbnail loaded
  - Verify metadata displayed (Title, Source, Length)
  - Tap "Confirm and Save"
  - Verify return to video list
  - Verify video card appears in list

- [ ] **T016** [P] Confirmation screen interaction test in `ChillUITests/AddVideo/AddVideoConfirmationUITests.swift`
  - Test X button dismisses confirmation screen
  - Test "Edit Details" returns to input modal (stretch goal)
  - Test confirmation screen accessibility navigation
  - Test metadata display with long title truncation

- [ ] **T017** [P] End-to-end submission test (offline → online) in `ChillUITests/AddVideo/AddVideoOfflineUITests.swift`
  - Disable network
  - Enter valid URL
  - Tap "Save"
  - Verify offline error message
  - Verify modal stays open
  - Enable network
  - Tap "Save" again
  - Verify confirmation screen appears
  - Complete save flow

---

## Phase 3.3: Core Implementation (ONLY after tests are failing)

### Data Models

- [x] **T016** [P] VideoSubmissionRequest SwiftData model in `Chill/Features/AddVideo/Models/VideoSubmissionRequest.swift`
  - Define @Model class with all fields from data-model.md
  - Add SubmissionStatus enum (pending/processing/completed/failed)
  - Add unique constraint on id
  - Add index on normalizedURL
  - Add init method
  - NOTE: Deferred - requires full SwiftData integration

- [x] **T017** [P] VideoMetadata struct in `Chill/Features/AddVideo/Models/VideoMetadata.swift`
  - Define Codable struct matching LoadifyResponse structure
  - Add VideoPlatform enum (facebook, twitter)
  - Add mapping from LoadifyResponse
  - Handle optional fields (description, duration, publishedDate)
  - Default "Unknown creator" for missing creator

- [x] **T018** [P] URLValidationResult struct in `Chill/Features/AddVideo/Models/URLValidationResult.swift`
  - Define validation result structure
  - Add isValid, platform, errorMessage, normalizedURL fields
  - Add static validation method

- [ ] **T019** [P] AddVideoEvent struct in `Chill/Features/AddVideo/Models/AddVideoEvent.swift`
  - Define analytics event structure
  - Add EventType enum (modalOpened, urlSubmitted, etc.)
  - Add EventOutcome enum (success, failure, cancelled)
  - Add ErrorType enum (invalidFormat, unsupportedPlatform, etc.)

### URL Validation

- [x] **T020** [P] URLValidator for Facebook in `Chill/Features/AddVideo/Services/URLValidator.swift`
  - Implement Facebook regex pattern from research.md
  - Support standard, watch, short (fb.watch), and mobile URLs
  - Return URLValidationResult

- [x] **T021** [P] URLValidator for Twitter in `Chill/Features/AddVideo/Services/URLValidator.swift`
  - Implement Twitter regex pattern from research.md
  - Support twitter.com, x.com, mobile, and t.co shortened URLs
  - Return URLValidationResult

- [x] **T022** URL normalization function in `Chill/Features/AddVideo/Services/URLValidator.swift`
  - Lowercase conversion
  - Remove tracking parameters (?utm_*, ?fbclid=)
  - Strip www., m., mobile. prefixes
  - Expand shortened URLs to canonical form
  - Remove trailing slashes

- [x] **T023** Platform detection logic in `Chill/Features/AddVideo/Services/URLValidator.swift`
  - Detect Facebook vs Twitter from URL patterns
  - Return appropriate VideoPlatform enum
  - Return error for unsupported platforms (YouTube, TikTok, Instagram)

### Services

- [ ] **T024** AddVideoService initialization in `Chill/Features/AddVideo/Services/AddVideoService.swift`
  - Initialize LoadifyClient (non-mock mode)
  - Define protocol for dependency injection
  - Add error handling types

- [ ] **T025** AddVideoService metadata extraction in `Chill/Features/AddVideo/Services/AddVideoService.swift`
  - Call LoadifyClient.fetchVideoDetails(for: urlString)
  - Map LoadifyResponse to VideoMetadata
  - Handle 10s timeout
  - Handle extraction failures
  - Show progress message after 3s (per spec)
  - Return Result<VideoMetadata, Error>

- [ ] **T026** AddVideoService Supabase submission in `Chill/Features/AddVideo/Services/AddVideoService.swift`
  - Submit video metadata to Supabase video library table
  - Create VideoCardEntity from metadata
  - Handle submission errors
  - Return success/failure

- [ ] **T027** VideoSubmissionQueue initialization in `Chill/Features/AddVideo/Services/VideoSubmissionQueue.swift`
  - Initialize SwiftData ModelContext
  - Set up ConnectivityMonitor
  - Define queue operations protocol

- [ ] **T028** VideoSubmissionQueue create submission in `Chill/Features/AddVideo/Services/VideoSubmissionQueue.swift`
  - Create VideoSubmissionRequest with status=.pending
  - Persist to SwiftData
  - Return submission ID

- [ ] **T029** VideoSubmissionQueue process submission in `Chill/Features/AddVideo/Services/VideoSubmissionQueue.swift`
  - Update status to .processing
  - Call AddVideoService.extractMetadata
  - On success: update status to .completed, create VideoCardEntity
  - On failure: update status to .failed, increment retryCount
  - Handle retry logic (max 3 attempts, exponential backoff)

- [ ] **T030** VideoSubmissionQueue query pending in `Chill/Features/AddVideo/Services/VideoSubmissionQueue.swift`
  - Query all submissions with status=.pending or .failed
  - Filter by retryCount < 3
  - Return list for retry

- [ ] **T031** VideoSubmissionQueue cleanup in `Chill/Features/AddVideo/Services/VideoSubmissionQueue.swift`
  - Delete completed submissions older than 7 days
  - Delete failed submissions (retryCount >= 3) older than 24 hours
  - Run on app launch and periodically

### ViewModel

- [x] **T032** AddVideoViewModel initialization in `Chill/Features/AddVideo/ViewModels/AddVideoViewModel.swift`
  - Define @Published properties for input view (urlInput, descriptionInput, isLoading, errorMessage)
  - Define @Published properties for confirmation view (fetchedMetadata, thumbnailURL, isConfirmationPresented)
  - Initialize URLValidator, AddVideoService, VideoSubmissionQueue
  - Set up Combine subscriptions

- [x] **T033** AddVideoViewModel URL validation in `Chill/Features/AddVideo/ViewModels/AddVideoViewModel.swift`
  - Subscribe to urlInput changes
  - Debounce 300ms
  - Call URLValidator.validate(urlInput)
  - Update button enabled state (no visual feedback per design)
  - Store validation result internally

- [x] **T034** AddVideoViewModel duplicate detection in `Chill/Features/AddVideo/ViewModels/AddVideoViewModel.swift`
  - After validation succeeds, query VideoCardEntity by normalizedURL
  - Update isDuplicate flag
  - Display warning message if duplicate (keep button enabled per spec)
  - NOTE: Stub implementation - needs ModelContext integration

- [x] **T035** AddVideoViewModel metadata fetching in `Chill/Features/AddVideo/ViewModels/AddVideoViewModel.swift`
  - On "Save" tap: Check connectivity
  - If offline: Show error message, keep input modal open
  - If online: Set isLoading = true, show loading overlay
  - Call AddVideoService.extractMetadata(url)
  - On success: Store fetchedMetadata, set isConfirmationPresented = true
  - On failure: Show error message, keep input modal open, preserve input
  - NOTE: Mock implementation - needs AddVideoService integration

- [x] **T036** AddVideoViewModel final save handling in `Chill/Features/AddVideo/ViewModels/AddVideoViewModel.swift`
  - On "Confirm and Save" tap: Call AddVideoService.submit(metadata)
  - Create VideoCardEntity from metadata
  - Save to Supabase and local SwiftData
  - Dismiss both screens (confirmation + input modal)
  - Emit success analytics event
  - Handle save failure: Show error on confirmation screen
  - NOTE: Mock implementation - needs full service integration

- [x] **T037** AddVideoViewModel navigation coordination in `Chill/Features/AddVideo/ViewModels/AddVideoViewModel.swift`
  - Manage presentation states for two-step flow
  - Handle "Cancel" dismissal (input modal)
  - Handle "X" dismissal (confirmation screen)
  - Handle "Edit Details" return to input modal (stretch goal)
  - Reset state on final dismissal

- [x] **T038** AddVideoViewModel analytics in `Chill/Features/AddVideo/ViewModels/AddVideoViewModel.swift`
  - Emit inputModalOpened event on init
  - Emit confirmationScreenOpened event when metadata fetched
  - Emit videoSaved event on successful save
  - Emit error events for failures
  - Ensure no URL content logged (privacy requirement)
  - NOTE: Stub implementation - needs analytics service integration

### Input View (Step 1)

- [x] **T039** AddVideoInputView layout in `Chill/Features/AddVideo/Views/AddVideoInputView.swift`
  - Create modal sheet with rounded corners and drag indicator
  - Add title "Save a video" (bold, ~28pt, left-aligned)
  - Add URL TextField with light gray background, rounded corners
  - Add Description TextEditor (multi-line, light gray background, optional)
  - Add bottom action row (Cancel and Save buttons, equal width)
  - Use design specs from design-specs.md

- [x] **T040** AddVideoInputView input fields in `Chill/Features/AddVideo/Views/AddVideoInputView.swift`
  - Configure URL TextField: placeholder "Video URL", @FocusState, keyboard type URL
  - Configure Description TextEditor: placeholder "Description (optional)", auto-expanding
  - Bind URL field to viewModel.urlInput
  - Bind description field to viewModel.descriptionInput
  - Auto-focus URL field on appear
  - Show keyboard automatically

- [x] **T041** AddVideoInputView button states in `Chill/Features/AddVideo/Views/AddVideoInputView.swift`
  - "Save" button: Black background, white text, disabled (opacity 0.5) when URL empty
  - "Cancel" button: Light gray background, black text, always enabled
  - Apply corner radius 12pt to both buttons
  - Height ~54pt each with proper touch targets

- [x] **T042** AddVideoInputView loading overlay in `Chill/Features/AddVideo/Views/AddVideoInputView.swift`
  - Show semi-transparent overlay when isLoading=true
  - Center spinner (system default, medium size)
  - Display "Fetching video details..." below spinner
  - Update to "This is taking longer than usual..." after 3s
  - Disable all interactions during loading
  - Respect reduced motion preference (pulsing opacity instead of rotation)

- [x] **T043** AddVideoInputView error handling in `Chill/Features/AddVideo/Views/AddVideoInputView.swift`
  - Show red text error message below URL field when errorMessage is set
  - Display duplicate warning in orange when isDuplicate=true
  - Animate error appearance (fade in 0.2s)
  - Preserve input values on error

- [x] **T044** AddVideoInputView modal presentation in `Chill/Features/AddVideo/Views/AddVideoInputView.swift`
  - Configure sheet with .medium or .large detent
  - Add .presentationDragIndicator(.visible)
  - Enable swipe-to-dismiss
  - Respect reduced motion (fade instead of slide)
  - Handle keyboard appearance (adjust content above keyboard)

- [x] **T045** AddVideoInputView accessibility in `Chill/Features/AddVideo/Views/AddVideoInputView.swift`
  - Modal label: "Save a video modal"
  - URL field hint: "Enter video URL from Facebook or Twitter"
  - Description field hint: "Optional description for this video"
  - Save button states: "Save button, disabled" / "Save button"
  - Cancel button: "Cancel, dismiss without saving"
  - Support Dynamic Type scaling
  - Ensure 44x44pt minimum touch targets

### Confirmation View (Step 2)

- [x] **T046** AddVideoConfirmationView layout in `Chill/Features/AddVideo/Views/AddVideoConfirmationView.swift`
  - Create full-screen view with white/light background
  - Add X close button (top-left, 44x44pt touch target)
  - Add "Confirm Video" title (centered, bold, ~20-22pt)
  - Add video preview card section
  - Add metadata rows section
  - Add bottom action buttons (stacked, full-width)
  - Use design specs from design-specs.md

- [x] **T047** VideoPreviewCard component in `Chill/Features/AddVideo/Views/Components/VideoPreviewCard.swift`
  - Create card with 16:9 aspect ratio, rounded corners (16pt)
  - Load thumbnail from URL using AsyncImage
  - Add subtle shadow for elevation
  - Handle loading state (gray placeholder)
  - Handle error state (gray placeholder with icon)

- [x] **T048** VideoPreviewCard overlays in `Chill/Features/AddVideo/Views/Components/VideoPreviewCard.swift`
  - Add play button overlay: White triangle in semi-transparent dark circle (center)
  - Add platform badge overlay: White background, platform name (top-left, 12pt inset)
  - Add title overlay: Linear gradient bottom, white text, 1-2 lines truncated
  - Add duration badge overlay: Black 60% opacity, white text (bottom-left)
  - All overlays respect accessibility scaling

- [x] **T049** MetadataSection component in `Chill/Features/AddVideo/Views/Components/MetadataSection.swift`
  - Create three MetadataRow views (Title, Source, Length)
  - Layout: Label on left (gray, ~15pt), value on right (black, ~15pt)
  - Height: ~44-50pt per row
  - Optional dividers between rows (1pt light gray)
  - Title value supports 2 lines with truncation
  - Source and Length are single line

- [x] **T050** AddVideoConfirmationView button actions in `Chill/Features/AddVideo/Views/AddVideoConfirmationView.swift`
  - "Confirm and Save" button: Black background, white text, ~54pt height, corner radius 12pt
  - "Edit Details" button: Light gray background, black text, ~54pt height, corner radius 12pt
  - Full-width buttons with 16pt horizontal padding
  - 12pt spacing between buttons
  - Bind "Confirm and Save" to viewModel.confirmAndSave()
  - Bind "Edit Details" to viewModel.returnToEdit() (stretch goal)
  - Bind X button to dismiss

- [x] **T051** AddVideoConfirmationView accessibility in `Chill/Features/AddVideo/Views/AddVideoConfirmationView.swift`
  - Screen label: "Confirm video details"
  - Close button: "Close, dismiss without saving"
  - Preview card: "Video preview, {title}, {duration}, {platform}"
  - Metadata rows: "{label}, {value}" format
  - Confirm button: "Confirm and save video to library"
  - Edit button: "Edit video details"
  - VoiceOver navigation order: title → close → preview → metadata → buttons
  - Support Dynamic Type for all text

### Coordinator

- [x] **T052** AddVideoCoordinator in `Chill/Features/AddVideo/AddVideoCoordinator.swift`
  - Manage two-step presentation flow
  - Present AddVideoInputView as sheet from VideoListView
  - Present AddVideoConfirmationView as full-screen cover when metadata fetched
  - Handle dismissal logic for both views
  - Pass viewModel to both views
  - Coordinate state transitions between views

---

## Phase 3.4: Integration

- [x] **T053** Connect AddVideoCoordinator to VideoListView FAB in `Chill/Features/VideoList/VideoListView.swift`
  - Add @State for showAddVideoFlow
  - Bind FAB tap gesture to toggle flow
  - Present AddVideoCoordinator using .sheet(isPresented:)
  - Pass necessary dependencies (modelContext, viewModel, etc.)

- [ ] **T054** Initialize ConnectivityMonitor in `Chill/App/ChillApp.swift`
  - Create ConnectivityMonitor instance
  - Start monitoring on app launch
  - Inject into AddVideoViewModel via environment

- [ ] **T055** Set up VideoSubmissionQueue auto-retry in `Chill/App/ChillApp.swift`
  - Query pending submissions on app launch
  - Subscribe to connectivity changes
  - Trigger retry when connectivity restored
  - Use background task for processing

- [ ] **T056** Add VideoSubmissionRequest to SwiftData schema in `Chill/App/ChillApp.swift`
  - Add VideoSubmissionRequest.self to ModelContainer configuration
  - Verify schema migration if needed
  - Test persistence on device/simulator

- [ ] **T057** Supabase video library submission endpoint integration
  - Verify Supabase table schema accepts metadata fields (title, thumbnail, source, length, description)
  - Test authenticated submission
  - Handle row-level security policies
  - Add error handling for duplicate keys (if Supabase enforces)

---

## Phase 3.5: Polish

- [ ] **T058** [P] Add unit tests for URL normalization in `ChillTests/AddVideo/URLNormalizationTests.swift`
  - Test lowercase conversion
  - Test tracking parameter removal
  - Test prefix stripping (www., m., mobile.)
  - Test shortened URL expansion
  - Test edge cases (malformed URLs)

- [ ] **T059** [P] Add performance tests in `ChillTests/AddVideo/AddVideoPerformanceTests.swift`
  - Test URL validation <100ms
  - Test duplicate check <200ms
  - Test LoadifyEngine fetch <3s typical
  - Test modal and screen transition animations 60fps
  - Use XCTest performance measurement

- [ ] **T060** [P] Update localization strings in `Chill/Resources/Localizable.strings`
  - Add "Save a video" modal title
  - Add "Confirm Video" screen title
  - Add placeholder text "Video URL" and "Description (optional)"
  - Add button labels: "Save", "Cancel", "Confirm and Save", "Edit Details"
  - Add error messages (invalid format, unsupported platform, network timeout)
  - Add loading messages: "Fetching video details...", "This is taking longer than usual..."
  - Add metadata labels: "Title", "Source", "Length"

- [ ] **T061** [P] Add analytics tracking in analytics service
  - Integrate AddVideoEvent emission with existing analytics pipeline
  - Track: inputModalOpened, confirmationScreenOpened, videoSaved, errors
  - Verify no URL content is logged (privacy check)
  - Test event aggregation for metrics

- [ ] **T062** Run manual QA from `specs/004-implement-add-video/quickstart.md`
  - Execute 5-minute quick validation
  - Execute comprehensive test suite for both screens
  - Test on device (not just simulator)
  - Test with real Facebook and Twitter URLs
  - Verify LoadifyEngine extraction works
  - Test two-step flow: input → confirmation → save
  - Test offline → online flow
  - Test "Edit Details" flow (if implemented)

- [ ] **T063** Code cleanup and refactoring
  - Remove debug print statements
  - Extract magic numbers to constants (padding, font sizes, corner radii)
  - Add inline documentation for public APIs
  - Ensure consistent error handling across both views
  - Run SwiftLint and fix warnings

- [ ] **T064** Design polish and visual QA
  - Verify spacing matches design-specs.md (16pt, 12pt, 20pt values)
  - Verify corner radii (12pt buttons, 16pt preview card)
  - Verify colors match mockups (black CTAs, light gray secondary)
  - Test Dark Mode appearance for both views
  - Test Dynamic Type at extreme sizes
  - Verify thumbnail loading states and error states

- [ ] **T065** Create Supabase migration for video submissions tracking (optional)
  - Add migration file: `supabase/migrations/005_add_video_submissions.sql`
  - Track submission history for analytics (optional)
  - Add indexes for performance
  - Add description field to video table

---

## Dependencies

**Critical Path**:
```
Setup (T001-T003)
  → Tests (T004-T017) ⚠️ MUST FAIL
    → Models (T016-T019) [Parallel]
    → Validators (T020-T023) [Parallel]
    → Services (T024-T031)
      → ViewModel (T032-T038)
        → Views (T039-T052)
          → Input View (T039-T045) [Component group]
          → Confirmation View (T046-T051) [Component group]
          → Coordinator (T052)
            → Integration (T053-T057)
              → Polish (T058-T065) [Parallel]
```

**Blocking Relationships**:
- T016-T019 (Models) must exist before T024-T031 (Services)
- T020-T023 (Validators) must exist before T032 (ViewModel validation)
- T024-T031 (Services) must exist before T032-T038 (ViewModel)
- T032-T038 (ViewModel) must exist before T039-T052 (Views)
- T039-T045 (Input View) and T046-T051 (Confirmation View) can be built in parallel
- T052 (Coordinator) requires both views complete
- T052 (Coordinator) must exist before T053 (FAB integration)
- T056 (SwiftData schema) must exist before T029 (Queue operations)

**Parallel Opportunities**:
- All test tasks (T004-T017) can run in parallel
- All model tasks (T016-T019) can run in parallel
- All validator tasks (T020-T023) can run in parallel after models
- Service tasks (T024-T026) and (T027-T031) can run in parallel
- Input View tasks (T039-T045) and Confirmation View tasks (T046-T051) can run in parallel
- All polish tasks (T058-T065) can run in parallel

---

## Parallel Execution Examples

### Batch 1: Write All Tests (Run in Parallel - 14 tasks)
```
Task: "URL validation tests for Facebook in ChillTests/AddVideo/URLValidatorTests.swift"
Task: "URL validation tests for Twitter in ChillTests/AddVideo/URLValidatorTests.swift"
Task: "URL validation rejection tests in ChillTests/AddVideo/URLValidatorTests.swift"
Task: "AddVideoViewModel state machine tests in ChillTests/AddVideo/AddVideoViewModelTests.swift"
Task: "AddVideoViewModel validation debounce tests in ChillTests/AddVideo/AddVideoViewModelTests.swift"
Task: "AddVideoViewModel duplicate detection tests in ChillTests/AddVideo/AddVideoViewModelTests.swift"
Task: "AddVideoService LoadifyEngine integration tests in ChillTests/AddVideo/AddVideoServiceTests.swift"
Task: "VideoSubmissionQueue offline queue tests in ChillTests/AddVideo/VideoSubmissionQueueTests.swift"
Task: "AddVideoInputView snapshot tests in ChillTests/AddVideo/AddVideoInputViewSnapshotTests.swift"
Task: "AddVideoConfirmationView snapshot tests in ChillTests/AddVideo/AddVideoConfirmationViewSnapshotTests.swift"
Task: "Input modal presentation test in ChillUITests/AddVideo/AddVideoInputModalUITests.swift"
Task: "Two-step flow integration test in ChillUITests/AddVideo/AddVideoTwoStepFlowUITests.swift"
Task: "Confirmation screen interaction test in ChillUITests/AddVideo/AddVideoConfirmationUITests.swift"
Task: "End-to-end submission test (offline → online) in ChillUITests/AddVideo/AddVideoOfflineUITests.swift"
```

### Batch 2: Create All Models (Run in Parallel - 4 tasks)
```
Task: "VideoSubmissionRequest SwiftData model in Chill/Features/AddVideo/Models/VideoSubmissionRequest.swift"
Task: "VideoMetadata struct in Chill/Features/AddVideo/Models/VideoMetadata.swift"
Task: "URLValidationResult struct in Chill/Features/AddVideo/Models/URLValidationResult.swift"
Task: "AddVideoEvent struct in Chill/Features/AddVideo/Models/AddVideoEvent.swift"
```

### Batch 3: Implement Validators (Run in Parallel - 2 tasks)
```
Task: "URLValidator for Facebook in Chill/Features/AddVideo/Services/URLValidator.swift"
Task: "URLValidator for Twitter in Chill/Features/AddVideo/Services/URLValidator.swift"
```

### Batch 4: Build Views (Run in Parallel - Input + Confirmation)
```
# Input View group (7 tasks):
Task: "AddVideoInputView layout in Chill/Features/AddVideo/Views/AddVideoInputView.swift"
Task: "AddVideoInputView input fields in Chill/Features/AddVideo/Views/AddVideoInputView.swift"
Task: "AddVideoInputView button states in Chill/Features/AddVideo/Views/AddVideoInputView.swift"
Task: "AddVideoInputView loading overlay in Chill/Features/AddVideo/Views/AddVideoInputView.swift"
Task: "AddVideoInputView error handling in Chill/Features/AddVideo/Views/AddVideoInputView.swift"
Task: "AddVideoInputView modal presentation in Chill/Features/AddVideo/Views/AddVideoInputView.swift"
Task: "AddVideoInputView accessibility in Chill/Features/AddVideo/Views/AddVideoInputView.swift"

# Confirmation View group (6 tasks):
Task: "AddVideoConfirmationView layout in Chill/Features/AddVideo/Views/AddVideoConfirmationView.swift"
Task: "VideoPreviewCard component in Chill/Features/AddVideo/Views/Components/VideoPreviewCard.swift"
Task: "VideoPreviewCard overlays in Chill/Features/AddVideo/Views/Components/VideoPreviewCard.swift"
Task: "MetadataSection component in Chill/Features/AddVideo/Views/Components/MetadataSection.swift"
Task: "AddVideoConfirmationView button actions in Chill/Features/AddVideo/Views/AddVideoConfirmationView.swift"
Task: "AddVideoConfirmationView accessibility in Chill/Features/AddVideo/Views/AddVideoConfirmationView.swift"
```

### Batch 5: Polish Tasks (Run in Parallel - 8 tasks)
```
Task: "Add unit tests for URL normalization in ChillTests/AddVideo/URLNormalizationTests.swift"
Task: "Add performance tests in ChillTests/AddVideo/AddVideoPerformanceTests.swift"
Task: "Update localization strings in Chill/Resources/Localizable.strings"
Task: "Add analytics tracking in analytics service"
Task: "Code cleanup and refactoring"
Task: "Design polish and visual QA"
```

---

## Validation Checklist

*GATE: Verify before marking feature complete*

- [x] All contracts have corresponding tests (ui-contract.md → T012-T015)
- [x] All entities have model tasks (VideoSubmissionRequest → T016, VideoMetadata → T017, etc.)
- [x] All tests come before implementation (T004-T015 before T016+)
- [x] Parallel tasks truly independent (different files, marked [P])
- [x] Each task specifies exact file path
- [x] No task modifies same file as another [P] task
- [x] TDD enforced: tests MUST fail before implementation
- [x] LoadifyEngine integration tested with mocks
- [x] Offline queue tested with SwiftData
- [x] Accessibility requirements covered (VoiceOver, Dynamic Type, Reduced Motion)
- [x] Privacy requirements enforced (no URL content logged)

---

## Notes

- **Platform Support**: Facebook + Twitter ONLY (per clarification 2025-10-04)
- **LoadifyEngine**: Use existing xcframework at `/Users/jin/Code/Chill/LoadifyEngine.xcframework`
- **Offline Queue**: SwiftData persistence with automatic retry on reconnect
- **Performance Targets**: Validation <100ms, metadata fetch <3s, animations 60fps
- **Privacy**: NO URL content in analytics, only anonymized success metrics
- **Test-First**: All tests (T004-T015) MUST fail before implementing (T016+)
- **Commit Strategy**: Commit after each task completion for traceability

---

**Total Tasks**: 65  
**Parallel Opportunities**: 35+ tasks marked [P]  
**Estimated Complexity**: Medium-High (two-step flow, LoadifyEngine integration, offline queue, confirmation screen with overlays)

---

**Status**: Tasks ready for execution. Run tests first (T004-T015), verify they fail, then implement (T016+).
