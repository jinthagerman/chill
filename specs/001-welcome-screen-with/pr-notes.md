# PR Notes — Welcome Screen With Login and Signup

- References: [Spec](spec.md), [Plan](plan.md)
- Feature flag `WelcomeExperienceEnabled` remains OFF by default; include launch argument `--enable-welcome-experience` when validating.
- Automated coverage currently includes `WelcomeViewModelTests` and `WelcomeViewSnapshotTests`; re-enable UI automation once Supabase login/signup is in place.
- Manual QA checklist captured in `quickstart.md` and rollout toggle guidance in `rollout-notes.md`.
