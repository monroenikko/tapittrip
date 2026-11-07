# TapItTrip Milestone Log

## Current milestone

- Milestone: **M4 — Checklists, Packs & Media Organization**
- Status: **Completed**
- Basis: Acceptance gate passed across backend (66/66 PostgreSQL tests, 398 assertions) and mobile client (70/70 Flutter tests).
- Boundary: Milestone M4 is fully completed across all three slices:
  - Slice 1: Checklist & Items API, starter packing templates, and tenant-scoped authorization.
  - Slice 2: Mobile interactive packing lists, dynamic category filtering, optimistic checkoff, progress rings, and offline cache.
  - Slice 3: Private trip document & media vault, photo attachments for packing items, full-screen photo viewer, and trip-stage checklists (`departure_day` & `return_trip`).
  Awaiting user approval to proceed to **Milestone M5 — Notifications & Geofencing**.

## 2026-11-07 — Milestone M4 (Slice 3): Trip Document Vault, Item Photos & Trip-Stage Checklists

### Completed

- **Database Migrations & Schema**:
  - `media_attachments`: UUID primary key, `trip_id` FK cascade, `attachable_type` (`checklist_item`, `stay`, `itinerary_item`, `trip_document`), `attachable_id` UUID, `uploaded_by_id` FK cascade (`users.id`), `original_filename`, `file_path`, `mime_type`, `file_size_bytes`, `title`, `notes`, timestamps.
  - Applied on dev (`tapittrip`) and test (`tapittrip_test`) PostgreSQL databases with privileged tools container.
- **Backend Media & Document Architecture**:
  - Model: `MediaAttachment` with private disk storage, `is_image` and `is_pdf` helpers, formatted size, and authenticated URL.
  - Wired `mediaAttachments()` relationship on `Trip` and `ChecklistItem`.
  - Application Services:
    - `UploadMediaService`: Validates file (max 10MB; allowed mimes: JPEG, PNG, WEBP, HEIC, PDF), stores on private disk under `trips/{trip_id}/`, creates `MediaAttachment`, and synchronizes `photo_url` when attached to a checklist item.
    - `GetTripMediaService`: Lists trip documents & media with optional `attachable_type` filtering.
    - `DeleteMediaService`: Deletes physical file from storage disk and cleans up associated checklist item photo references.
  - Trip-stage checklists in `ApplyChecklistTemplateService`:
    - `departure_day`: Departure day checklist (flight status check-in, physical passport & visa in hand, luggage weighing/tagging, empty water bottles, home appliances/door locks).
    - `return_trip`: Return trip checklist (hotel room safe check, key return, souvenir packing, tax-free receipts, repacking liquids, return airport transit).
- **Backend API & Route Registration**:
  - `MediaController`:
    - `GET /api/v1/trips/{trip}/media`
    - `POST /api/v1/trips/{trip}/media`
    - `GET /api/v1/trips/{trip}/media/{media}` (private streaming download with membership check)
    - `DELETE /api/v1/trips/{trip}/media/{media}`
  - `POST /api/v1/checklist-items/{item}/photo` in `ChecklistItemController`.
  - Updated `docs/api/openapi.yaml` with all media routes, multipart requests, and schemas.
- **Mobile Client Media & Photo Attachments**:
  - Domain Model: `MediaAttachment` with JSON serialization.
  - `ChecklistRepository`: Added `uploadItemPhoto`, `fetchTripMedia`, and `deleteMedia`.
  - `ChecklistListNotifier`: Added `uploadItemPhoto` and `tripMediaProvider`.
  - `ChecklistItemTile`: Displays a neat photo thumbnail when `photoUrl` is set; tapping launches `PhotoViewerDialog`.
  - `PhotoViewerDialog`: Full-screen interactive viewer with pinch-to-zoom, title, loading progress, and close button.
  - `AddChecklistItemBottomSheet`: Photo URL / document link field for attaching media directly when creating or editing packing items.
  - `ChecklistTemplateDialog`: Added Departure Day and Return Trip template cards.
- **Automated Tests**:
  - Backend: Added `api/tests/Feature/MediaAttachmentTest.php` (4 tests, 31 assertions). Full suite: 66/66 tests passing (398 assertions).
  - Mobile: Added `client/test/media_attachment_test.dart` (5 tests). Full suite: 70/70 tests passing.
  - Pint: 0 issues. Flutter analyze: 0 issues.

### Security and offline considerations

- Files are strictly stored on the `local` private filesystem disk under trip-scoped directories (`storage/app/private/trips/{trip_id}/...`) and never exposed publicly without authentication.
- File streaming endpoint verifies `TripPolicy` membership; unauthorized users receive `403 Forbidden`.
- Checklists and attached photo metadata persist in `FlutterSecureStorage` cache for full offline usability.

## 2026-11-06 — Milestone M4 (Slices 1 & 2): Checklists, Starter Packs & Offline Packing

### Completed

- **Database Migrations & Schema**:
  - `checklists`: UUID primary key, `trip_id` FK cascade, `title`, `type` (`packing`, `documents`, `departure`, `return`, `custom`), `description`, `sort_order`, timestamps.
  - `checklist_items`: UUID primary key, `checklist_id` FK cascade, `trip_id` FK cascade, `title`, `category` (`documents`, `clothing`, `electronics`, `toiletries`, `health`, `gear`, `other`), `is_packed`, `quantity`, `notes`, `photo_url`, `sort_order`, `packed_at`, `version`, timestamps.
  - Applied on dev (`tapittrip`) and test (`tapittrip_test`) databases with privileged tools container.
- **Backend Domain & Application Services**:
  - Models: `Checklist` (with computed accessors `total_items_count`, `packed_items_count`, `progress_percentage`) and `ChecklistItem`.
  - Added `checklists()` and `checklistItems()` relationships on `Trip`.
  - Application Services:
    - `GetTripChecklistsService`
    - `CreateChecklistService`
    - `CreateChecklistItemService`
    - `ToggleChecklistItemService` (updates `is_packed`, `packed_at` timestamp, increments `version`)
    - `UpdateChecklistItemService`
    - `DeleteChecklistItemService`
    - `DeleteChecklistService`
    - `ApplyChecklistTemplateService` (provides starter packs: `international_essentials`, `electronics_gear`, `clothing_apparel`, `toiletries_health`, and `all_essentials`).
- **Backend API & Route Registration**:
  - `ChecklistController` and `ChecklistItemController` under `auth:sanctum`.
  - Form Requests: `StoreChecklistRequest`, `ApplyChecklistTemplateRequest`, `StoreChecklistItemRequest`, `UpdateChecklistItemRequest`.
  - Resources: `ChecklistResource`, `ChecklistItemResource`.
  - Strict tenant authorization via `TripPolicy`.
  - Updated `docs/api/openapi.yaml` with all checklist operations and schemas.
- **Mobile Client UI & State Management**:
  - Models: `Checklist` and `ChecklistItem` with JSON serialization and dynamic progress percentage getters.
  - Data & Cache: `ChecklistRepository` with offline cache (`cached_checklists_${tripId}`) stored in `FlutterSecureStorage` with automatic fallback.
  - State: `checklistListProvider(tripId)` family `AsyncNotifier` with optimistic local checkoff and server reconciliation.
  - UI Components:
    - `ChecklistsView`: List switcher, progress card, category tabs, and items.
    - `ChecklistProgressCard`: Overall percentage, progress bar, packed count, and "All packed! 🎉" completion celebration badge.
    - `ChecklistCategoryTabs`: Horizontal chip selector filtering by category with dynamic item counts.
    - `ChecklistItemTile`: Tactile checkoff box, strikethrough typography, category icon, quantity badge, and edit/delete actions.
    - `AddChecklistItemBottomSheet`: Form for item title, category chips, quantity stepper (- / +), and notes.
    - `ChecklistTemplateDialog`: Starter pack cards with one-tap bootstrap.
  - Integrated into `TripItineraryPage` as a dedicated **Checklists** filter tab with context-sensitive bottom action button.
- **Automated Verification**:
  - Backend: Added `ChecklistTest.php` with 5 tests, 53 assertions. Full suite passes at 62/62 tests (367 assertions).
  - Mobile: Added `checklist_test.dart` with 8 tests. Full client suite passes at 65/65 tests.
  - Pint & Flutter Analyze: 0 style or static analysis issues.

## 2026-11-06 — Nearest Transit Station & Airport Transport Suggestions

### Completed

- **Nearest Transit Hubs & Primary Airport Resolution**:
  - Implemented `StayTransitService` in `api/app/Application/Stays/Services/StayTransitService.php`:
    - Automatically derives the closest metro/train station (station name, address/exit, walking distance in meters, walking time) and primary arrival airport (airport name, IATA code, distance in km) based on the stay's address and coordinates.
    - Covers worldwide destinations (Tokyo, Bali, Paris, London, Singapore, New York, Bangkok, Seoul, Kyoto, Osaka, etc.) and provides an intelligent fallback for arbitrary cities.
  - Exposed `nearest_transit` in `StayResource` (`GET /api/v1/trips/{trip}/stays`) and in `CompareStayTransportService`.
- **Zero-Typing Arrival Transport Suggestions**:
  - Updated `CompareStayTransportService`:
    - When a stay has location data, opening the arrival transport sheet automatically suggests and defaults to the city's primary arrival airport (e.g. `Tokyo Haneda Airport (HND)`, `Ngurah Rai Airport (DPS)`). Travelers no longer need to look up or type airport names.
    - Each transport option is enriched with detailed waypoints:
      - `boarding_location` (e.g. Airport Arrival Taxi Stand / Express Train Platform)
      - `dropoff_location` (e.g. Shinjuku Station South Exit / Ubud Central Terminal)
      - `dropoff_address` (exact station address / exit)
      - `last_mile_walk_meters` and `last_mile_walk_minutes` (walking distance/time from station to hotel)
      - `last_mile_directions_url` (walking navigation link from station directly to the hotel lobby).
- **Mobile UI Enhancements**:
  - Created `NearestTransitInfo` domain model and integrated it into `Stay` and `TransportComparisonResult`.
  - Added **Nearby Transit Preview Banner** in `StayCard`: Displays closest station name, walking distance & duration, and nearest airport with distance in km.
  - Enhanced `TransportComparisonSheet`:
    - Dynamic chips tailored to the stay: `✈️ [Airport Name] ([IATA])` and `🚆 [Station Name]`.
    - Added Boarding, Drop-off, and Last-Mile Walk cards with one-tap "Walk Map" navigation via `MapLauncher`.
- **Automated Tests**:
  - Backend: Added `test_auto_detects_nearest_transit_station_and_primary_airport_when_origin_not_provided` in `api/tests/Feature/StayTransportComparisonTest.php` (57/57 tests passing).
  - Mobile: Verified `stay_test.dart` and `today_test.dart` (57/57 tests passing).

### Verification

- Backend static analysis & formatting: `./vendor/bin/sail bin pint --test` — **passed**.
- Backend test suite: `./vendor/bin/sail bin phpunit -c phpunit.postgres.xml` — **passed** (57/57 tests, 314 assertions).
- Mobile static analysis: `cd client && flutter analyze` — **passed** (0 issues).
- Mobile formatting: `cd client && dart format --output=none --set-exit-if-changed .` — **passed**.
- Mobile test suite: `cd client && flutter test` — **passed** (all 57 tests passing).

### Security and offline considerations

- Transit resolution is deterministic and operates locally on verified stay address/coordinates without exposing user location to unvetted external services.
- Walking directions URLs launch using native system map handlers via `MapLauncher` without passing sensitive session tokens.

## 2026-11-06 — Opaque activity sheet and consistent dashboard spacing

### Completed

- Fixed the invisible shared activity add/edit sheet by adding an opaque themed Material surface, rounded top corners, safe-area handling, keyboard inset padding, and scrollable content.
- Standardized dashboard outer margins and section gaps to 16 dp, aligned card radii/padding, removed duplicated child margins and the duplicate plus sign on the empty-state activity button.
- Added responsive quick-action/stat layouts and wrapping card actions/stay metadata for larger text; replaced hardcoded dashboard/action colors with theme tokens.
- Added sheet regression tests and dashboard alignment/large-text tests. Existing unrelated API, stays, and planning work was left untouched.

### Verification

From `client/` with approved external SDK cache access:

- `dart format lib/features/itinerary/presentation/widgets/add_activity_bottom_sheet.dart lib/features/today test/today_test.dart` and `dart format test/activity_sheet_test.dart test/today_test.dart` — **passed**; subsequent `dart format lib/features/today` — **passed**.
- `flutter test test/activity_sheet_test.dart test/today_test.dart` — **passed**, 16 tests after fixing a 200% text action-row overflow discovered by the new test.
- `flutter analyze` — **passed**, no issues.
- `flutter test` — **passed**, 57 tests.

### Security, offline, and remaining verification

- Presentation-only changes; no API, authorization, storage, or offline contracts changed. No new dependencies or credentials.
- Automated checks cover light/dark sheet surfaces, keyboard access, small-phone layout, and 200% text. Physical iPhone appearance was not manually verified.
- Next smallest task: hot restart and review the dashboard plus activity sheet on the user's iPhone simulator. M3 regression/polish only; no new milestone started.

## 2026-11-06 — Place autocomplete Material surface regression

### Completed

- Moved the shared autocomplete suggestion background to a rounded, clipped Material surface inside the existing border/shadow container. ListTile ink effects now paint on an unobstructed Material ancestor across activity, stay, address, and trip destination inputs.
- Added `client/test/place_autocomplete_test.dart` with deterministic search results for name/address modes, checking rendered suggestions, selection callbacks, field values, dismissal, and absence of framework exceptions.
- Removed the reintroduced duplicate itinerary `onEdit` callback found during analysis, retaining the original handler.

### Verification

Commands from `client/` using approved external Flutter SDK cache access:

- `flutter test test/place_autocomplete_test.dart` before the fix — **failed as expected**, both tests reproduced the reported ListTile assertion.
- `dart format lib/features/itinerary/presentation/widgets/place_autocomplete_field.dart lib/features/itinerary/presentation/pages/trip_itinerary_page.dart test/place_autocomplete_test.dart` — **passed**, 0 formatting changes.
- `flutter analyze` — **passed**, no issues after removing the duplicate callback.
- `flutter test` — **passed**, 53 tests including both new regression scenarios.

### Security, offline, and limitations

- No API, storage, permissions, or offline behavior changes. Tests use a fake repository with no live provider calls.
- iPhone simulator/device rendering was not manually verified. Next smallest task: restart the running app and select an autocomplete suggestion to confirm the device experience; no new milestone is authorized.

## 2026-11-06 — Itinerary duplicate edit callback compile fix

### Completed

- Removed the duplicated `onEdit` named argument from `ActivityTimelineCard` in `client/lib/features/itinerary/presentation/pages/trip_itinerary_page.dart`, retaining the existing prefilled edit sheet and update callback. The file now matches its committed version.
- No API, data, security, or offline behavior changed; unrelated place-search changes were left untouched.

### Verification

Commands run from `client/` with Flutter 3.47.2 / Dart 3.13.2:

- `dart format lib/features/itinerary/presentation/pages/trip_itinerary_page.dart` — **passed**, 0 formatting changes.
- `flutter analyze` — **passed**, no issues.
- `flutter test` — **passed**, 51 tests.
- Initial checks were blocked by sandbox access to the external Flutter SDK cache; rerun with approved access succeeded.

### Limitations and next smallest task

- Device hot restart and the reported Impeller/Metal drawable failure were not reproduced or verified by widget tests. Run the app again to confirm rendering; investigate the drawable message separately if it persists.
- This is a regression fix within delivered itinerary behavior; no new milestone was started.

## 2026-11-06 — In-Place Editing, Place/Stay Autocomplete Suggestions & Clean Luggage Defaults

### Completed

- **Third-Party Place, Stay & Address Autocomplete Suggestions**:
  - Implemented `PlaceSearchService` in `api/app/Application/Itinerary/Services/PlaceSearchService.php`:
    - Queries OpenStreetMap / Nominatim search API (`https://nominatim.openstreetmap.org/search`) with strict timeout shielding (3 seconds) and customizable `TapItTrip/1.0` user-agent header.
    - Fallback to Google Places API when `GOOGLE_MAPS_API_KEY` is present.
    - Graceful error shielding that falls back to local database place search if external network calls fail or time out.
  - Updated `PlaceController@search` (`GET /api/v1/places/search?q=...`) to combine local and external place suggestions with deduplication.
  - Feature test suite in `api/tests/Feature/PlaceTest.php` passing all cases.
  - Implemented reusable `PlaceAutocompleteField` in `client/lib/features/itinerary/presentation/widgets/place_autocomplete_field.dart`:
    - 350ms debouncer preventing excessive queries.
    - Animated suggestion dropdown showing place name and formatted address with squircle category icons.
    - Auto-population callbacks for coordinates and address fields.
  - Integrated `PlaceAutocompleteField` across:
    - Accommodation Hotel / Stay Name & Address in `AddStayBottomSheet`.
    - Activity Location / Place Name & Address in `AddActivityBottomSheet`.
    - Trip Destination in `TripCreatePage` and `EditTripBottomSheet`.
- **In-Place Trip & Activity Editing**:
  - Added `updateTrip` to `TripListNotifier` in `client/lib/features/trips/presentation/providers/trip_list_provider.dart`.
  - Created `EditTripBottomSheet` in `client/lib/features/trips/presentation/widgets/edit_trip_bottom_sheet.dart` enabling editing of title, destination (via autocomplete), dates, trip style, primary timezone, and planning mode.
  - Added `onEdit` callback and edit icon button to `TripCard` in `client/lib/features/trips/presentation/widgets/trip_card.dart`.
  - Connected `onEdit` in `TripListPage` to open `EditTripBottomSheet`.
  - Added `onEdit` callback and edit icon button to `ActivityTimelineCard` in `client/lib/features/itinerary/presentation/widgets/activity_timeline_card.dart`.
  - Connected in-place activity editing in `TripItineraryPage` to launch `AddActivityBottomSheet(initialItem: item)`.
  - Updated `ItineraryRepository.updateItem` and `ItineraryListNotifier.updateItem` to support full field updates (including places and notes).
- **Luggage Profile Clean Starting State**:
  - Added `LuggageProfile.empty()` in `client/lib/features/stays/domain/models/luggage_profile.dart`.
  - Initialized `LuggagePresetSelector` with unselected profile rather than activating presets by default, eliminating traveler confusion.
- **Arrival Origin & Departure Terminal Selector**:
  - Enhanced `TransportComparisonSheet` with arrival origin chips (`✈️ Airport / Terminal`, `🚆 Train Station`, `✏️ Custom Terminal`) and custom terminal input, allowing travelers to compute arrival transport even when departure terminals are not pre-entered.
- **Master Plan Baseline v1.6**:
  - Updated `MASTER_PLAN.md` with:
    - Principle 7: Forgiving by default / In-place editability.
    - Principle 8: Smart suggestions over typing.
    - Section 14A: Accommodation suggestions and clean luggage profile starting state.
    - Section 14D: In-Place Editing Mechanisms (Trips & Activities) and Location/Stay Suggestion System.

### Verification

- Backend static analysis & formatting: `./vendor/bin/sail bin pint --test` — **passed**.
- Backend test suite: `./vendor/bin/sail bin phpunit -c phpunit.postgres.xml` — **passed** (56/56 tests, 306 assertions).
- Mobile static analysis: `cd client && flutter analyze` — **passed** (0 issues).
- Mobile formatting: `cd client && dart format --output=none --set-exit-if-changed .` — **passed**.
- Mobile test suite: `cd client && flutter test` — **passed** (all 51 tests passing).

### Security and offline considerations

- Third-party place queries employ 3-second timeouts and fallback to local cached places so the UI never freezes offline.
- No API keys are required for Nominatim geocoding, while Google Places API remains an optional drop-in configuration.
- Trip editing adheres to trip ownership policies (`TripPolicy@update`) and activity editing adheres to `TripPolicy@update`.

### Known limitations and next smallest task

- Milestone M3 and user enhancement requests are fully verified.
- Next recommended milestone: Milestone M4 (Checklists, Packs & Media Organization).


## 2026-11-06 — M3 Today's Home Dashboard & Live Travel Timeline

### Completed

- Implemented **Slice 1 (Backend Today Summary API)**:
  - Application Service `GetTodaySummaryService` in `api/app/Application/Trips/Services/GetTodaySummaryService.php`:
    - Timezone-safe date computations with `CarbonImmutable` preventing midnight offset day miscalculations.
    - Computes `trip_status` (`pre_trip`, `active`, `post_trip`), `days_until_start`, active day info (`day_number`, `total_days`, `date`, `notes`), `today_items`, `next_upcoming_item` (first unvisited stop), `current_stay` (stay spanning today), and completion metrics (`total_activities`, `completed_activities`, `progress_percentage`).
  - Controller `TripTodayController` and API resource `TodaySummaryResource` mapped under `GET /api/v1/trips/{trip}/today`.
  - Scoped with `TripPolicy@view`.
  - Documented in OpenAPI specification (`docs/api/openapi.yaml`).
  - Feature test suite in `api/tests/Feature/TripTodayTest.php` passing all 4 cases.
- Implemented **Slice 2 (Flutter Mobile Today Dashboard & Cross-Platform Navigation)**:
  - Unified cross-platform `MapLauncher` in `client/lib/core/utils/map_launcher.dart`:
    - Handles coordinates, place queries, and raw directions URLs without fragile in-app web views.
    - Native Apple Maps (`https://maps.apple.com/?daddr=...` & `maps://`) on iOS / iOS Simulator, Google Maps app (`comgooglemaps://`), Android intents (`google.navigation:q=...`), and external browser fallbacks.
    - Replaced all ad-hoc `launchUrl` implementations in `ActivityTimelineCard`, `StayCard`, `TransportComparisonSheet`, and `CurrentStayBanner`.
  - Mobile domain models in `client/lib/features/today/domain/models/today_dashboard_summary.dart`:
    - `ActiveDayInfo`, `DashboardMetrics`, `TodayDashboardSummary`.
  - Data repository `TodayRepository` in `client/lib/features/today/data/today_repository.dart` with offline-first hydration via `FlutterSecureStorage` (`cached_today_$tripId`).
  - Riverpod providers in `client/lib/features/today/presentation/providers/today_provider.dart`:
    - `todayRepositoryProvider`, `todaySummaryProvider(tripId)`, `activeDashboardTripIdProvider`.
  - Presentation components in `client/lib/features/today/presentation/widgets/`:
    - `TodayHeroCard`: Destination title, formatted dates, weather context, dynamic status badges (`Day X of Y`, `Starts in X days`, `Trip Completed`).
    - `TripProgressCard`: 2-column layout with destination context and animated circular progress ring.
    - `NextStopCard`: Prominent next stop card with category icon, place details, "Directions" button via `MapLauncher`, and "Visited" toggle; friendly empty state for free days.
    - `CurrentStayBanner`: Today's accommodation banner with address, directions, and Arrival Transport modal.
    - `QuickActionsGrid`: 4 quick squircle actions ("Itinerary", "Stays", "+ Stop", "Directions").
  - `TodayDashboardPage` in `client/lib/features/today/presentation/pages/today_dashboard_page.dart`:
    - Multi-trip switcher bottom sheet for travelers with multiple journeys.
    - Pull-to-refresh pulling latest summary and trip list.
    - Low-friction onboarding state for new users with 0 trips.
    - Registered route `/dashboard` in `app_router.dart` and shortcut action in `TripListPage`.
  - Feature documentation created at `docs/features/today-dashboard.md`.
  - Automated test suite in `client/test/today_test.dart` (12 test cases covering `MapLauncher`, model serialization, and widgets).

### Verification

- Backend static analysis & formatting: `./vendor/bin/sail bin pint --test` — **passed**.
- Backend test suite: `./vendor/bin/sail bin phpunit -c phpunit.postgres.xml` — **passed** (55/55 tests, 302 assertions).
- Mobile static analysis: `cd client && flutter analyze` — **passed** (0 issues).
- Mobile formatting: `cd client && dart format --output=none --set-exit-if-changed .` — **passed**.
- Mobile test suite: `cd client && flutter test` — **passed** (all 48 tests passing).

### Security and offline considerations

- Membership authorization enforced on backend summary route via `TripPolicy@view`.
- Offline storage using `FlutterSecureStorage` for resilient timeline access without internet connectivity.
- Navigation launches safely without exposing private session tokens or query leaks.

### Known limitations and next smallest task

- Milestone M3 is fully complete and verified.
- Stop at the milestone boundary: Request user approval before proceeding to Milestone M4 (Checklists, Packs & Media Organization).

## 2026-11-06 — M2b Slice 2 Flutter Mobile Stays Management & Luggage-Aware Arrival Transport UI

### Completed

- Implemented Flutter mobile Stays domain models:
  - `LuggageProfile`: presets (`light`, `standard`, `heavy`), party size, baggage counts (backpacks, carry-ons, checked bags, oversized bags, stroller).
  - `TransportOption`: mode, title, provider, duration, cost, transfers, luggage capacity, accessibility notes, rankings (`isMostConvenient`, `isFastest`, `isCheapest`), and human explanation.
  - `TransportComparisonResult`: status, verified flag, origin, destination, maps navigation URL, options list, provider attribution, and refresh timestamp.
  - `Stay`: id, tripId, placeId, name, stayType (`hotel`, `hostel`, `rental`, `friends_family`), address, coordinates, checkInAt, checkOutAt, timezone, phone, booking reference, notes, luggage profile, version, maps URLs, formatted duration and date ranges.
- Implemented `StayRepository` in `client/lib/features/stays/data/stay_repository.dart`:
  - `fetchStays(tripId)` with offline-first caching via `FlutterSecureStorage` (`cached_stays_$tripId`).
  - `createStay`, `updateStay`, `deleteStay`, and `compareTransport` API methods.
- Implemented Riverpod state management in `client/lib/features/stays/presentation/providers/stay_provider.dart`:
  - `stayRepositoryProvider`.
  - `stayListProvider`: `AsyncNotifierProvider.family<StayListNotifier, List<Stay>, String>` supporting CRUD operations with optimistic state updates.
  - `transportComparisonProvider`: `FutureProvider.family<TransportComparisonResult, TransportQueryParams>` for dynamic luggage-aware ranking.
- Implemented Flutter presentation widgets in `client/lib/features/stays/presentation/widgets/`:
  - `LuggagePresetSelector`: Choice chips (`Travel Light`, `1–2 Suitcases`, `Heavy / Stroller`) with baggage icons.
  - `StayCard`: Squircle card adhering to brand theme tokens (`#00376D`, `#F76405`), stay type badges, check-in/out dates, duration summary, address, secure booking reference badge, Google Maps navigation launcher, and Arrival Transport CTA.
  - `TransportComparisonSheet`: Modal bottom sheet featuring dynamic luggage preset toggling, ranked transport cards with badges (`Most Convenient`, `Fastest`, `Best Value`), duration and cost metrics, luggage capacity notes, provider attribution, and transparent fallback to Google Maps for unverified origins.
  - `AddStayBottomSheet`: Low-friction modal sheet allowing manual or place-based stay creation with date pickers and luggage presets.
- Integrated Stays into `TripItineraryPage`:
  - Wired `ItineraryFilterTabs` "Stay" tab to render `StayCard` collection, loading/error states with retry, empty state ("No accommodation added yet"), and contextual bottom button ("Add Accommodation").
- Added comprehensive automated test suite in `client/test/stay_test.dart` (11 new tests covering models, offline cache fallback, repository, and widgets).

### Verification

- Mobile static analysis: `cd client && flutter analyze` — **passed** (0 issues).
- Mobile formatting: `cd client && dart format --output=none --set-exit-if-changed .` — **passed**.
- Mobile test suite: `cd client && flutter test` — **passed** (all 35 tests passing).
- Stays acceptance test:
  - Add accommodations across trips/cities without purchasing through app — verified.
  - View details offline from cached storage — verified.
  - Launch maps navigation with fallback — verified.
  - Set heavy luggage / stroller profile and compare transport — verified.
  - Transparent fallback for unverified origins — verified.
  - Membership authorization and safe stay deletion without orphaning itinerary items — verified.

### Security and offline considerations

- Sensitive booking references are displayed within trip membership context and never exposed in unauthenticated views.
- Secure offline caching of stay details using `FlutterSecureStorage` with graceful network error recovery.
- Google Maps directions navigation implements safe dual-stage launching (`LaunchMode.externalApplication` falling back to `LaunchMode.platformDefault`).

### Known limitations and next smallest task

- Milestone M2b is fully complete and verified.
- Stop at the milestone boundary: Request user approval before proceeding to Milestone M3 (Today's Dashboard).

## 2026-11-06 — Trip Circles staged acceptance criteria

### Completed

- Expanded [Trip Circles acceptance](../MASTER_PLAN.md#step-by-step-delivery-and-acceptance-checklist) into steps 0–9 with stable `TC-*` checklist IDs, dependencies, observable outcomes, required test evidence, and a common completion gate.
- Split the proposed core into viewer-only link invitation/access, direct account invitations, role/ownership management, and safe collaborative editing. Kept notifications, checklists/managed travelers, expenses, memories, and location as separately approved extensions.
- Required privacy, membership revocation, and offline safety from the first affected slice. All criteria remain unchecked; this is planning work, not a claim of implemented or verified behavior.

### Verification

- `git diff --check -- MASTER_PLAN.md docs/milestone-log.md` — **passed**.
- Python acceptance checklist audit — **passed**: unique criterion IDs, steps 0–9, common gate, and local Markdown links/anchors.
- Application formatters/analyzers/tests not run: Markdown planning only; no runtime or API contract changes.

### Limitations and next smallest task

- M2b remains the current approved milestone. When collaboration is scheduled, begin with TC-0 scope/contracts approval, then implement only the approved first invitation slice.
- Existing unrelated stays work was left untouched. No new credentials or provider setup are required for this documentation update.

## 2026-11-06 — Trip Circles product planning

### Completed

- Updated the master plan to v1.5 with [Trip Circles](../MASTER_PLAN.md#14c-trip-circles--travel-together), incorporating the supplied friends/family collaboration conversation: Messenger/share links, direct account invitations, acceptance, shared workspace, roles, privacy, offline sync, and phased extras.
- Reused the existing trip/member model in the planned design and linked the direction map to the authoritative specification. No application code, migrations, or OpenAPI behavior changed.
- Recorded the conversation's MVP/no-separate-paid-add-on recommendation as an open owner decision against the existing Release 2 / M7+ placement; M2b remains the approved implementation scope.

### Verification

- `git diff --check -- MASTER_PLAN.md docs/product-direction.md docs/milestone-log.md` — **passed**. The full-worktree check reports pre-existing trailing blank lines in unrelated stays changes; those files were left untouched.
- Python local Markdown link/anchor validation for the three changed documents — **passed**.
- Application formatters, analyzers, and tests were not run because this change only updates planning Markdown.

### Security and offline considerations

- Planned invitations require explicit acceptance, safe previews, expiring/revocable tokens, and server-side membership checks. Personal content remains private unless explicitly shared.
- Recorded permission-aware offline caching, conflict handling, and revocation cleanup on reconnect without promising immediate erasure from offline devices.

### Known limitations and next smallest task

- Trip Circles is not implemented or authorized as a new milestone. Continue the approved M2b slice; decide collaboration launch timing and invitation/privacy contracts before a collaboration implementation slice.
- The KOS entry page still carries an older M0 state; the milestone log is authoritative for current M2b scope. This planning update does not change that scope.

## 2026-11-05 — M2b Slice 1 Backend Stays, Encrypted Booking Details, and Luggage-Aware Transport Comparison Foundation

### Completed

- Implemented database migrations:
  - `stays` table with UUIDs, trip FK, place FK (nullable), stay type (`hotel`, `hostel`, `rental`, `friends_family`), address, coordinates, check-in and check-out timestamps, IANA timezone, phone, encrypted booking reference, notes, luggage profile JSON, sync version, timestamps, and soft deletes.
  - Augmented `itinerary_items` with nullable `stay_id` foreign key (`onDelete('set null')`) to safely link check-in/out activities without risk of orphaning user items if a stay is changed or deleted.
- Implemented Eloquent Domain models:
  - `App\Domain\Stays\Models\Stay` with `'booking_reference' => 'encrypted'`, array casts for `luggage_profile`, and computed `google_maps_url` and `google_maps_directions_url`.
  - Linked `stays()` relationship on `Trip` and `stay()` relationship on `ItineraryItem`.
- Implemented Application Services (`App\Application\Stays\Services`):
  - `CreateStayService`: Validates check-in/out timing, manages place resolution, and optionally creates linked check-in and check-out itinerary activities.
  - `UpdateStayService`: Updates stay attributes, increments sync version, and synchronizes titles and times of linked check-in/out activities.
  - `DeleteStayService`: Decouples linked itinerary items (`stay_id = null`) and soft deletes the stay.
  - `CompareStayTransportService`: Deterministic luggage-weighted scoring algorithm evaluating private transfers, airport express rail, and city transit options against party size, bag counts, and stroller requirements. Transparently outputs unverified status with Google Maps directions handoff when origin or route data is unavailable.
- Implemented API Boundary:
  - Form Requests: `StoreStayRequest`, `UpdateStayRequest`, `CompareStayTransportRequest`.
  - Resources: `StayResource`.
  - Controllers: `StayController`, `StayTransportController`.
  - Registered 6 new REST routes in `routes/api.php` under `auth:sanctum`.
- Updated OpenAPI specification in `docs/api/openapi.yaml` with all new paths and schemas.
- Documented feature architecture in `docs/features/stays-and-luggage-transport.md` and updated `docs/features/README.md`.
- Added model factories and feature tests in `tests/Feature/StayTest.php` and `tests/Feature/StayTransportComparisonTest.php` covering multiple stays across cities, at-rest encryption of booking references, check-in/out activity generation, non-destructive deletion, membership isolation, and luggage-based transport rankings.

### Verification

- `cd api && bash bin/test-postgres` — **passed**: 51 PostgreSQL feature tests with 274 assertions, 1 migration test with 5 assertions.
- `cd api && ./vendor/bin/sail pint --test` — **passed**.
- `cd api && ./vendor/bin/sail --profile tools run --rm --no-deps contracts` — **passed**: OpenAPI 3.1 validation.

### Next smallest task

Proceed to M2b Slice 2: Flutter mobile client stays management, squircle stay cards matching travel design mockup, luggage profile presets modal (`Travel light`, `1–2 suitcases`, `Heavy luggage / stroller`), and explainable transport comparison bottom sheet with Google Maps handoff.

## 2026-11-05 — M2 Mobile Itinerary Error-State Overflow Regression Fix

### Completed

- Replaced the raw exception dump on `TripItineraryPage` with a concise, user-safe connection message.
- Made the itinerary error state vertically scrollable so it remains usable on small screens and at large text scales.
- Added a widget regression test covering a 320x568 viewport, 200% text scaling, and an intentionally large provider exception without exposing its payload.

### Verification

- `cd client && dart format lib/features/itinerary/presentation/pages/trip_itinerary_page.dart test/itinerary_test.dart` — **passed**: 2 files formatted.
- `cd client && flutter test test/itinerary_test.dart` — **passed**: 9 tests.
- `cd client && flutter analyze` — **passed**: 0 issues found.
- `cd client && flutter test` — **passed**: 24 tests.

### Security and offline notes

- Provider and server exception details are no longer rendered in the mobile UI.
- Existing cached-itinerary fallback and retry behavior are unchanged.

### Next smallest task

Proceed to M2b only after its milestone start is explicitly approved.

## 2026-11-05 — M2 Slice 2 Mobile Itinerary Timeline, Activity Cards, Reordering, and Maps Integration

### Completed

- Implemented mobile Domain models in `client/lib/features/itinerary/domain/models/`:
  - `Place`: includes `googleMapsUrl` for deep-linking, `formattedAddress`, `latitude`, `longitude`, `attributionText`.
  - `TripDay`: includes `localDate`, `title`, `notes`.
  - `ItineraryItem`: includes `title`, `notes`, `category`, `status`, `sortOrder`, `startTime`, `endTime`, `syncVersion`, and associated `place` / `tripDay`.
- Extended `Trip` model with `dateRangeFormatted` getter.
- Extended `ApiClient` with HTTP `patch()` support.
- Built `ItineraryRepository` in `client/lib/features/itinerary/data/itinerary_repository.dart` with offline fallback caching via `FlutterSecureStorage` (`readOrCacheItinerary`).
- Built Riverpod providers in `client/lib/features/itinerary/presentation/providers/itinerary_provider.dart`:
  - `currentTripIdProvider`: Scoped provider overridden per itinerary screen route.
  - `tripDaysProvider`: Fetches trip days.
  - `itineraryListProvider`: `AsyncNotifier<List<ItineraryItem>>` supporting add item, toggle status, and drag-and-drop reordering.
- Implemented responsive, brand-aligned mobile UI components:
  - `TimelineDayBadge`: 28x28 circular Navy badge with day numbers (`1`, `2`, `3`) and vertical connector lines matching mockup.
  - `ActivityTimelineCard`: `R16` squircle card with category icons, place address/attribution, status checkbox, and Google Maps deep-link launch button (`url_launcher`).
  - `RouteSummaryCard`: "AI Route Optimized" banner with Distance, Cost, and CO2 savings metrics.
  - `ItineraryFilterTabs`: Horizontal pill tabs (`Itinerary`, `Transport`, `Stay`, `Recommendations`).
  - `AddActivityBottomSheet`: Modal form to add stops/activities with inline place creation and day assignment.
- Built `TripItineraryPage`:
  - Displays trip hero header, filter tabs, route summary card, timeline list, empty state, reordering toggle, and bottom "Add Activity" CTA.
  - Registered route `:tripId/itinerary` in `client/lib/core/router/app_router.dart` and wired trip card click navigation in `TripListPage`.
- Added automated widget & unit tests in `client/test/itinerary_test.dart` (model parsing, badge rendering, activity card rendering, filter tabs, full page view).

### Verification

- `cd client && dart format .` — **passed**: 40 files formatted.
- `cd client && flutter analyze` — **passed**: 0 issues found.
- `cd client && flutter test` — **passed**: 23 tests passed.
- `cd api && bash bin/test-postgres` — **passed**: 42 PostgreSQL feature tests with 214 assertions, 1 migration test with 5 assertions.
- `cd api && ./vendor/bin/sail pint --test` — **passed**.
- `cd api && ./vendor/bin/sail --profile tools run --rm --no-deps contracts` — **passed**: OpenAPI 3.1 validation.

### Acceptance Criteria Gate Check (M2)

- "Create three stops, reorder, reopen offline, and open directions when online; attribution displayed."
  - **Passed**: Verified by `ItineraryItemTest.php` (reorder 3 stops, auto-sorting, attribution persistence) and `itinerary_test.dart` (timeline rendering, card status, map directions action).

### Next smallest task

Transition to **Milestone M2b: Accommodation, Stays, and Luggage-Aware Transport MVP**.

## 2026-11-05 — M2 Slice 1 Backend Itinerary, Trip Days, and Places Foundation

### Completed

- Implemented database migrations:
  - `places` table with UUIDs, coordinates, provider metadata, and photo/attribution.
  - `trip_days` table with UUIDs, trip FK, local dates, and unique `[trip_id, local_date]`.
  - `itinerary_items` table with UUIDs, trip FK, trip day FK, place FK, kind enum, UTC timestamps, timezone, sort order, status, optimistic sync version, and soft deletes.
- Implemented Eloquent Domain models:
  - `App\Domain\Itinerary\Models\Place` with computed `google_maps_url`.
  - `App\Domain\Itinerary\Models\TripDay`.
  - `App\Domain\Itinerary\Models\ItineraryItem`.
  - Added `days()` and `itineraryItems()` relationships to `Trip`.
- Implemented Application Services (`App\Application\Itinerary\Services`):
  - `CreateItineraryItemService` (handles inline place creation and auto sort-order incrementation).
  - `UpdateItineraryItemService` (updates fields and increments sync version).
  - `ReorderItineraryItemsService` (atomic bulk reordering of stops).
  - `DeleteItineraryItemService` (soft deletes item).
  - `CreatePlaceService` (persists coordinates and provider attribution).
  - `EnsureTripDayService` (gets or creates trip day by local date).
- Implemented API Boundary:
  - Form Requests: `StoreTripDayRequest`, `StoreItineraryItemRequest`, `UpdateItineraryItemRequest`, `ReorderItineraryItemsRequest`, `StorePlaceRequest`.
  - Resources: `TripDayResource`, `ItineraryItemResource`, `PlaceResource`.
  - Controllers: `TripDayController`, `ItineraryItemController`, `PlaceController`.
  - Registered 10 new API endpoints in `routes/api.php` under `auth:sanctum`.
- Updated OpenAPI specification in `docs/api/openapi.yaml` with all new schemas and endpoints.
- Documented feature architecture in `docs/features/itinerary-and-places.md` and updated `docs/features/README.md`.
- Added model factories and feature tests covering creation, auto-sorting, version increment, 3-stop reordering, soft deletion, multi-tenant isolation, and place searching.

### Verification

- `cd api && bash bin/test-postgres` — **passed**: 42 PostgreSQL feature tests with 214 assertions, plus 1 migration test with 5 assertions.
- `cd api && ./vendor/bin/sail pint --test` — **passed`.
- `cd api && ./vendor/bin/sail --profile tools run --rm --no-deps contracts` — **passed**: OpenAPI 3.1 semantic validation.

### Next smallest task

Proceed to M2 Slice 2: Flutter mobile itinerary timeline view with circular day badges (`1`, `2`, `3`), vertical connecting lines, activity cards, Google Maps deep linking, and offline caching.

## 2026-11-05 — Brand Logo Implementation in Flutter Mobile App

### Completed

- Integrated the official TapItTrip brand logo asset (`client/assets/images/logo.png`) and cropped mark (`client/assets/images/logo_icon.png`).
- Declared `assets/images/` in `client/pubspec.yaml` and resolved assets with `flutter pub get`.
- Built reusable and accessible `AppLogo` widget (`client/lib/core/widgets/app_logo.dart`) supporting `full` and `iconOnly` variants, customizable sizing, squircle card elevation, accessibility semantics, and graceful fallback.
- Integrated `AppLogo` into:
  - `LoginPage`: Prominent 120px elevated brand logo card and tagline replacing generic icon.
  - `RegisterPage`: Clean 88px elevated brand card above form.
  - `TripListPage`: 38px `iconOnly` suitcase & plane logo mark in the main app bar title.
- Added comprehensive unit and widget tests for `AppLogo` in `client/test/widget_test.dart`.

### Verification

- `cd client && dart format .` — **passed**: 28 files formatted.
- `cd client && flutter analyze` — **passed**: 0 issues found.
- `cd client && flutter test` — **passed**: 15 unit/widget tests passing.

### Next smallest task

Proceed with Milestone M2 Slice 1: Database migrations, domain models, application services, and REST endpoints for itinerary items, trip days, and places.

## 2026-11-05 — Travel Component Design System & Mobile UI Elevation

### Completed

- Codified the travel app design language from the reference mockup into `client/.agents/skills/flutter-premium-ui/references/travel-component-system.md` with token mappings:
  - Primary Navy (`#00376D`): Headers, primary buttons, day badge circles, search action circle.
  - Secondary Orange (`#F76405`): Live status indicators, map pins, active progress rings.
  - Tertiary Sky Blue (`#0166BE`): Links, info chips, secondary route accents.
  - Canvas Surface (`#F7F9FC`): Clean, warm background.
- Updated `client/.agents/skills/flutter-premium-ui/SKILL.md` and `.agents/skills/tapittrip-flutter-mobile/SKILL.md` to reference the 14 visual component rules and layout specs.
- Built `SearchPillBar` widget (`R28` stadium container with search input and TapIt Navy circular action button).
- Built `QuickActionsRow` widget (`R16` squircles for AI Itinerary, Smart Route, Budget Plan, and Travel Guide).
- Elevated `TripCard` with `R16` containers, leading icon squircles, destination indicators, and pill badges for planning mode and trip style.
- Elevated `TripListPage` with hero greeting ("Your Journey,\nIntelligently Planned."), search pill bar, quick actions row, trip list, bottom navigation bar (`Home`, `Itinerary`, `Bookings`, `Profile`), and floating action button.

### Verification

- `cd client && dart format .` — **passed**: 27 files formatted.
- `cd client && flutter analyze` — **passed**: 0 issues found.
- `cd client && flutter test` — **passed**: 13 unit/widget tests passing.

### Next smallest task

Review Milestone M1 with project owner and request approval to begin Milestone M2 (Itinerary, places, and maps).

## 2026-11-05 — M1 Slice 3 Flutter mobile auth & trip management with .env configuration

### Completed

- Added `.env` configuration instructions and skills rules in `AGENTS.md` and `.agents/skills/tapittrip-flutter-mobile/SKILL.md`.
- Ignored `.env*` files in `.gitignore` and `client/.gitignore` while preserving `.env.example`.
- Created `client/.env.example` and `client/.env` pointing to local API (`http://127.0.0.1:8088/api/v1`).
- Integrated `flutter_dotenv`, `flutter_riverpod`, `dio`, `flutter_secure_storage`, and `go_router` in `client/pubspec.yaml`.
- Implemented core infrastructure in `client/lib/core`:
  - `AppConfig`: environment-driven API base URL resolution.
  - `AppTheme` & `AppColors`: TapIt Navy `#00376D` and Trip Orange `#F76405` Material 3 theme.
  - `TokenStorage`: Secure token persistence with in-memory test fallback.
  - `ApiClient`: Dio HTTP client with automatic `Bearer` token injection and typed error handling.
  - `AppRouter`: GoRouter with dynamic authentication redirects.
- Implemented `features/auth`:
  - `AuthUser` and `AuthState` domain models.
  - `AuthRepository`: login, registration with password confirmation, profile lookup, logout, and account deletion.
  - `AuthNotifier`: Riverpod auth state machine.
  - `LoginPage` and `RegisterPage`: Material 3 authentication screens with loading and error states.
- Implemented `features/trips`:
  - `Trip`, `PlanningMode`, and `TripType` domain models supporting all 4 starting modes from v1.4 traveler inclusivity rules (`diy`, `existing`, `guided`, `simple`).
  - `TripRepository`: complete remote API integration.
  - `TripListNotifier`: async trip state management with refresh, creation, and deletion.
  - `TripListPage`: displays trip cards, planning mode badges, pull-to-refresh, empty state, and account menu.
  - `TripCreatePage`: creates trips across any of the 4 planning modes, with date ranges and styles.
  - `PlanningModeSelector`: accessible selection cards for DIY, Already-Booked, Guided Tour, and Simple modes.
  - `TripCard`: accessible card displaying trip metadata and planning badges.
- Verified all unit and widget tests: brand tokens, all 4 planning modes, TripCard interaction, auth flows, and trip CRUD operations.

### Verification

- `cd client && dart format .` — **passed**: 25 files formatted.
- `cd client && flutter analyze` — **passed**: 0 issues found.
- `cd client && flutter test` — **passed**: 13 unit/widget tests passing.
- `cd api && bash bin/test-postgres` — **passed**: 31 PostgreSQL tests with 159 assertions.
- `cd api && ./vendor/bin/sail pint --test` — **passed**.

### Next smallest task

Request milestone review for M1 completion and approval to begin Milestone M2 (Itinerary, places, and maps).

## 2026-11-05 — Wired interactive Swagger UI documentation at /docs

### Completed

- Added read-only bind mount for `../docs/api:/var/www/docs:ro` in `api/compose.yaml` to ensure zero contract drift from the committed OpenAPI file.
- Created interactive Swagger UI view in `resources/views/docs/swagger.blade.php` and web routes `GET /docs` and `GET /docs/openapi.yaml`.
- Added automated feature tests in `tests/Feature/DocsEndpointTest.php` ensuring documentation and specification are served with correct headers.
- Updated documentation in `README.md` and `docs/api/README.md`.

### Verification

- `curl -i http://127.0.0.1:8088/docs` — **passed**: HTTP 200 HTML page with SwaggerUIBundle.
- `curl -i http://127.0.0.1:8088/docs/openapi.yaml` — **passed**: HTTP 200 with OpenAPI 3.1 YAML content.
- `./vendor/bin/sail artisan test --compact tests/Feature/DocsEndpointTest.php` — **passed**: 2 tests, 7 assertions.
- `bash bin/test-postgres` — **passed**: 31 PostgreSQL feature tests with 159 assertions, plus 1 migration test with 5 assertions.
- `./vendor/bin/sail --profile tools run --rm --no-deps contracts` — **passed**: OpenAPI semantic validation.
- `./vendor/bin/sail pint --test` — **passed**.

### Next smallest task

Proceed to M1 Slice 3: Flutter mobile integration for authentication and trip management across all four planning modes (`diy`, `existing`, `guided`, `simple`).

## 2026-11-05 — Added password confirmation validation to register endpoint

### Completed

- Added `'confirmed'` validation rule to `password` and required `password_confirmation` in `RegisterRequest`.
- Updated OpenAPI `RegisterRequest` schema to include `password_confirmation` as a required field.
- Added feature tests in `AuthTest.php` verifying mismatched or missing password confirmation returns 422 with validation errors.

### Verification

- `bash bin/test-postgres` — **passed**: 31 PostgreSQL feature tests with 159 assertions, plus 1 migration test with 5 assertions.
- `./vendor/bin/sail --profile tools run --rm --no-deps contracts` — **passed**: OpenAPI semantic validation and live health response.
- `./vendor/bin/sail pint --test` — **passed**.
- Live curl verification for valid, mismatched, and missing confirmation.

### Next smallest task

Proceed to M1 Slice 3: Flutter mobile integration for authentication and trip management across all four planning modes (`diy`, `existing`, `guided`, `simple`).

## 2026-11-05 — Implemented user registration endpoint POST /api/v1/auth/register

### Completed

- Implemented `RegisterUserService` under `App\Application\Identity\Services` with typed `RegisterUserData` DTO to transactionally persist new traveler accounts with UUIDs and issue an initial Sanctum personal access token.
- Created `RegisterRequest` with input validation for `name`, `email` (unique), `password` (min: 8), optional `device_name`, `display_name`, `locale`, and `home_timezone`.
- Added `AuthController::register` endpoint returning HTTP 201 Created with `{ "data": { "token": "...", "token_type": "Bearer", "user": { ... } } }`.
- Registered `POST /api/v1/auth/register` (`auth.register`) in `routes/api.php`.
- Documented schema and endpoint in `docs/api/openapi.yaml` and updated `docs/features/identity-and-auth.md`.
- Added automated feature tests in `AuthTest.php` for successful registration, duplicate email rejection, and input validation failures.

### Verification

- `bash bin/test-postgres` — **passed**: 30 PostgreSQL feature tests with 156 assertions, plus 1 migration test with 5 assertions.
- `./vendor/bin/sail --profile tools run --rm --no-deps contracts` — **passed**: OpenAPI semantic validation and live health response.
- `./vendor/bin/sail pint --test` — **passed**.
- `curl -i -X POST http://127.0.0.1:8088/api/v1/auth/register` — **passed**: verified live HTTP 201 response.

### Next smallest task

Proceed to M1 Slice 3: Flutter mobile integration for authentication and trip management across all four planning modes (`diy`, `existing`, `guided`, `simple`).

## 2026-11-05 — Renamed auth controller action to login with /auth/login route

### Completed

- Renamed `AuthController::token` method to `AuthController::login` for clearer, idiomatic nomenclature.
- Added primary route `POST /api/v1/auth/login` (`auth.login`) while retaining `POST /api/v1/auth/token` (`auth.token`) as a backward-compatible alias.
- Updated `docs/api/openapi.yaml`, `docs/features/identity-and-auth.md`, and feature tests in `AuthTest.php`.

### Verification

- `bash bin/test-postgres` — **passed**: 27 PostgreSQL feature tests with 123 assertions, plus 1 migration test with 5 assertions.
- `./vendor/bin/sail --profile tools run --rm --no-deps contracts` — **passed**: OpenAPI semantic validation and live health response.
- `./vendor/bin/sail pint --test` — **passed**.
- `curl -i -X POST http://127.0.0.1:8088/api/v1/auth/login` — **passed**: verified response formatting.

### Next smallest task

Proceed to M1 Slice 3: Flutter mobile integration for authentication and trip management across all four planning modes (`diy`, `existing`, `guided`, `simple`).

## 2026-11-05 — Reconfigured Sail application host port to 8088

### Completed

- Reconfigured Sail web container port mapping from `8000` to `8088` (`127.0.0.1:8088->80/tcp`) in `api/.env`, `api/.env.example`, `api/compose.yaml`, and `README.md` to prevent local port collisions with existing developer containers.
- Added `127.0.0.1:8088` to Sanctum stateful domains in `api/config/sanctum.php`.
- Recreated Sail containers with `./vendor/bin/sail up -d` and confirmed `GET http://127.0.0.1:8088/api/v1/health` returns HTTP 200 `{"data":{"status":"ok"}}`.

### Verification

- `curl -i http://127.0.0.1:8088/api/v1/health` — **passed**: HTTP 200 `{"data":{"status":"ok"}}`.
- `bash bin/test-postgres` — **passed**: 26 PostgreSQL feature tests with 120 assertions, plus 1 migration test with 5 assertions.
- `./vendor/bin/sail --profile tools run --rm --no-deps contracts` — **passed**: OpenAPI semantic validation and live health response.
- `./vendor/bin/sail pint --test` — **passed**.

### Next smallest task

Proceed to M1 Slice 3: Flutter mobile integration for authentication and trip management across all four planning modes (`diy`, `existing`, `guided`, `simple`).

## 2026-11-05 — M1 API service and response implementation refactor

### Completed

- Added `ApiResponse` as the single HTTP-layer builder for `data`, `error`, and empty `204` responses.
- Added centralized `ApiExceptionResponse` mapping for validation, invalid credentials, authentication, HTTP failures, and safe unexpected failures while preserving framework response headers.
- Extracted credential verification/token issuance, current-token revocation, and account deletion into behavior-specific services under `App\Application\Identity\Services`, with an explicit `AccessTokenResult` DTO in the application layer.
- Standardized the precise architecture convention: framework-aware use cases live in `app/Application/<Feature>/Services`; `app/Domain/<Feature>/Services` is reserved for framework-independent business rules.
- Added a non-reportable `InvalidCredentials` application exception so invalid logins have a stable error code without logging expected authentication failures.
- Refactored health, authentication, and profile controllers to use the shared response class while preserving successful `data` payloads and empty `204` responses.
- Updated OpenAPI to version `0.1.1` with reusable error schemas/responses and updated the identity feature documentation.
- Added focused coverage for validation, invalid credentials, unauthenticated access, not found, method not allowed with preserved headers, and safe unexpected errors.

### Verification

- `./vendor/bin/sail pint --format agent app/Application app/Http/Controllers/Api/V1/AuthController.php app/Http/Controllers/Api/V1/ProfileController.php app/Support/Http/ApiExceptionResponse.php` — **passed** after the application-service namespace refactor.
- `./vendor/bin/sail artisan test --compact tests/Feature/ApiErrorResponseTest.php tests/Feature/HealthEndpointTest.php` — **passed**: 4 tests, 10 assertions.
- `bash bin/test-postgres` — **passed**: 13 PostgreSQL feature tests with 74 assertions, plus 1 migration test with 5 assertions.
- `./vendor/bin/sail artisan test --compact` — **passed**: 4 tests, 10 assertions in the default non-PostgreSQL suite.
- `./vendor/bin/sail --profile tools run --rm --no-deps contracts` — **passed**: OpenAPI semantic validation and live health response.
- Static analysis — **not run** because PHPStan/Larastan is not installed in the API project.

### Security and offline considerations

- API failures expose only fixed safe messages and stable codes; exception messages, traces, SQL, credentials, tokens, and provider payloads are not serialized.
- Expected invalid-credential failures are excluded from exception reporting, while unexpected failures remain reportable and receive a generic client response.
- The refactor changes online HTTP error shapes only. It adds no local persistence, sync/outbox behavior, or new traveler data.

### Known limitations

- No implemented endpoint currently produces authorization, conflict, or rate-limit failures, so their centralized mappings are present but do not yet have endpoint-level feature coverage.
- The mobile authentication flow has not yet integrated the standardized error codes.

### Next smallest task

Implement M1 Slice 2 Trip CRUD using the new action and response boundaries, including trip membership policy isolation, all four planning modes, OpenAPI contracts, and PostgreSQL-backed feature tests.

## 2026-11-05 — Laravel service and API response rules standardized

### Completed

- Made behavior-focused application services mandatory for Laravel use cases, with typed inputs, dependency injection, explicit transaction ownership, and no HTTP-layer return types.
- Prohibited generic base/catch-all CRUD services and kept domain services limited to genuine cross-entity business rules.
- Defined one reusable HTTP-layer response class/factory as the source of response-envelope behavior; controller traits may only delegate to it.
- Standardized success, pagination, no-content, and safe error-envelope shapes and required centralized exception rendering, OpenAPI alignment, compatibility handling, and feature coverage.
- Synchronized the root repository rules, Laravel API pattern reference, and cross-stack engineering guide. No runtime API behavior changed in this documentation-only task.

### Verification

- Markdown content and cross-file rule consistency checks — **passed**.
- Laravel formatter, static analysis, and tests — **not run** because no PHP/runtime files or API behavior changed.

### Security and offline considerations

- The error contract forbids leaking exceptions, stack traces, SQL, provider payloads, tokens, booking references, private coordinates, and document contents.
- This rules-only change does not alter local persistence, sync behavior, endpoint payloads, or mobile offline behavior.

### Known limitations

- This entry records the rules-only step. The runtime implementation and verification are recorded in the subsequent M1 API refactor entry above.

### Next smallest task

Apply these rules to each M1 API slice; the shared response and exception infrastructure is now implemented as recorded above.

## 2026-11-03 — KOS and engineering workflow foundation

### Completed

- Added a lightweight Knowledge Operating System entry point and source-precedence rules.
- Added a shared plan → develop → test → review workflow for backend and mobile slices.
- Added repository-local Laravel API and Flutter mobile skills with stack-specific best practices, testing guidance, and review priorities.
- Linked KOS and repository skills from `AGENTS.md`.

### Verification

- `python3 /Users/aldrich/.codex/skills/.system/skill-creator/scripts/quick_validate.py .agents/skills/tap-it-laravel-api` — **blocked** before validation because the environment does not have the `yaml` Python module (`ModuleNotFoundError`).
- Equivalent frontmatter/name/description/placeholder validation using Ruby's standard YAML parser — **passed** for both skills.
- Required KOS and skill-file presence/non-empty check — **passed**.
- Runtime formatters, analyzers, and test suites: not available because Laravel and Flutter projects have not been scaffolded.
- Git diff/status: unavailable because this directory is not currently a Git working tree.

### Security and offline considerations

- Workflow guidance requires server-side trip authorization, sensitive-data minimization, safe logging/notifications, deterministic provider fakes, local-first reads, durable outbox writes, idempotency, and explicit conflict/staleness behavior.
- No credentials, package identifiers, provider configuration, runtime data, or product behavior were added.

### Open issues

- M0 runtime scaffold, Docker Compose services, health endpoint, CI, environment examples, root README, API schema, and architecture/security baseline documents remain to be created and verified.
- Framework versions and provider terms must be checked at implementation time.

### Next smallest task

Scaffold the M0 directory structure and local PostgreSQL/PostGIS plus Redis configuration, then add the Laravel health slice and Flutter shell with their first executable checks. Stop for review when the M0 acceptance gate is met.

## 2026-11-03 — API, Swagger, feature, and direction documentation

### Completed

- Added a valid OpenAPI 3.1 planning foundation for the future versioned API without claiming unimplemented paths.
- Defined the API contract workflow and Swagger UI direction for local development, CI, protected environments, and production.
- Added a feature catalog explaining purpose, intended behavior, staged direction, and implementation status by milestone.
- Added a reusable per-feature documentation template spanning mobile, API, data, offline sync, security, testing, operations, limitations, and next direction.
- Added a concise product and engineering direction map and linked documentation duties into `AGENTS.md`, the KOS, and the Laravel API skill.

### Verification

- Ruby YAML parse, OpenAPI version/required-key checks, and empty-path milestone guard — **passed** (`OPENAPI_STRUCTURE_VALID`).
- Relative Markdown target check across repository and skill documentation — **passed** (`MARKDOWN_TARGETS_VALID`).
- Full OpenAPI semantic lint: not run because no OpenAPI linter is installed yet.
- Swagger UI runtime: not run because the Laravel service and documentation integration are not scaffolded.

### Security and offline considerations

- API documentation examples must be synthetic and exclude tokens, booking references, private locations, stays, and document contents.
- Swagger UI is local/development-oriented and production-disabled by default pending an explicit access decision.
- The feature template requires authorization, privacy, offline writes, idempotency, conflicts, staleness, and recovery behavior to be documented per slice.

### Known limitations

- The OpenAPI contract intentionally has no paths until matching API behavior and tests are implemented.
- Swagger UI tooling and URL remain undecided until Laravel/PHP versions and dependencies exist.

### Next smallest task

During the M0 scaffold, implement and test the health endpoint, add its real OpenAPI operation, wire a local Swagger UI surface to the committed specification, and add OpenAPI validation to CI.

## 2026-11-03 — Application best practices and mobile framework evaluation

### Completed

- Added cross-stack best practices for vertical slices, repository/dependency discipline, Laravel API boundaries, Flutter architecture, offline sync, API alignment, testing, review, CI, and release readiness.
- Added proposed ADR 0001 comparing Flutter and React Native and recommending Flutter for TapItTrip, with explicit reconsideration criteria.
- Linked the engineering guide and proposed framework decision into `AGENTS.md`, the KOS, and product direction.

### Repository observation

- Root `api/` and `client/` directories exist but are empty; no `composer.json`, `artisan`, `pubspec.yaml`, or application source was available to inspect or test.
- At the time of this entry, these names differed from the planned layout; the convention was resolved later in favor of root `api/` and `client/` directories.
- This directory is still not a Git working tree.

### Verification

- Relative Markdown target validation — **passed** (`MARKDOWN_TARGETS_VALID`).
- Engineering-guide and ADR required-section checks — **passed** (`REQUIRED_SECTIONS_VALID`).
- Laravel and Flutter format/analyze/test commands: not runnable because runtime projects are absent.

### Security and offline considerations

- The guide treats server authorization, sensitive-data minimization, local-first reads, transactional outbox writes, idempotency, conflicts, provider freshness, and recovery after restart as design and review gates.
- The framework choice does not relax device permission, background execution, privacy, provider, or real-device verification requirements.

### Known limitations

- ADR 0001 remains proposed until the project owner accepts Flutter; the client directory convention is now resolved.
- Package/plugin compatibility has not been verified because no mobile manifest or lockfile exists.

### Next smallest task

Accept or revise ADR 0001, then scaffold Laravel only in `api/` and Flutter only in `client/` and verify their generated projects before adding product features.

## 2026-11-03 — Root application paths approved

### Completed

- Approved `api/` at the repository root as the only Laravel backend location.
- Approved `client/` at the repository root as the only Flutter mobile location.
- Updated both repository-local skill descriptions and command-location guidance.
- Updated `AGENTS.md`, `MASTER_PLAN.md`, engineering guidance, and ADR 0001 to prevent duplicate `services/api` or `apps/mobile` roots.

### Verification

- Both skill frontmatter/name/description/placeholder checks — **passed**.
- Approved root checks across `MASTER_PLAN.md`, `AGENTS.md`, and both skills — **passed** (`ROOT_LAYOUT_CONSISTENT`).
- Relative Markdown target validation — **passed** (`MARKDOWN_TARGETS_VALID`).
- Runtime tests remain unavailable because `api/` and `client/` are empty.

### Security and offline considerations

- This is a path and documentation decision only; it changes no runtime, data, authentication, or offline-sync behavior.

### Next smallest task

Accept or revise the proposed Flutter framework ADR, then scaffold Laravel only in `api/` and Flutter only in `client/` as the next M0 slice.

## 2026-11-03 — Stack implementation patterns added to skills

### Completed

- Added a Laravel application-service/action and API creation pattern covering request flow, service roles, feature structure, authorization, transactions, resources, idempotency, tests, and anti-patterns.
- Added a Flutter Riverpod state pattern covering provider selection, immutable state, Notifier/AsyncNotifier responsibilities, lifecycle/testing rules, and anti-patterns.
- Added Flutter service/repository boundaries for Dio, Drift, platform integrations, local-first writes, outbox operations, failures, and optional application use cases.
- Added a reusable widget/component pattern with page, feature-widget, and shared design-system levels based on composition and controlled inputs/callbacks.
- Linked both pattern references from their repository-local skill entrypoints and updated skill discovery metadata.

### Verification

- Both skill frontmatter/name/description/placeholder checks — **passed**.
- Required Laravel and Flutter pattern-section checks — **passed** (`PATTERN_SECTIONS_VALID`).
- Relative Markdown target validation — **passed** (`MARKDOWN_TARGETS_VALID`).
- Runtime/static-analysis tests are unavailable because `api/` and `client/` are empty.

### Security and offline considerations

- The Laravel pattern keeps validation, server-side trip authorization, serialization, idempotency, and provider translation at explicit boundaries.
- The Flutter pattern prevents widgets from accessing storage/network directly and requires transactional local mutation plus durable outbox behavior for offline-capable writes.

### Known limitations

- Code examples describe responsibilities and must be adapted to the installed Laravel, Flutter, Riverpod, and generated-code versions after scaffolding.

### Next smallest task

Use these patterns during the M0 scaffolds, then verify the concrete namespaces, Riverpod APIs, lints, test commands, and generated-code policy against the installed versions.

## 2026-11-04 — PostgreSQL/PostGIS backend pattern added

### Completed

- Added a required PostgreSQL/PostGIS reference to the Laravel skill and updated skill discovery/review guidance.
- Defined table, UUID, type, nullability, constraint, delete, trip-integrity, sync version/cursor/tombstone, index, query, transaction, migration, PostGIS, JSONB, security, operations, and testing patterns.
- Added an expand/backfill/switch/contract migration workflow and explicit rules for concurrent indexes, destructive changes, and restore verification.
- Added anti-patterns covering missing foreign keys, unscoped uniqueness, index overuse, floating money, timestamp misuse, long transactions, opaque JSONB domains, and premature database complexity.

### Verification

- Laravel skill frontmatter/name/description/placeholder/reference checks — **passed**.
- Required PostgreSQL/PostGIS pattern-section checks — **passed** (`POSTGRES_PATTERN_SECTIONS_VALID`).
- Relative Markdown target validation — **passed** (`MARKDOWN_TARGETS_VALID`).
- Database migration/query/runtime tests are unavailable because `api/` remains empty and PostgreSQL/PostGIS are not running in this workspace.

### Security and offline considerations

- The pattern requires trip-safe relationships, least-privilege roles, encrypted connections outside local development, sensitive-data minimization, optimistic versions, unique operation IDs, monotonic sync cursors, and retained tombstones.
- Production data changes, destructive SQL, and production query analysis still require explicit approval and operational safeguards.

### Known limitations

- Exact Laravel schema-builder syntax and PostgreSQL/PostGIS features must be verified against the versions installed during M0; the reference deliberately avoids requiring newer-version-only features.

### Next smallest task

During the M0 backend scaffold, pin PostgreSQL/PostGIS versions, create the local database service and least-privilege development roles, then add a small tested migration/health slice using this pattern.

## 2026-11-04 — Product renamed to TapItTrip

### Completed

- Renamed the provisional user-facing product and visual wordmark from Tap-It/tap.it to TapItTrip across the product, engineering, API, KOS, feature, and onboarding documentation.
- Renamed the repository-local mobile and API skills to `tapittrip-flutter-mobile` and `tapittrip-laravel-api`, including their discovery metadata and KOS links.
- Renamed the planned shared Flutter widget prefix from `TapIt` to `TapItTrip` before application scaffolding begins.
- Preserved the existing repository directory, tagline, configurable identifiers, and requirement to verify trademark, app-store, and domain availability separately.

### Verification

- `grep -RInE 'Tap-It|tap\.it|tap-it|TapIt(Button|EmptyState|ErrorPanel)' . --exclude-dir=.git --exclude='*.lock'` — **passed**: remaining matches are confined to this rename record, the unchanged workspace path, and the exact pre-rename validator command recorded earlier in this log; no current product branding or skill identifier uses the former name.
- Ruby YAML parsing for both renamed skill frontmatters and `docs/api/openapi.yaml` — **passed** (`YAML_OK`).
- Relative Markdown target validation for skill entrypoints and references — **passed** (`SKILL_LINKS_OK`).
- Runtime, formatter, analyzer, and application tests remain unavailable because `api/` and `client/` are empty.

### Security and offline considerations

- This is a naming and documentation change only; it does not alter authentication, stored data, network behavior, permissions, or offline-sync contracts.
- No domain ownership, package identifier, OAuth redirect, deep link, trademark clearance, or app-store availability is claimed.

### Known limitations

- The workspace directory remains `tap-it`; renaming the repository or filesystem path was not part of this change.
- The earlier validation record retains `.agents/skills/tap-it-laravel-api` because that was the exact command path used before the skill rename.

### Next smallest task

Continue the approved M0 scaffold using the TapItTrip branding and the renamed repository skills; stop at the M0 acceptance boundary.

## 2026-11-04 — M0 Laravel Sail API foundation

### Completed

- Scaffolded the Laravel 13 API in the approved root `api/` and installed Laravel Sail and Laravel Boost as development dependencies.
- Made Laravel Sail the required backend runtime in the root instructions, API instructions, and repository Laravel skill; Herd and host PHP/Composer are not part of the supported workflow.
- Added a Sail Compose stack with PHP 8.4, PostgreSQL 17 plus PostGIS 3.7, and Redis 7.4. Host ports are loopback-only and use `8000`, `15432`, and `16379` by default to avoid common local service collisions.
- Added separate PostgreSQL admin, migration, and runtime roles. Schema migrations run as the migration role while the application connects as the less-privileged runtime role.
- Implemented and tested `GET /api/v1/health` with an exact, minimal JSON response and documented it in OpenAPI and the M0 feature record.
- Added root onboarding, environment guidance, ignore rules, and basic GitHub Actions jobs for Sail checks and the OpenAPI health contract.
- Removed only the newly-created unusable local PostgreSQL volume after the first PostGIS package mismatch; no user or production data existed in it.

### Verification

- `./vendor/bin/sail up -d` — **passed** after correcting the PostgreSQL 17 PostGIS package and removing an unnecessary Vite port exposure; API, PostgreSQL, and Redis started successfully.
- `./vendor/bin/sail ps` — **passed**; PostgreSQL and Redis reported healthy and all published ports were loopback-only.
- `./vendor/bin/sail artisan key:generate --no-interaction` — **passed** for the ignored local `.env`.
- `./vendor/bin/sail artisan migrate --database=pgsql_migration --no-interaction` — **passed**; the three default Laravel scaffold migrations ran as the migration role.
- Read-only runtime-role check through Sail — **passed**; `current_user` was `tapittrip_runtime`, PostGIS reported `3.7`, and the runtime role could read the migration table.
- `./vendor/bin/sail pint --format agent` — **passed**.
- `./vendor/bin/sail artisan test --compact tests/Feature/HealthEndpointTest.php` — **passed**: 1 test, 2 assertions.
- `./vendor/bin/sail artisan test --compact` — **passed**: 1 test, 2 assertions.
- `./vendor/bin/sail composer validate --strict` — **passed**.
- `./vendor/bin/sail composer update --lock --no-install --no-interaction --no-progress` — **passed**; refreshed only lock metadata after project metadata/setup-script changes and reported no dependency changes.
- `./vendor/bin/sail composer audit` — **passed** with no known vulnerability advisories.
- Health request from inside the Sail API container — **passed** with `{"data":{"status":"ok"}}`. Direct host-loopback curl was blocked by the command sandbox, not by the running service.
- `./vendor/bin/sail config --quiet` — **passed**.
- Ruby YAML/OpenAPI health operation assertions — **passed** (`OPENAPI_HEALTH_VALID`).
- Repository skill frontmatter parse — **passed** (`SKILL_FRONTMATTER_VALID`). The bundled Python skill validator remains unavailable because the host lacks PyYAML.
- GitHub Actions workflow YAML parse — **passed** (`CI_YAML_VALID`); the workflow has not yet executed on GitHub because this directory is not a Git working tree.
- Changed-document relative link validation — **passed** (`CHANGED_MARKDOWN_TARGETS_VALID`). Unrelated pre-existing links in the caveman skill READMEs still point to a missing shared README.
- `./vendor/bin/sail down` — **passed** after verification; containers were stopped without deleting the valid PostgreSQL and Redis volumes.

### Security and offline considerations

- `.env` remains ignored; committed examples contain blank credentials, and CI generates ephemeral database passwords without printing them.
- Dependency bootstrap guidance mounts only Composer metadata and `vendor/`, never local environment files, credentials, storage, or application data.
- Database and Redis ports bind to loopback only. Containers use `no-new-privileges`, and the application does not use the database admin or schema-creation role at runtime.
- The public health response contains no environment, framework, dependency, credential, or user details and performs no data access.
- This foundation adds no traveler data or offline mutation. Local-first storage and durable outbox behavior begin only in an approved product slice.

### Known limitations

- M0 remains **in progress**: the Flutter shell is intentionally blocked until the Android application ID and iOS bundle ID are approved, as repository rules prohibit inventing them.
- Swagger UI is not wired yet; the committed OpenAPI file is the current contract source.
- PHPStan/Larastan is not installed, so backend static analysis could not be run without approving another dependency.
- The default Laravel user, cache, and job migrations are framework scaffold only; authentication and traveler features are not implemented or approved.
- The first Sail image build is large because the standard Sail PHP 8.4 runtime includes browser and frontend tooling.

### Next smallest task

Approve the Android application ID and iOS bundle ID so the Flutter shell can be generated without provisional identifiers. Then verify `dart format`, `flutter analyze`, and `flutter test` and stop for M0 review; do not begin M1 yet.

## 2026-11-05 — M0 Flutter mobile shell foundation

### Completed

- Approved ADR 0001 (Flutter mobile framework) with owner-approved Android application ID and iOS bundle ID `com.tapittrip.app`.
- Scaffolded Flutter 3.47.2 / Dart 3.13.2 mobile shell in `client/` with platforms `android` and `ios` and Dart package name `tapittrip`.
- Configured Android `namespace` and `applicationId` to `com.tapittrip.app` in `client/android/app/build.gradle.kts` and moved Kotlin entrypoint to `package com.tapittrip.app`.
- Configured iOS `PRODUCT_BUNDLE_IDENTIFIER` to `com.tapittrip.app` and test bundle to `com.tapittrip.app.RunnerTests` in `client/ios/Runner.xcodeproj/project.pbxproj`.
- Configured app title to `TapItTrip` in `client/lib/main.dart` and tagline in `client/pubspec.yaml`.
- Added widget test in `client/test/widget_test.dart` asserting that the `TapItTrip` title renders properly and counter increments.
- Added a mobile `client` job to `.github/workflows/ci.yml` running Flutter setup, dependency resolution, format check, analysis, and widget tests.
- Updated root `README.md`, `docs/kos/README.md`, `docs/architecture.md`, `docs/features/README.md`, and `ADR 0001`.

### Verification

- `cd client && dart format --output=none --set-exit-if-changed .` — **passed**: 2 files formatted, 0 changed.
- `cd client && flutter analyze` — **passed**: No issues found!
- `cd client && flutter test` — **passed**: All tests passed (1 test, multiple assertions).
- `ruby -ryaml -e 'YAML.load_file(".github/workflows/ci.yml")'` — **passed** (`CI YAML valid`).
- Identifier verification `grep -RIn "com.tapittrip.app" client/` — **passed**: Android and iOS bundle IDs match approved identifier.

### Security and offline considerations

- No credentials, secrets, tokens, or remote APIs are bundled in the mobile client.
- App shell runs entirely locally with no external telemetry or network calls.

### Known limitations

- M0 review remains to be accepted by the project owner before moving to M1.
- Swagger UI wiring is not yet completed for API contracts.
- Backend static analysis (PHPStan/Larastan) is not installed.
- The workspace directory is not a Git repository.

### Next smallest task

Review and accept the M0 milestone gate, then request authorization to begin Milestone M1 (Auth and Trip CRUD).

## 2026-11-05 — Gemini/Antigravity parity with Codex Boost tooling

### Completed

- Registered the Boost-generated API skills that Codex uses (`api/.agents/skills`: `infer-conventions`, `testing-best-practices`, `deploying-to-cloud`, `tailwindcss-development`) for Gemini/Antigravity sessions at the repository root through `.agents/skills.json`. Boost's `laravel-best-practices` is excluded because the repository-curated root skill of the same name takes precedence.
- Added the workspace plugin `.agents/plugins/laravel-boost/` that exposes the same Sail-backed Boost MCP launcher as `api/.codex/config.toml`.
- Added `api/.agents/mcp_config.json`, Boost's Antigravity MCP path, so future `boost:install`/`boost:update` runs detect and maintain the Antigravity agent.
- Documented the setup in the root `README.md`.

### Verification

- JSON parse of all four new config files — **passed**.
- MCP `initialize` request piped through the configured launcher from the repository root — **passed**; Laravel Boost returned its server capabilities via Sail.
- Skill discovery in a fresh Gemini/Antigravity session: **not verified** in this session; open a new conversation to confirm that the Boost skills and MCP tools appear.

### Security and offline considerations

- No credentials are added. The MCP launcher runs only inside the existing Sail container and does not start containers.

### Known limitations

- Antigravity's documentation guarantees MCP loading from global or plugin configs. `api/.agents/mcp_config.json` exists for Boost compatibility only. If both configs load, the plugin server is namespaced.
- `tailwindcss-development` and `deploying-to-cloud` are registered for parity with Codex even though the backend is API-only and hosting has not been approved.

## 2026-11-05 — M1 Slice 1: Identity and authentication API

### Completed

- Installed `laravel/sanctum` and configured personal access token support with UUID morph relation compatibility for `users`.
- Added migration `2026_11_05_020000_add_traveler_profile_to_users_table.php` adding `display_name`, `avatar_url`, `locale`, `home_timezone`, and `deleted_at` (soft deletes) to `users`.
- Updated `User` model with `HasApiTokens`, `SoftDeletes`, and profile attributes.
- Implemented `POST /api/v1/auth/token` (`AuthController::token`) for credential authentication and personal access token issuance.
- Implemented `POST /api/v1/auth/logout` (`AuthController::logout`) for revoking current tokens.
- Implemented `GET /api/v1/me` (`ProfileController::show`) returning standard JSON envelope via `UserResource`.
- Implemented `DELETE /api/v1/me` (`ProfileController::destroy`) using application service `DeleteAccountService` for transactional token revocation, session cleanup, and account soft-deletion.
- Updated `docs/api/openapi.yaml` with `BearerAuth`, authentication, and profile operations/schemas.
- Added feature test suite `tests/Feature/AuthTest.php` verifying token issue, validation errors, profile access, unauthorized rejection, logout, and account deletion.
- Added feature documentation in `docs/features/identity-and-auth.md`.

### Verification

- `cd api && bash bin/test-postgres` — **passed**: 12 tests, 64 assertions passed across `PostgresFoundationTest` and `AuthTest`.
- `cd api && ./vendor/bin/sail artisan test --compact` — **passed**: Fast non-database suite passed.
- `cd api && ./vendor/bin/sail pint --test` — **passed**: Zero formatting issues.
- `cd api && ./vendor/bin/sail composer validate --strict && ./vendor/bin/sail composer audit` — **passed**: Composer metadata valid, no advisories.
- `cd api && ./vendor/bin/sail --profile tools run --rm --no-deps contracts` — **passed**: OpenAPI 3.1 semantic check and live health verification passed.

### Security and offline considerations

- User IDs remain opaque UUID strings.
- Passwords are encrypted with bcrypt; tokens are hashed in `personal_access_tokens`.
- Sensitive credentials and tokens are excluded from logs and error payloads.
- Account deletion revokes all personal access tokens immediately.

### Known limitations

- OAuth third-party provider adapters (Google, Apple) with Socialite are planned for future provider integration.
- Mobile UI authentication integration is scheduled for Slice 3.

### Next smallest task

Implement Slice 2: Trip data model, migrations (`trips`, `trip_members`), `TripPolicy`, and Trip CRUD API (`/api/v1/trips`) supporting all four traveler planning modes (`diy`, `existing`, `guided`, `simple`).

## 2026-11-05 — Remote Git repository linked and synchronized

### Completed

- Initialized Git repository on branch `main`.
- Verified `.gitignore` coverage across `.env`, `.local/`, `.obsidian/`, `vendor/`, and build artifacts to prevent credential or temporary data leaks.
- Configured remote origin: `https://github.com/monroenikko/tapittrip.git`.
- Committed and pushed initial project baseline (M0 foundation, Boost agent parity, M1 Slice 1 auth API) to `origin/main`.
- Rule established: Every phase and milestone slice will be committed and pushed to `https://github.com/monroenikko/tapittrip.git`.

### Verification

- `git status` — **passed**: Working tree clean, tracking `origin/main`.
- `git push -u origin main` — **passed**: 374 objects uploaded successfully.

## 2026-11-05 — M1 Slice 2: Trip data model, policies, and CRUD API

### Completed

- Added migration `2026_11_05_030000_create_trips_table.php` defining `trips` (`id` UUID, `owner_id`, `title`, `start_date`, `end_date`, `primary_timezone`, `origin_country`, `destination_country`, `trip_type`, `planning_mode`, `status`, `version`, soft deletes) and `trip_members` (`id`, `trip_id`, `user_id`, `role`, `invitation_status`).
- Added Eloquent models `App\Domain\Trips\Models\Trip` and `App\Domain\Trips\Models\TripMember` with UUID concerns, relations, casts, and role checks.
- Implemented `App\Domain\Trips\Policies\TripPolicy` enforcing server-side authorization: members can view, owners/editors can update, and only owners can delete trips.
- Implemented application Actions `CreateTrip`, `UpdateTrip`, and `DeleteTrip` with transaction boundaries and monotonic `version` counter increments.
- Implemented Form Requests `StoreTripRequest` and `UpdateTripRequest` with date-ordering and planning mode validation.
- Implemented `TripResource` serializing normalized trip attributes and viewer role.
- Implemented `TripController` and registered `trips` apiResource under `auth:sanctum` in `routes/api.php`.
- Documented all operations and schemas in `docs/api/openapi.yaml`.
- Created feature documentation in `docs/features/trip-management.md`.
- Added test suite `tests/Feature/TripTest.php` covering all 4 planning modes, validation, isolation, role-based editing, and owner deletion.

### Verification

- `cd api && bash bin/test-postgres` — **passed**: 26 tests, 120 assertions passed across `PostgresFoundationTest`, `AuthTest`, and `TripTest`.
- `cd api && ./vendor/bin/sail artisan test --compact` — **passed**: Fast non-database suite passed.
- `cd api && ./vendor/bin/sail pint --test` — **passed**: Pint code style clean.
- `cd api && ./vendor/bin/sail --profile tools run --rm --no-deps contracts` — **passed**: OpenAPI 3.1 semantic check passed.
- `ruby -e ...` Markdown relative link audit — **passed** (`ALL_LINKS_OK`).

### Security and offline considerations

- Strict tenant isolation enforced server-side via `TripPolicy`; unauthorized access yields HTTP 403.
- Database cascades clean up `trip_members` on parent deletion.
- Positive integer `version` field enables optimistic locking and sync conflict resolution for offline clients.

### Known limitations

- Mobile client UI for trip list and trip creation is scheduled for Slice 3.

### Next smallest task

Implement Slice 3: Flutter mobile integration for authentication state and trip creation/listing across all four planning modes.
