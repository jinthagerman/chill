# AddVideo Feature

**Status**: Setup Complete (Phase 3.1)  
**Branch**: 004-implement-add-video

## Structure

```
AddVideo/
├── Models/              # Data models (VideoSubmissionRequest, VideoMetadata, etc.)
├── Services/            # Business logic (URLValidator, AddVideoService, VideoSubmissionQueue)
├── ViewModels/          # ViewModels (AddVideoViewModel)
├── Views/               # SwiftUI views
│   ├── Components/      # Reusable components (VideoPreviewCard, MetadataSection)
│   ├── AddVideoInputView.swift
│   ├── AddVideoConfirmationView.swift
│   └── AddVideoCoordinator.swift
└── README.md           # This file
```

## Test Coverage

```
ChillTests/AddVideo/     # Unit and integration tests
ChillUITests/AddVideo/   # UI automation tests
```

## Dependencies

- LoadifyEngine.xcframework (metadata extraction)
- SwiftSnapshotTesting (snapshot tests)
- Supabase Swift SDK (backend integration)
- SwiftData (offline queue)

## Design Reference

- See `/specs/004-implement-add-video/design-specs.md` for visual specifications
- See `/specs/004-implement-add-video/ui-contract.md` for behavior contracts

## Next Steps

- Phase 3.2: Write failing tests (T004-T017)
- Phase 3.3: Implement core functionality
- Phase 3.4: Integration with VideoListView
- Phase 3.5: Polish and validation
