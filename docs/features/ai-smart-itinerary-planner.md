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
- `POST /api/v1/trips/{trip}/assistant/query`: Contextual Q&A taking active stays, days, party type, and query intent (`dining`, `lounge`, `toddler_friendly`, `weather`, `general`).

---

## 5. Mobile UI & Experience
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
