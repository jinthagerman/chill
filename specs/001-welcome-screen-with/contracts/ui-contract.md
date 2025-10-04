# UI Contract — Welcome Screen With Login and Signup

## Surface Overview
- **View**: `WelcomeView`
- **View Model**: `WelcomeViewModel`

## Interaction Contract

| Interaction | Precondition | Expected Result | Telemetry |
|-------------|--------------|-----------------|-----------|
| Screen appears | App launches while user is unauthenticated | Welcome content renders with headline, subheadline, imagery, and two enabled buttons with "coming soon" helper text | None |
| Tap "Log In" | User taps button once | Button shows standard press animation; no navigation occurs | None |
| Tap "Sign Up" | User taps button once | Button shows standard press animation; no navigation occurs | None |
| Accessibility focus on CTAs | VoiceOver focus moves to either button | VoiceOver reads button title plus helper hint "Authentication coming soon" | None |

## Visual States
- **Default**: Primary buttons styled per design system with helper text below each.
- **Large Dynamic Type**: Layout switches to vertical stacking with scroll support; helper text remains adjacent to buttons.
- **Reduced Motion**: Skip entry animation; content still fades in.

## Error & Offline Handling
- No error states; offline mode identical to default because no network calls occur.

## Future Hooks
- Placeholder callbacks `onLoginSelected` and `onSignupSelected` in view model remain `nil` until authentication shipped.
