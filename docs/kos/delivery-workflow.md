# Planning, Testing, and Code Review

Use this workflow for both Laravel API and Flutter mobile work. Scale the detail to the risk; a small slice should have a small plan.

## 1. Plan

Before implementation, state:

- the current approved milestone and the single traveler outcome being delivered;
- in-scope and explicitly out-of-scope behavior;
- affected API, local database, server database, sync, security, privacy, localization, accessibility, and offline contracts;
- acceptance scenarios, including loading, empty, error, permission-denied, and offline/stale states where relevant;
- automated tests to add and exact verification commands expected to run;
- assumptions, credentials, provider access, migrations, or decisions that could block completion.

Prefer a vertical slice that can be demonstrated and rolled back independently. Do not create speculative abstractions for later milestones.

## 2. Develop

- Implement the domain rule and contract before presentation details that depend on it.
- Keep external providers behind interfaces with deterministic fakes.
- Treat retries, idempotency, authorization, timezones, money minor units, and sensitive-data logging as design inputs rather than cleanup tasks.
- Preserve local-first rendering and durable outbox behavior for offline-capable mutations once sync work begins.
- Update OpenAPI, migrations, environment examples, and ADRs in the same slice when their contract changes.

## 3. Test

Choose the narrowest tests that prove the behavior, then add boundary coverage where risk justifies it.

### Backend

- Unit-test domain rules and deterministic ranking or conflict behavior.
- Feature-test request validation, policy isolation, serialization, idempotency, database effects, and safe error envelopes.
- Use provider fakes; do not make live third-party calls in the default suite.
- Verify migrations in both directions when rollback is supported and safe.

### Mobile

- Unit-test domain/application state, repository behavior, mapping, and sync decisions.
- Widget-test accessibility semantics and loading, empty, error, offline, stale, and success states.
- Integration-test only critical cross-layer journeys such as durable offline edits and reconnect.
- Use an in-memory or isolated local database and deterministic clocks/providers where practical.

Run the installed project’s formatter, analyzer/static analysis, and tests. Report skipped or blocked checks with the precise reason.

## 4. Review

Review the final diff as if it were a pull request. Resolve high-risk findings before style improvements.

1. Scope: stays inside the approved milestone and avoids unrelated churn.
2. Correctness: acceptance cases and failure paths match contracts and timezone/currency rules.
3. Security/privacy: authorization is enforced server-side; inputs are validated; sensitive data is minimized, encrypted as designed, and absent from logs/notifications.
4. Offline/sync: local state, outbox durability, retries, idempotency, conflicts, and stale indicators are coherent.
5. API/data: OpenAPI, migrations, indexes, constraints, compatibility, and rollout/rollback notes agree.
6. Mobile UX: accessibility, localization, responsive layout, minimal navigation, and all four starting modes remain viable without requiring an itinerary.
7. Tests/operations: assertions prove behavior, fakes are deterministic, environment variables are documented without values, and observability avoids PII.

Finish by updating `docs/milestone-log.md` with the completed slice, exact command results, limitations, open issues, and next smallest task. Stop at the milestone boundary.

