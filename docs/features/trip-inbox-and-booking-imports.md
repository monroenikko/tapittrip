# Trip Inbox & Smart Booking Imports

- **Status**: Implemented
- **Milestone**: M2 / M4 Smart Extraction & Release 1 Booking Imports
- **Primary contracts**: [`docs/api/openapi.yaml`](../api/openapi.yaml) (`listTripBookingImports`, `createTripBookingImport`, `getBookingImport`, `confirmBookingImport`, `deleteBookingImport`), [`MASTER_PLAN.md`](../../MASTER_PLAN.md) (Sections 3, 6, 7, 10, and 14A)

## Traveler Flow

1. From **Today's Dashboard**, a traveler taps **Trip Inbox & Smart Imports** (or navigates to `/trips/:tripId/inbox`).
2. Travelers can also paste confirmation text anywhere by opening the **Smart Booking Import Sheet** (`SmartBookingImportSheet.show`).
3. The traveler can optionally hint the booking category (`Auto-detect`, `Flight`, `Stay`, `Activity`) or let Gemini AI extract it automatically from raw confirmation text or forwarded email snippets.
4. Extracted bookings enter the **Trip Inbox** in `extracted` status with an explainable AI confidence score (e.g. `95% confidence`).
5. Tapping **Review & Add** displays the `ReviewExtractedBookingDialog`, allowing travelers to review and edit extracted fields (airline, flight numbers, airport codes, hotel names, addresses, check-in dates, activity details) before confirming.
6. When confirmed, the import transitions to `confirmed` status, optimistic concurrency is verified (`base_version`), and domain records are materialized into:
   - [`Flight`](../../api/app/Models/Flight.php) & [`FlightSegment`](../../api/app/Models/FlightSegment.php) (with automated flight preparation notifications).
   - [`Stay`](../../api/app/Models/Stay.php) (with stay dates, address, and luggage presets).
   - [`ItineraryItem`](../../api/app/Models/ItineraryItem.php) (with start/end times and place name).

## Implementation & Security Behavior

- **Encryption at Rest**:
  - [`BookingImport`](../../api/app/Models/BookingImport.php) encrypts `extracted_data` using Laravel's `encrypted:array` cast in PostgreSQL (`booking_imports.extracted_data`). Raw passenger details, booking references, and confirmation payload data are protected from plaintext exposure at rest.
- **Explainable Confidence & Grounding**:
  - `confidence_score` is stored as an explicit floating-point value `[0.0, 1.0]`. The UI visually highlights confidence levels and allows manual adjustments before materializing entities.
- **Pluggable Extractor Architecture**:
  - Bound via [`BookingExtractorInterface`](../../api/app/Contracts/BookingExtractorInterface.php):
    - [`FakeBookingExtractor`](../../api/app/Services/Imports/FakeBookingExtractor.php) handles deterministic automated testing and offline regex fallbacks.
    - [`GeminiBookingExtractor`](../../api/app/Services/Imports/GeminiBookingExtractor.php) uses Google Gemini structured JSON multimodal extraction when configured.
- **Idempotency & Optimistic Concurrency**:
  - `POST /api/v1/trips/{trip}/imports` handles retries via `client_operation_id`.
  - `POST /api/v1/imports/{import}/confirm` requires `base_version` and throws `409 version_conflict` if the record changed concurrently.
- **Offline Storage & Revocation Cleanup**:
  - [`BookingImportRepository`](../../client/lib/features/imports/data/booking_import_repository.dart) caches inbox items in `FlutterSecureStorage` under `cached_booking_imports_{tripId}`.
  - A `403` response or Circle revocation (`TripCircleRepository.purgeAllTripCachesForStorage`) purges cached booking imports immediately.

## Verification

- Backend feature tests: [`api/tests/Feature/BookingImportTest.php`](../../api/tests/Feature/BookingImportTest.php) (100% passing under PostgreSQL)
- OpenAPI contract: [`docs/api/openapi.yaml`](../api/openapi.yaml) (validated via `./vendor/bin/sail --profile tools run --rm --no-deps contracts`)
- Mobile repository and widget tests: [`client/test/booking_import_test.dart`](../../client/test/booking_import_test.dart) (`dart format`, `flutter analyze` 0 issues, `flutter test` passing)

## Known Limitations & Direction

- Phase A supports text-based pasting and parsing of flight confirmations, hotel bookings, and activity vouchers. Direct IMAP/Gmail sync and PDF file attachments are scheduled for future milestone enhancements.
