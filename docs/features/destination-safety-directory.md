# Destination Safety & Official Emergency Directory

## Traveler flow

From the **Today Dashboard** (`Safety & Emergency Directory` card) or direct navigation (`/safety`), travelers can view verified destination emergency numbers (`Police`, `Ambulance / Medical`, `Fire Rescue`, and `Tourist Helpline`), copy emergency numbers with one tap, launch nearby map searches (`Nearest Hospital`, `24h Pharmacy`, `Embassy / Consulate`, `Police Box / Station`), read offline emergency and medical phrases in the local script with phonetic pronunciation, and inspect official entry/travel portals with explicit `Verified YYYY-MM-DD` timestamps.

Travelers can switch between curated destination countries at the top of the screen. The directory works for trips in all four planning modes (`diy`, `existing`, `guided`, `simple`) and for trips with zero itinerary activities.

## API and honesty rules

- `GET /api/v1/safety/countries` lists curated destination safety profiles (with optional `?q=` search).
- `GET /api/v1/safety/countries/{country}` resolves a destination safety profile by ISO-2 code or country name.
- `GET /api/v1/trips/{trip}/safety` resolves the safety profile for a trip's `destination_country` (or optional `?country=` override) and enforces `TripPolicy::view` membership authorization.
- **No fabricated emergency numbers or immigration claims**: If a country is not in the curated directory, the API and mobile repository return `is_curated: false` with `null` emergency numbers and an explicit warning to verify local emergency numbers on arrival. Every profile includes a prominent disclaimer that official links are provided for reference only and do not constitute visa or immigration eligibility advice.

## Offline and privacy

`SafetyRepository` caches per-trip (`cached_safety_trip_{tripId}`) and per-country (`cached_safety_country_{code}`) responses in secure storage and falls back to a bundled offline directory (`JP`, `PH`, `KR`, `SG`, `TH`) so emergency numbers and phrases remain available without cellular connectivity. When trip access is revoked (`403` or Circle removal), `cached_safety_trip_{tripId}` is purged.

## Verification

- `api/tests/Feature/DestinationSafetyTest.php` (4 tests, 51 assertions) covers unauthenticated rejection, curated country listing/search, trip-scoped lookup across all four planning modes without itinerary items, member/outsider authorization, and uncurated country non-fabrication (`is_curated: false`).
- `client/test/destination_safety_test.dart` (3 tests) covers offline bundled fallback, uncurated non-fabrication, `403` cache purge, and `DestinationSafetyPage` widget rendering and country switching.

