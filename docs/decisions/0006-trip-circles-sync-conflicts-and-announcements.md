# ADR 0006: Trip Circles Conflict Resolution, Stay Privacy Redaction, Group Announcements & Notification Lifecycle

- **Status**: Accepted
- **Date**: 2026-11-10
- **Extends**: [`0005-trip-circles-targeted-invites-and-ownership-transfer.md`](0005-trip-circles-targeted-invites-and-ownership-transfer.md)
- **Context**: `MASTER_PLAN.md` Section 14C Steps 4–5 (`TC-4`, `TC-5`) require multi-device conflict detection and resolution on collaborative itinerary and stay edits, strict permission-boundary privacy and cache revocation across multiple shared trips, organizer group announcements (`trip_announcements`) with idempotent retries, `timezone_behavior`-aware quiet hours (`destination` vs `home`), automatic reminder rescheduling/cancellation on item/stay updates or deletions, and immediate notification cancellation plus local device cache purge when a member leaves or is removed.

## Decisions

### 1. Optimistic Concurrency & Multi-Device Sync Hardening (`TC-4.1`–`TC-4.4`)
- **REST Version Checks (`409 version_conflict`)**:
  - `PATCH /api/v1/itinerary-items/{item}` and `PATCH /api/v1/stays/{stay}` accept optional `base_version`. Inside a `DB::transaction` with `lockForUpdate()`, if `base_version` is provided and does not match the current row `version`, the backend throws `VersionConflictException` rendered via `ApiExceptionResponse` as HTTP `409` (`code: "version_conflict"`, `details: { server_version, server_payload }`).
  - `POST /api/v1/trips/{trip}/itinerary-items/reorder` accepts optional `expected_versions` (`map<uuid, int>`) so concurrent drag-and-drop reorders detect stale state rather than silently clobbering another companion's ordering.
- **Sync Engine Entity Coverage & Schema Alignment**:
  - `SyncService::handleItineraryItem()` and `SyncService::handleStay()` are aligned with actual schema columns (`trip_day_id`, `kind`, `starts_at_utc`, `ends_at_utc`, `timezone` for itinerary items; `stay_type`, `check_in_at`, `check_out_at`, `timezone`, `luggage_profile`, etc. for stays), support `create`/`update`/`delete`, enforce `entity_id` belongs to `op.trip_id` (`403`/`rejected` on cross-trip tampering), and validate permission checks before mutating.
- **Stay Privacy Redaction (`TC-1.6`, `TC-4.4`)**:
  - `StayResource` and `SyncService` conflict `server_payload` redact sensitive organizer fields (`booking_reference`, `phone`, and `friends_family` private `address`, `latitude`, `longitude`, and map links) whenever the authenticated user is not the `trip.owner_id`. Newly invited editors or companions with changed roles never leak private stay booking codes or host addresses.

### 2. Organizer Announcements & Member Circle Notifications (`TC-5.1`–`TC-5.3`)
- **`trip_announcements` Table**:
  - Stores `id`, `trip_id`, `author_id`, `title`, `body`, `is_pinned`, optional `client_operation_id` (scoped unique per `(trip_id, client_operation_id)` for idempotent mobile/retry posting), `version`, timestamps, and soft deletes.
  - Only the active `trip.owner_id` (verified via `Trip::isOwner($user)`) may create, update, or delete announcements; permitted circle members (`Trip::hasMember($user)`) may list and read them in-app regardless of OS push permission or category opt-outs.
- **`trip_notifications` Inbox & Delivery Controls**:
  - Stores personalized companion notification records (`id`, `trip_id`, `user_id`, `announcement_id`, `category`, `title`, `body`, `scheduled_for_utc`, `timezone`, `trip_local_time_label`, `status`, `dedupe_key`, `read_at`, timestamps, soft deletes) with a unique `(user_id, dedupe_key)` constraint to prevent duplicate notices on announcement edits or network retries.
  - Notification bodies and titles are sanitized and explicitly exclude booking references, private host addresses, attached private documents, and raw invitation tokens.
  - `NotificationPreference` adds `circle_announcements_enabled` (default `true`). When disabled for a companion, `trip_notifications` records are not dispatched (`suppressed` / skipped) while in-app announcement listing on the trip circle feed remains accessible (`TC-5.1`).
  - `NotificationService` evaluates quiet hours using `$preferences->timezone_behavior === 'home' ? ($user->home_timezone ?: $tripTimezone) : $itemTimezone`, formatting user-facing notification labels with clear trip-local time context.
  - Editing or deleting an itinerary item (`ItineraryService::updateItem`/`deleteItem`) or stay (`StayService::update`/`delete`) automatically cancels stale `scheduled` reminders and reschedules updated ones where applicable.
  - Removing or leaving a circle (`TripCircleService::removeMember` / `leaveTrip`) immediately transitions pending/suppressed `trip_notifications` and `scheduled` `reminders` for `(trip_id, user_id)` to `'cancelled'`, and mobile `403`/sync rejection triggers full per-trip cache + reminder cleanup across stays, checklists, expenses, reminders, announcements, itinerary, days, journal, and recap (`TC-4.4`, `TC-4.5`, `TC-5.3`).

## Consequences
- Existing clients that omit `base_version` or `expected_versions` remain backward-compatible while updated clients detect stale edits cleanly and preserve both versions until resolved.
- Companion UI can read organizer announcements in-app even when `circle_announcements_enabled = false` or device notifications are denied, while respecting delivery preferences and removal isolation for inbox notifications and scheduled alerts.

