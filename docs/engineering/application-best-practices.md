# TapItTrip Application Engineering Best Practices

These practices apply to the Laravel API and Flutter mobile application. They translate `MASTER_PLAN.md` into day-to-day engineering choices without authorizing work beyond the current milestone.

## 1. Build vertical slices

Plan one traveler or engineering outcome across all required layers instead of creating an entire layer in isolation.

For each slice:

1. Confirm the approved milestone and write observable acceptance scenarios.
2. Define or update the OpenAPI and local-data contracts.
3. Implement the smallest backend domain behavior and mobile flow that satisfy the scenarios.
4. Test domain rules, API boundaries, persistence, UI states, offline behavior, and failures proportionate to risk.
5. Review security, privacy, accessibility, localization, performance, compatibility, and operations.
6. Update feature documentation and the milestone log with exact results.

Do not build abstractions for speculative later features. Extract shared code after a real repeated requirement appears and the shared behavior has a stable name.

## 2. Repository and dependency discipline

- Keep a single Laravel service and a single Flutter application during the MVP unless an approved ADR establishes another boundary.
- Use the approved root layout: `api/` for the Laravel backend and `client/` for the Flutter mobile application. Do not create parallel `services/api` or `apps/mobile` roots.
- Pin framework and tool versions through their normal lockfiles. Review dependency health, platform support, license, maintenance, size, security history, and exit cost before adoption.
- Prefer platform/framework capabilities and the approved stack over overlapping packages.
- Keep generated files reproducible. Commit them only when the selected tool and team workflow require it; enforce a no-drift check in CI.
- Never place secrets or environment-specific identifiers in source. Document variable names without values in `.env.example` files.

## 3. Laravel API practices

### Boundaries

- Version public controllers under `/api/v1`; keep controllers responsible for HTTP translation only.
- Use Form Requests for validation and normalization, Policies for trip-scoped authorization, API Resources for response shape, and application/domain services for business rules.
- Organize business behavior by domain capability, not by framework file type alone. Keep external maps, transit, AI, OCR, notification, flight, and storage providers behind interfaces/adapters.
- Do not trust the mobile client for authorization, price/freshness claims, version checks, or sensitive-field filtering.

### Data and consistency

- Use Sail for backend commands. Provisioning credentials stay outside the API mount; migrations run in the separate one-off service described in the root README.

- Use UUIDs, foreign keys, unique constraints, useful indexes, explicit nullability, and tested migrations.
- Store instants in UTC and preserve the relevant IANA timezone. Store money as integer minor units plus ISO currency.
- Use transactions for multi-record invariants. Dispatch irreversible side effects only after commit where applicable.
- Require idempotency for retriable creates, sync operations, webhooks, and queued jobs. Make concurrency and version-conflict behavior explicit.
- Avoid N+1 queries and unbounded collections; paginate and select only fields the response needs.

### Errors and observability

- Return predictable JSON error envelopes with stable machine-readable codes and safe human messages.
- Use structured logs with request/correlation identifiers, but redact tokens, booking references, private coordinates, stay notes, document contents, and provider payloads containing PII.
- Record operational metrics for latency, errors, queue delay, retries, conflicts, provider calls, and rate/cost limits without creating user surveillance.

## 4. Flutter mobile practices

Flutter's official architecture guidance emphasizes separation between UI, application/view-model state, repositories, and services. TapItTrip uses Riverpod to provide and observe those boundaries rather than duplicating a second state-management pattern.

### Feature structure

Keep code feature-first and introduce only the layers a feature needs:

```text
client/lib/
  app/                 # bootstrap, routing, theme, localization
  core/                # network, database, sync, auth, platform services
  features/<feature>/
    presentation/      # widgets/screens and Riverpod UI state
    application/       # orchestration/use cases when needed
    domain/            # stable models and rules when needed
    data/              # repositories, DTO mapping, local/remote sources
  shared/              # genuinely cross-feature UI/utilities
```

Use this internal shape under the approved root `client/` only.

### State and UI

- Keep widgets declarative and free of business/data-access logic. Represent loading, data, empty, refreshing, offline/stale, recoverable error, and terminal error states explicitly.
- Scope Riverpod providers as narrowly as practical and dispose transient state. Use immutable state and predictable commands; avoid global mutable singletons.
- Keep GoRouter routes typed or centrally named, shallow, guarded where required, and restorable from deep links only after hosts/identifiers are approved.
- Use localized strings, semantic labels, logical focus order, scalable text, sufficient contrast, and at least platform-appropriate touch targets.
- Avoid blocking trip creation on optional itinerary, flight, accommodation, or personal-profile data.

### Local-first data and sync

Introduce the minimum sync contract with the first offline write, no later than M2b. M6 is a reliability and concurrency hardening gate for an already working mechanism.

- Treat Drift as the mobile source of truth for offline-capable features. Render local streams first, then refresh through repositories.
- Persist a local mutation and its outbox operation in one transaction. Use stable UUID operation IDs, base versions, retry metadata, and user-visible sync state.
- Let Dio remote data sources translate HTTP only. Repositories coordinate local and remote sources, mapping, caching, retries, and freshness.
- Do not infer connectivity from an HTTP failure or assume a network interface means the internet/provider is reachable.
- Sync on sensible lifecycle/connectivity/user actions rather than an aggressive timer. Make retries bounded with backoff and preserve operations across app termination.
- Never silently overwrite material conflicts. Checklist items may use narrow deterministic rules; itinerary, stay, and sensitive changes require explicit conflict behavior.

### Platform integrations

- Wrap secure storage, notifications, location/geofence, maps, sharing, camera/OCR, and background work behind small interfaces.
- Test with deterministic fakes and verify critical behavior on real Android and iOS devices before claiming support.
- Treat background execution, exact alarms, geofences, permissions, and provider coverage as platform-limited capabilities with honest fallback UI.

## 5. API and mobile contract alignment

- `docs/api/openapi.yaml` is the committed HTTP contract. Update it with the implementation and tests in one slice.
- Generate clients only if generation is reproducible, reviewable, and does not leak transport DTOs into domain/UI code.
- Map API DTOs to local/domain models explicitly. Preserve unknown or forward-compatible enum behavior where the contract requires it.
- Align authentication expiry, pagination, idempotency keys, entity versions, sync cursors, deletion tombstones, error codes, and server-clock assumptions end to end.
- A new required API field needs a backward-compatible rollout or a documented coordinated release plan.

## 6. Testing strategy

### Laravel

- Unit tests: domain rules, ranking, conflicts, value objects, and provider-independent logic.
- Feature tests: validation, authentication, cross-trip policy isolation, serialization, database effects, idempotency, pagination, rate limits, and safe errors.
- Integration/contract tests: database constraints, queues, storage, and provider adapters using controlled fakes or sandboxes.

### Flutter

- Unit tests: application state, mapping, repositories, retry/sync/conflict decisions, and timezone/currency handling.
- Drift tests: migrations, transactions, query behavior, outbox durability, tombstones, and restart recovery using isolated databases.
- Widget tests: loading, empty, offline/stale, errors, permissions, accessibility semantics, large text, localization, and success states.
- Integration/device tests: only critical journeys—startup, authentication, local write/restart, offline edit/reconnect, notification/location permissions, and deep links when approved.

Use deterministic clocks, UUID factories, provider fakes, and synthetic data. A test should prove behavior or a contract, not mirror implementation details.

## 7. Code review checklist

Review high-risk behavior before style:

- Is the change inside the approved milestone and the smallest coherent slice?
- Do API, migration, feature documentation, mobile mapping, and tests agree?
- Is every trip-scoped server operation authorized, including nested resources and files?
- Can retries duplicate data or side effects? Can concurrency lose a newer edit?
- Can offline writes survive process death? Are conflicts and stale data visible?
- Are sensitive values absent from logs, analytics, notifications, URLs, screenshots, and examples?
- Do no-itinerary and all four starting modes remain usable where relevant?
- Are accessibility, localization, timezone, currency, loading, empty, error, and permission states covered?
- Are migrations, rollout, rollback, monitoring, and provider limitations understood?

Block merging on correctness, security, data-loss, privacy, inaccessible critical flows, contract drift, or missing acceptance evidence. Track lower-risk cleanup explicitly rather than hiding it.

## 8. CI and release gates

The M0 CI baseline should eventually run:

- Laravel formatter, static analysis, unit/feature tests, migration checks, and OpenAPI lint/compatibility checks.
- Dart format check, `flutter analyze`, unit/widget tests, generated-code drift checks, and selected integration tests.
- Secret scanning, dependency/security review, license checks, and build artifact creation appropriate to the repository.

Before a beta or store build, also verify real-device permissions/background behavior, offline restart/reconnect, accessibility, localization, privacy disclosures, environment configuration, signed-build ownership, monitoring, rollback, and data migration/restore procedures.

## References

- [Flutter: Guide to app architecture](https://docs.flutter.dev/app-architecture/guide)
- [Flutter: Offline-first support](https://docs.flutter.dev/app-architecture/design-patterns/offline-first)
- [Laravel documentation](https://laravel.com/docs)
- [OpenAPI Specification](https://spec.openapis.org/oas/latest.html)

