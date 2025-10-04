# Phase 1 Quickstart — Welcome Screen With Login and Signup

1. **Check out branch**
   ```bash
   git checkout 001-welcome-screen-with
   ```
2. **Open the project in Xcode**
   ```bash
   open /Users/jin/Code/Chill/Chill.xcodeproj
   ```
3. **Run UI preview**
   - In `WelcomeView.swift`, use `#Preview` to verify dynamic type sizes (≧ExtraExtraExtraLarge) and reduced-motion states.
4. **Run unit + snapshot tests**
   ```bash
   xcodebuild test \
     -project /Users/jin/Code/Chill/Chill.xcodeproj \
     -scheme Chill \
     -destination 'platform=iOS Simulator,name=iPhone 16'
   ```
5. **Manual accessibility smoke test**
   - Launch simulator, enable VoiceOver, ensure buttons announce "coming soon" status and do not navigate.
6. **Review analytics backlog item**
   - Confirm no new logging is introduced; create ticket to enable telemetry when authentication ships.
7. **Plan UI end-to-end coverage later**
   - UI automation for the welcome flow is deferred until Supabase authentication is implemented; reintroduce UITests when the full flow is ready.
