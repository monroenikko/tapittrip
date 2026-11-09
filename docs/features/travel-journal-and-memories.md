# Travel Journal & Memories

## Overview

The **Travel Journal & Memories** feature in TapItTrip (Milestone M9, TC-8.1) enables travelers to capture their personal thoughts, moods, weather conditions, locations, and photo attachments as daily reflections during their trip.

To respect traveler privacy in shared trip circles, every reflection is **strictly private by default** (`is_shared = false`). Only the author can view and edit private memories. Authors can explicitly toggle `is_shared` to share a memory with companions in their trip circle.

---

## User Flows

### 1. Writing a Travel Reflection
1. From the Itinerary page overflow menu, select **Memories & Journal**.
2. Tap the **New Memory** floating action button.
3. Enter a reflection title, date, location (optional), select a mood chip (🤩 Amazed, 😊 Happy, 😌 Peaceful, 🎉 Excited, 😴 Tired, 🙏 Grateful, 🏔️ Adventurous), and weather condition (☀️ Sunny, ⛅ Cloudy, 🌧️ Rainy, ❄️ Snowy, 💨 Windy).
4. Enter reflection notes and optionally add photo attachments (URLs or uploaded images).
5. The **"Share with Circle"** toggle is off by default (`Keep Private (Only You)`).
6. Tap **Save Travel Memory**.

### 2. Companion Visibility & Circle Sharing (TC-8.1)
- When `is_shared = false`:
  - Only the author can see the entry in their journal timeline.
  - The entry displays an amber badge: `🔒 Only You`.
- When `is_shared = true`:
  - All trip circle members can see the entry in their journal timeline.
  - The entry displays a teal badge: `👥 Shared with Circle` alongside the author's name and avatar.
- Authors can toggle privacy at any time via the entry card options menu (`Make Private` / `Share with Circle`).
- Companions cannot edit or delete reflections authored by other travelers (enforced server-side with HTTP 403 Forbidden).

---

## Architecture & API Contracts

### Data Model (`journal_entries`)
- `id` (UUID PK)
- `trip_id` (UUID FK -> `trips.id`, cascade)
- `user_id` (UUID FK -> `users.id`, cascade)
- `itinerary_item_id` (UUID FK -> `itinerary_items.id`, nullable)
- `title` (string 255)
- `content` (text)
- `entry_date` (date)
- `location_name` (string 255, nullable)
- `weather` (string 64, nullable)
- `mood` (string 32, nullable)
- `is_shared` (boolean, default false)
- `photos` (jsonb array of URLs, default `[]`)
- `created_at`, `updated_at`, `deleted_at` (soft deletes)

### Endpoints
- `GET /api/v1/trips/{trip}/journal`: Lists author's entries + shared circle entries.
- `POST /api/v1/trips/{trip}/journal`: Creates a new journal reflection (enforces trip membership).
- `GET /api/v1/journal-entries/{entry}`: Fetches entry details (enforces author or shared membership).
- `PATCH /api/v1/journal-entries/{entry}`: Updates entry attributes and `is_shared` toggle (author only).
- `DELETE /api/v1/journal-entries/{entry}`: Soft deletes entry (author or trip owner only).
- `POST /api/v1/journal-entries/{entry}/photos`: Uploads image file and appends to `photos` array (author only).

---

## Security & Offline Considerations

### Security & Privacy
- **Strict Personal Privacy Default (TC-8.1)**: Every entry defaults to `is_shared = false`. Companions cannot access unshared entries via list, direct ID lookup, or search queries.
- **Author-Only Modifications**: Companions receive HTTP 403 when attempting to update, toggle sharing, delete, or upload photos to another traveler's reflection.
- **Safe Response Envelope**: All endpoints return responses via the standardized `ApiResponse` envelope (`{"data": ...}`).

### Offline-First Storage
- The mobile client caches all trip journal reflections in encrypted `FlutterSecureStorage` (`cached_journal_{tripId}`).
- When offline or in airplane mode, travelers can continue reading past reflections and viewing cached entries.

---

## Automated Verification

- **Backend PHPUnit**: `tests/Feature/TripJournalTest.php` (5 tests, 25 assertions):
  - `test_user_can_create_journal_entry`
  - `test_companion_can_only_see_shared_entries`
  - `test_author_can_update_journal_entry_and_toggle_sharing`
  - `test_non_author_companion_cannot_update_or_delete_entry`
  - `test_author_can_upload_photo_to_journal_entry`
  - Full suite passes: **125/125 tests, 700 assertions**.
- **Backend Pint**: 0 style issues.
- **Mobile Flutter Tests**: `client/test/journal_test.dart` (10 tests):
  - Model serialization & mood/privacy/weather getters
  - Repository caching and offline fallback
  - Riverpod `TripJournalNotifier` state management & sharing toggles
  - `JournalEntryCard`, `AddJournalEntrySheet`, and `TripJournalPage` widget interactions & filtering
  - Full mobile suite passes: **136/136 tests**.
- **Flutter Analyzer**: 0 issues (`flutter analyze` clean).
- **Dart Formatter**: 100% formatted.
