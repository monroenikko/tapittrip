# API health

## Status and milestone

- Status: Implemented backend slice
- Milestone: M0 — repo and infrastructure
- OpenAPI operation: `getHealth` in [`../api/openapi.yaml`](../api/openapi.yaml)

## Purpose and flow

The endpoint provides a minimal liveness signal for local development, CI, and future deployment probes. A caller sends `GET /api/v1/health` and receives HTTP 200 with `{"data":{"status":"ok"}}` while the Laravel process is available.

This is not a traveler-facing feature and it does not authenticate a user, read trip data, or prove that PostgreSQL, Redis, or third-party providers are ready.

## API and persistence

The versioned route invokes a stateless controller and performs no database, cache, queue, file, or provider operation. Its exact JSON envelope is covered by a feature test and the committed OpenAPI schema.

## Offline and security implications

- Mobile offline behavior is unaffected; clients must not use this endpoint as the source of truth for locally saved data.
- The response intentionally reveals no framework version, environment name, host details, dependency state, credentials, or user information.
- The route is public so infrastructure can call it, but it performs no mutation and exposes only a fixed value.
- A future readiness endpoint, if required, must be separately approved and must avoid leaking dependency details.

## Verification

From `api/`, run:

```sh
./vendor/bin/sail artisan test --compact tests/Feature/HealthEndpointTest.php
```

## Limitations and direction

Swagger UI is not yet wired to the committed OpenAPI file. Health monitoring, readiness checks, authentication, trips, and offline synchronization are outside this slice.

