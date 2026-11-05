# Feature name

- Milestone: `M?`
- Status: `planned | in-progress | implemented | deprecated`
- Owner: `unassigned`
- Last verified: `YYYY-MM-DD`

## Purpose and traveler outcome

Describe the problem, who benefits, and the smallest successful outcome. State what is out of scope.

## How it works

Describe the user flow and important business rules. Include loading, empty, error, offline/stale, permission-denied, accessibility, localization, and no-itinerary behavior when relevant.

## Architecture and data flow

Explain mobile state, repository/data-source boundaries, API/domain services, persistence, provider adapters, queues/events, and sync behavior. Link to accepted ADRs and migrations.

## API contract

Link to the relevant operations and schemas in `docs/api/openapi.yaml`. Document authentication, authorization, validation, idempotency, pagination/versioning, and client-visible errors. Do not duplicate the schema here.

## Security and privacy

List sensitive data, authorization boundaries, storage/encryption, retention/deletion, consent, logging/notification redaction, and abuse cases.

## Offline and conflict behavior

Explain local reads/writes, outbox operations, retries, freshness, conflicts, tombstones, and recovery after restart. If the feature is intentionally online-only, explain the honest fallback.

## Testing and acceptance evidence

List domain, API feature, repository, widget, integration, accessibility, security, and failure-mode coverage. Link to tests and record device/provider limitations.

## Operations and observability

Document configuration names without values, queues/schedules, rate or cost controls, metrics, safe logs, alerts, rollout, rollback, and migration considerations.

## Known limitations

Record current gaps and unavailable providers or credentials without presenting planned behavior as complete.

## Direction

State the next approved smallest improvement and separately list later ideas that still require milestone approval.

