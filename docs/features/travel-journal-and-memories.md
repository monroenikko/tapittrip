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

### 2. Companion Visibility & Circle Sharing (TC-8.1 & TC-8.2)
- When `is_shared = false`:
  - Only the author can see the entry in their journal timeline.
  - The entry displays an amber badge: `🔒 Only You`.
  - Zero events are published to the trip circle activity feed (`activity_events`).
- When `is_shared = true`:
  - All trip circle members can see the entry in their journal timeline.
  - The entry displays a teal badge: `👥 Shared with Circle` alongside the author's name and avatar.
  - A privacy-safe summary is published to the shared trip circle activity feed (`event_type: 'moment_shared'`).
- Authors can toggle privacy at any time via the entry card options menu (`Make Private` / `Share with Circle`).
- When an author unshares (`is_shared = false`) or deletes a journal entry, the corresponding activity feed event is immediately soft-deleted, preventing any companion from seeing past references or cached summaries (TC-8.1 & TC-8.2).
- Companions cannot edit or delete reflections authored by other travelers (enforced server-side with HTTP 403 Forbidden).

### 3. Automated Trip Recap & Story Album (Slice 3)
1. From the **Itinerary** overflow menu or **Memories & Journal** header, tap **Story Album & Recap**.
2. TapItTrip dynamically aggregates:
   - **Trip Metadata & Highlights**: Travel duration (days), stops visited vs. planned with completion rate progress bar, total stays and calculated lodging nights, and travel circle companions count.
   - **Photo Story Album Carousel**: Curated horizontal gallery of uploaded photos from shared circle entries and your personal reflections, with tap-to-zoom modal preview.
   - **Emotional Journey & Mood Breakdown**: Frequency summary and top mood highlight across recorded journal reflections.
   - **Expense Footprint Summary**: Total spent formatted in trip destination/budget currency, logged expenses count, and top spending category.
3. All data is cached locally in `FlutterSecureStorage` (`cached_recap_{tripId}`) for offline trip review.

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

### Data Model (`activity_events` — TC-8.2)
- `id` (UUID PK)
- `trip_id` (UUID FK -> `trips.id`, cascade)
- `actor_id` (UUID FK -> `users.id`, cascade)
- `event_type` (string 64, e.g. `'moment_shared'`)
- `title` (string 255)
- `summary` (text, sanitized and truncated safe excerpt)
- `entity_type` (string 64, nullable, e.g. `'journal_entry'`)
- `entity_id` (UUID, nullable)
- `metadata` (jsonb, photos array, mood, weather, location name)
- `occurred_at` (timestamptz)
- `created_at`, `updated_at`, `deleted_at` (soft deletes)
- Indexes: `['trip_id', 'occurred_at']`, `['entity_type', 'entity_id']`

### Endpoints
- `GET /api/v1/trips/{trip}/journal`: Lists author's entries + shared circle entries.
- `POST /api/v1/trips/{trip}/journal`: Creates a new journal reflection (enforces trip membership).
- `GET /api/v1/journal-entries/{entry}`: Fetches entry details (enforces author or shared membership).
- `PATCH /api/v1/journal-entries/{entry}`: Updates entry attributes and `is_shared` toggle (author only).
- `DELETE /api/v1/journal-entries/{entry}`: Soft deletes entry (author or trip owner only).
- `POST /api/v1/journal-entries/{entry}/photos`: Uploads image file and appends to `photos` array (author only).
- `GET /api/v1/trips/{trip}/feed`: Retrieves chronological circle activity stream and shared moments (TC-8.2, cursor pagination supported).
- `GET /api/v1/trips/{trip}/recap`: Retrieves the automated trip recap, highlights, photo story album, mood breakdown, and expense summary (Slice 3).

---

## Security & Offline Considerations

### Security & Privacy
- **Strict Personal Privacy Default (TC-8.1)**: Every entry defaults to `is_shared = false`. Companions cannot access unshared entries via list, direct ID lookup, or search queries.
- **Feed Redaction & Safe Summaries (TC-8.2)**: Circle activity summaries show only permitted changes, actors, and timestamps. They contain no raw private notes, unshared documents, booking references, or tokens.
- **Idempotent Deduplication (TC-8.2)**: Updating shared moments reuses existing activity rows to prevent event flooding or duplicate circle notifications.
- **Immediate Unsharing Revocation**: Switching `is_shared` from true to false immediately soft-deletes the feed event so companions cannot see it.
- **Author-Only Modifications**: Companions receive HTTP 403 when attempting to update, toggle sharing, delete, or upload photos to another traveler's reflection.
- **Safe Response Envelope**: All endpoints return responses via the standardized `ApiResponse` envelope (`{"data": ...}`).

### Offline-First Storage
- The mobile client caches all trip journal reflections in encrypted `FlutterSecureStorage` (`cached_journal_{tripId}`) and trip recaps (`cached_recap_{tripId}`).
- When offline or in airplane mode, travelers can continue reading past reflections, viewing cached entries, and reviewing their Trip Story Album.

---

## Automated Verification

- **Backend Feature Tests (`TripRecapTest.php`)** (8 tests, 52 assertions):
  - `test_trip_member_can_view_trip_recap_with_highlights_album_and_expenses`
  - `test_outsider_cannot_view_trip_recap_forbidden`
  - `test_recap_excludes_unshared_journal_entries_from_other_users_strict_privacy`
  - `test_recap_handles_empty_trip_without_activities_stays_or_expenses`
  - `test_recap_calculates_nights_across_multiple_stays`
  - `test_unauthenticated_request_is_rejected`
  - `test_soft_deleted_entries_and_activities_are_omitted_from_recap`
  - `test_recap_formats_cents_based_currency_appropriately`
- **Backend Feature Tests (`ActivityFeedTest.php`)** (8 tests, 36 assertions):
  - `test_trip_member_can_view_activity_feed_with_actor_and_metadata`
  - `test_outsider_cannot_view_trip_activity_feed` (403 Forbidden)
  - `test_creating_shared_journal_entry_creates_activity_feed_event`
  - `test_private_journal_entry_does_not_create_activity_feed_event_tc_8_2`
  - `test_unsharing_journal_entry_removes_it_from_activity_feed_tc_8_1_and_tc_8_2`
  - `test_deleting_journal_entry_removes_it_from_activity_feed`
  - `test_activity_feed_pagination_with_before_cursor`
  - `test_idempotent_event_recording_updates_without_duplication`
- **Backend Feature Tests (`TripJournalTest.php`)** (5 tests, 25 assertions):
  - `test_user_can_create_journal_entry`
  - `test_companion_can_only_see_shared_entries`
  - `test_author_can_update_journal_entry_and_toggle_sharing`
  - `test_non_author_companion_cannot_update_or_delete_entry`
  - `test_author_can_upload_photo_to_journal_entry`
  - Full suite passes: **155/155 tests, 2,000 assertions**.
- **Backend Pint**: 0 style issues.
- **Mobile Flutter Tests**: `client/test/journal_test.dart` (10 tests) & `client/test/trip_recap_test.dart` (6 tests):
  - Model serialization & mood/privacy/weather/recap getters
  - Repository caching and offline fallback (`cached_journal_{tripId}`, `cached_recap_{tripId}`)
  - Riverpod `TripJournalNotifier` & `tripRecapProvider` state management & sharing toggles
  - `JournalEntryCard`, `AddJournalEntrySheet`, `TripJournalPage`, and `TripRecapPage` widget interactions & filtering
  - Full mobile suite passes: **175/175 tests**.
- **Flutter Analyzer**: 0 issues (`flutter analyze` clean).
- **Dart Formatter**: 100% formatted.
