# Phase 1 Data Model — Welcome Screen With Login and Signup

## View Models

### WelcomeViewModel
- **Purpose**: Supplies static content, layout state, and accessibility messaging for the welcome surface while exposing a hook for future authentication enablement.
- **State**:
  - `content: WelcomeContent` — localized copy and asset references for the screen.
  - `isAnimatingEntry: Bool` — drives optional intro animation (default `false`, flips to `true` on `onAppear`).
  - `buttonState: ButtonState` — enum representing `.inactive` (current), future `.enabled` values for login/signup.
- **Derived Values**:
  - `primaryButtons: [WelcomeButton]` — computed array describing CTA metadata for the view layer.
  - `welcomeAccessibilityNotice: String` — combined status used in VoiceOver announcements.
- **Side Effects**: None in UI-only release.

### WelcomeButton
- **Fields**:
  - `id: UUID` — stable identifier for ForEach usage.
  - `title: LocalizedStringKey`
  - `role: WelcomeButton.Role` — `.login` or `.signup`.
  - `isActive: Bool` — `false` for this release.
  - `helperText: LocalizedStringKey` — copy explaining inactivity.

### ButtonState (enum)
- `.inactive` — default; view renders helper text and keeps actions local.
- `.active(loginPermitted: Bool, signupPermitted: Bool)` — placeholder for future functionality.

## Content Types

### WelcomeContent
- `headline: LocalizedStringKey`
- `subheadline: LocalizedStringKey`
- `comingSoonHelper: LocalizedStringKey`
- `backgroundImageName: String?`
- `accessibilityMessage: String`

## Assets & Resources
- Marketing imagery stored in `Assets.xcassets/Welcome` namespace.
- Typography and spacing pulled from existing design tokens; create `DesignSystem/Spacing.swift` if missing.

## Persistence & Sync
- None required; state lives entirely in memory.

## Contracts With Other Modules
- Expose `WelcomeViewModel` initializer with overridable `WelcomeContent` for previews and tests.
