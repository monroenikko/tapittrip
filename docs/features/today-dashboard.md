# Today's Home Dashboard & Live Travel Timeline (M3)

## User Flow & Behavior
1. **Live Travel Timeline Landing**:
   - Authenticated travelers navigate to `/dashboard` to view their active journey or upcoming trip at a glance.
   - For multi-trip travelers, an app bar dropdown switcher allows seamlessly changing active trips.
   - For new travelers with 0 trips, an onboarding empty state prompts them to create their first adventure or import bookings.
2. **Context-Aware Hero Card (`TodayHeroCard`)**:
   - Displays trip destination, date range, local timezone, current weather / local context, and dynamic status badge:
     - `Pre-trip`: Countdown badge (`Starts in X days` or `Starts tomorrow`).
     - `Active journey`: Active day index (`Day X of Y`).
     - `Post-trip`: `Trip Completed` status badge.
3. **Trip Progress & Destination Context (`TripProgressCard`)**:
   - Two-column responsive card:
     - Left column: Destination country context and primary timezone.
     - Right column: Circular progress ring showing percentage completed and fraction of stops visited (`X/Y stops`).
4. **Next Upcoming Stop (`NextStopCard`)**:
   - Prominently showcases the traveler's next unvisited activity for today with category icon, place name, address, and scheduled time.
   - One-tap "Directions" button launches turn-by-turn navigation via `MapLauncher`.
   - "Visited" button marks the activity complete, recalculating progress in real time.
   - Completed / free-day state: when all activities are done or 0 activities are planned, provides an encouraging message ("No stops scheduled today — enjoy free exploration!") and a quick "Add Activity" button.
5. **Today's Stay Banner (`CurrentStayBanner`)**:
   - Highlights today's accommodation with check-in/out badges, address, navigation shortcut, and Arrival Transport comparison.
6. **Quick Actions Grid (`QuickActionsGrid`)**:
   - 4 squircle shortcuts: "Itinerary" (full timeline), "Stays" (accommodation list), "+ Stop" (add activity sheet), and "Directions" (map navigation to active place/stay).

## Cross-Platform Map Navigation (`MapLauncher`)
- Avoids fragile in-app web views (`SFSafariViewController`) that throw unhandled load errors on Google Maps SPAs or iOS simulators.
- Native navigation order:
  1. iOS: Checks for Google Maps app (`comgooglemaps://`), then native Apple Maps (`https://maps.apple.com/?daddr=...` and `maps://?daddr=...` built into all iOS devices and simulators), falling back to external browser.
  2. Android: Checks native navigation intent (`google.navigation:q=...`), `geo:` URI, falling back to external browser.
  3. All calls are safely wrapped without throwing `PlatformException` to the UI.

## Offline & Security Considerations
- **Offline-First Storage**: `TodayRepository` stores and hydrates cached today summaries using `FlutterSecureStorage` (`cached_today_$tripId`).
- **Authorization**: Scoped by `TripPolicy@view`. Travelers can only access today's summary for trips they own or belong to.
- **Privacy**: Booking references are kept private to trip members and not exposed to third-party trackers.

## Verification
- Backend tests: `api/tests/Feature/TripTodayTest.php` (4 test cases, 55 suite total) passed.
- Mobile tests: `client/test/today_test.dart` (12 test cases, 48 suite total) passed.
- Static analysis & linting: Pint and `flutter analyze` passed with 0 warnings/errors.


## Dashboard and activity sheet layout — 2026-11-06

- Dashboard sections share 16 dp side margins and vertical gaps. Cards use consistent 16 dp corner radii; the hero and next-stop cards use 16 dp content padding.
- Quick actions use theme colors and visible Material ink feedback. They switch to two columns for narrow widths or larger text. Stat cards align in a row when space permits and stack otherwise; action buttons and stay metadata wrap rather than overflow.
- The shared activity add/edit sheet paints its own opaque, rounded Material surface, including when opened by a transparent modal route. Safe-area padding, keyboard insets, and scrolling keep the form and submit action usable.
- Verification: `test/activity_sheet_test.dart` covers light/dark surfaces, a 320 dp phone, 200% text and a 280 dp keyboard inset; `test/today_test.dart` verifies dashboard margins/gaps and 100%/200% text on a 390 dp phone. `flutter analyze` passes; all 57 Flutter tests pass.
- No API, authorization, stored data, or offline behavior changes. Physical iPhone visual verification remains outstanding.
