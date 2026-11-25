# Offline Sync and Durable Outbox

- Milestone: `M6`
- Status: `implemented` (Hardened multi-device sync, chunked outbox & privacy redaction)
- Owner: `TapItTrip Engineering`
- Last verified: `2026-11-20`

## Purpose and traveler outcome

Travelers frequently experience spotty internet, airplane mode, and disconnected periods while on transit or exploring remote destinations.
TapItTrip provides a seamless offline-first experience:
- **Instant Local Responsiveness**: Travelers can check off packing items, edit trip details, and adjust itineraries without waiting for a server network round-trip.
- **Restart & Reboot Durability**: Offline mutations are written to an encrypted local queue (`OutboxStorage`) using `FlutterSecureStorage`. They survive app termination, memory pressure, and device reboot.
- **Idempotent Retry**: Retrying sync batches never creates duplicate entities or records redundant operations (`operation_id` unique deduplication).
- **Monotonic Sync Cursors**: Changes are ordered strictly sequentially by `server_sequence`, ensuring devices never miss concurrent edits.
- **Interactive Conflict Resolution**: Version mismatches (`base_version < current_version`) trigger clean conflict payloads and an interactive prompt (`ConflictResolutionDialog`), preventing silent data loss.
- **Transparent Traveler Status**: The `SyncStatusIndicator` provides immediate visual confirmation:
  - 🟢 *All changes synced*
  - 🟡 *N changes pending sync* (tap to sync now)
  - 🔴 *Conflict detected* (tap to review and resolve)
  - ⚪ *Offline mode*

## How it works

1. **Offline Mutation Capture**:
   - When offline, any user modification creates an `OutboxOperation` containing a client-generated UUID `operation_id`, entity identifiers, operation type (`create`, `update`, `delete`), base version, and payload.
   - The operation is immediately written to `OutboxStorage` (`tapittrip_outbox_queue`).
2. **Reconciliation on Reconnection (`POST /api/v1/sync/push`)**:
   - When connectivity resumes or the traveler taps the sync badge, `SyncService` sends pending operations in bounded chunks (`maxPushBatchSize = 25`) so large offline queues survive partial network drops without re-pushing already-accepted chunks.
   - Outbox queueing (`SyncService::saveWithChainedVersion`) automatically chains `baseVersion` past prior queued pending updates for the same entity while preserving the last confirmed server `version` in UI state, so multi-step offline edits sync sequentially without self-conflicts or skewed REST `base_version` checks.
   - `SyncService::push()` processes each batch inside a database transaction using PostgreSQL row-level locking (`lockForUpdate()`):
     - **Idempotency**: If `operation_id` was already processed, returns the recorded result without duplicate processing.
     - **Authorization**: Validates trip membership and permissions (`owner`/`editor`, or `viewer` own assigned checklist item completion).
     - **Conflict Detection & Soft-Delete Recovery**: Compares `base_version` against the current entity's `version` (including soft-deleted rows). Stale edits produce `status = 'conflict'` with `server_version` and redacted `server_payload` (including `deleted: true` when soft-deleted remotely); resolving with `"Keep My Offline Edit"` restores soft-deleted items cleanly.
     - **Per-Trip Cursor Updates**: Tracks and updates `SyncCursor` per affected `trip_id`.
3. **Monotonic Pull (`GET /api/v1/sync/pull`)**:
   - The client requests all accepted mutations with `server_sequence > cursor`.
   - The server returns ordered changes, enforces private expense isolation, redacts sensitive stay/flight organizer fields for non-owner companions, and advances the client's monotonic cursor.
4. **Conflict Handling (`ConflictResolutionDialog`)**:
   - If a concurrent edit or remote deletion is flagged as a conflict, the traveler is shown a comparison dialog (`ConflictResolutionDialog`, including remote deletion notices when `deleted: true`).
   - **Keep My Offline Edit**: Re-queues the operation with `base_version = server_version` and re-pushes immediately.
   - **Keep Server Version**: Discards the local offline edit and adopts the remote version.

## Architecture and data flow

- **Backend**:
  - `sync_operations`: UUID PK, `operation_id` (unique client UUID), `user_id`, `trip_id`, `device_key`, `entity_type`, `entity_id`, `operation_type`, `payload` (sanitized of sensitive stay/flight booking codes and phones), `base_version`, `server_sequence` (monotonic serial), `status`, `conflict_details`, `processed_at`, `timestamps`.
  - `sync_cursors`: UUID PK, `user_id`, `device_key`, `trip_id`, `last_server_sequence`, `timestamps`.
- **Application Services**:
  - `SyncService` (`api/app/Services/Sync/SyncService.php`): Idempotent batch `push()` with `lockForUpdate()`, soft-delete conflict/restore handling, stay/flight privacy sanitization, per-trip cursor maintenance, and monotonic `pull()` across `trip`, `itinerary_item`, `stay`, `flight`, `checklist_item`, and `expense`.
- **Mobile Client**:
  - `OutboxOperation` & `SyncOperationResult`: Strong typed sync models.
  - `OutboxStorage`: Encrypted persistence backed by `FlutterSecureStorage` (`tapittrip_outbox_queue`, `tapittrip_sync_cursor_${tripId}`).
  - `SyncService`: Queue mutation, chunked `pushPending()`, cursor `pullLatest()`, bidirectional `syncAll()`, and `resolveConflict()`.
  - `SyncNotifier` & `syncProvider`: Reactive Riverpod state management.
  - `SyncStatusIndicator`: Compact AppBar badge showing synced/pending/conflict/rejected/offline status.
  - `ConflictResolutionDialog`: Interactive choice between local and server versions (including remote deletion status).

## API contract

Documented in [`docs/api/openapi.yaml`](../api/openapi.yaml):
- `POST /api/v1/sync/push`: Batch push offline mutations.
- `GET /api/v1/sync/pull`: Pull server updates using monotonic cursors.

## Offline and security considerations

- **Encryption**: Offline outbox payloads and sync cursors are stored in encrypted hardware keystore / keychain storage via `FlutterSecureStorage`.
- **Least Privilege & Redaction**: Sync operations enforce active trip membership/roles and redact sensitive organizer fields (`booking_reference`, `phone`, and `friends_family` private locations/notes) in conflict snapshots, `sync_operations.payload` ledger storage, and `/sync/pull` responses for non-owners.
- **No Sensitive Leaks**: Private tokens, passwords, and external credential payloads are never queued in the outbox.

## Verification

- **Backend Tests**: `api/tests/Feature/SyncTest.php` (**13/13 tests, 110 assertions**):
  - Multi-device concurrent `stay` and `itinerary_item` edits detecting deterministic conflicts, redacting sensitive stay fields in conflict snapshots, and resolving at bumped `base_version`.
  - Remote soft-delete triggering conflict (`deleted: true`) and `"Keep My Offline Edit"` restoring the entity with the traveler's offline changes.
  - Privacy redaction stripping `booking_reference`, `phone`, and `friends_family` location/notes from ledger storage and companion pulls.
  - Consecutive offline updates within a single push batch applying sequentially without self-conflicts.
- **Mobile Tests**: `client/test/sync_test.dart` (**16/16 tests**):
  - `OutboxStorage` persistence across restarts and cursor saving.
  - Chunked `pushPending()` across `> 25` operations and partial network-drop recovery preserving un-pushed chunks.
  - `ConflictResolutionDialog` remote deletion rendering and resolution flows.
  - Consecutive offline stay edits bumping optimistic `version` and persisting coordinates (`latitude`, `longitude`) in the outbox.

