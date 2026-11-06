# Stays and Luggage-Aware Arrival Transport

- Milestone: `M2b`
- Status: `implemented` (Backend foundation + Flutter mobile UI)
- Owner: `engineering`
- Last verified: `2026-11-06`

## Purpose and traveler outcome

Empowers travelers to manage already-booked accommodations (hotels, hostels, rentals, staying with friends/family) across sequential cities without booking through the app.

Provides luggage-aware, explainable transport comparisons from arrival airports/stations to the saved stay, scoring options based on luggage burden (backpacks, carry-ons, checked bags, oversized bags, and strollers) while providing honest fallback navigation handoffs when verified transit data is unavailable.

## How it works

1. **Independent Stays CRUD**:
   - Supports multiple sequential or overlapping stays per trip in different cities.
   - Travelers can save stay name, address, coordinates, check-in and check-out times in the stay's local timezone, phone number, and private notes.
   - **Privacy & Encryption**: Sensitive `booking_reference` values are encrypted at rest using Laravel's `'encrypted'` casts. They are never exposed in public previews or push notification payloads.
2. **Non-Destructive Itinerary Integration**:
   - Stays can optionally generate linked `Check-in: {name}` and `Check-out: {name}` itinerary items.
   - Linked items reference `stay_id` with `nullOnDelete`. Deleting or modifying a stay never orphans or destroys the user's itinerary activities.
3. **Luggage-Aware Transport Comparisons**:
   - Travelers configure their luggage profile via presets (`light`, `standard`, `heavy`, `custom`) or explicit item counts (`backpacks`, `carry_ons`, `checked_bags`, `oversized`, `stroller`).
   - The comparison engine evaluates arrival options against luggage burden and party size:
     - **Private Transfer / Taxi**: 0 transfers, door-to-door, highest luggage capacity (fits 4+ bags and strollers). Ranked **Most Convenient** when heavy luggage or strollers are present. Economical for larger groups due to flat vehicle pricing.
     - **Airport Express Rail**: Direct or 1 transfer, dedicated luggage racks, elevator-accessible terminals. Ranked **Fastest** and **Most Convenient** for light or standard baggage profiles.
     - **Public City Transit**: Lowest overall cost for solo or light travelers, but incurs heavy penalties for transfers and walking distance when transporting heavy baggage. Ranked **Lowest Estimated Cost**.
4. **Honest Limitations & Maps Handoff**:
   - If an origin lacks verified transit schedules or coordinates, the system returns `verified: false` with status `unverified` and immediately provides a direct Google Maps directions URL (`google_maps_directions_url`), ensuring no fabricated transit times, fares, or accessibility claims.

## Architecture and data flow

- **Data Models**:
  - `stays`: UUID, `trip_id` (FK `trips`), `place_id` (FK `places`, nullable), `name`, `stay_type` (`hotel`, `hostel`, `rental`, `friends_family`), `address`, `latitude`, `longitude`, `check_in_at`, `check_out_at`, `timezone`, `phone`, `booking_reference` (encrypted), `notes`, `luggage_profile` (JSON), `version`, timestamps, soft deletes.
  - `itinerary_items`: augmented with nullable `stay_id` foreign key (`onDelete('set null')`).
- **Application Services** (`app/Application/Stays/Services`):
  - `CreateStayService`: Validates check-in < check-out, creates stay, optionally links/creates place, and provisions check-in/out itinerary items.
  - `UpdateStayService`: Updates stay attributes, increments version, and updates linked itinerary item titles and timestamps.
  - `DeleteStayService`: Decouples linked itinerary items without orphaning and soft deletes stay.
  - `CompareStayTransportService`: Deterministically evaluates transit options against luggage burden, party size, and provider attribution.
- **Security & Authorization**: All stay endpoints enforce `TripPolicy` (`view` for reading and transport comparisons, `update` for creating, editing, and deleting).

## API contract

Documented in [`docs/api/openapi.yaml`](../api/openapi.yaml):
- `GET /api/v1/trips/{trip}/stays` (`listTripStays`)
- `POST /api/v1/trips/{trip}/stays` (`storeStay`)
- `GET /api/v1/stays/{stay}` (`getStay`)
- `PATCH /api/v1/stays/{stay}` (`updateStay`)
- `DELETE /api/v1/stays/{stay}` (`deleteStay`)
- `POST /api/v1/stays/{stay}/transport-options` (`compareStayTransport`)

