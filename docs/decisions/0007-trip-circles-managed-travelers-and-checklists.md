# ADR 0007: Trip Circles Minimal Managed Traveler Profiles & Checklist Task Assignments

- **Status**: Accepted
- **Date**: 2026-11-10
- **Extends**: [`0006-trip-circles-sync-conflicts-and-announcements.md`](0006-trip-circles-sync-conflicts-and-announcements.md)
- **Context**: `MASTER_PLAN.md` Section 14C Step 6 (`TC-6.1`–`TC-6.3`) requires coordinating shared packing/preparation responsibilities across accepted trip members and minimal managed traveler profiles (e.g. children or dependents without user accounts), isolating personal completion from shared visit status and editing permissions, preventing orphaned task ownership when members leave or travelers are removed, and resolving offline completion conflicts safely.

## Decisions

### 1. Minimal Managed Traveler Profiles (`trip_travelers`, `TC-6.3`)
- **Non-Authenticated Entity**: `trip_travelers` stores `id`, `trip_id`, optional `linked_member_id`, `managing_user_id`, minimal `display_name`, `traveler_category` (`adult`, `child`, `infant`, `companion`), nullable encrypted `restricted_notes`, `version`, timestamps, and soft deletes.
- **No Account / Capability Escalation**: Managed travelers have no credentials, Sanctum tokens, email addresses, or `trip_members` records. Endpoints never expose document-sharing or location-sharing toggles for managed profiles (`TC-6.3`).
- **Authorized Adult Controls & Field Redaction**:
  - `owner` and `editor` trip members can view active travelers on the trip and create managed profiles where `managing_user_id = $actor->id`. (`viewer` members can view non-restricted `display_name`/`traveler_category` for checklist responsibility clarity, or manage nothing -> `403`).
  - Only `$traveler->managing_user_id === $viewer->id` can read or edit `restricted_notes`, edit profile details, or delete their managed profile (`owner` may also remove an orphaned traveler profile when cleanup is required). All other members receive `restricted_notes: null`.

### 2. Checklist Assignment, Viewer Completion Isolation & Orphan Prevention (`TC-6.1`, `TC-6.2`)
- **Explicit Assignment Columns on `checklist_items`**:
  - Adds nullable `assigned_user_id` (FK -> `users`, `nullOnDelete`), nullable `assigned_traveler_id` (FK -> `trip_travelers`, `nullOnDelete`), and nullable `completed_by_user_id` (FK -> `users`, `nullOnDelete`).
  - An item may be unassigned (`null`/`null`) or assigned to **either** an accepted circle member (`assigned_user_id`) **or** an active trip traveler (`assigned_traveler_id`), never both simultaneously and never cross-trip (`422` validation failure).
- **Scoped Completion Without Shared Edit Escalation**:
  - An accepted member with role `viewer` may call `POST /api/v1/checklist-items/{item}/toggle` (or push an `is_packed`-only `update` via `POST /api/v1/sync/push`) **strictly when** `$item->assigned_user_id === $actor->id`.
  - Viewers still receive `403` when toggling unassigned/other-member items, modifying `title`/`notes`/`category`/assignee, deleting items, or touching itinerary/visit records. Toggling a checklist item never modifies `itinerary_items` or `visit_events`.
- **Orphan Prevention on Departure or Deletion**:
  - When a companion leaves or is removed (`TripCircleService::removeMember`), or when a `TripTraveler` is soft-deleted, affected `checklist_items` on that trip atomically clear `assigned_user_id` / `assigned_traveler_id` and bump `version` inside the same database transaction so no inaccessible assignee remains.

### 3. Optimistic Concurrency & Offline Checklist Sync (`TC-6.2`)
- `PATCH /api/v1/checklist-items/{item}` and `POST /api/v1/checklist-items/{item}/toggle` accept optional `base_version` and throw `VersionConflictException` (`409 version_conflict`) under `lockForUpdate()` when stale.
- `SyncService::handleChecklistItem()` enforces `trip_id` ownership, viewer completion-only restrictions, `base_version` conflict detection, assignee updates (`assigned_user_id` / `assigned_traveler_id`), and `completed_by_user_id` tracking.

## Consequences
- Existing solo and shared checklist flows remain backward-compatible when assignment fields and `base_version` are omitted.
- Managed travelers cannot bypass future location/document consent policies (`TC-9`) because no user/session identity exists for them.
