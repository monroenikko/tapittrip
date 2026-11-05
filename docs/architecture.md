# TapItTrip architecture

## Implemented M0 foundation

The sole Laravel backend is `api/`. Sail runs its HTTP process, PostgreSQL/PostGIS, and Redis. The versioned health endpoint has no persistence or provider dependencies. No authentication or trip endpoints exist yet.

The API mounts only `api/` and reads runtime credentials from its ignored `.env`. Root `.local/` holds separate PostgreSQL provisioning and migration environment files. A short-lived migration service receives migration credentials. Boost runs inside the API container via a non-TTY MCP launcher. See [ADR 0002](decisions/0002-m0-runtime-and-identity.md).

## Planned application boundaries

Flutter widgets consume Riverpod application state and repositories. Drift is the source of truth for offline-capable features; repositories coordinate local storage and Dio HTTP sources. A local mutation and durable outbox entry commit in the same transaction.

Laravel routes pass validated/authorized requests through thin controllers into application actions. Policies enforce trip membership, PostgreSQL enforces relational constraints, and API resources control serialization. Provider adapters isolate external systems. Introduce each boundary only when its feature needs it.

Before the first offline mutation, settle operation identity, aggregate versioning, retry results, pull cursor ordering, tombstones, conflict responses, and logout/account-switch isolation. A sequence allocated before commit must not cause later pulls to skip an earlier uncommitted change; cursor design needs explicit concurrency tests. M6 hardens this mechanism.

## Verification boundaries

- Fast PHPUnit suite: health HTTP behavior without a database.
- PostgreSQL suite: runtime DML, UUID identities, foreign keys, forbidden DDL/role escalation, PostGIS queries, and absence of privileged credential files inside the runtime.
- Migration suite: preserves legacy IDs and relationships in a transaction within a dedicated test schema.
- Contract container: OpenAPI semantic validation and live JSON response schema validation.

## Remaining M0 gaps

Flutter shell is scaffolded and verified with package ID `com.tapittrip.app` ([ADR 0001](decisions/0001-mobile-framework.md)). Swagger UI and PHP static analysis remain open. Repository is connected to remote `https://github.com/monroenikko/tapittrip.git`. See the [milestone log](milestone-log.md), not this document, for current verification results.
