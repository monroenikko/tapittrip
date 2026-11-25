# Translator & Offline Phrasebook

## Traveler flow

From the **Today Dashboard** (`Translator & Offline Phrasebook` card) or direct navigation (`/translator`), travelers can browse curated offline destination phrasebooks across six categories (`essentials`, `dining`, `transit`, `hotel`, `shopping`, `emergency`) in Japanese (`ja`), Filipino/Tagalog (`tl`), Korean (`ko`), Thai (`th`), and French (`fr`). Each phrase displays the English meaning, native local script, phonetic pronunciation, optional context notes, a one-tap copy button, and a full-screen display card for showing to local staff.

Travelers can also type a custom phrase into the **Quick Translator**:
- If the phrase matches an entry in the offline phrasebook, it translates immediately offline (`Offline Phrasebook Match`).
- If the phrase is not in the offline phrasebook, cloud translation is only requested when the traveler explicitly enables **Allow cloud translation when not in offline pack** (`consent_cloud: true`).

## API, provider boundary, and consent rules

- `GET /api/v1/translation/languages` lists supported destination phrasebook languages.
- `GET /api/v1/translation/phrasebook/{language}` returns the curated phrasebook for a language code or country name, with optional `?category=` and `?q=` filters.
- `GET /api/v1/trips/{trip}/phrasebook` resolves the phrasebook for a trip's `destination_country` (or optional `?language=` override) and enforces `TripPolicy::view` membership authorization across all four planning modes (`diy`, `existing`, `guided`, `simple`) and trips with zero itinerary activities.
- `POST /api/v1/translation/translate` checks the curated offline phrasebook first; if no offline match exists and `consent_cloud` is `false`, it returns `422 cloud_consent_required`. When `consent_cloud` is `true`, it delegates to `TranslationProviderInterface` (`FakeTranslationProvider` in automated tests; `GeminiTranslationProvider` when configured), returning `503 translation_unavailable` rather than fabricating output when the cloud provider is unavailable.

## Offline and privacy

`TranslationRepository` caches per-trip (`cached_phrasebook_trip_{tripId}`) and per-language (`cached_phrasebook_lang_{code}`) phrasebooks in secure storage and includes bundled offline phrasebooks so essential phrases work in airplane mode. When trip access is revoked (`403` or Circle removal), `cached_phrasebook_trip_{tripId}` is purged.

## Verification

- `api/tests/Feature/TranslationTest.php` (4 tests, 52 assertions) covers unauthenticated rejection, language listing and category filtering, trip-scoped phrasebook lookup across all four planning modes without itinerary items, offline phrasebook matching, `422 cloud_consent_required` enforcement, consented cloud translation, and `503 translation_unavailable` handling.
- `client/test/translation_test.dart` (3 tests) covers offline phrase matching without cloud consent, `cloud_consent_required` enforcement, consented cloud translation, `403` cache purge, and `TranslatorPhrasebookPage` widget rendering and language switching.
