# Smart Airport Lounge Finder

- Milestone: `M7 (Slice 1)`
- Status: `implemented`
- Owner: `TapItTrip Engineering`
- Last verified: `2026-11-08`

## Purpose and traveler outcome

International travelers often spend unnecessary time searching multiple third-party apps or navigating confusing terminal maps to locate accessible airport lounges before boarding.
The **Smart Airport Lounge Finder** brings discovery and eligibility directly into TapItTrip:
- **Terminal & Concourse Accuracy**: Surfaces lounges specific to the traveler's departure terminal (e.g. Manila MNL Terminal 3, Narita NRT Terminal 1) with precise location descriptions and walking directions from security checkpoints.
- **Airside vs. Landside Clarity**: Clear labeling prevents travelers from trying to access post-security lounges before clearing passport control or vice-versa.
- **Inter-Terminal Transit Warnings**: Explains physical accessibility limitations when transferring between separated terminals (e.g. MNL T3 vs. T1).
- **Amenities & Entry Methods**: Complete inventory of amenities (hot buffet, full bar, private showers, high-speed Wi-Fi, power outlets, quiet rest zones, nursery/family rooms) and entry programs (Priority Pass, DragonPass, LoungeKey, airline status, business class, and paid walk-in rates).
- **Boarding Reminder Guidance**: Reminds travelers to allow 15–20 minutes to exit the lounge and walk to their departure gate.
- **Offline In-Flight Caching**: Directory records for the departure airport are automatically cached in `FlutterSecureStorage` so travelers can reference lounge details without cellular roaming or airport Wi-Fi.

## How it works

1. **Airport & Terminal Selection**:
   - The traveler enters an airport IATA code (or taps a quick-select hub chip like MNL, NRT, HND, SIN, BKK, ICN, SFO, LAX).
   - Dynamic terminal chips allow filtering between all terminals, specific terminals (e.g. "T3"), and airside-only zones.
2. **Directory & Pricing**:
   - The backend `SearchAirportLoungesService` queries PostgreSQL and returns matching lounges with operating hours, walk-in price estimates, and direct booking links.
   - The mobile client renders responsive `LoungeCard` widgets and caches the response locally.
3. **Detail Inspection (`LoungeDetailSheet`)**:
   - Tapping any card opens an interactive bottom sheet presenting directions, amenities chips, entry program eligibility tags, walk-in price estimates, official booking links, and disclaimers.
4. **Dashboard Integration**:
   - An "Airport Lounge Finder" launcher card on `TodayDashboardPage` enables one-tap access directly from the trip hub.

## Architecture and data flow

- **Backend**:
  - `airports`: `id` (UUID), `iata_code` (unique char 3), `name`, `city`, `country`, `latitude`, `longitude`, `timezone`.
  - `airport_terminals`: `id` (UUID), `airport_id` (FK), `name`, `code` (e.g. "T3").
  - `airport_lounges`: `id` (UUID), `airport_id` (FK), `terminal_id` (FK), `name`, `operator`, `location_description`, `is_airside`, `opening_hours` (jsonb), `amenities` (jsonb array), `access_methods` (jsonb array), `estimated_price` (jsonb), `booking_url`, `transit_warning`, `disclaimer`.
- **Application Services**:
  - `SearchAirportLoungesService`: Case-insensitive IATA lookup, terminal scoping, airside filtering, and access method filtering.
  - `GetAirportLoungeDetailsService`: Single lounge lookup with relations.
- **Mobile Client**:
  - `Airport`, `AirportTerminal`, `AirportLounge` domain models.
  - `LoungeRepository`: API client integration with `FlutterSecureStorage` fallback (`cached_lounges_{iata}`).
  - `LoungeCard`: Compact list tile with terminal badges and amenities preview.
  - `LoungeDetailSheet`: Comprehensive modal sheet with directions, amenities, access programs, and boarding alerts.
  - `AirportLoungeFinderPage`: Hub search, terminal filter chips, and airside toggle.

## API contract

Documented in `docs/api/openapi.yaml`:
- `GET /api/v1/airports/{iata}/lounges`: Search airport lounges by IATA code with terminal, airside, and access method query parameters.
- `GET /api/v1/lounges/{lounge}`: Retrieve detailed lounge record.

## Verification

- **Backend Tests**: `api/tests/Feature/AirportLoungeTest.php`:
  - `test_user_can_search_lounges_by_airport_iata`: Verified IATA airport lookup and lounge collection.
  - `test_user_can_filter_lounges_by_terminal`: Verified terminal scoping (T3 vs T1).
  - `test_user_can_filter_lounges_by_access_method`: Verified access method filtering (Priority Pass).
  - `test_user_can_view_lounge_details`: Verified detailed fields, transit warning, and amenities.
  - `test_search_unknown_airport_returns_404`: Verified 404 behavior for invalid IATA codes.
- **Mobile Tests**: `client/test/airport_lounge_test.dart`:
  - Verified JSON serialization and deserialization across `Airport`, `AirportTerminal`, and `AirportLounge`.
  - Verified `LoungeRepository` network caching and offline storage fallback on network failure.
  - Widget tests for `LoungeCard`, `LoungeDetailSheet`, and `AirportLoungeFinderPage` filter chips.
- **Test Suite Results**:
  - Backend: 86/86 tests passed (502 assertions), Pint 0 issues.
  - Mobile: 100/100 tests passed, `flutter analyze` 0 issues, `dart format` clean.
