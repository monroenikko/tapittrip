# Notifications and Geofencing

- Milestone: `M5`
- Status: `implemented`
- Owner: `TapItTrip Engineering`
- Last verified: `2026-11-08`

## Purpose and traveler outcome

Travelers receive proactive, timely alerts without being overwhelmed or having their privacy compromised:
- **Morning Itinerary Summary**: Daily overview of the day's planned activities in destination-local time.
- **Activity Departure Alerts**: Upcoming reminders (15m, 30m, 1h lead time) before activities start.
- **Stays & Packing Checklists**: Timely reminders before hotel check-in/out deadlines and departure packing checks.
- **Quiet Hours**: Traveler-controlled rest periods (e.g. 22:00 to 07:00) that mute non-critical reminders.
- **Arrival Suggestions (Geofencing)**: Proximity detection that gently prompts travelers to confirm arrival; never silently marks destinations visited.

## How it works

1. **Preference Configuration**:
   - The traveler configures preferences in `NotificationPreferencesPage` (daily summary time, activity lead time, quiet hours, arrival suggestions).
   - If OS notification permissions are denied, an informative, non-blocking `NotificationPermissionBanner` appears with a one-tap action to system settings.
2. **Deterministic Scheduling & Deduplication**:
   - The backend `ScheduleTripRemindersService` computes upcoming triggers based on trip activities, stays, checklists, and user preferences.
   - Generates reproducible `dedupe_key` hashes (`{trip_id}:{type}:{target_id}:{trigger_utc}`). Re-running never produces duplicate notifications.
   - Rescheduling an itinerary activity or stay automatically cancels outdated reminders (`status = 'cancelled'`) and schedules updated ones.
3. **Local Offline Engine**:
   - The mobile client caches scheduled reminders in `FlutterSecureStorage` (`scheduled_local_notifications_$tripId`).
   - Scheduled alerts survive app termination, reboots, and offline airplane mode.
4. **Arrival Detection & Confirmation**:
   - `GeofenceService` monitors distance between the traveler's coordinates and the next upcoming activity place using the Haversine formula (250m radius).
   - Upon proximity, `ArrivalSuggestionDialog` prompts: *"You've arrived at [Place]! Would you like to mark this activity as visited?"*
   - Tapping "Mark Visited" dispatches `POST /itinerary-items/{item}/visit-events` with `method: 'geofence'`, updating the activity's status to `visited`.

## Architecture and data flow

- **Backend**:
  - `user_devices`: UUID PK, `user_id`, `platform`, `device_key`, `push_token`, `last_seen_at`.
  - `notification_preferences`: UUID PK, `user_id`, `morning_summary_enabled`, `morning_summary_time`, `activity_reminders_enabled`, `activity_reminder_lead_minutes`, `checklist_reminders_enabled`, `stay_reminders_enabled`, `quiet_hours_enabled`, `quiet_hours_start`, `quiet_hours_end`, `geofence_arrival_enabled`, `timezone_behavior`.
  - `reminders`: UUID PK, `trip_id`, `itinerary_item_id`, `checklist_id`, `type`, `title`, `body`, `trigger_at_utc`, `timezone`, `delivery_channel`, `status`, `dedupe_key`, `source_version`.
  - `visit_events`: UUID PK, `itinerary_item_id`, `user_id`, `event_type`, `method`, `detected_at`, `accuracy_m`.
- **Application Services**:
  - `RegisterDeviceService`: Upserts device tokens.
  - `GetNotificationPreferencesService` & `UpdateNotificationPreferencesService`: Manages user notification settings.
  - `GetTripRemindersService`: Queries trip reminders.
  - `ScheduleTripRemindersService`: Calculates triggers, enforces quiet hours, cancels stale reminders.
  - `RecordVisitEventService`: Records visit event and synchronizes item status.
- **Mobile Client**:
  - `NotificationPreference` and `TripReminder` models.
  - `NotificationRepository`: Secure storage caching (`cached_notification_preferences`, `cached_reminders_$tripId`).
  - `LocalNotificationService`: Quiet hours verification and local offline persistence (`scheduled_local_notifications_$tripId`).
  - `GeofenceService`: Proximity detection within 250m.
  - `NotificationPreferencesPage`: Full settings UI with permission banner.
  - `ArrivalSuggestionDialog`: Interactive arrival verification.

## API contract

Documented in `docs/api/openapi.yaml`:
- `POST /api/v1/devices/register`
- `GET /api/v1/me/notification-preferences`
- `PUT /api/v1/me/notification-preferences`
- `GET /api/v1/trips/{trip}/reminders`
- `POST /api/v1/trips/{trip}/reminders/generate`
- `POST /api/v1/itinerary-items/{item}/visit-events`

## Security and privacy

- **No Silent Arrival Confirmation**: In compliance with `AGENTS.md`, locations are never silently marked visited without user confirmation.
- **Tenant Authorization**: All reminder and visit-event operations enforce `TripPolicy`. Unauthorized travelers receive `403 Forbidden`.
- **Sensitive Data Minimization**: Booking references and private notes are never included in notification bodies or push payloads.

## Offline and conflict behavior

- Local reminders are persisted in `FlutterSecureStorage` and trigger on device even without internet connectivity.
- Offline arrival events queue local state transitions and synchronize to the backend when connectivity returns.

## Testing and acceptance evidence

- **Backend**: `NotificationTest.php` (6 tests) and `VisitEventTest.php` (4 tests). Full PHPUnit suite passes at 76/76 tests (446 assertions).
- **Mobile**: `notification_test.dart` (7 tests) and `geofence_test.dart` (6 tests). Full Flutter test suite passes at 83/83 tests.
- **Code Style & Analyzer**: `./vendor/bin/sail bin pint --test` (0 issues) and `flutter analyze` (0 issues).
