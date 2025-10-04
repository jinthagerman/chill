# Manual QA Script — Supabase Auth

## Preconditions
- Test device or simulator configured with Supabase credentials via environment variables or `SupabaseConfig.plist`.
- Supabase dashboard open with access to Auth > Users to verify sign-up and password reset events.

## 1. New Account Creation (Sign Up)
1. Launch Chill (cold start).
2. From WelcomeView, tap **Sign Up**.
3. Enter a fresh email alias and strong password.
4. Accept the consent toggle and submit.
5. **Expected**: Info banner instructs to verify email; no navigation to SavedLinksView until email confirmed.
6. Approve the verification email via Supabase dashboard; relaunch app.
7. **Expected**: SavedLinksView placeholder renders automatically.
8. Capture screenshot: `signup-awaiting-verification.png` (banner visible).
9. Capture screenshot: `saved-links-placeholder.png` after verification.

## 2. Returning Session Launch
1. With previously verified account signed in, kill and relaunch the app.
2. **Expected**: WelcomeView is skipped; SavedLinksView appears within 1 s.
3. Verify analytics log for `auth_sign_in` with `result=success`.
4. Capture screenshot: `returning-session.png`.

## 3. OTP Password Reset Flow
1. From SavedLinksView, terminate the session (delete the app or trigger `AuthCoordinator.signOut()` via debug tools) so WelcomeView is shown on next launch.
2. On WelcomeView, choose **Log In**, then tap **Forgot password?**.
3. Enter existing user email and request reset.
4. **Expected**: Info banner describing OTP entry; mode transitions to verification screen.
5. Retrieve OTP from Supabase dashboard (Auth > Users > Email log).
6. Enter OTP and a new password, submit.
7. **Expected**: `auth_password_reset` analytics event with `phase=verify`, user routed to SavedLinksView.
8. Capture screenshot: `otp-success.png` showing SavedLinksView post reset.

## Notes
- Record timestamps for each submission to confirm latency <2 s; log snippet acceptable in QA doc.
- Attach captured screenshots to release ticket for marketing/support reference.
