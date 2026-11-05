# ADR 0002: M0 runtime, credential isolation, and identity

- Status: Accepted for the M0 remediation authorized on 2026-11-04
- Scope: local backend foundation; no production hosting or authentication approval

## Context

The initial scaffold mixed provisioning secrets into the API environment, launched MCP with host PHP, used integer user IDs despite the UUID requirement, and tested only a database-free health response.

## Decision

- Keep one Laravel modular monolith and the planned Flutter client. Use Sail for every backend runtime command, including Boost MCP.
- Store ignored provisioning files outside `api/`. Only PostgreSQL receives admin credentials; a one-off migration service receives migration credentials. The runtime has a single PostgreSQL connection and no privileged connection configuration.
- Set `DB_URL` to empty in the migration service, ensuring runtime URL overrides cannot replace its dedicated credentials. Do not cache privileged config into the shared source mount.
- Preserve the original migrations and add a transactional forward conversion of bigint user IDs and matching session references to UUID. Existing integers map injectively to a 128-bit UUID representation; new users use Laravel's UUIDv7 support. Session foreign keys cascade on user deletion.
- Keep fast database-free tests separate from PostgreSQL integration tests. Use a distinct test database, runtime-role tests, and a dedicated schema for transactional migration-upgrade fixtures.
- Validate the full OpenAPI specification and the live response using an isolated validator container with only contract/check files mounted.

## Consequences

Docker control and the host filesystem remain privileged trust boundaries; local isolation does not protect against a compromised host. Production must independently inject secrets and provide deploy-only migration jobs.

UUID migration changes internal identity values; no public identity endpoint has shipped. Existing orphan sessions cause the migration to fail and roll back; investigate them rather than deleting them automatically. Rollback to bigint is intentionally unsupported after new UUID writes.

The initial user/cache/job tables remain framework scaffold. Domain modules, auth, policies, offline storage, and sync are still future approved slices. Do not create generic services merely to wrap the health endpoint.

## Verification

See the [milestone log](../milestone-log.md) for commands and observed results. CI runs the same bootstrap, PostgreSQL, formatting, health, dependency, and contract checks as local development.
