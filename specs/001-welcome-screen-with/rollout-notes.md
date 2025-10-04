# Rollout Notes — Welcome Screen With Login and Signup

## Toggle Overview
- **Feature flag**: `WelcomeExperienceEnabled`
- **Control**: Launch argument `--enable-welcome-experience` (local/testing) or configuration toggle in production build settings.
- **Default state**: OFF (legacy home flow displays).

## Enable Procedure
1. Add `--enable-welcome-experience` to the production scheme or remote configuration.
2. Deploy build to internal testers; confirm VoiceOver, Dynamic Type, and reduced-motion interactions via manual QA checklist.
3. Monitor support channels for confusion around inactive CTAs during the staged rollout.

## Disable / Rollback Procedure
1. Remove the launch argument or flip the remote toggle to `false`.
2. Relaunch the app (no rebuild required); users return to the prior home flow.
3. File incident summary if disabling in response to a customer issue.

## Pre-Release Checklist
- [ ] Capture updated simulator screenshots (light and dark mode) showing coming-soon helper text.
- [ ] VoiceOver announces "Authentication coming soon" for both CTAs.
- [ ] Snapshot, unit, and UI tests pass on CI.
- [ ] Analytics instrumentation ticket scheduled for authentication milestone.
- [ ] Release notes communicate that login/signup will activate in a future update.

## Owner
- Product: TBD  
- Engineering: Welcome Experience feature lead
