---
name: tapittrip-laravel-api
description: Plan, implement, test, or review TapItTrip Laravel API slices using the repository's service/action, PostgreSQL/PostGIS, modular-monolith, security, offline-sync, and API-contract patterns. Use for backend work under the root api folder; do not use it to authorize a new milestone or live provider integration.
---

# TapItTrip Laravel API

Read `AGENTS.md`, the relevant `MASTER_PLAN.md` sections, `docs/kos/README.md`, `docs/kos/delivery-workflow.md`, and `docs/milestone-log.md`. Inspect installed Laravel/PHP versions and current project conventions before selecting packages or commands.

## Repository location

- The Laravel backend lives at `<repository-root>/api`.
- Laravel Sail is the required backend runtime. Run commands from `api/` through `./vendor/bin/sail`; do not use Laravel Herd or host PHP/Composer.
- Use `./vendor/bin/sail composer ...`, `./vendor/bin/sail artisan ...`, `./vendor/bin/sail pint`, and `./vendor/bin/sail test --compact` for dependency, framework, formatting, and test workflows. Run installed static-analysis binaries through Sail as well.
- If Sail is absent during a clean bootstrap, install it with an official Composer container that mounts only `composer.json`, `composer.lock`, and `vendor/`. Never mount `.env`, credentials, storage, or application data into that bootstrap container.
- Do not create or use `services/api` as an alternative backend root.

## Required implementation pattern

For API creation, service/action design, domain organization, or review, read and apply [`references/application-and-api-patterns.md`](references/application-and-api-patterns.md). Use its default dependency flow unless existing code establishes an equally safe convention. Explain a material deviation in the plan or an ADR rather than mixing patterns silently.

For schema design, migrations, constraints, indexes, transactions, sync persistence, PostGIS, database security, or query review, also read and apply [`references/postgresql-data-patterns.md`](references/postgresql-data-patterns.md). Verify version-specific behavior against the installed PostgreSQL, PostGIS, Laravel, and database-driver versions.

## Plan the slice

- Confirm the approved milestone and define one traveler-visible or contract-visible outcome.
- Trace request, validation, authorization, domain service, persistence, serialization, OpenAPI, and consumer impact.
- Identify idempotency, transaction, queue, timezone, currency, sensitive-data, offline-sync, compatibility, migration, and rollback concerns.
- Name feature and unit tests before coding. Do not plan work for a later milestone as part of the slice.

## Implement

- Keep versioned controllers thin. Use Form Requests for validation, Policies for trip membership/ability checks, one-purpose services under `app/Application/<Feature>/Services` for use-case orchestration, domain services only for genuine framework-independent cross-entity rules, and API Resources for stable responses.
- Model UUID keys, tenant/trip-safe foreign keys, constraints, delete behavior, and query-driven indexes explicitly. Store instants in UTC-aware columns while preserving required IANA timezone context; store money in integer minor units with currency.
- Wrap multi-record invariants in transactions. Dispatch side effects after commit where appropriate. Make retried writes and jobs idempotent.
- Use interfaces/adapters at external provider boundaries and deterministic fakes in tests. Validate and sanitize untrusted provider, upload, URL, OCR, AI, and webhook input.
- Never log secrets, tokens, booking references, private coordinates, or document contents. Keep sensitive fields out of notification payloads and ordinary API resources.
- Update OpenAPI, API examples, the relevant `docs/features/` document, migration notes, and `.env.example` in the same change when affected. Mark planned and implemented behavior distinctly.

## Test and verify

- Unit-test domain rules without HTTP or third-party services.
- Feature-test validation, policy isolation including cross-trip denial, response envelopes, database effects, idempotent retries, and relevant queue/event behavior.
- Use factories and fakes with synthetic data. Add provider contract tests only at adapter boundaries.
- Run the installed formatter, PHPStan/Larastan configuration, and Pest/PHPUnit suite. Discover actual scripts first; do not invent successful commands.

## Review

Review the final diff using `docs/kos/delivery-workflow.md`. Prioritize authorization gaps, mass assignment, unsafe serialization, transaction/race errors, cross-trip relationships, unsafe/destructive migrations, missing constraints/query evidence/indexes, non-idempotent retries, PII leakage, contract drift, and insufficient behavior assertions. Record exact results and remaining limits in `docs/milestone-log.md`, then stop at the milestone boundary.
