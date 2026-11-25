# Trip Management

- Milestone: `M1`
- Status: `implemented` (Slice 2 backend foundation)
- Owner: `engineering`
- Last verified: `2026-11-05`

## Purpose and traveler outcome

Allows travelers to create, list, view, update, and delete trips across all four supported planning modes (`diy`, `existing`, `guided`, `simple`). Itinerary creation is strictly optional: travelers who already have bookings or are joining a guided tour can organize their journey immediately without being forced into a detailed schedule.

## Bottom navigation (2026-11-11)

- **Home** shows the existing trip list. **Itinerary** shows a trip picker and opens that trip's existing itinerary; all planning modes and trips without activities are supported.
- **Bookings** is a saved-accommodation overview grouped by authorized trip. Each trip loads/retries its stays independently; empty trips retain a Manage accommodation action. Stay rows and management actions open `/trips/{tripId}/itinerary?tab=stays` directly on the Stays tab. No flight import or live reservation functionality is implied.
- **Profile** opens the existing account/settings route and returns to the prior selected tab. Home/list scroll positions use PageStorage keys. English/Filipino navigation copy follows the resolved app locale.
- Loading, no-trip, no-stay, trip-error and per-trip stay-error states are explicit. Empty lists offer trip creation. UI uses existing authorized trip/stay providers and their cached offline reads; cached freshness is not currently exposed by those providers. The overview shows saved stay names, not booking references, private addresses or notes.
- No API, migration, dependency or credential changes. API membership checks and existing revoked-trip cache handling remain authoritative. Tests use fakes; device navigation/offline checks remain manual.
- Verification: `main_navigation_test.dart` covers actual bottom-bar taps, real Profile rendering, the real Stays route, all four planning modes, no activities, correct trip context, errors/retry, and 320 px/200% text in light/dark themes. Next smallest check: hot restart, switch all four tabs and open stays from two different trips.

## How it works

1. **Trip Creation**: An authenticated traveler creates a trip with a title, optional travel dates (`start_date`, `end_date`), primary IANA timezone, destination country, and planning mode preference. The creator is automatically assigned as the trip `owner` in `trip_members`.
2. **Flexible Modes**:
   - `diy`: For travelers planning activities and routes from scratch.
   - `existing`: For travelers who already booked flights and hotels and want an immediate dashboard.
   - `guided`: For package or tour participants following an operator's schedule.
   - `simple`: Minimal organizer for tickets, stays, and reminders without an itinerary.
   Planning mode is an editable preference that can be updated at any time without data loss.
3. **Trip Listing & Isolation**: Travelers can only list and retrieve trips where they hold membership. Non-members receive HTTP 403 Forbidden.
4. **Collaboration & Roles**:
   - `owner`: Full control, can update details, invite members, and delete the trip.
   - `editor`: Can update trip attributes and edit contents.
   - `viewer`: Read-only access to trip details.
5. **Deletion**: Only the trip owner can delete a trip. Deletions are soft-deleted for safety and tombstone synchronization.

## Architecture and data flow

- **Data Models**:
  - `trips`: `id` (UUIDv7/v4), `owner_id` (FK `users`), `title`, `start_date`, `end_date`, `primary_timezone`, `origin_country`, `destination_country`, `trip_type`, `planning_mode`, `status`, `version` (optimistic locking), `timestamps`, `softDeletes`.
  - `trip_members`: `id` (UUID), `trip_id` (FK `trips`), `user_id` (FK `users`), `role` (`owner`, `editor`, `viewer`), `invitation_status`, `timestamps`.
- **Policy Authorization**: `TripPolicy` enforces membership verification for `view`, role checks (`owner` or `editor`) for `update`, and owner verification for `delete`.
- **Actions**:
  - `CreateTrip`: Transactionally creates the trip record and the initial owner membership.
  - `UpdateTrip`: Transactionally applies validated changes and increments the monotonic `version` counter.
  - `DeleteTrip`: Transactionally soft-deletes the trip.
- **Resource**: `TripResource` serializes normalized trip fields and calculates the viewing user's specific `role`.

## API contract

Documented in [`docs/api/openapi.yaml`](../api/openapi.yaml):
- `GET /api/v1/trips` (`listTrips`)
- `POST /api/v1/trips` (`createTrip`)
- `GET /api/v1/trips/{trip}` (`getTrip`)
- `PATCH /api/v1/trips/{trip}` (`updateTrip`)
- `DELETE /api/v1/trips/{trip}` (`deleteTrip`)

## Security and privacy

- All endpoints require Sanctum bearer token authentication.
- Strict multi-tenant isolation: Querying another user's trip is blocked by `TripPolicy` and yields HTTP 403.
- Database cascading deletes cleanly prune `trip_members` when a trip is purged.
- Identifiers are UUIDs; internal sequential integers are never exposed.

## Offline and conflict behavior

- The API maintains a positive integer `version` field on each trip. Each update increments `version` by 1 to support optimistic concurrency control and sync conflict detection.
- Mobile client persistence and outbox sync for offline trip mutations will be connected in Slice 3 and hardened in M6.

## Testing and acceptance evidence

- Feature test suite: [`api/tests/Feature/TripTest.php`](../../api/tests/Feature/TripTest.php)
  - `test_user_can_create_trip_in_all_four_planning_modes` (data provider: `diy`, `existing`, `guided`, `simple`)
  - `test_trip_creation_validates_required_fields_and_date_ordering`
  - `test_user_can_list_only_trips_they_are_a_member_of`
  - `test_user_can_view_trip_they_belong_to`
  - `test_user_cannot_view_another_users_trip`
  - `test_owner_and_editor_can_update_trip_and_increment_version`
  - `test_viewer_cannot_update_trip`
  - `test_non_owner_cannot_delete_trip`
  - `test_trip_owner_can_delete_trip`
  - `test_unauthenticated_trip_requests_are_rejected`
- Verification commands:
  - `cd api && bash bin/test-postgres`
  - `cd api && ./vendor/bin/sail pint --test`
  - `cd api && ./vendor/bin/sail --profile tools run --rm --no-deps contracts`

## Operations and observability

- Migrations: `2026_11_05_030000_create_trips_table.php`
- Structured logs omit private trip notes and sensitive coordinates.

## Known limitations

- Invitations and member addition workflows are scheduled for Release 2 (collaboration). Current membership is assigned to creator on creation.
- Mobile UI for trip list and trip creation is scheduled for Slice 3.

## Direction

- Proceed to Slice 3: Flutter mobile integration for authentication and trip creation/listing across all four planning modes.
