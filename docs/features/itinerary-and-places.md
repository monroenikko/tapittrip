# Itinerary, Places, and Maps

- Milestone: `M2`
- Status: `implemented` (Slice 1 backend foundation)
- Owner: `engineering`
- Last verified: `2026-11-05`

## Purpose and traveler outcome

Empowers travelers to build, schedule, and reorder daily activities and physical stops (`itinerary_items`) associated with geographically defined, provider-attributed locations (`places`) and calendar days (`trip_days`).

Travelers can easily create stops (attractions, meals, transport, hotels, flights, and custom activities), reorder their daily flow, and instantly trigger Google Maps deep links for offline-ready coordinates and directions.

## How it works

1. **Trip Days**: Trips organize itinerary stops by local calendar dates (`local_date`). The `EnsureTripDayService` automatically gets or creates a day entry with optional notes.
2. **Places & Providers**:
   - Every physical stop can be linked to a `places` record containing geographical coordinates (`latitude`, `longitude`), formatted address, country code, and attribution.
   - Places can be searched via `/api/v1/places/search?q=...` or created inline during itinerary item creation.
   - Computed `google_maps_url` provides direct deep-linking into Google Maps (`geo:` / `https://www.google.com/maps/search/?api=1&query=...`).
3. **Itinerary Items**:
   - Supports 6 activity kinds: `attraction`, `meal`, `transport`, `flight`, `hotel`, `custom`.
   - Items track start/end times in UTC (`starts_at_utc`, `ends_at_utc`), local timezone, notes, status (`planned`, `visited`, `skipped`), and sort order.
   - When items are created without explicit `sort_order`, they are appended automatically to the end of the day or trip sequence (`max(sort_order) + 1`).
4. **Bulk Reordering**:
   - The `/api/v1/trips/{trip}/itinerary-items/reorder` endpoint allows clients to submit an array of UUIDs (`item_ids`) to reorder activities transactionally.
   - Verifies trip tenancy and updates sort order and version atomically.
5. **Soft Deletes**:
   - Deleting an itinerary item marks it soft-deleted to support offline tombstone synchronization.

## Architecture and data flow

- **Data Models**:
  - `places`: UUID, provider (`manual`, `google`, `osm`), `provider_place_id`, `name`, `formatted_address`, `country_code`, `latitude`, `longitude`, `photo_reference`, `attribution`, `last_refreshed_at`, `timestamps`.
  - `trip_days`: UUID, `trip_id` (FK `trips`), `local_date`, `notes`, `timestamps`, unique `[trip_id, local_date]`.
  - `itinerary_items`: UUID, `trip_id` (FK `trips`), `trip_day_id` (FK `trip_days`), `place_id` (FK `places`), `kind`, `title`, `notes`, `starts_at_utc`, `ends_at_utc`, `timezone`, `sort_order`, `status`, `version`, `timestamps`, `softDeletes`.
- **Application Services** (`app/Application/Itinerary/Services`):
  - `CreateItineraryItemService`: Orchestrates item creation, inline place resolution, and sort order calculation.
  - `UpdateItineraryItemService`: Updates item fields, resolves inline places, and increments the sync version.
  - `ReorderItineraryItemsService`: Transactionally validates and updates the sequence order for a set of items.
  - `DeleteItineraryItemService`: Soft deletes the item.
  - `CreatePlaceService`: Persists or updates place coordinates and attribution.
  - `EnsureTripDayService`: Finds or creates trip days.
- **Authorization**: All scoped endpoints enforce `TripPolicy` (`view` for reading, `update` for creating, editing, and reordering).

## API contract

Documented in [`docs/api/openapi.yaml`](../api/openapi.yaml):
- `GET /api/v1/trips/{trip}/days` (`listTripDays`)
- `POST /api/v1/trips/{trip}/days` (`createTripDay`)
- `GET /api/v1/trips/{trip}/itinerary-items` (`listItineraryItems`)
- `POST /api/v1/trips/{trip}/itinerary-items` (`createItineraryItem`)
- `POST /api/v1/trips/{trip}/itinerary-items/reorder` (`reorderItineraryItems`)
- `GET /api/v1/itinerary-items/{item}` (`getItineraryItem`)
- `PATCH /api/v1/itinerary-items/{item}` (`updateItineraryItem`)
- `DELETE /api/v1/itinerary-items/{item}` (`deleteItineraryItem`)
- `GET /api/v1/places/search` (`searchPlaces`)
- `POST /api/v1/places` (`createPlace`)
- `GET /api/v1/places/{place}` (`getPlace`)

## Security and privacy

- Enforces strict trip membership: non-members receive HTTP 403 Forbidden on all scoped day and itinerary endpoints.
- Reordering verifies that all submitted IDs belong to the target trip, rejecting spoofed or cross-tenant IDs with a 422 validation response.
- Coordinates and notes are stored with least privilege and encrypted in transit via TLS.

## Testing and acceptance evidence

- Feature test suite:
  - [`api/tests/Feature/ItineraryItemTest.php`](../../api/tests/Feature/ItineraryItemTest.php) (creation with inline place, automatic sort order increment, updates & version increment, 3-stop reordering, soft delete, tenancy isolation, day filtering).
  - [`api/tests/Feature/TripDayTest.php`](../../api/tests/Feature/TripDayTest.php) (listing, creation, tenancy isolation).
  - [`api/tests/Feature/PlaceTest.php`](../../api/tests/Feature/PlaceTest.php) (place creation, Google Maps deep link calculation, keyword search).
- Verification commands:
  - `cd api && bash bin/test-postgres` — **passed** (42 tests, 214 assertions).
  - `cd api && ./vendor/bin/sail pint --test` — **passed**.
  - `cd api && ./vendor/bin/sail --profile tools run --rm --no-deps contracts` — **passed**.


### Mobile compile verification — 2026-11-06

Removed a duplicate activity-card `onEdit` argument while retaining the existing edit flow. `dart format lib/features/itinerary/presentation/pages/trip_itinerary_page.dart`, `flutter analyze`, and `flutter test` passed (51 tests). No API or offline contract changed. Device rendering and the reported Metal drawable error remain unverified; see the [milestone log](../milestone-log.md).

### Autocomplete suggestion surface — 2026-11-06

Shared place suggestions use a clipped Material surface so ListTile backgrounds and ink feedback remain visible inside the rounded container. This applies to activity, stay/address, and trip destination fields. `client/test/place_autocomplete_test.dart` exercises name/address search and selection with a fake repository; both cases reproduced the assertion before the fix. Analysis and all 53 Flutter tests pass; device rendering remains unverified. API and offline behavior are unchanged.
