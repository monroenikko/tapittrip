# TapItTrip API

This directory contains the TapItTrip Laravel JSON API and its Laravel Sail development environment. Run backend commands here through `./vendor/bin/sail`; Laravel Herd and host PHP/Composer are not supported runtime paths.

See the repository [README](../README.md) for setup, [`AGENTS.md`](AGENTS.md) for API-specific working rules, and the committed [OpenAPI contract](../docs/api/openapi.yaml) for implemented HTTP behavior.

Interactive Swagger API documentation is available locally at:
- `http://127.0.0.1:8088/docs` (interactive UI)
- `http://127.0.0.1:8088/docs/openapi.yaml` (raw contract)

Implemented behavior:
- Health check: `GET /api/v1/health`
- Traveler identity & auth: `POST /api/v1/auth/register`, `POST /api/v1/auth/login`, `POST /api/v1/auth/logout`, `GET/DELETE /api/v1/me`
- Trips CRUD & planning modes: `GET/POST /api/v1/trips`, `GET/PUT/DELETE /api/v1/trips/{id}`
