# Chill

A SwiftUI iOS application for discovering and managing curated video content, built with a focus on accessibility, offline resilience, and a calm user experience.

## Overview

Chill is a native iOS app that provides a card-based video browsing experience with Supabase-powered authentication and real-time content updates. The app emphasizes privacy, accessibility, and graceful offline behavior.

## Features

### Implemented

- **Welcome Experience** - Clean onboarding screen with branding and call-to-action buttons
- **Supabase Authentication** - Email/password signup and login with secure session management
- **Card-Based Video List** - Scrollable video cards with rich metadata (thumbnails, titles, creators, duration)
- **Real-Time Updates** - GraphQL subscriptions for live content synchronization
- **Offline Support** - Cached content browsing and queued updates during connectivity loss
- **Accessibility** - Full VoiceOver support, Dynamic Type, and WCAG 2.1 AA compliance

### Coming Soon

- Video playback
- Saved links management
- Profile customization
- Content filtering and search

## Tech Stack

- **Language**: Swift 6 (Xcode 16)
- **UI Framework**: SwiftUI with MVVM architecture
- **Backend**: Supabase (Postgres + GraphQL + Auth)
- **Local Storage**: SwiftData for offline caching
- **Secure Storage**: Keychain (via Supabase SDK)
- **Testing**: XCTest with snapshot and contract testing

## Project Structure

```
Chill/
├── App/                      # App initialization and coordination
│   ├── ChillApp.swift        # App entry point with SwiftData setup
│   ├── AuthConfiguration.swift
│   └── AuthCoordinator.swift
├── Features/                 # Feature modules (MVVM slices)
│   ├── Auth/                 # Authentication flows
│   ├── Welcome/              # Welcome screen
│   ├── VideoList/            # Card-based video browsing
│   └── SavedLinks/           # Saved content (placeholder)
├── Support/
│   ├── DesignSystem/         # Colors, typography, spacing tokens
│   └── Resources/
│       ├── Config/           # Configuration files
│       └── Localizable.strings
└── Assets.xcassets/          # Design assets and colors

ChillTests/                   # Unit and snapshot tests
ChillUITests/                 # UI automation tests

supabase/
├── config.toml               # Supabase project configuration
└── migrations/               # Database schema migrations

specs/                        # Feature specifications and planning
docs/                         # Release notes and QA documentation
```

## Getting Started

### Prerequisites

- macOS 15.0+ (Sequoia or later)
- Xcode 16+ with Swift 6 toolchain
- iOS 18.0+ target device or simulator
- Supabase account (for backend services)

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd Chill
   ```

2. **Open in Xcode**
   ```bash
   open Chill.xcodeproj
   ```

3. **Configure Supabase**
   - Copy your Supabase project URL and anon key
   - Update `Chill/App/AuthConfiguration.swift` with your credentials
   - Run database migrations from `supabase/migrations/`

4. **Build and Run**
   - Select your target device/simulator
   - Press `Cmd + R` to build and run

### Running Tests

```bash
# Unit and snapshot tests
xcodebuild test -scheme Chill -destination 'platform=iOS Simulator,name=iPhone 15'

# UI tests
xcodebuild test -scheme ChillUITests -destination 'platform=iOS Simulator,name=iPhone 15'
```

## Development Workflow

### Architecture Principles

- **MVVM Pattern**: Views bind to ViewModels; ViewModels coordinate with Services
- **Feature Slices**: Each feature lives in its own namespace with dedicated tests
- **Design System**: All UI components use shared tokens from `DesignSystem/`
- **Calm UX**: Non-blocking loading states, graceful error recovery, minimal motion
- **Offline-First**: Cache data locally, queue updates, maintain usability without connectivity

### Design System

Chill uses a centralized design system with:
- **Colors**: Defined in `Assets.xcassets` color sets
- **Typography**: Shared text styles in `DesignSystem/`
- **Spacing**: Consistent padding and margin tokens
- **Components**: Reusable SwiftUI views following brand guidelines

### Feature Development

Features follow a structured development process documented in `specs/`:

1. **Specification** (`spec.md`) - User-focused requirements
2. **Planning** (`plan.md`) - Technical approach and architecture
3. **Research** (`research.md`) - Design decisions and alternatives
4. **Data Model** (`data-model.md`) - Entity definitions
5. **Contracts** (`contracts/`) - API and UI behavior contracts
6. **Tasks** (`tasks.md`) - Implementation checklist

See `AGENTS.md` for active technologies and recent changes.

## Contributing

### Code Style

- Follow standard Swift conventions and Swift 6 strict concurrency
- Use `// MARK:` comments to organize code sections
- Write descriptive variable names (avoid abbreviations)
- Add inline documentation for public APIs
- Ensure all code passes SwiftLint checks

### Testing Requirements

- **Unit Tests**: Cover all ViewModels and Services
- **Contract Tests**: Validate UI behavior contracts
- **Snapshot Tests**: Verify visual consistency
- **Accessibility Tests**: Ensure VoiceOver compatibility

### Commit Guidelines

- Write clear, descriptive commit messages
- Reference feature branch IDs (e.g., `001-welcome-screen-with`)
- Keep commits focused on single logical changes
- Run tests before committing

## Privacy & Security

- **No PII Logging**: Credentials and personal data never logged
- **Secure Storage**: Auth tokens stored in iOS Keychain
- **Privacy-First Analytics**: Only aggregated, anonymized metrics
- **Offline Privacy**: No tracking during offline sessions

## Accessibility

Chill is committed to WCAG 2.1 AA compliance:

- **VoiceOver**: Full screen reader support with descriptive labels
- **Dynamic Type**: Respects user font size preferences
- **Color Contrast**: Meets minimum contrast ratios
- **Reduced Motion**: Respects system animation preferences
- **Switch Control**: Full keyboard/switch navigation support

## License

[License information to be added]

## Support

For questions or issues:
- Review feature specs in `specs/`
- Check release notes in `docs/releases/`
- Review QA documentation in `docs/qa/`

---

**Built with ❄️ by the Chill team**
