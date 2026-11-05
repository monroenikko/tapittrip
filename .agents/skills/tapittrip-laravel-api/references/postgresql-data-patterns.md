# PostgreSQL and PostGIS Data Patterns

Apply these patterns to the Laravel backend in root `api/`. The approved direction is PostgreSQL with PostGIS, UUID identifiers, explicit constraints, and offline-sync support. Inspect the installed versions before using version-specific SQL or Laravel schema-builder features.

## Core principles

- Let PostgreSQL enforce durable invariants with types, `NOT NULL`, `CHECK`, `UNIQUE`, `EXCLUDE`, and foreign keys. Application validation improves errors but is not the integrity boundary.
- Design tables around domain ownership, authorization paths, sync aggregates, and observed queries—not API response nesting.
- Keep migrations forward-safe and reviewable. Never experiment against or mutate production data without explicit approval and a rollout/rollback plan.
- Prefer normalized columns for identity, relationships, filtering, sorting, authorization, conflicts, and reporting. Use `jsonb` only where flexible structure is genuinely valuable.
- Treat schema, migrations, factories, tests, OpenAPI, and mobile mappings as one contract.

## Naming and table baseline

- Use lowercase `snake_case`, plural table names, descriptive constraint/index names, and no quoted mixed-case identifiers.
- Use `uuid` primary keys for mutable/domain records. Accept client-generated UUIDs for offline creation only after format, ownership, and idempotency validation.
- Do not depend on UUID sort order for chronology. Store and index explicit timestamps/server sequences.
- Add `created_at` and `updated_at` to mutable records, `deleted_at` only when soft deletion/tombstones are part of the domain, and a positive `version` for synchronized aggregates.
- Set nullability deliberately. Most required domain fields should be `NOT NULL`; `null` must have a documented meaning distinct from empty/unknown/default.
- Name foreign-key delete behavior explicitly. Use cascade only when the child has no valid life outside its owner; use restrict/no-action when deletion requires a domain workflow.

Illustrative shape only:

```sql
CREATE TABLE stays (
    id uuid PRIMARY KEY,
    trip_id uuid NOT NULL REFERENCES trips(id) ON DELETE CASCADE,
    name text NOT NULL,
    check_in_at timestamptz,
    timezone text NOT NULL,
    version bigint NOT NULL DEFAULT 1 CHECK (version > 0),
    created_at timestamptz NOT NULL,
    updated_at timestamptz NOT NULL,
    deleted_at timestamptz
);

CREATE INDEX stays_trip_active_check_in_idx
    ON stays (trip_id, check_in_at)
    WHERE deleted_at IS NULL;
```

Adapt this to approved migrations and queries; do not copy it as an unreviewed schema.

## Data types

- **Instants:** use `timestamptz`; write/read UTC and retain an IANA timezone column when local display or calendar rules matter.
- **Local calendar values:** use `date` or `time` only when the value is intentionally not an instant, such as a stay-local check-in date. Document conversion rules.
- **Money:** use signed `bigint` minor units plus a validated uppercase ISO currency code. Do not use floating point or PostgreSQL `money`.
- **Names, addresses, URLs, codes:** normally use `text` plus validation/checks where the database invariant is stable. Do not choose arbitrary `varchar(n)` without a product/protocol limit.
- **Statuses/types:** prefer application enums backed by `text` plus a named `CHECK` when values may evolve. Use a PostgreSQL enum only for a truly stable set with a deliberate migration strategy.
- **Counts/order/version:** choose `smallint`, `integer`, or `bigint` from realistic range and growth; add nonnegative/positive checks where required.
- **Sensitive ciphertext:** use the type required by the encryption format (`bytea` or encoded text), store key/version metadata, and never assume encrypted values remain searchable.
- **Case-insensitive identity:** normalize explicitly. Adding `citext` or expression indexes is an extension/schema decision, not an automatic default.

## Trip and tenant integrity

- Every trip-scoped table must have an unambiguous authorization path to its trip. Include `trip_id` directly when it materially improves policy checks, sync queries, partitioning/retention, or integrity.
- Prevent a child from referencing a parent in another trip. Where both IDs are stored, enforce same-trip membership with a composite unique key on the parent `(trip_id, id)` and a composite foreign key from the child `(trip_id, parent_id)`.
- Scope business uniqueness to its owner, such as `(trip_id, operation_id)` or another approved aggregate key, instead of assuming global uniqueness where the domain does not require it.
- Index referencing foreign-key columns used for joins, authorization, and parent deletes; PostgreSQL does not automatically create every referencing-side index.
- Laravel Policies remain mandatory. PostgreSQL row-level security is optional defense in depth and requires an ADR covering connection identity, queue/jobs, migrations, admin access, pooling, and tests before adoption.

## Constraints and deletes

- Use `NOT NULL` plus `CHECK` together when null must be rejected and the value constrained.
- Use `UNIQUE`, foreign keys, or exclusion constraints for cross-row/table invariants. Do not write `CHECK` constraints that inspect other rows/tables.
- Use named checks for stable row invariants such as nonnegative counts, valid date ordering, latitude/longitude bounds, and positive versions.
- Choose `ON DELETE` and `ON UPDATE` behavior explicitly. Test deletion/cancellation flows and ensure soft-deleted parents do not leave visible or authorized orphans.
- Soft delete only when restore, audit, or sync tombstones require it. Define retention and hard-purge behavior; do not add `deleted_at` mechanically to every table.

## Offline sync persistence

- Use a monotonically increasing server sequence/cursor for pull ordering. Do not use `updated_at` alone as a sync cursor because timestamps can collide or change semantics.
- Keep client `operation_id` UUIDs unique at the intended scope and persist processing result so retries return the prior outcome rather than repeating side effects.
- Use an aggregate `version` for optimistic concurrency. Update with the expected base version and return a conflict when no row matches.
- Persist entity changes, version/sequence changes, and durable server outbox/event records atomically when downstream processing depends on them.
- Preserve deletion tombstones long enough for supported offline clients to observe them; document purge and cursor-expiry recovery.
- Store provider/import payload fragments only when needed, validated, encrypted if sensitive, and governed by retention. Never make opaque JSON the authoritative sync model.

Illustrative optimistic update:

```sql
UPDATE trips
SET name = :name,
    version = version + 1,
    updated_at = :now
WHERE id = :id
  AND owner_id = :owner_id
  AND version = :base_version;
```

Treat zero affected rows as not-found/unauthorized/conflict according to a safe lookup policy; do not leak another user's record existence.

## Index and query pattern

- Add indexes for demonstrated access paths: foreign-key joins, trip/member authorization, active-record lists, sync cursors, due jobs, idempotency, and provider identifiers.
- Prefer B-tree for equality/range/order queries. Use GiST/SP-GiST/GIN/BRIN only for operators and data shapes that justify them.
- Order multicolumn B-tree keys from leading equality/scope columns toward range/sort columns, based on actual predicates. Avoid redundant permutations and very wide indexes.
- Use partial indexes for frequently queried subsets such as active/non-deleted or pending records when the query predicate matches.
- Use unique constraints for integrity rather than a non-unique index plus application checks.
- Add GIN indexes to `jsonb` only for specific operators/queries. Every index increases write, vacuum, storage, and migration cost.
- Confirm important queries using `EXPLAIN (ANALYZE, BUFFERS)` with production-like synthetic volume outside production transactions. Do not optimize from row counts in an empty development database.
- Review pagination stability. Use deterministic ordering and cursor/keyset pagination for large/changing collections where offset semantics are inadequate.

## Transactions and concurrency

- Keep transactions short and database-only. Never wait for network providers, file uploads, email, push, or AI inside a transaction.
- Use the default isolation level unless a demonstrated invariant requires another level. Document and test any stronger isolation.
- Prefer optimistic version checks for offline edits. Use `SELECT ... FOR UPDATE`/Laravel locking only when a specific read-modify-write invariant needs row locking.
- Lock rows in a consistent order to reduce deadlocks. Catch and boundedly retry deadlock/serialization failures only when the whole operation is safe to retry.
- Never hide transaction boundaries inside low-level helpers when callers need to compose operations. The application service/action normally owns the use-case transaction.
- Dispatch jobs/events after commit when consumers require committed data, and make consumers idempotent.

## Migration and rollout pattern

For a compatibility-sensitive change, use **expand → migrate/backfill → switch → contract**:

1. Add nullable columns/tables/indexes or backward-compatible structures.
2. Deploy code that can read/write both old and new forms when needed.
3. Backfill in bounded, restartable batches with progress and load monitoring.
4. Validate constraints and data, then switch reads/writes.
5. Remove old fields/paths only after all supported clients and rollback windows are clear.

Additional rules:

- Inspect generated SQL and lock impact. A syntactically small migration can rewrite or lock a large table.
- Add `NOT NULL` only after existing rows are valid. For large tables, consider PostgreSQL validation techniques supported by the installed version and deployment tooling.
- Build large production indexes concurrently when appropriate, remembering PostgreSQL concurrent index creation cannot run inside a normal transaction block; isolate and document the operation.
- Do not combine destructive schema changes with the first release that stops using them.
- Laravel `down()` methods must not pretend dropped/transformed production data is recoverable. Prefer a forward corrective migration when rollback would lose data.
- Back up before material/destructive migrations and verify the restore process, not merely backup creation.

## PostGIS pattern

- Enable PostGIS explicitly in infrastructure/migrations and verify extension availability; do not assume hosted environments permit extensions.
- Use `geography(Point, 4326)` for global earth-distance/radius queries when its semantics fit. Use `geometry` with an explicit SRID for planar/regional operations and provider geometries that require it.
- Choose one canonical coordinate representation. If latitude/longitude and a spatial column coexist, define how drift is prevented and tested.
- Add a GiST spatial index only when spatial predicates need it; continue using ordinary indexes for provider IDs, country, trip scope, and other attributes.
- Validate longitude/latitude/SRID, use parameterized spatial functions, and disclose provider/source/freshness. Precise private coordinates remain sensitive even when indexed.

## JSONB pattern

- Use `jsonb` for bounded metadata, provider snapshots, or evolving external fields—not core relationships, authorization, money, time, status, or frequently filtered domain fields.
- Define an application schema/version, size limit, allowed keys, validation, encryption/retention, and migration path for each JSONB payload.
- Promote stable queried fields to typed columns. Avoid deeply coupled SQL paths into volatile provider payloads.

## Security and operations

- Use separate least-privilege runtime, migration, worker, and read-only/analytics roles where operations support them. The runtime role must not own the database or create extensions.
- Restrict schema `CREATE`, control `search_path`, use parameter binding, and require encrypted connections in non-local environments.
- Keep credentials outside source, rotate them, and avoid PII in query logs, slow-query samples, fixtures, dumps, and support exports.
- Encrypt sensitive application fields as designed. If lookup is required, use a separately reviewed keyed hash/token strategy; never weaken encryption merely to index ciphertext.
- Configure connection limits/pooling, statement and lock timeouts, slow-query monitoring, autovacuum/`ANALYZE`, disk/replication alerts, backups, retention, and periodic restore drills before production.
- Never run `EXPLAIN ANALYZE`, bulk fixes, vacuum tuning, or destructive SQL against production without explicit approval and operational safeguards.

## Testing and review gates

- Run migrations on a fresh database and from the previous supported schema; test rollback only where it is safe and claimed.
- Feature-test foreign keys, uniqueness, checks, delete behavior, cross-trip rejection, optimistic conflicts, idempotent retries, and tombstone/cursor behavior.
- Test PostGIS calculations with known synthetic coordinates and correct SRIDs; do not assert live provider results.
- Seed enough synthetic data to inspect critical query plans and pagination order.
- Review SQL injection/parameter binding, transaction duration, lock order, query count, N+1 behavior, index write cost, migration locks, retention, and backup/restore impact.
- Keep schema dumps/definitions reproducible according to the chosen Laravel workflow and fail CI on unexpected migration/schema drift.

## Avoid

- Missing foreign keys because “Laravel validates it.”
- Global uniqueness when uniqueness is actually trip/user/provider scoped.
- Indexing every column, redundant multicolumn indexes, or JSONB GIN indexes without query evidence.
- Floating money, timestamp-without-time-zone for instants, and timestamps as the only sync cursor.
- Cross-table `CHECK` constraints, triggers containing ordinary application workflows, or hidden business rules only in observers.
- Long transactions containing network work, unbounded backfills, and lock-heavy migrations in ordinary deploys.
- Raw provider payloads as the primary domain schema or real PII in seeds/tests.
- Enabling row-level security, partitioning, read replicas, or sharding without an ADR and demonstrated operational need.

## Official references

- [PostgreSQL constraints](https://www.postgresql.org/docs/current/ddl-constraints.html)
- [PostgreSQL indexes](https://www.postgresql.org/docs/current/indexes.html)
- [PostgreSQL transaction isolation](https://www.postgresql.org/docs/current/transaction-iso.html)
- [PostgreSQL explicit locking](https://www.postgresql.org/docs/current/explicit-locking.html)
- [PostgreSQL row security](https://www.postgresql.org/docs/current/ddl-rowsecurity.html)
- [PostGIS manual](https://postgis.net/docs/)
- [Laravel database migrations](https://laravel.com/docs/migrations)

