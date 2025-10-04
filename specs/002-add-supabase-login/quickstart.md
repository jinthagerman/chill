# Phase 1 Quickstart — Supabase Login and Signup

1. **Check out branch**
   ```bash
   git checkout 002-add-supabase-login
   ```
2. **Start Supabase local stack (if testing locally)**
   ```bash
   cd /Users/jin/Code/Chill/supabase
   supabase start
   ```
   - Ensure `.env.local` exposes `SUPABASE_URL` and `SUPABASE_ANON_KEY` for the iOS app scheme.
3. **Configure runtime credentials**
   - Preferred: add `SUPABASE_URL` and `SUPABASE_ANON_KEY` to the Chill scheme's run environment. The app automatically prefers those variables when present.
   - Alternate: populate `Chill/Chill/Resources/Config/SupabaseConfig.plist` with the same keys. The file ships empty—avoid committing secrets.
4. **Run unit + snapshot tests**
   ```bash
   xcodebuild test \
     -project /Users/jin/Code/Chill/Chill.xcodeproj \
     -scheme Chill \
     -destination 'platform=iOS Simulator,name=iPhone 16'
   ```
5. **Manual auth verification**
   - Launch the app, create a new user, confirm verification email via Supabase dashboard, log back in, and ensure the placeholder SavedLinksView appears (static content with bookmark glyph + copy).
   - Exercise password reset OTP flow end to end. OTP entry is `textContentType(.oneTimeCode)` enabled for autofill.
6. **Monitor analytics + Supabase dashboard**
   - `AuthAnalytics` logs `auth_sign_up`, `auth_sign_in`, and `auth_password_reset` events with latency buckets. Use Console (`subsystem: com.bitcrank.Chill category: Auth`) or forward to your telemetry sink.
   - Confirm Supabase Auth logs and email templates fire as expected; capture anomalies for observability tickets.
7. **Shutdown Supabase services (optional)**
    ```bash
    supabase stop
    ```
