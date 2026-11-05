# TapItTrip API Documentation

[`openapi.yaml`](openapi.yaml) is the machine-readable contract for implemented HTTP behavior. It uses OpenAPI 3.1 and is the single input for Swagger UI, contract linting, generated examples, and future client generation.

The file currently documents the implemented M0 health endpoint. An endpoint appears in the contract only when its milestone is approved and the implementation and tests exist in the same slice.

## Contract workflow

For every API change:

1. Confirm the approved milestone and affected feature document.
2. Define the path, operation ID, tags, authentication, parameters, request body, responses, examples, and error cases in OpenAPI.
3. Implement validation, policy authorization, domain behavior, resources, and persistence.
4. Add feature tests that cover the documented success and failure responses.
5. Validate the OpenAPI file and review it against the implementation.
6. Update the feature document, migration/rollout notes, and milestone log.

Use synthetic examples only. Never place real tokens, booking references, private coordinates, accommodation details, document contents, or other user data in the specification.

## API documentation standards

- Base path: `/api/v1`; version breaking changes deliberately.
- JSON operations use stable `operationId` values and feature-oriented tags.
- Document every response that clients must handle, including validation, unauthenticated, unauthorized, not found, conflict, rate-limit, and server errors when applicable.
- Reuse named schemas for stable envelopes and domain objects after their shape is approved; do not create vague catch-all objects.
- Show required and nullable fields accurately. Document IANA timezone meaning, UTC instants, currency codes, and integer minor units.
- Document pagination, filters, sort order, idempotency headers, optimistic-version fields, sync cursors, and stale/freshness metadata where used.
- Describe server-side authorization. Hiding an action in the mobile UI is never the authorization control.
- Mark deprecated behavior in OpenAPI and document compatibility and removal direction before changing clients.
- Do not describe provider data as live unless the implementation has a fresh, attributed source.

## Swagger UI

Swagger UI reads directly from the committed [`docs/api/openapi.yaml`](openapi.yaml) to eliminate contract drift.

- **Interactive Swagger UI**: [`http://127.0.0.1:8088/docs`](http://127.0.0.1:8088/docs)
- **Raw OpenAPI Spec**: [`http://127.0.0.1:8088/docs/openapi.yaml`](http://127.0.0.1:8088/docs/openapi.yaml)
- **Local/development**: available out-of-the-box via Sail.
- **CI**: validates syntax and semantic compliance on every build.
- **Production**: disabled by default pending explicit access authorization.

## Implemented operations

- `GET /api/v1/health` — unauthenticated liveness response; it deliberately omits database, cache, version, environment, and configuration details.

Swagger UI is a rendering and exploration surface; `openapi.yaml`, implementation, and executable contract tests determine correctness.

