# AI Smart Itinerary Planner & Contextual Trip Assistant

## 1. Overview & Purpose
The **AI Smart Itinerary Planner** and **"Ask TapItTrip" Assistant** provide intelligent, personalized travel guidance seamlessly integrated into the TapItTrip mobile companion.

The feature is built around the fundamental invariant:
> **AI suggests; the user approves.**
> TapItTrip will never overwrite, delete, or replace an existing family or group itinerary. Suggestions are staged for preview and only added as new stops when approved by the traveler.

---

## 2. Planning Modes
Travelers have three flexible planning approaches:
1. **Manual Planning**: Travelers create daily schedules, destinations, and activities directly.
2. **AI-Generated Itinerary**: Proposes a complete multi-day plan based on destination, duration (1–7 days), budget tier (`budget`, `moderate`, `luxury`), travel party (`solo`, `couple`, `family`, `friends`, `seniors`), pace (`relaxed`, `balanced`, `fast`), and interests (`food`, `culture`, `shopping`, `nature`, `theme_parks`, `hidden_gems`).
3. **AI-Assisted Planning & "Ask TapItTrip"**: Travelers ask questions inside their active trip to fill free time, get dining suggestions near their hotel, check airport lounges in their departure terminal, or adjust pacing for toddlers.

---

## 3. Core Architectural Intelligence
- **Neighborhood Route Clustering**: Activities within the same day are grouped geographically (e.g. Asakusa & Taito for Day 1, Shibuya & Harajuku for Day 2) to minimize unnecessary transfers and transit fatigue.
- **Family & Toddler Pacing**: Automatically introduces afternoon rest buffers, highlights stroller-accessible routes, and warns against peak rush-hour transit with children.
- **Weather Alternatives**: Pre-computes indoor alternatives (covered arcades, science museums, indoor aquariums) for rainy or inclement weather.
- **Budget Estimation**: Resolves destination currency (JPY, PHP, SGD, EUR, USD) and provides transparent per-day and per-stop cost estimates.
- **Contextual In-Trip Assistant ("Ask TapItTrip")**:
  - Leverages active stay locations to suggest nearby dining within walking distance.
  - Resolves airport terminals to suggest accessible lounges with gate walking time warnings.
  - Recommends toddler pacing adjustments.

---

## 4. API Endpoints
All endpoints enforce trip membership via `TripPolicy`.

- `POST /api/v1/trips/{trip}/ai-plan/generate`: Proposes a staging itinerary plan matching traveler parameters.
- `POST /api/v1/trips/{trip}/ai-plan/apply`: Transactionally persists approved days and activity stops into `trip_days` and `itinerary_items`.
- `POST /api/v1/trips/{trip}/ai-plan/replan`: Proposes or applies non-destructive in-trip replanning (`rain_weather`, `flight_delay`, `skipped_stop`, `tired_family_pacing`) while preserving all `visited` stops and past memories.
- `POST /api/v1/itinerary-items/{item}/vote`: Allows Trip Circle members (`owner`, `editor`, `viewer`) to cast or clear thumbs-up / thumbs-down votes (`up`, `down`, `none`) on planned activities.
- `POST /api/v1/trips/{trip}/assistant/query`: Contextual Q&A taking active stays, days, party type, and query intent (`dining`, `lounge`, `toddler_friendly`, `weather`, `general`).

---

## 5. Mobile UI & Experience

### Automatic itinerary recommendations (2026-11-10)

- **External place links and directions**: Planned and suggested cards offer localized **View place** and **Directions** actions. View place opens a Google Maps place search; directions uses the existing native-map/browser launcher. Queries prefer place names, append saved address or trip destination context, and fall back to activity titles. These are search results, not verified venue websites: travelers should confirm the destination. Buttons wrap on small screens and launch failures show a retryable message.
- Links use app-constructed, encoded parameters on a fixed Google Maps host, never arbitrary AI-supplied URLs. They open only after a tap and send destination text to the selected map provider; the app does not request a current location. Connectivity/offline coverage depends on the external maps app. No new API, database, credentials, or mobile dependencies are needed. Format reference: [Google Maps URLs](https://developers.google.com/maps/documentation/urls/get-started).
- Opening the itinerary page observes its saved items and automatically requests suggestions through the existing assistant endpoint after a 600 ms debounce. Creating, editing, or deleting items refreshes the context; changing tabs does not issue another request. This works independently of the trip's planning mode.
- The Recommendations tab lists existing stops under **From your itinerary** and additional ideas under **Suggested for your trip**. Matching titles/place names and duplicate suggestion titles are suppressed. Suggestions never create or overwrite activities automatically.
- The assistant uses up to 50 saved stops with day/place context. `context_summary.source` identifies `gemini` or `local_fallback`; neither implies verified live prices, availability, hours, or accessibility. Missing/unavailable Gemini is labeled honestly.
- Empty itineraries remain usable and do not trigger an AI request. Failed requests preserve the itinerary list and offer manual retry; automatic Riverpod retries are disabled. Results are held in page-session memory, not persisted or synchronized across devices. Previously cached itinerary items can still be shown offline; new AI suggestions need connectivity.
- Existing trip membership authorization applies. Stop titles, dates, place names, destination, and stay name may be sent to the configured Gemini provider. Private stay addresses and freeform itinerary notes are excluded from this prompt; raw provider response bodies and exception messages are not logged.
- Feature copy supports English and Filipino based on the resolved app locale, falling back to English; this slice does not add an app-wide language selector.
- Verification: `client/test/recommendations_test.dart` covers automatic fetch/edit refresh, deduplication, empty itinerary, failure/retry, source labels, localized copy, and 320 px/200% text layouts. `api/tests/Feature/TripAssistantTest.php` verifies source metadata, fallback, trip isolation, and context beyond six stops without private stay addresses. See the milestone log for exact commands.
- Limitations: automatic generation runs while the itinerary page is mounted, not as a server background job. Exact normalized title/place matching cannot detect every semantic duplicate. Live provider output and device interaction were not exercised. Next candidate slice: explicitly approved saving/dismissing suggestions across sessions.
- **`AiItineraryPlannerDialog`**: Input dialog with budget, party, and interest chips.
- **`AiItineraryPreviewSheet`**: Staging bottom sheet displaying day themes, neighborhood badges, activity timeline, weather fallback, and an explicit "Accept Full Plan" button.
- **`AskTapItTripSheet`**: Conversational in-trip assistant sheet with quick-prompt chips ("Where should we eat near our hotel?", "Which lounge can I use in Terminal 3?", "Can you make Day 2 easier for our toddler?") and executable suggested action buttons.
- **Today Dashboard Launcher**: One-tap access to both Airport Lounge Finder and Ask TapItTrip Assistant.

---

## 6. Offline & Sync Behavior
- Approved itinerary items are recorded locally in SQLite / Drift and queued to the durable outbox for idempotent upstream synchronization.
- Staged previews do not mutate local storage until accepted by the user.

---

## 7. Verification
- **Backend Tests**:
  - `AiItineraryTest.php` (4 feature tests, full parameter variations, non-destructive merge into `trip_days`).
  - `TripAssistantTest.php` (7 feature tests, hotel dining proximity, terminal lounge resolution with gate warnings, toddler pacing, weather fallback, authorization gates).
  - 97/97 total backend tests passing (545 assertions).
- **Mobile Tests**:
  - `ai_itinerary_test.dart` (5 tests covering model parsing, repository, preview sheet, planner dialog).
  - `trip_assistant_test.dart` (3 tests covering model, repository, assistant sheet with action execution).
  - 108/108 total mobile tests passing.

