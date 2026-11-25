# Flights and booking details

## Traveler flow

From **Bookings**, a traveler chooses a trip, opens **Flights**, and adds or edits a confirmed flight. A booking can contain up to eight scheduled segments so a multi-leg connection remains one booking. Travelers can also paste confirmation text into the sheet to pre-fill recognized airline, booking reference, flight number, and IATA airport codes, then review and complete every field before saving. The app shows saved route and schedule details only; it does not claim live airline status, gate changes, fares, or alerts.

Travelers enter airport IATA codes, scheduled UTC instants, and the origin/destination IANA timezones. They can add an optional airline, terminal, gate, and private booking reference. The confirmation reference is encrypted at rest and only returned to the trip owner.

On the **Today Dashboard**, `TodayFlightCard` surfaces the trip's next upcoming flight (or a prompt to add a flight), showing the scheduled route, departure time and timezone, terminal/gate chips, owner-only booking reference badge, a clear non-live notice (`Scheduled booking details • Not live airline status`), and a one-tap **Explore `<IATA>` `<Terminal>` Lounges** handoff directly to the Airport Lounge Finder (`/lounges?iata=<IATA>&terminal=<terminal>`).

## API, reminders, and persistence

- `GET`/`POST /api/v1/trips/{trip}/flights`, `PATCH`/`DELETE /api/v1/flights/{flight}` are authenticated and authorize through the trip policy.
- `GET /api/v1/trips/{trip}/today` includes `upcoming_flight` and `flights` serialized through `FlightResource` so `booking_reference` is redacted for non-owners.
- `flights` is trip-scoped and owns `flight_segments`; deleting a flight cascades to its segments.
- Updates require `base_version`; a stale edit returns the standard `version_conflict` response.
- Creates accept an optional `client_operation_id`, unique per trip, for retry-safe creation.
- Creating, updating, or deleting a flight automatically schedules, reschedules, or cancels `flight_prep` (3 hours before scheduled departure) and `flight_gate_departure` (45 minutes before scheduled departure) reminders via `NotificationService`. Reminder titles and bodies never include `booking_reference`.

## Offline and privacy

The mobile repository keeps a secure per-trip cache (`cached_flights_{tripId}`) and removes it when trip access is revoked (`403` or circle removal). Offline `create`, `update`, and `delete` operations are queued in the durable outbox (`entity_type: 'flight'`); server sync processes `flight` mutations, syncs flight-prep reminders, and redacts `booking_reference` from stored `sync_operations.payload` and conflict payloads so non-owners never receive private booking references via REST or `/sync/pull`. Pulled `flight` operations (`create`, `update`, `delete`) are applied to the local per-trip flight cache during `SyncService.pullLatest`. Offline state never represents schedules as live data.

## Limitations

Document/image OCR, live airline-provider status, and automated gate/delay alerts are not implemented in this slice. Pasted confirmation text is a local convenience parser only; travelers must review and verify the confirmed schedule manually before saving. This feature should not be used as a boarding pass or real-time departure source.

## Verification

- `api/tests/Feature/FlightTest.php` (6 tests, 47 assertions) covers multi-leg creation, encrypted references, member redaction, authorization, validation, version conflict, deletion, `/sync/push` + `/sync/pull` booking-reference redaction, `GET /api/v1/trips/{trip}/today` flight serialization, and automatic `flight_prep` / `flight_gate_departure` reminder scheduling and cancellation without `booking_reference`.
- `client/test/flight_confirmation_parser_test.dart` (5 tests) covers confirmation text extraction, non-invented fallback, applying pulled `flight` sync operations (`create`, `update`, `delete`) with `403` cache purge, multi-leg flight creation with pasted confirmation review, and editing/deleting existing flights.
- `client/test/today_test.dart` (17 tests) covers `TodayDashboardSummary` flight parsing and `TodayFlightCard` rendering, non-live disclaimer, and one-tap Lounge Finder terminal handoff across text scales `1.0` and `2.0`.
