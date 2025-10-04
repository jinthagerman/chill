# PR Notes — Supabase Login & Signup

## Summary
- integrate Supabase Auth via `AuthService` and `SupabaseAuthClient`, including session publisher + secure sign-out.
- Add MVVM-driven authentication flow (`AuthViewModel`, `AuthView`) with login, sign up, and OTP reset screens.
- Introduce `SavedLinksView` placeholder and update `ContentView` coordinator to route between Welcome, Auth, and Saved states.
- Wire analytics (`auth_sign_in`, `auth_sign_up`, `auth_password_reset`) with latency measurements and error buckets.
- Monitor reachability with `NWPathMonitor` to gate submissions offline.

## Testing
- `xcodebuild test -project Chill.xcodeproj -scheme Chill -destination 'platform=iOS Simulator,name=iPhone 16'`
- Manual verification: sign up, verify email path, returning session launch, OTP reset.
- Confirm analytics output in Console (`subsystem: com.bitcrank.Chill`, `category: Auth`).
