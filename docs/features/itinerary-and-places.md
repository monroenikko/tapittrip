# Itinerary, Places, and Maps

- Milestone: `M2`
- Status: `implemented` (Slice 1 backend foundation)
- Owner: `engineering`
- Last verified: `2026-11-05`

## Purpose and traveler outcome

Empowers travelers to build, schedule, and reorder daily activities and physical stops (`itinerary_items`) associated with geographically defined, provider-attributed locations (`places`) and calendar days (`trip_days`).

Travelers can easily create stops (attractions, meals, transport, hotels, flights, and custom activities), reorder their daily flow, and instantly trigger Google Maps deep links for offline-ready coordinates and directions.

## How it works

- **Activity day picker**: Selected labels fit the sheet width using an ellipsis; opening the picker shows full titles and dates in wrapping rows. Verified at 320 logical pixels and 200% text scaling in both themes with keyboard coverage via `flutter test test/activity_sheet_test.dart` (2026-11-10). API, security, and offline behavior are unchanged; device verification remains manual.

1. **Trip Days**: Trips organize itinerary stops by local calendar dates (`local_date`). The `EnsureTripDayService` automatically gets or creates a day entry with optional notes.
2. **Places & Providers**:
   - Every physical stop can be linked to a `places` record containing geographical coordinates (`latitude`, `longitude`), formatted address, country code, and attribution.
   - Places can be searched via `/api/v1/places/search?q=...` or created inline during itinerary item creation.
   - Computed `google_maps_url` provides direct deep-linking into Google Maps (`geo:` / `https://www.google.com/maps/search/?api=1&query=...`).
3. **Itinerary Items**:
   - Supports 6 activity kinds: `attraction`, `meal`, `transport`, `flight`, `hotel`, `custom`.
   - Items track start/end times in UTC (`starts_at_utc`, `ends_at_utc`), local timezone, notes, status (`planned`, `visited`, `skipped`), and sort order.
   - When items are created without explicit `sort_order`, they are appended automatically to the end of the day or trip sequence (`max(sort_order) + 1`).
4. **Bulk Reordering & Drag-and-Drop Card Ordinals**:
   - The `/api/v1/trips/{trip}/itinerary-items/reorder` endpoint allows clients to submit an array of UUIDs (`item_ids`) plus optional `day_assignments` (`item_id => trip_day_id|null`) to reorder activities and reassign days transactionally.
   - Verifies trip tenancy for both item IDs and target trip day IDs (`422` on cross-trip IDs), and updates `sort_order`, `trip_day_id`, and `version` atomically.
   - On the Flutter client (`TripItineraryPage`), every stop card renders an interactive `⋮⋮` drag handle (`ReorderableDragStartListener`) and long-press drag (`ReorderableDelayedDragStartListener`) directly inside the day-grouped or dateless timeline—updating ordinal numbers (`1`, `2`, `3`...) immediately and supporting cross-day card dragging.
   - Tapping the numbered ordinal badge circle (`TimelineDayBadge`) opens a quick "Change Stop Order" picker sheet for accessible exact position & day reassignment.
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
- `POST /api/v1/trips/{trip}/itinerary-items/optimize-route` (`optimizeItineraryRoute`)
- `GET /api/v1/trips/{trip}/food-suggestions` (`listTripFoodSuggestions`)
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

### Constrained Route Optimization, Stop-to-Stop Transit Comparisons & Restaurant Discovery — 2026-11-20

- **Constrained Route Optimization (`RouteOptimizationService`, `POST /api/v1/trips/{trip}/itinerary-items/optimize-route`)**:
  - Evaluates geographic stop order within each day (`trip_day_id`) using Haversine coordinates with a 1.3x urban road detour factor anchored to the trip's primary `Stay` coordinates (when available) or the day's first stop.
  - Respects constraints (`preserve_fixed_times`, `max_walking_meters_per_leg`): items with explicit `starts_at_utc` or `kind` in `['flight', 'hotel']` remain pinned in their slot index while flexible geocoded stops are ordered by nearest-neighbor distance.
  - Defaults to `apply: false` (**"AI suggests; the user approves"**), returning `current_total_distance_km`, `optimized_total_distance_km`, `distance_saved_km`, `estimated_co2_saved_kg`, `proposed_item_ids`, `pinned_item_ids`, and stop-to-stop transit `segments`. When `apply: true`, atomically updates `sort_order` and increments `version` via `ItineraryService::reorderItems()` with `expected_versions` optimistic locking (requires `TripPolicy@update`).
- **Stop-to-Stop Itinerary Transit Mode Comparisons**:
  - Compares `walk`, `public_transit`, and `taxi_rideshare` for consecutive same-day itinerary stops with estimated minutes, suitability (`recommended`, `alternative`, `long_walk`, `unknown`), encoded Google Maps directions URLs (`https://www.google.com/maps/dir/?api=1&...`), and explicit limitation notices (`verified: false`).
  - When coordinates are missing on either stop, returns `recommended_mode: 'unknown_coordinates'` and `null` distances/durations without fabricating values.
  - Rendered on mobile inside the **Transport** tab (`ItineraryTransitSegmentsSection`) alongside arrival transport, and live route distance/CO2 metrics are displayed on `RouteSummaryCard` with a one-tap **Optimize Route** trigger (`RouteOptimizationSheet`).
- **Restaurant & Food Discovery (`FoodSuggestionService`, `GET /api/v1/trips/{trip}/food-suggestions`)**:
  - Returns curated destination- and stay-aware dining suggestions (`breakfast`, `lunch`, `dinner`, `cafe`) with optional `meal_type`, `dietary` (`vegetarian`, `halal`, `kid_friendly`, `local_specialty`), and `near` (`stay`, `itinerary`) filters.
  - Labels proximity using `$stay->name` (e.g., `"5–10 min walk from <stay name>"`) while never exposing private `friends_family` stay addresses or booking references.
  - Deduplicates meals already present in the trip's `itinerary_items` and provides one-tap **Add to Itinerary** and Google Maps search links in `FoodDiscoverySection` under the **Recommendations** tab.
