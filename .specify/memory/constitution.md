<!--
Sync Impact Report
Version change: 1.0.0 → 1.1.0
Modified principles: Engineering Guardrails (added MVVM architecture mandate); SwiftUI Experience Integrity (reinforced view-model separation)
Added sections: None
Removed sections: None
Templates requiring updates: ✅ .specify/templates/plan-template.md; ✅ .specify/templates/spec-template.md; ✅ .specify/templates/tasks-template.md (no command templates present)
Follow-up TODOs: None
-->

# Chill Constitution

## Core Principles

### SwiftUI Experience Integrity
- All user-facing features MUST be implemented with SwiftUI first; introducing UIKit or platform bridges requires a documented debt ticket with a rollback plan.
- Every new view MUST include Dynamic Type support, VoiceOver labels, and contrast-safe color usage reviewed in design previews.
- Interactive prototypes MUST ship with SwiftUI previews or UI tests that demonstrate the expected interaction states.
- SwiftUI views MUST remain declarative; state derivation, side effects, and navigation logic live in dedicated view models or coordinators.
Relentlessly enforcing this principle keeps the app cohesive, accessible, and easy to maintain as the design system evolves.

### Calm State & Offline Resilience
- Feature work MUST define explicit state diagrams covering loading, success, empty, and failure states; undefined states block implementation.
- User-affecting data MUST persist locally (SwiftData/Core Data or equivalent) and fall back gracefully when the network is unavailable.
- Asynchronous flows MUST use Swift Concurrency (async/await, actors) with documented main-thread boundaries to prevent race conditions.
This protects user trust by ensuring the app behaves predictably even when connectivity is unreliable.

### Observability With Privacy Guarantees
- Every new capability MUST declare the metrics, structured logs, and critical traces needed for debugging before code is written.
- Logs and analytics MUST exclude personal data or secrets; if context is required, hash or bucketize values and document the retention policy.
- Runtime health signals (alerts, dashboards) MUST be updated when critical paths change so on-call engineers can diagnose incidents quickly.
These safeguards create actionable visibility without compromising user privacy or regulatory obligations.

### Test-First Delivery
- For each change, failing XCTest coverage (unit, integration, or snapshot) MUST exist before implementation; developers may not merge greenfield code without failing tests.
- Tests MUST isolate SwiftUI views, business logic, and persistence boundaries to catch regressions with minimal flakiness.
- CI MUST execute the full test suite on every pull request; flaky cases require immediate mitigation or quarantine with an owner and due date.
This discipline shortens feedback loops and keeps release cadence calm.

### Release Confidence & Support
- Every feature MUST identify the release flag or configuration toggle controlling rollout and document the fallback behavior.
- Automated build pipelines MUST produce signed, archive-ready artifacts and block release if constitution gates fail.
- Customer-impacting incidents MUST trigger a post-release review within five business days with corrective tasks tracked to completion.
Stable releases protect the team’s focus and the customer’s trust.

## Engineering Guardrails

- **Primary stack**: Swift 6 toolchain with SwiftUI and Swift Concurrency; third-party SDKs require approval and a removal plan.
- **Architecture**: Follow MVVM—business logic, data fetching, and state transitions MUST reside in view models; views stay “dumb” renderers wired through observable state.
- **Deployment target**: Match `IPHONEOS_DEPLOYMENT_TARGET` in `Chill.xcodeproj` (currently 26.0); lowering or raising it requires governance review.
- **Accessibility assets**: Store shared colors, typography, and spacing tokens in a dedicated module; reuse them across screens.
- **Persistence**: Prefer SwiftData/Core Data for local models; additive migrations must accompany schema changes.
- **Security**: Secrets MUST live in the Keychain or Secure Enclave abstractions; never hard-code keys or tokens.
- **Build hygiene**: Xcode warnings MUST be treated as errors; linting rulesets must run locally and in CI before merging.

## Workflow Standards

- Capture feature clarifications before `/plan`; unresolved questions from `/spec` block downstream commands.
- Include accessibility, offline state handling, observability, and release toggles in every plan’s Constitution Check.
- `/tasks` outputs MUST place failing tests before implementation work and include tasks for instrumentation, migrations, and operational runbooks.
- Code reviews MUST verify principle adherence explicitly; deviations require annotated debt tickets with mitigation timelines.
- Publish release notes aligned with the Release Confidence principle before distributing a build to testers or App Store Connect.

## Governance

- Amendments require a proposal outlining the change, affected principles, migration impact, and test updates; two maintainers must approve before merging.
- Constitution versions follow semantic rules: MAJOR for incompatible principle changes, MINOR for new principles or sections, PATCH for clarifications.
- Ratified changes MUST update the Synced templates list and notify the team via the #chill-engineering channel within one business day.
- Quarterly audits sample recent plans, specs, tasks, and merged pull requests to verify Constitution compliance; findings drive remediation tasks.
- Non-compliance discovered in production requires an incident review including why Constitution enforcement failed and how safeguards will improve.

**Version**: 1.1.0 | **Ratified**: 2025-10-04 | **Last Amended**: 2025-10-04
