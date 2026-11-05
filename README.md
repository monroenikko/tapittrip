# TapItTrip

TapItTrip is an offline-first Flutter and Laravel travel companion. The repository is currently in **M0 — repo and infrastructure**; product features are not implemented yet.

## Repository layout

- `api/` — Laravel JSON API and Laravel Sail environment
- `client/` — Flutter mobile application (`com.tapittrip.app`)
- `docs/` — product, architecture, API contract, feature, and delivery records

## Laravel API with Sail

Use Docker, Bash, and OpenSSL on the host. Run backend PHP, Composer, Artisan, formatter, analysis, and test commands through Laravel Sail; Laravel Herd and host PHP/Composer are not required.

From `api/`, bootstrap a clean checkout:

```sh
bash bin/configure-local
bash bin/bootstrap
./vendor/bin/sail up -d
./vendor/bin/sail composer install --no-interaction --prefer-dist
./vendor/bin/sail artisan key:generate --no-interaction
./vendor/bin/sail --profile tools run --rm --no-deps migrate
```

Open `http://127.0.0.1:8088/api/v1/health`. The expected response is:

   ```json
   {"data":{"status":"ok"}}
   ```

Interactive Swagger API documentation is available locally at:
- `http://127.0.0.1:8088/docs` (interactive UI)
- `http://127.0.0.1:8088/docs/openapi.yaml` (raw contract)

Useful checks from `api/`:

```sh
./vendor/bin/sail pint --test
./vendor/bin/sail artisan test --compact
bash bin/test-postgres
./vendor/bin/sail --profile tools run --rm --no-deps contracts
./vendor/bin/sail composer validate --strict
./vendor/bin/sail composer audit
```

Stop the stack without deleting its database and Redis volumes:

```sh
./vendor/bin/sail down
```

`bin/bootstrap` runs an official Composer container as the host UID/GID, mounting only Composer metadata and `vendor/`. Application autoloading and scripts run afterwards in Sail. The same scripts are used in CI.

`bin/configure-local` creates runtime credentials in `api/.env` and privileged credentials in ignored root `.local/postgres.env` and `.local/migrate.env`. These privileged files are outside the API bind mount. The migration service receives only migration credentials; the API receives only runtime credentials. Never run `config:cache` in the migration container or put privileged secrets in `api/`. This is local development tooling, not a production deployment definition.

Existing M0 workspaces: `bin/configure-local` preserves the original generated database passwords while moving privileged values out of `.env`. It does not rotate roles or delete volumes. It leaves existing provisioning files intact on repeated runs. For custom quoted or shell-special password values, transfer them manually before running the helper. Initialization scripts run only on new database volumes; `bin/test-postgres` explicitly provisions the isolated `tapittrip_test` database for older volumes too.

The UUID upgrade preserves bigint user/session relationships using a deterministic mapping. It fails atomically if existing orphan sessions prevent adding the foreign key. New users receive UUIDv7 identifiers. There is no safe automatic rollback to bigint after UUID writes; use a forward migration. See [architecture decisions](docs/decisions/0002-m0-runtime-and-identity.md).

Boost MCP uses `api/bin/boost-mcp`, with checked-in settings for generic MCP, Codex, Cursor, and Gemini/Antigravity. Start Sail first and launch the editor from the repository root or `api/`; the launcher supports either working directory and does not start containers implicitly.

Gemini/Antigravity uses the same Boost-generated skills as Codex (`api/.agents/skills`). The root `.agents/skills.json` registers them for sessions opened at the repository root, excluding Boost's `laravel-best-practices` because the repository-curated root version takes precedence. The workspace plugin `.agents/plugins/laravel-boost/` exposes the Boost MCP server; `api/.agents/mcp_config.json` is Boost's Antigravity convention so `boost:update` detects and maintains it.

## Mobile application

Flutter is the accepted mobile framework ([ADR 0001](docs/decisions/0001-mobile-framework.md)) with application ID and iOS bundle ID `com.tapittrip.app`.

From `client/`, run:

```sh
flutter pub get
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
```

See [the KOS entry point](docs/kos/README.md) and [milestone log](docs/milestone-log.md) for authoritative scope and delivery status.

