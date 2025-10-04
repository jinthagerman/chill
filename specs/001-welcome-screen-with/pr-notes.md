# PR Notes — Welcome Screen With Login and Signup

- References: [Spec](spec.md), [Plan](plan.md)
- Feature flag `WelcomeExperienceEnabled` remains OFF by default; include launch argument `--enable-welcome-experience` when validating.
- Unit, snapshot, and UI tests target: `WelcomeViewModelTests`, `WelcomeViewSnapshotTests`, `WelcomeFlowUITests`.
- Manual QA checklist captured in `quickstart.md` and rollout toggle guidance in `rollout-notes.md`.
