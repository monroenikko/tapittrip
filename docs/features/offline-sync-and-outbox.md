# Offline Sync and Durable Outbox

- Milestone: `M6`
- Status: `implemented`
- Owner: `TapItTrip Engineering`
- Last verified: `2026-11-08`

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
   - When connectivity resumes or the traveler taps the sync badge, `SyncService` batches pending operations to the server.
   - `PushSyncOperationsService` processes the batch inside a database transaction:
     - **Idempotency**: If `operation_id` was already processed, it returns the recorded result without duplicate processing.
     - **Authorization**: Validates trip membership and update permissions via `TripPolicy`.
     - **Conflict Detection**: Compares `base_version` against the current entity's version. If the server version is newer, marks `status = 'conflict'` and returns the server's current state. If current, applies the update, increments entity `version`, and marks `status = 'accepted'`.
   - On the client, accepted operations are safely removed from the outbox queue.
3. **Monotonic Pull (`GET /api/v1/sync/pull`)**:
   - The client requests all mutations with `server_sequence > cursor`.
   - The server returns ordered changes and deletion tombstones, advancing the client's cursor.
4. **Conflict Handling (`ConflictResolutionDialog`)**:
   - If a concurrent edit is flagged as a conflict, the traveler is shown a comparison dialog.
   - **Keep My Offline Edit**: Re-queues the operation with `base_version = server_version` and re-pushes immediately.
   - **Keep Server Version**: Discards the local offline edit and adopts the remote version.

## Architecture and data flow

- **Backend**:
  - `sync_operations`: UUID PK, `operation_id` (unique client UUID), `user_id`, `trip_id`, `device_key`, `entity_type`, `entity_id`, `operation_type`, `payload`, `base_version`, `server_sequence` (monotonic serial), `status`, `conflict_details`, `processed_at`, `timestamps`.
  - `sync_cursors`: UUID PK, `user_id`, `device_key`, `trip_id`, `last_server_sequence`, `timestamps`.
- **Application Services**:
  - `PushSyncOperationsService`: Idempotent batch processing, authorization, version conflict detection, sequence assignment.
  - `PullSyncChangesService`: Monotonic cursor querying, membership scoping, deletion tombstone delivery.
- **Mobile Client**:
  - `OutboxOperation` & `SyncOperationResult`: Strong typed sync models.
  - `OutboxStorage`: Encrypted persistence backed by `FlutterSecureStorage` (`tapittrip_outbox_queue`, `tapittrip_sync_cursor_${tripId}`).
  - `SyncService`: Queue mutation, batch push, cursor pull, bidirectional reconciliation, and conflict resolution.
  - `SyncNotifier` & `syncProvider`: Reactive Riverpod state management.
  - `SyncStatusIndicator`: Compact AppBar badge showing synced/pending/conflict/offline status.
  - `ConflictResolutionDialog`: Interactive choice between local and server versions.

## API contract

Documented in `docs/api/openapi.yaml`:
- `POST /api/v1/sync/push`: Batch push offline mutations.
- `GET /api/v1/sync/pull`: Pull server updates using monotonic cursors.

## Offline and security considerations

- **Encryption**: Offline outbox payloads and sync cursors are stored in encrypted hardware keystore / keychain storage via `FlutterSecureStorage`.
- **Least Privilege Authorization**: Sync operations for trips verify active editor or owner membership before applying mutations. Unauthorized attempts are rejected (`status = 'rejected'`).
- **No Sensitive Leaks**: Private tokens, passwords, and external credential payloads are never queued in the outbox.

## Verification

- **Backend Tests**: `api/tests/Feature/SyncTest.php`:
  - `test_push_applies_accepted_mutations_and_bumps_version`: Verified mutation execution and version bumping.
  - `test_push_idempotency_returns_recorded_result_without_duplicate_processing`: Verified duplicate retries produce no duplicate operations.
  - `test_push_detects_conflict_when_base_version_is_stale`: Verified conflict detection when base_version is stale.
  - `test_push_rejects_unauthorized_trip_operations`: Verified authorization rejection on unpermitted trips.
  - `test_pull_returns_changes_with_monotonic_cursor_and_tombstones`: Verified monotonic ordering and deletion tombstones.
- **Mobile Tests**: `client/test/sync_test.dart`:
  - `OutboxStorage` persistence across restarts and cursor saving.
  - `SyncService` queueing, push removal, conflict flagging, conflict resolution (both keep local and keep server), and pull cursor advancement.
  - Widget tests for `SyncStatusIndicator` (synced, pending, conflict states) and `ConflictResolutionDialog`.
- **Test Results**:
  - Backend: 81/81 passed (484 assertions), Pint 0 issues.
  - Mobile: 94/94 passed, `flutter analyze` 0 issues, `dart format` clean.
