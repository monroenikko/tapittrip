# TapItTrip API

This directory contains the TapItTrip Laravel JSON API and its Laravel Sail development environment. Run backend commands here through `./vendor/bin/sail`; Laravel Herd and host PHP/Composer are not supported runtime paths.

See the repository [README](../README.md) for setup, [`AGENTS.md`](AGENTS.md) for API-specific working rules, and the committed [OpenAPI contract](../docs/api/openapi.yaml) for implemented HTTP behavior.

The current M0 endpoint is `GET /api/v1/health`. Authentication, trips, and other product behavior are not implemented yet.
