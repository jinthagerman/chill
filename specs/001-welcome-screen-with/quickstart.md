# Phase 1 Quickstart — Welcome Screen With Login and Signup

1. **Check out branch**
   ```bash
   git checkout 001-welcome-screen-with
   ```
2. **Open the project in Xcode**
   ```bash
   open /Users/jin/Code/Chill/Chill.xcodeproj
   ```
3. **Enable the feature toggle for local runs**
   - In the active scheme, add the launch argument `--enable-welcome-experience`.
   - For previews or unit tests, you can also invoke `WelcomeExperienceEnabled.setOverride(true)` from the debugger.
4. **Run UI preview**
   - In `WelcomeView.swift`, use `#Preview` to verify dynamic type sizes (≧ExtraExtraExtraLarge) and reduced-motion states.
5. **Run unit + snapshot tests**
   ```bash
   xcodebuild test \
     -project /Users/jin/Code/Chill/Chill.xcodeproj \
     -scheme Chill \
     -destination 'platform=iOS Simulator,name=iPhone 16'
   ```
6. **Manual accessibility smoke test**
   - Launch simulator, enable VoiceOver, ensure buttons announce "coming soon" status and do not navigate.
7. **Review analytics backlog item**
   - Confirm no new logging is introduced; create ticket to enable telemetry when authentication ships.
8. **Plan UI end-to-end coverage later**
   - UI automation for the welcome flow is deferred until Supabase authentication is implemented; reintroduce UITests when the full flow is ready.
