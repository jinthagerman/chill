# Rollout Notes — Supabase Login & Signup

## Launch Checklist
- [ ] Supabase project has email templates updated for verification and OTP copy communicated in-app.
- [ ] `SupabaseConfig.plist` or environment variables populated for Chill release configuration.
- [ ] Analytics pipeline subscribed to `auth_sign_up`, `auth_sign_in`, `auth_password_reset` events; dashboards tagged with release version.
- [ ] Support playbook updated with verification-pending messaging and OTP recovery guidance.
- [ ] Saved session bootstrap validated on a cold install to ensure returning members bypass WelcomeView.

## Monitoring
- Watch Supabase Auth logs for spike in `invalid_credentials` and `over_email_send_rate_limit` error buckets.
- Review Console logs (subsystem `com.bitcrank.Chill`, category `Auth`) for latency regressions >2 s.
- Confirm analytics ingestion after first day—expect sign-in volume to mirror active DAU baseline.

## Rollback Plan
- If Supabase instability occurs, set `route = .welcome` in a hotfix to disable auth surface while WelcomeView CTA copy directs users to status page.
- Supabase project retains existing users; no schema changes shipped with this feature, so rollback is UI only.
