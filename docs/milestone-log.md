# TapItTrip Milestone Log

## 2026-11-25 — Google & Facebook Social Sign-In (Completed)

- Implemented end-to-end **Google & Facebook Social Sign-In** across Laravel (`api/`), OpenAPI (`docs/api/openapi.yaml`), and Flutter (`client/`):
  - **Backend (`api/`)**:
    - Added `'facebook'` to `AuthService::SUPPORTED_OAUTH_PROVIDERS` (`['google', 'facebook', 'apple']`) in [`AuthService.php`](../api/app/Services/Identity/AuthService.php).
    - Implemented `LiveOAuthTokenVerifier::verifyFacebookToken()` in [`LiveOAuthTokenVerifier.php`](../api/app/Services/Identity/LiveOAuthTokenVerifier.php) verifying tokens via Meta Graph API `debug_token` (`is_valid === true` & `app_id` match) and `/me?fields=id,name,email,picture.type(large)` with redacted failure logs.
    - Documented `FACEBOOK_OAUTH_APP_ID` and `FACEBOOK_OAUTH_APP_SECRET` in [`api/config/services.php`](../api/config/services.php) and [`api/.env.example`](../api/.env.example).
    - Updated `POST /api/v1/auth/{provider}/exchange` enum in [`docs/api/openapi.yaml`](../docs/api/openapi.yaml) and added Facebook exchange & live verifier tests in [`OAuthExchangeTest.php`](../api/tests/Feature/OAuthExchangeTest.php).
  - **Mobile (`client/`)**:
    - Added provider boundary [`SocialAuthService`](../client/lib/features/auth/data/social_auth_service.dart) (`SocialSignInResult`, `PlatformSocialAuthService`, `socialAuthServiceProvider`) checking `.env` (`GOOGLE_OAUTH_CLIENT_ID`, `FACEBOOK_APP_ID` documented in [`client/.env.example`](../client/.env.example)) and failing transparently when native SDK credentials are not yet configured.
    - Wired `AuthNotifier.signInWithSocialProvider()` in [`auth_provider.dart`](../client/lib/features/auth/presentation/providers/auth_provider.dart) and added reusable [`SocialAuthButtons`](../client/lib/features/auth/presentation/widgets/social_auth_buttons.dart) (**Continue with Google** & **Continue with Facebook**) to [`login_page.dart`](../client/lib/features/auth/presentation/pages/login_page.dart) and [`register_page.dart`](../client/lib/features/auth/presentation/pages/register_page.dart).
    - Added widget and notifier tests for Google/Facebook sign-in, cancellation, and errors in [`auth_test.dart`](../client/test/auth_test.dart).
- **Verification**:
  - Backend: `./vendor/bin/sail bin pint --test` passed; `./vendor/bin/sail --profile tools run --rm --no-deps contracts` passed; `OAuthExchangeTest.php` (`6/6 tests, 36 assertions`) and full PostgreSQL suite (`phpunit.postgres.xml`) passed (**227/227 tests, 1,754 assertions**).
  - Mobile: `dart format --output=none --set-exit-if-changed lib/ test/` (`232 files, 0 changed`); `flutter analyze` (`No issues found!`); `test/auth_test.dart` (`13/13`) and full `flutter test` passed (**290/290 tests**).

## 2026-11-25 — Trips Live Search & Filter Bar + Chip Contrast & Paper Card Polish (Completed)

- Upgraded [`search_pill_bar.dart`](../client/lib/features/trips/presentation/widgets/search_pill_bar.dart) and [`trip_list_page.dart`](../client/lib/features/trips/presentation/pages/trip_list_page.dart) so the Home search pill bar now performs live offline trip filtering across trip title, destination country, planning mode, and trip type (replacing the `/trips/new` stub):
  - Styled `SearchPillBar` with crisp white paper surface (`surfaceContainerLowest`), `1px` `outlineVariant` hairline border, clear-search button, and a circular navy filter trigger with an orange active-filter indicator dot.
  - Added a **Filter Trips** bottom sheet for **Planning Mode** (`DIY Planner`, `Already-Booked`, `Guided Tour`, `Simple / Essentials`) and **Trip Type** (`Leisure`, `Business`, `Family`, `Solo`, `Adventure`), dismissible active filter chips, and an empty-search state with **Clear filters** and **New Trip** actions.
  - Added widget test coverage in [`trip_search_filter_test.dart`](../client/test/trip_search_filter_test.dart).
- Completed visual polish fixes across the mobile app:
  - Removed vertical left accent bars from [`trip_card.dart`](../client/lib/features/trips/presentation/widgets/trip_card.dart) and [`today_hero_card.dart`](../client/lib/features/today/presentation/widgets/today_hero_card.dart) for a cleaner, natural card layout.
  - Aligned [`current_stay_banner.dart`](../client/lib/features/today/presentation/widgets/current_stay_banner.dart), [`today_budget_card.dart`](../client/lib/features/today/presentation/widgets/today_budget_card.dart), [`next_stop_card.dart`](../client/lib/features/today/presentation/widgets/next_stop_card.dart), [`stay_card.dart`](../client/lib/features/stays/presentation/widgets/stay_card.dart), [`route_summary_card.dart`](../client/lib/features/itinerary/presentation/widgets/route_summary_card.dart), [`checklist_progress_card.dart`](../client/lib/features/checklists/presentation/widgets/checklist_progress_card.dart), [`checklists_view.dart`](../client/lib/features/checklists/presentation/widgets/checklists_view.dart), [`trip_circle_page.dart`](../client/lib/features/circles/presentation/pages/trip_circle_page.dart), [`destination_safety_page.dart`](../client/lib/features/safety/presentation/pages/destination_safety_page.dart), [`translator_phrasebook_page.dart`](../client/lib/features/translation/presentation/pages/translator_phrasebook_page.dart), [`trip_recap_page.dart`](../client/lib/features/journal/presentation/pages/trip_recap_page.dart), and [`trip_weather_view.dart`](../client/lib/features/weather/presentation/widgets/trip_weather_view.dart) to crisp white `surfaceContainerLowest` paper surfaces with `1px` hairline borders and zero muddy drop shadows.
  - Fixed global `ChipThemeData` in [`app_theme.dart`](../client/lib/core/theme/app_theme.dart) and `FilterChip` avatars in [`ai_itinerary_planner_dialog.dart`](../client/lib/features/itinerary/presentation/widgets/ai_itinerary_planner_dialog.dart) so unselected chips render crisp dark text, selected `ChoiceChip`s render white text + Trip Orange checkmark on navy, and selected `FilterChip`s render crisp dark text + Trip Orange checkmark on `primaryContainer`.
  - Aligned [`login_page.dart`](../client/lib/features/auth/presentation/pages/login_page.dart) and [`register_page.dart`](../client/lib/features/auth/presentation/pages/register_page.dart) to crisp white `surfaceContainerLowest` paper cards with `1px` hairline borders, wired `AuthNotifier.exchangeOAuthToken()` in [`auth_provider.dart`](../client/lib/features/auth/presentation/providers/auth_provider.dart), and added OAuth exchange unit tests in [`auth_test.dart`](../client/test/auth_test.dart).
- **Verification**:
  - Mobile: `cd client && dart format --output=none --set-exit-if-changed lib/ test/` (`230 files, 0 changed`); `flutter analyze` (`No issues found!`); `flutter test` (**288/288 tests passed**).

## 2026-11-24 — Mobile Editorial Premium UI Overhaul (Completed)

- Upgraded the TapItTrip Flutter UI (`client/`) from default Material 3 dashboard styling to a cohesive, editorial travel design system following `client/.agents/skills/flutter-premium-ui/SKILL.md`:
  - **Paper-on-Canvas Token System & Editorial Theme**: Updated [`app_colors.dart`](../client/lib/core/theme/app_colors.dart) and [`app_theme.dart`](../client/lib/core/theme/app_theme.dart) with neutral light/dark canvas vs. crisp paper surfaces (`surfaceContainerLowest` + `1px` `outlineVariant` hairline borders, zero muddy shadows), preserved dark brand tokens (`#A6C8FF`, `#FF8A3D`), added tight-tracked editorial typography (`_buildTextTheme`), and unified `AppBar`, `Card`, `FilledButton`, `OutlinedButton`, `TextButton`, `Chip`, `InputDecoration`, `NavigationBar`, `BottomSheet`, `SnackBar`, and `FAB` themes.
  - **Today Dashboard Redesign**: Rebuilt [`today_hero_card.dart`](../client/lib/features/today/presentation/widgets/today_hero_card.dart) as a deep-navy boarding-pass hero card with white typography, Trip Orange status pill, tabular-figure weather pill, and accent-bordered day note strip (removing the pasted app logo and drop shadow); unified [`quick_actions_grid.dart`](../client/lib/features/today/presentation/widgets/quick_actions_grid.dart) into crisp `surfaceContainerLowest` squircles with a single orange accent on `+ Stop` (removing rainbow icon colors); upgraded [`trip_progress_card.dart`](../client/lib/features/today/presentation/widgets/trip_progress_card.dart), [`next_stop_card.dart`](../client/lib/features/today/presentation/widgets/next_stop_card.dart), and [`today_flight_card.dart`](../client/lib/features/today/presentation/widgets/today_flight_card.dart).
  - **Trips & Itinerary Dossier Cards & Quick Actions**: Upgraded [`trip_card.dart`](../client/lib/features/trips/presentation/widgets/trip_card.dart) to a travel dossier card with a 4dp primary left accent rail, squircle badge, and theme-tokenized shared pill (removing hardcoded `Colors.teal`); updated [`quick_actions_row.dart`](../client/lib/features/trips/presentation/widgets/quick_actions_row.dart) and [`activity_timeline_card.dart`](../client/lib/features/itinerary/presentation/widgets/activity_timeline_card.dart) to match the crisp hairline-bordered surface system; wired all 4 Home **Quick Actions** (`AI Itinerary`, `Smart Route`, `Budget Plan`, `Travel Guide`) in [`trip_list_page.dart`](../client/lib/features/trips/presentation/pages/trip_list_page.dart), [`app_router.dart`](../client/lib/core/router/app_router.dart), and [`trip_itinerary_page.dart`](../client/lib/features/itinerary/presentation/pages/trip_itinerary_page.dart) with single-trip direct routing, multi-trip picker sheet, and empty-state fallback, verified by [`quick_actions_test.dart`](../client/test/quick_actions_test.dart).
- **Verification**:
  - Mobile: `cd client && dart format --output=none --set-exit-if-changed lib/ test/` (`229 files, 0 changed`); `flutter analyze` (`No issues found!`); `flutter test` (**284/284 tests passed**).

## 2026-11-24 — OAuth Provider Token Exchange (`google` / `apple`) & Encrypted Binary Attachment Verification (Completed)

- Verified **Binary File Attachments for Encrypted Travel Documents Vault & Trip Inbox** on PostgreSQL via Sail (`2026_11_24_010000_add_encrypted_file_columns_to_documents_and_imports`, `EncryptedAttachmentsTest.php` 3/3 tests, 45 assertions).
- Implemented **OAuth Provider Token Exchange (`POST /api/v1/auth/{provider}/exchange`)** across Laravel (`api/`), Flutter (`client/`), and OpenAPI (`docs/api/openapi.yaml`) per `MASTER_PLAN.md` Section 7:
  - Added migration [`2026_11_24_020000_create_user_oauth_identities_table.php`](../api/database/migrations/2026_11_24_020000_create_user_oauth_identities_table.php) and model [`UserOAuthIdentity`](../api/app/Models/UserOAuthIdentity.php) storing provider subject bindings without persisting raw OAuth tokens.
  - Added provider boundary [`OAuthTokenVerifierInterface`](../api/app/Contracts/OAuthTokenVerifierInterface.php), [`VerifiedOAuthIdentity`](../api/app/DTOs/Identity/VerifiedOAuthIdentity.php), [`FakeOAuthTokenVerifier`](../api/app/Services/Identity/FakeOAuthTokenVerifier.php) (testing), and [`LiveOAuthTokenVerifier`](../api/app/Services/Identity/LiveOAuthTokenVerifier.php) (Google `tokeninfo` + audience validation with redacted failure logs).
  - Added [`ExchangeOAuthRequest`](../api/app/Http/Requests/Api/V1/Auth/ExchangeOAuthRequest.php), `AuthService::exchangeOAuth()` with unverified-email account-takeover protection, `AuthController::exchangeOAuth()`, and rate-limited route `POST /api/v1/auth/{provider}/exchange` (`throttle:20,1`).
  - Documented `GOOGLE_OAUTH_CLIENT_ID` and `APPLE_OAUTH_CLIENT_ID` in `api/.env.example` and `api/config/services.php`.
  - Extended Flutter [`AuthRepository`](../client/lib/features/auth/data/auth_repository.dart) (`exchangeOAuthToken`) and added [`OAuthExchangeTest.php`](../api/tests/Feature/OAuthExchangeTest.php).
- **Verification**:
  - Backend: `./vendor/bin/sail --profile tools run --rm --no-deps migrate` (dev & test) passed; `./vendor/bin/sail bin pint --test` passed; `./vendor/bin/sail --profile tools run --rm --no-deps contracts` passed; full PostgreSQL test suite (`phpunit.postgres.xml`) passed **225/225 tests (1,739 assertions)**.
  - Mobile: `dart format --output=none --set-exit-if-changed lib/ test/` clean; `flutter analyze` (`0 issues`); full Flutter test suite (`flutter test`) passed **281/281 tests**.

## 2026-11-24 — Binary File Attachments for Encrypted Travel Documents Vault & Trip Inbox (Completed)

- Implemented **Encrypted Binary File Attachments & Short-Lived Signed Downloads** across Laravel (`api/`), Flutter (`client/`), and OpenAPI (`docs/api/openapi.yaml`) per `MASTER_PLAN.md` Release 1 lines 79 & 82.
- **Encrypted Private Storage & Short-Lived Signed URLs (`api/`)**:
  - Added migration [`2026_11_24_010000_add_encrypted_file_columns_to_documents_and_imports.php`](../api/database/migrations/2026_11_24_010000_add_encrypted_file_columns_to_documents_and_imports.php) adding `file_path`, `original_filename`, `mime_type`, `file_size_bytes`, and `file_encrypted` to `travel_documents` and `booking_imports`.
  - Added [`EncryptedAttachmentService`](../api/app/Services/Storage/EncryptedAttachmentService.php) enforcing strict MIME (`application/pdf`, `image/jpeg`, `image/png`, `image/webp`, `image/heic`) and 10 MB size validation, filename sanitization, at-rest encryption via `Crypt::encryptString` in private `local` storage, and decrypted streaming with `Cache-Control: private, no-store, max-age=0` and `X-Content-Type-Options: nosniff`.
  - Added [`UploadDocumentAttachmentRequest`](../api/app/Http/Requests/Api/V1/Documents/UploadDocumentAttachmentRequest.php), multipart `file` support on [`StoreTravelDocumentRequest`](../api/app/Http/Requests/Api/V1/Documents/StoreTravelDocumentRequest.php) & [`StoreBookingImportRequest`](../api/app/Http/Requests/Api/V1/Imports/StoreBookingImportRequest.php), and endpoints `POST /api/v1/documents/{document}/attachment`, `GET /api/v1/documents/{document}/download`, and `GET /api/v1/imports/{import}/download`.
  - Exposed `has_attachment`, `original_filename`, `mime_type`, `file_size_bytes`, and 10-minute `URL::temporarySignedRoute` `download_url` on [`TravelDocumentResource`](../api/app/Http/Resources/Api/V1/TravelDocumentResource.php) (strictly `null` for non-owners) and [`BookingImportResource`](../api/app/Http/Resources/Api/V1/BookingImportResource.php) (strictly `null` for companions who are neither creator nor trip owner).
  - Added [`EncryptedAttachmentsTest.php`](../api/tests/Feature/EncryptedAttachmentsTest.php) and registered it in [`api/phpunit.postgres.xml`](../api/phpunit.postgres.xml).
- **Mobile Integration (`client/`)**:
  - Updated [`TravelDocument`](../client/lib/features/documents/domain/models/travel_document.dart), [`BookingImport`](../client/lib/features/imports/domain/models/booking_import.dart), [`TravelDocumentRepository`](../client/lib/features/documents/data/travel_document_repository.dart) (`uploadAttachment`), [`BookingImportRepository`](../client/lib/features/imports/data/booking_import_repository.dart) (`createImportFromFile`), and [`TripDocumentsVaultPage`](../client/lib/features/documents/presentation/pages/trip_documents_vault_page.dart) (encrypted attachment badge and owner-only **View File** action).
  - Added [`encrypted_attachments_test.dart`](../client/test/encrypted_attachments_test.dart).
- **Verification**:
  - Mobile: `dart format --output=none --set-exit-if-changed lib/ test/` clean; `flutter analyze` (`0 issues`); full Flutter test suite (`flutter test`) passed **281/281 tests**.
  - Backend: Docker Desktop was stopped during this turn (`Docker or Podman is not running`), so Sail migrations, Pint, OpenAPI contracts, and `EncryptedAttachmentsTest.php` are ready to execute once Docker Desktop is started.

## 2026-11-22 — Smart In-Trip Replanning & Group Activity Voting (Completed)

- Implemented **Smart In-Trip Replanning & Trip Circles Group Activity Voting** across Laravel (`api/`), Flutter (`client/`), and OpenAPI (`docs/api/openapi.yaml`) per `MASTER_PLAN.md` Section 14F.
- **Trip Circles Group Activity Voting (`api/`)**:
  - Added migration [`2026_11_22_010000_create_itinerary_item_votes_table.php`](../api/database/migrations/2026_11_22_010000_create_itinerary_item_votes_table.php) (applied to both `tapittrip` and `tapittrip_test`), model [`ItineraryItemVote`](../api/app/Models/ItineraryItemVote.php), [`VoteItineraryItemRequest`](../api/app/Http/Requests/Api/V1/Itinerary/VoteItineraryItemRequest.php), `ItineraryService::voteItem()`, and `POST /api/v1/itinerary-items/{item}/vote` on [`ItineraryItemController`](../api/app/Http/Controllers/Api/V1/ItineraryItemController.php).
  - Exposed `upvotes_count`, `downvotes_count`, and `viewer_vote` (`'up' | 'down' | null`) on [`ItineraryItemResource`](../api/app/Http/Resources/Api/V1/ItineraryItemResource.php).
  - Wired member removal cleanup in [`TripCircleService`](../api/app/Services/Circles/TripCircleService.php) to delete the removed member's `itinerary_item_votes` for that trip.
- **Smart In-Trip Replanning (`api/`)**:
  - Added [`SmartReplanItineraryRequest`](../api/app/Http/Requests/Api/V1/Itinerary/SmartReplanItineraryRequest.php), [`SmartReplanService`](../api/app/Services/Itinerary/SmartReplanService.php), and `POST /api/v1/trips/{trip}/ai-plan/replan` on [`AiItineraryController`](../api/app/Http/Controllers/Api/V1/AiItineraryController.php).
  - Supports `rain_weather`, `flight_delay` (with configurable `delay_minutes`), `skipped_stop`, and `tired_family_pacing` triggers.
  - Strictly preserves all `visited` stops (`preserved_visited_count`, `action: 'keep_visited'`) and past memories, defaults to `apply: false` preview mode (`TripPolicy@view`), and when `apply: true` (`TripPolicy@update`) shifts unvisited timed stops (resyncing reminders via `NotificationService`) and adds approved backup stops transactionally.
- **Mobile Integration (`client/`)**:
  - Updated [`ItineraryItem`](../client/lib/features/itinerary/domain/models/itinerary_item.dart), [`ItineraryRepository`](../client/lib/features/itinerary/data/itinerary_repository.dart), [`ItineraryListNotifier`](../client/lib/features/itinerary/presentation/providers/itinerary_provider.dart), and [`ActivityTimelineCard`](../client/lib/features/itinerary/presentation/widgets/activity_timeline_card.dart) to render interactive thumbs-up / thumbs-down voting buttons and counts on timeline cards.
  - Added [`SmartReplanResult`](../client/lib/features/itinerary/domain/models/smart_replan_result.dart), `AiItineraryRepository.replanItinerary()`, and [`SmartReplanSheet`](../client/lib/features/itinerary/presentation/widgets/smart_replan_sheet.dart) wired into [`TripItineraryPage`](../client/lib/features/itinerary/presentation/pages/trip_itinerary_page.dart).
- **Verification**:
  - Backend: `./vendor/bin/sail bin pint --test` passed; `./vendor/bin/sail --profile tools run --rm --no-deps contracts` passed; full PostgreSQL test suite (`phpunit.postgres.xml`) passed **218/218 tests (1,673 assertions)**, including [`ActivityVotingAndSmartReplanTest.php`](../api/tests/Feature/ActivityVotingAndSmartReplanTest.php) (`2/2 tests, 37 assertions`).
  - Mobile: `dart format --output=none --set-exit-if-changed lib/ test/` clean; `flutter analyze` (`0 issues`); full Flutter test suite (`flutter test`) passed **279/279 tests**, including [`activity_voting_and_smart_replan_test.dart`](../client/test/activity_voting_and_smart_replan_test.dart) (`3/3 tests`).

## 2026-11-22 — Phase F: Security, Privacy & PII Log Redaction Audit (Completed)

- Completed **Phase F: Security, Privacy & PII Log Redaction Audit + Release Readiness Gate** across Laravel (`api/`), Flutter (`client/`), and OpenAPI (`docs/api/openapi.yaml`).
- **Provider Log Redaction (`api/`)**:
  - Hardened [`GeminiBookingExtractor`](../api/app/Services/Imports/GeminiBookingExtractor.php), [`GeminiTransitService`](../api/app/Services/Stays/GeminiTransitService.php), [`GeminiItineraryService`](../api/app/Services/Itinerary/GeminiItineraryService.php), [`PlaceService`](../api/app/Services/Itinerary/PlaceService.php), and [`WeatherService`](../api/app/Services/Weather/WeatherService.php) so HTTP/network failures log only status codes or event names and never log raw provider response bodies, exception URLs containing `?key=...` API credentials, raw booking references, or private coordinates.
- **Trip Inbox At-Rest Encryption & Companion Redaction (`api/`)**:
  - Updated [`BookingImport`](../api/app/Models/BookingImport.php) to encrypt `raw_text` at rest (`'raw_text' => 'encrypted'`) alongside `'extracted_data' => 'encrypted:array'`.
  - Hardened [`BookingImportResource`](../api/app/Http/Resources/Api/V1/BookingImportResource.php) to redact `raw_text` (`null`) and sensitive extracted fields (`flight.booking_reference`, `stay.booking_reference`, `stay.phone`, and `friends_family` `stay.address`/`notes`) when viewed by companions who are neither the import creator nor the trip owner.
  - Hardened [`BookingImportService`](../api/app/Services/Imports/BookingImportService.php) so only the import creator or trip owner can confirm or delete a booking import (`403 Forbidden` for other members).
- **`friends_family` Stay Location Privacy Across Transport, Route Optimization & Trip Assistant (`api/`)**:
  - Hardened [`StayTransportController`](../api/app/Http/Controllers/Api/V1/StayTransportController.php), [`StayService`](../api/app/Services/Stays/StayService.php), and [`CompareStayTransportService`](../api/app/Services/Stays/CompareStayTransportService.php) to enforce `StayPrivacy::hidesPrivateAddress($stay, $viewer)`—returning `google_maps_directions_url: null`, `nearest_transit: null`, and `options: []` for non-owner companions on `friends_family` stays.
  - Hardened [`GeminiTransitService::buildPrompt`](../api/app/Services/Stays/GeminiTransitService.php), [`AskTapItTripService::handleStayAndDiningQuery`](../api/app/Services/Itinerary/AskTapItTripService.php), and [`RouteOptimizationService::optimize`](../api/app/Services/Itinerary/RouteOptimizationService.php) so private `friends_family` street addresses and coordinates are never sent to external AI prompts, assistant replies, or non-owner route distance anchors.
- **Verification**:
  - Backend: `./vendor/bin/sail bin pint --test` passed; `./vendor/bin/sail --profile tools run --rm --no-deps contracts` passed; full PostgreSQL test suite (`phpunit.postgres.xml`) passed **216/216 tests (1,636 assertions)**, including [`SecurityAndPrivacyAuditTest.php`](../api/tests/Feature/SecurityAndPrivacyAuditTest.php) (`3/3 tests, 40 assertions`).
  - Mobile: `dart format --output=none --set-exit-if-changed lib/ test/` clean; `flutter analyze` (`0 issues`); `flutter test` (**276/276 tests passed**).

## 2026-11-20 — Constrained Itinerary Route Optimization, Stop-to-Stop Transit Mode Comparisons & Restaurant Discovery (Completed)

- Implemented the **Constrained Route Optimization, Stop-to-Stop Transit Mode Comparisons & Restaurant Discovery (`food-suggestions`)** vertical slice across Laravel (`api/`) and Flutter (`client/`) per `MASTER_PLAN.md` (Release 1 line 81, Section 7 line 251, and Section 14F).
- **Constrained Route Optimization & Stop-to-Stop Transit Mode Comparisons (`api/`)**:
  - Added [`OptimizeItineraryRouteRequest`](../api/app/Http/Requests/Api/V1/Itinerary/OptimizeItineraryRouteRequest.php), [`RouteOptimizationService`](../api/app/Services/Itinerary/RouteOptimizationService.php), and `POST /api/v1/trips/{trip}/itinerary-items/optimize-route` on [`ItineraryItemController`](../api/app/Http/Controllers/Api/V1/ItineraryItemController.php).
  - Evaluates geographic stop order within each day (`trip_day_id`) using Haversine coordinates with a 1.3x urban detour factor anchored to the trip's primary `Stay` coordinates (when available) or the day's first stop.
  - Respects constraints (`preserve_fixed_times`, `max_walking_meters_per_leg`): items with explicit `starts_at_utc` or `kind` in `['flight', 'hotel']` remain pinned in their slot index while flexible geocoded stops are ordered by nearest-neighbor distance.
  - Defaults to `apply: false` (**"AI suggests; the user approves"**), returning `current_total_distance_km`, `optimized_total_distance_km`, `distance_saved_km`, `estimated_co2_saved_kg`, `proposed_item_ids`, `pinned_item_ids`, and stop-to-stop transit `segments` (`walk`, `public_transit`, `taxi_rideshare`, or `unknown_coordinates` with `null` durations when coordinates are missing). When `apply: true`, atomically updates `sort_order` and increments `version` via `ItineraryService::reorderItems()` with `expected_versions` optimistic locking (`TripPolicy@update`).
- **Curated Restaurant & Food Discovery (`api/`)**:
  - Added [`ListFoodSuggestionsRequest`](../api/app/Http/Requests/Api/V1/Itinerary/ListFoodSuggestionsRequest.php), [`FoodSuggestionService`](../api/app/Services/Itinerary/FoodSuggestionService.php), [`FoodSuggestionController`](../api/app/Http/Controllers/Api/V1/FoodSuggestionController.php), and `GET /api/v1/trips/{trip}/food-suggestions`.
  - Returns destination- and stay-aware dining recommendations (`breakfast`, `lunch`, `dinner`, `cafe`) with optional `meal_type`, `dietary` (`vegetarian`, `halal`, `kid_friendly`, `local_specialty`), and `near` (`stay`, `itinerary`) filters, deduplicating meals already in `itinerary_items` and never leaking private `friends_family` stay addresses.
- **Mobile Integration (`client/`)**:
  - Added [`RouteOptimizationResult`](../client/lib/features/itinerary/domain/models/route_optimization_result.dart), [`FoodSuggestionsResult`](../client/lib/features/itinerary/domain/models/food_suggestion.dart), [`RouteOptimizationSheet`](../client/lib/features/itinerary/presentation/widgets/route_optimization_sheet.dart) (`RouteMetricsCalculator` & `ItineraryTransitSegmentsSection`), and [`FoodDiscoverySection`](../client/lib/features/itinerary/presentation/widgets/food_discovery_section.dart).
  - Updated [`RouteSummaryCard`](../client/lib/features/itinerary/presentation/widgets/route_summary_card.dart) and [`TripItineraryPage`](../client/lib/features/itinerary/presentation/pages/trip_itinerary_page.dart) to replace hardcoded `'142 km'` and `'18 kg'` with live coordinate-calculated route metrics, added the **Optimize Route** trigger & approval sheet, added stop-to-stop transit mode comparisons in the **Transport** tab, and integrated `FoodDiscoverySection` into the **Recommendations** tab.
  - Extended [`ItineraryRepository`](../client/lib/features/itinerary/data/itinerary_repository.dart) and [`TripCircleRepository::purgeAllTripCachesForStorage`](../client/lib/features/circles/data/trip_circle_repository.dart) with offline caches and 403 revocation purge for `cached_food_suggestions_` and `cached_route_optimization_`.
- **Verification**:
  - Backend: `./vendor/bin/sail bin pint --test` passed; `./vendor/bin/sail --profile tools run --rm --no-deps contracts` passed; full PostgreSQL test suite (`phpunit.postgres.xml`) passed **213/213 tests (1,596 assertions)**, including `RouteOptimizationAndFoodSuggestionsTest.php` (3/3 tests, 39 assertions).
  - Mobile: `dart format --output=none --set-exit-if-changed lib/ test/` clean; `flutter analyze` (`0 issues`); full Flutter test suite (`flutter test`) passed **276/276 tests**, including `route_optimization_and_food_discovery_test.dart` (3/3 tests).

## 2026-11-20 — Notification Quiet Hours, Reminder Rescheduling & Circle Removal Cleanup Audit (Completed)

- Completed **Phase E: Notification Quiet Hours, Reminder Rescheduling & Circle Removal Cleanup Audit** across Laravel (`api/`) and Flutter (`client/`) per `MASTER_PLAN.md` Section 14C `TC-5`, ADR [`0006`](decisions/0006-trip-circles-sync-conflicts-and-announcements.md), and [`notifications-and-geofencing.md`](features/notifications-and-geofencing.md).
- **Timezone Fidelity & Auto-Rescheduling (`api/`)**:
  - Fixed [`CreateStayData`](../api/app/DTOs/Stays/CreateStayData.php) and [`UpdateStayData`](../api/app/DTOs/Stays/UpdateStayData.php) to normalize `check_in_at` and `check_out_at` timestamps via `->utc()` before writing to PostgreSQL `timestamp without time zone` columns.
  - Fixed [`NotificationService`](../api/app/Services/Notifications/NotificationService.php) morning-summary and departure-checklist scheduling to format `TripDay::local_date` and `Trip::start_date` via `->format('Y-m-d')` before parsing in `$tripTz` (preventing Carbon from ignoring the target timezone when passed an existing `Carbon` date cast).
  - Wired automatic reminder scheduling/rescheduling on stay creation & timezone changes ([`StayService`](../api/app/Services/Stays/StayService.php), propagating timezone updates onto linked check-in/check-out itinerary items), timed itinerary item creation ([`ItineraryService`](../api/app/Services/Itinerary/ItineraryService.php)), sync entity creation ([`SyncService`](../api/app/Services/Sync/SyncService.php)), trip timezone/start-date edits & deletion cleanup ([`TripService`](../api/app/Services/Trip/TripService.php)), and preference updates (`updatePreferences()` recalculating active trip reminders and cancelling opted-out pending announcements).
  - Exposed `trigger_local_time` (`HH:mm` in the reminder's timezone) on [`ReminderResource`](../api/app/Http/Resources/Api/V1/ReminderResource.php) and documented it in [`docs/api/openapi.yaml`](api/openapi.yaml).
- **Mobile Quiet Hours Timezone Evaluation & Revocation Cache Cleanup (`client/`)**:
  - Fixed [`LocalNotificationService`](../client/lib/features/notifications/services/local_notification_service.dart) and [`TripReminder`](../client/lib/features/notifications/domain/models/trip_reminder.dart) so quiet-hours checks convert UTC `'Z'` trigger timestamps into destination or home wall-clock time (`triggerLocalTime` or IANA offset resolution) rather than comparing raw UTC hours directly.
  - Hardened [`TripCircleRepository::purgeAllTripCachesForStorage`](../client/lib/features/circles/data/trip_circle_repository.dart) to scrub dynamic `cached_weather_{tripId}_*` subkeys and strip revoked-trip notices from `cached_user_notifications` while preserving notices for active trips.
- **Verification**:
  - Backend: `./vendor/bin/sail bin pint --test` passed; `./vendor/bin/sail --profile tools run --rm --no-deps contracts` passed; full PostgreSQL test suite (`phpunit.postgres.xml`) passed **210/210 tests (1,557 assertions)**, including expanded `NotificationTest.php` and `TripCollaborationSlice3Test.php`.
  - Mobile: `dart format --output=none --set-exit-if-changed lib/ test/` clean; `flutter analyze` (`0 issues`); full Flutter test suite (`flutter test`) passed **273/273 tests**, including `notification_test.dart` (9 tests) and `trip_circle_slice3_test.dart` (7 tests).

## 2026-11-20 — Offline Sync Outbox Queue Hardening & Multi-Device Conflict Simulation (Completed)

- Implemented **Phase D: Offline Sync Outbox Queue Hardening & Multi-Device Conflict Simulation** across Laravel (`api/`) and Flutter (`client/`) per `MASTER_PLAN.md` (Section 9) and `docs/features/offline-sync-and-outbox.md`.
- **Backend Sync Concurrency, Privacy & Tombstone Hardening**:
  - Updated [`SyncService`](../api/app/Services/Sync/SyncService.php) to acquire PostgreSQL row-level locks (`lockForUpdate()`) inside `push()` transactions across `checklist_item`, `itinerary_item`, `flight`, `stay`, and `trip` mutations.
  - Added version-bump-on-delete and `withTrashed()` conflict detection + restore support so offline edits racing against remote soft deletes trigger deterministic `conflict` responses (`deleted: true`) and allow `"Keep My Offline Edit"` recovery without silent data loss.
  - Extended `sanitizeSyncPayload()` and `pull()` privacy redaction to strip `booking_reference` and `phone` from stored `sync_operations.payload` ledger rows and redact private `friends_family` stay fields (`address`, `latitude`, `longitude`, `notes`) when pulled by non-owner companions.
  - Fixed multi-trip push batches to update `SyncCursor` per affected `trip_id`.
- **Mobile Outbox Chunking & Consecutive Offline Edit Chaining**:
  - Updated [`SyncService`](../client/lib/features/sync/services/sync_service.dart) `pushPending()` to send pending outbox operations in bounded chunks (`maxPushBatchSize = 25`), safely preserving un-pushed chunks after mid-batch network interruptions.
  - Added `SyncService.saveWithChainedVersion()` and wired it across [`StayListNotifier`](../client/lib/features/stays/presentation/providers/stay_provider.dart), [`ChecklistListNotifier`](../client/lib/features/checklists/presentation/providers/checklist_provider.dart), [`ItineraryListNotifier`](../client/lib/features/itinerary/presentation/providers/itinerary_provider.dart), [`TripExpensesNotifier`](../client/lib/features/expenses/presentation/providers/expense_provider.dart), and [`FlightListNotifier`](../client/lib/features/flights/presentation/providers/flight_provider.dart) so consecutive offline edits chain outbox `baseVersion` cleanly without inflating UI server versions.
  - Added `latitude` and `longitude` to offline stay update outbox payloads, and updated [`ConflictResolutionDialog`](../client/lib/features/sync/presentation/widgets/conflict_resolution_dialog.dart) to surface `"Status: Deleted on another device while offline"` when `deleted == true`.
- **Verification**:
  - Backend: `./vendor/bin/sail bin pint --test` passed; `./vendor/bin/sail --profile tools run --rm --no-deps contracts` passed; `./vendor/bin/sail bin phpunit -c phpunit.postgres.xml tests/Feature/SyncTest.php` passed **13/13 tests (110 assertions)**; full PostgreSQL test suite (`phpunit.postgres.xml`) passed **206/206 tests (1,525 assertions)**.
  - Mobile: `dart format --output=none --set-exit-if-changed lib/ test/` clean; `flutter analyze` (`0 issues`); `flutter test` (**269/269 tests passed**, including `sync_test.dart` 16/16 and `trip_circle_slice3_test.dart`).
  - Updated [`docs/features/offline-sync-and-outbox.md`](features/offline-sync-and-outbox.md).

## 2026-11-20 — Luggage-Aware Airport-to-Stay Transit Route Scoring & Waypoint Guidance (Completed)

- Implemented **Phase C: Luggage-Aware Airport-to-Stay Transit Route Scoring & Waypoint Guidance** across Laravel (`api/`) and Flutter (`client/`) per `MASTER_PLAN.md` (Section 14B), `AGENTS.md` (Stay arrival and luggage-aware transport rules v1.2), and `docs/features/stays-and-luggage-transport.md`.
- **Zero-Typing Arrival Transport Suggestions**:
  - In [`TransportComparisonSheet`](../client/lib/features/stays/presentation/widgets/transport_comparison_sheet.dart), auto-prefilled `_selectedOrigin` from `stay.nearestTransit` (`nearestAirportName` + `nearestAirportCode` or `stationName`).
  - The detected arrival terminal ChoiceChip is pre-selected upon sheet open, immediately initiating query execution and rendering ranked transit alternatives without requiring manual typing or terminal searching.
- **End-to-End Waypoint Guidance & Dedicated Last-Mile Walk Navigation**:
  - Enhanced [`CompareStayTransportService`](../api/app/Services/Stays/CompareStayTransportService.php) and [`StayTransitService`](../api/app/Services/Stays/StayTransitService.php) to surface explicit `boarding_location` (e.g. Airport Taxi Stand / Express Rail Platform), `dropoff_location` (e.g. Shinjuku Station South Exit / Central MTR Hub), `dropoff_address`, and last-mile walking metrics (`last_mile_walk_meters`, `last_mile_walk_minutes`).
  - Added `buildWalkingDirectionsUrl` generating dedicated walking directions URLs (`travelmode=walking` with origin set to the drop-off station and destination to the stay lobby).
  - Added dedicated one-tap **Walk Map** action in [`TransportComparisonSheet`](../client/lib/features/stays/presentation/widgets/transport_comparison_sheet.dart) opening direct station-to-stay walking directions.
  - Expanded regional transit hubs to cover Hong Kong (HKG / MTR Airport Express, Urban Red Taxi), Taipei (TPE / Taoyuan Airport MRT), Sydney (SYD / Airport Link), and Kuala Lumpur (KUL / KLIA Ekspres).
- **OpenAPI & Contract Alignment**:
  - Updated [`docs/api/openapi.yaml`](../docs/api/openapi.yaml) schemas `TransportOption` (`boarding_location`, `dropoff_location`, `dropoff_address`, `last_mile_walk_meters`, `last_mile_walk_minutes`, `last_mile_directions_url`) and `TransportComparisonResponse` (`nearest_transit`).
- **Verification**:
  - Backend: `./vendor/bin/sail bin pint` passed; `./vendor/bin/sail --profile tools run --rm --no-deps contracts` passed; `./vendor/bin/sail bin phpunit -c phpunit.postgres.xml tests/Feature/StayTransportComparisonTest.php` passed **9/9 tests (78 assertions)**; full PostgreSQL test suite (`phpunit.postgres.xml`) passed **202/202 tests (1,462 assertions)**.
  - Mobile: `dart format`, `flutter analyze` (`0 issues`), and `flutter test` (**266/266 tests passed**, including `stay_test.dart` with 13/13 tests verifying zero-typing origin pre-fill, switching origins, and waypoint guidance).
  - Updated [`docs/features/stays-and-luggage-transport.md`](features/stays-and-luggage-transport.md).

## 2026-11-20 — Currency Minor Units & Comprehensive Financial Audit (Completed)

- Completed a comprehensive financial audit and currency scale hardening across Laravel (`api/`) and Flutter (`client/`) per `MASTER_PLAN.md` (Sections 6, 14B, and 14C / `TC-7`).
- Hardened standard ISO 4217 zero-decimal currency support across the full stack:
  - Added [`ZERO_DECIMAL_CURRENCIES`](../api/app/Services/Expenses/CountryCurrencyResolver.php) to [`CountryCurrencyResolver`](../api/app/Services/Expenses/CountryCurrencyResolver.php) covering all 16 ISO 4217 zero-decimal currencies (`BIF`, `CLP`, `DJF`, `GNF`, `ISK`, `JPY`, `KMF`, `KRW`, `PYG`, `RWF`, `UGX`, `VND`, `VUV`, `XAF`, `XOF`, `XPF`).
  - Updated `database/data/countries.json` and added database migration [`2026_11_20_020000_update_zero_decimal_currencies_in_countries_table.php`](../api/database/migrations/2026_11_20_020000_update_zero_decimal_currencies_in_countries_table.php) applied across both `tapittrip` and `tapittrip_test` PostgreSQL databases.
  - Aligned Flutter [`CurrencyFormatter`](../client/lib/core/utils/currency_formatter.dart) to recognize the full set of ISO zero-decimal currencies and provided accurate symbols (`$`, `kr`, `₲`, `USh`, `RF`, `VT`, `FCFA`, `CFA`, `CFPF`).
- Audited integer minor-unit arithmetic:
  - Verified [`ExpenseSplitCalculator::allocateEqual`](../api/app/Domain/Expenses/ExpenseSplitCalculator.php) and [`ExpenseRepository.allocateEqualMinor`](../client/lib/features/expenses/data/expense_repository.dart) distribute remainder +1 units without any fractional rounding loss (`array_sum($splits) === $totalMinor`).
  - Verified [`ExpenseSplitCalculator::allocateProportional`](../api/app/Domain/Expenses/ExpenseSplitCalculator.php) uses largest-remainder apportionment for base currency conversions.
  - Hardened foreign-currency debt settlements in [`ExpenseService::getGroupBalances`](../api/app/Services/Expenses/ExpenseService.php) to prevent unverified cross-currency assumptions.
- Verification:
  - Backend: `./vendor/bin/sail bin pint` passed; `./vendor/bin/sail --profile tools run --rm --no-deps contracts` passed; `./vendor/bin/sail bin phpunit -c phpunit.postgres.xml tests/Feature/CurrencyTest.php tests/Feature/TripExpenseTest.php tests/Feature/GroupSettlementTest.php` passed **19/19 tests (157 assertions)**; full PostgreSQL test suite (`phpunit.postgres.xml`) passed **199/199 tests (1,437 assertions)**.
  - Mobile: `dart format`, `flutter analyze` (`0 issues`), and `flutter test` (**265/265 tests passed**, including `currency_minor_units_test.dart`, `expense_test.dart`, and `trip_circle_slice5_test.dart`).

## 2026-11-20 — Trip Inbox & Smart Booking Imports (Completed)

- Implemented the Trip Inbox & Smart Booking Imports (`features/imports`) vertical slice across Laravel (`api/`) and Flutter (`client/`) per `MASTER_PLAN.md` (Sections 3, 6, 7, 10, and 14A).
- Added migration [`2026_11_20_010000_create_booking_imports_table.php`](../api/database/migrations/2026_11_20_010000_create_booking_imports_table.php) (applied to both `tapittrip` and `tapittrip_test` PostgreSQL databases), [`ExtractedBookingData`](../api/app/DTOs/Imports/ExtractedBookingData.php), [`BookingExtractorInterface`](../api/app/Contracts/BookingExtractorInterface.php), [`FakeBookingExtractor`](../api/app/Services/Imports/FakeBookingExtractor.php) (deterministic tests and regex fallback), [`GeminiBookingExtractor`](../api/app/Services/Imports/GeminiBookingExtractor.php) (multimodal structured JSON AI parsing), [`BookingImport`](../api/app/Models/BookingImport.php) (`extracted_data` encrypted at rest via `encrypted:array`), [`BookingImportService`](../api/app/Services/Imports/BookingImportService.php), [`StoreBookingImportRequest`](../api/app/Http/Requests/Api/V1/Imports/StoreBookingImportRequest.php), [`ConfirmBookingImportRequest`](../api/app/Http/Requests/Api/V1/Imports/ConfirmBookingImportRequest.php), [`BookingImportResource`](../api/app/Http/Resources/Api/V1/BookingImportResource.php), and [`BookingImportController`](../api/app/Http/Controllers/Api/V1/BookingImportController.php).
- Supported endpoints under `auth:sanctum`:
  - `GET /api/v1/trips/{trip}/imports`
  - `POST /api/v1/trips/{trip}/imports` (idempotent via `client_operation_id`)
  - `GET /api/v1/imports/{import}`
  - `POST /api/v1/imports/{import}/confirm` (materializes into Flight, Stay, or ItineraryItem with `base_version` optimistic concurrency verification)
  - `DELETE /api/v1/imports/{import}`
- Added Flutter `features/imports` (`BookingImport`, `BookingImportRepository` with secure-storage cache `cached_booking_imports_{tripId}` and `403` cache purge, `tripBookingImportsProvider`, `TripInboxPage`, `SmartBookingImportSheet`, and `ReviewExtractedBookingDialog`), registered `/trips/:tripId/inbox` in `app_router.dart`, added `cached_booking_imports_` to `TripCircleRepository.purgeAllTripCachesForStorage`, and added the **Trip Inbox & Smart Imports** card on `TodayDashboardPage`.
- Updated [`docs/api/openapi.yaml`](api/openapi.yaml), [`docs/features/trip-inbox-and-booking-imports.md`](features/trip-inbox-and-booking-imports.md), and [`docs/features/README.md`](features/README.md).
- Verification:
  - Backend: `./vendor/bin/sail bin pint` passed; `./vendor/bin/sail --profile tools run --rm --no-deps contracts` passed; `./vendor/bin/sail bin phpunit -c phpunit.postgres.xml tests/Feature/BookingImportTest.php` passed **7/7 tests (39 assertions)**; full PostgreSQL test suite (`phpunit.postgres.xml`) passed **197/197 tests (1,400 assertions)**.
  - Mobile: `dart format`, `flutter analyze` (`0 issues`), and `flutter test` (**260/260 tests passed**, including `booking_import_test.dart`, `travel_document_test.dart`, `translation_test.dart`, `destination_safety_test.dart`, and `today_test.dart`).

## 2026-11-14 — Encrypted Travel Documents Vault (Completed)

- Implemented the Encrypted Travel Documents Vault (`features/documents`) vertical slice across Laravel (`api/`) and Flutter (`client/`).
- Added migration [`2026_11_14_010000_create_travel_documents_table.php`](../api/database/migrations/2026_11_14_010000_create_travel_documents_table.php) (applied to both `tapittrip` and `tapittrip_test`), [`TravelDocument`](../api/app/Models/TravelDocument.php) (`reference_number` and `notes_private` encrypted at rest), [`TravelDocumentService`](../api/app/Services/Documents/TravelDocumentService.php), [`StoreTravelDocumentRequest`](../api/app/Http/Requests/Api/V1/Documents/StoreTravelDocumentRequest.php), [`UpdateTravelDocumentRequest`](../api/app/Http/Requests/Api/V1/Documents/UpdateTravelDocumentRequest.php), [`TravelDocumentResource`](../api/app/Http/Resources/Api/V1/TravelDocumentResource.php), and [`TravelDocumentController`](../api/app/Http/Controllers/Api/V1/TravelDocumentController.php).
- Enforced `owner_only` default visibility (hidden from other Circle members), optional `circle_members` summary sharing where `reference_number` remains strictly redacted (`null`) for non-owners (`MASTER_PLAN.md` Section 14C), idempotent `client_operation_id` creation, and `base_version` (`409 version_conflict`) optimistic concurrency.
- Added Flutter `features/documents` (`TravelDocument`, `TravelDocumentRepository` with secure-storage cache `cached_documents_{tripId}` and `403` purge, `tripDocumentsProvider`, `AddTravelDocumentSheet`, and `TripDocumentsVaultPage`), registered `/trips/:tripId/documents` in `app_router.dart`, added `cached_documents_` to `TripCircleRepository.purgeAllTripCachesForStorage`, and added the **Travel Documents Vault** card on `TodayDashboardPage`.
- Updated [`docs/api/openapi.yaml`](api/openapi.yaml), [`docs/features/travel-documents-vault.md`](features/travel-documents-vault.md), and [`docs/features/README.md`](features/README.md).
- Verification:
  - Backend: `./vendor/bin/sail bin pint` passed; `./vendor/bin/sail --profile tools run --rm --no-deps contracts` passed; `./vendor/bin/sail bin phpunit -c phpunit.postgres.xml tests/Feature/TravelDocumentTest.php` passed **2/2 tests (29 assertions)**; full PostgreSQL test suite (`phpunit.postgres.xml`) passed **190/190 tests (1,361 assertions)**.
  - Mobile: `dart format`, `flutter analyze` (`0 issues`), and `flutter test` (**256/256 tests passed**, including `travel_document_test.dart`, `translation_test.dart`, `destination_safety_test.dart`, and `today_test.dart`).

## 2026-11-14 — Translator & Offline Phrasebook (Completed)

- Implemented the Translator & Offline Phrasebook (`features/translation`) vertical slice across Laravel (`api/`) and Flutter (`client/`).
- Added [`TranslationProviderInterface`](../api/app/Contracts/TranslationProviderInterface.php), [`PhrasebookBundleData`](../api/app/DTOs/Translation/PhrasebookBundleData.php), [`TranslationResultData`](../api/app/DTOs/Translation/TranslationResultData.php), [`FakeTranslationProvider`](../api/app/Services/Translation/FakeTranslationProvider.php), [`GeminiTranslationProvider`](../api/app/Services/Translation/GeminiTranslationProvider.php), [`TranslationService`](../api/app/Services/Translation/TranslationService.php), [`TranslateTextRequest`](../api/app/Http/Requests/Api/V1/Translation/TranslateTextRequest.php), [`PhrasebookResource`](../api/app/Http/Resources/Api/V1/PhrasebookResource.php), [`TranslationResultResource`](../api/app/Http/Resources/Api/V1/TranslationResultResource.php), and [`TranslationController`](../api/app/Http/Controllers/Api/V1/TranslationController.php).
- Enforced offline phrasebook matching first (`is_offline_match: true`), explicit user consent (`consent_cloud: true`, returning `422 cloud_consent_required` when unconsented custom phrases are submitted), and honest `503 translation_unavailable` when the cloud provider is unavailable.
- Added Flutter `features/translation` (`translation_models.dart`, `TranslationRepository` with offline secure-storage cache `cached_phrasebook_trip_{tripId}` / `cached_phrasebook_lang_{code}`, bundled offline phrasebooks, and `403` cache purge, `translation_provider.dart`, and `TranslatorPhrasebookPage`), registered `/translator` in `app_router.dart`, added `cached_phrasebook_trip_` to `TripCircleRepository.purgeAllTripCachesForStorage`, and added the **Translator & Offline Phrasebook** card on `TodayDashboardPage`.
- Updated [`docs/api/openapi.yaml`](api/openapi.yaml), [`docs/features/translator-and-phrasebook.md`](features/translator-and-phrasebook.md), and [`docs/features/README.md`](features/README.md).
- Verification:
  - Backend: `./vendor/bin/sail bin pint` passed; `./vendor/bin/sail --profile tools run --rm --no-deps contracts` passed; `./vendor/bin/sail bin phpunit -c phpunit.postgres.xml tests/Feature/TranslationTest.php` passed **4/4 tests (52 assertions)**; full PostgreSQL test suite (`phpunit.postgres.xml`) passed **188/188 tests (1,332 assertions)**.
  - Mobile: `dart format`, `flutter analyze` (`0 issues`), and `flutter test` (**254/254 tests passed**, including `translation_test.dart`, `destination_safety_test.dart`, and `today_test.dart`).

## 2026-11-14 — Destination Safety & Official Emergency Directory (Completed)

- Implemented the Destination Safety & Official Emergency Directory vertical slice across Laravel (`api/`) and Flutter (`client/`).
- Added [`DestinationSafetyProfileData`](../api/app/DTOs/Safety/DestinationSafetyProfileData.php), [`DestinationSafetyService`](../api/app/Services/Safety/DestinationSafetyService.php), [`DestinationSafetyResource`](../api/app/Http/Resources/Api/V1/DestinationSafetyResource.php), and [`DestinationSafetyController`](../api/app/Http/Controllers/Api/V1/DestinationSafetyController.php) serving `GET /api/v1/safety/countries`, `GET /api/v1/safety/countries/{country}`, and `GET /api/v1/trips/{trip}/safety` (`TripPolicy::view` authorized).
- Curated emergency numbers (`police`, `ambulance`, `fire`, `general_emergency`, `tourist_hotline`), emergency phrases (local script + phonetic + English), and official government/immigration portals with explicit `last_verified_at` dates and non-eligibility disclaimers. Uncurated destinations return `is_curated: false` with `null` emergency numbers and never fabricate local numbers.
- Added Flutter `features/safety` (`DestinationSafetyProfile`, `SafetyRepository` with offline secure-storage cache `cached_safety_trip_{tripId}` / `cached_safety_country_{code}`, bundled offline directory fallback, and `403` cache purge, `safety_provider.dart`, and `DestinationSafetyPage`), registered `/safety` in `app_router.dart`, added `cached_safety_trip_` to `TripCircleRepository.purgeAllTripCachesForStorage`, and added the **Safety & Emergency Directory** card on `TodayDashboardPage`.
- Updated [`docs/api/openapi.yaml`](api/openapi.yaml), [`docs/features/destination-safety-directory.md`](features/destination-safety-directory.md), and [`docs/features/README.md`](features/README.md).
- Verification:
  - Backend: `./vendor/bin/sail bin pint` passed; `./vendor/bin/sail --profile tools run --rm --no-deps contracts` passed; `./vendor/bin/sail bin phpunit -c phpunit.postgres.xml tests/Feature/DestinationSafetyTest.php` passed **4/4 tests (182 assertions)**; full PostgreSQL test suite (`phpunit.postgres.xml`) passed **184/184 tests (1,280 assertions)**.
  - Mobile: `dart format`, `flutter analyze` (`0 issues`), and `flutter test` (**251/251 tests passed**, including `destination_safety_test.dart` and `today_test.dart`).

## 2026-11-12 — Flight Prep Reminders & Today Dashboard Flight Card (Completed)

- Extended `GET /api/v1/trips/{trip}/today` (`TodaySummaryResult`, `TodaySummaryResource`, `TripService::getTodaySummary`) to return `upcoming_flight` and `flights` via `FlightResource`, preserving owner-only `booking_reference` redaction for non-owner trip members.
- Extended `NotificationService` with `scheduleFlightReminders`, `syncRemindersForFlight`, and `cancelRemindersForFlight` (`flight_prep` at 3 hours before scheduled departure and `flight_gate_departure` at 45 minutes before scheduled departure), wired into `CreateFlightService`, `FlightController` (`update`/`destroy`), and `SyncService::handleFlight` (`create`/`update`/`delete`). Verified that reminder titles and bodies never include `booking_reference`.
- Updated [`docs/api/openapi.yaml`](api/openapi.yaml) (`TodaySummary` properties `upcoming_flight` and `flights`, and `Reminder.type` enum values `flight_prep` and `flight_gate_departure`).
- Updated Flutter `TodayDashboardSummary` to parse and serialize `upcomingFlight` and `flights`, added `TodayFlightCard` on `TodayDashboardPage` (showing scheduled route, UTC/timezone departure details, terminal/gate chips, owner-only `booking_reference` chip, explicit `"Scheduled booking details • Not live airline status"` disclaimer, edit action, and one-tap **Explore `<IATA>` `<Terminal>` Lounges** handoff to `/lounges?iata=<IATA>&terminal=<terminal>`).
- Verification:
  - Backend: `./vendor/bin/sail bin pint --test` passed; `./vendor/bin/sail --profile tools run --rm --no-deps contracts` passed; `./vendor/bin/sail bin phpunit -c phpunit.postgres.xml tests/Feature/FlightTest.php tests/Feature/TripTodayTest.php tests/Feature/NotificationTest.php` passed **18/18 tests (123 assertions)**; full PostgreSQL test suite (`phpunit.postgres.xml`) passed **180/180 tests (1,098 assertions)**.
  - Mobile: `dart format --output=none --set-exit-if-changed`, `flutter analyze` (`0 issues`), and `flutter test` (**248/248 tests passed**, including `today_test.dart` and `flight_confirmation_parser_test.dart`).

## 2026-11-12 — Flights & Booking (Completed)

- Completed the Flights & Booking vertical slice: trip-scoped `flights` and multi-leg `flight_segments` (`1–8` segments), encrypted owner-only `booking_reference`, `TripPolicy` authorization, idempotent `client_operation_id` creation, and `base_version` (`409 version_conflict`) optimistic concurrency.
- Applied migration `2026_11_11_090000_create_flights_and_flight_segments_tables.php` cleanly to both `tapittrip` and `tapittrip_test` using the `tapittrip_migrator` database role.
- Hardened `SyncService` (`handleFlight` + `sanitizeSyncPayload`) so `flight` create/update/delete sync operations validate distinct origin/destination airports and strip `booking_reference` from `sync_operations.payload` and non-owner conflict responses.
- Completed OpenAPI flight operations and schemas in [`docs/api/openapi.yaml`](api/openapi.yaml) (`listTripFlights`, `createTripFlight`, `updateFlight`, `deleteFlight`, `Flight`, `FlightSegment`) and validated via `./vendor/bin/sail --profile tools run --rm --no-deps contracts`.
- Completed Flutter multi-leg add/edit/delete UI in `AddFlightSheet` (`1–8` segments, terminal/gate fields, confirmation text paste-and-review parser), wired `FlightRepository.applyPulledOperations` into `SyncService.pullLatest` for pulled `flight` mutations, and added `cached_flights_` to `TripCircleRepository.purgeAllTripCachesForStorage`. The UI explicitly labels schedules as non-live.
- Verification:
  - Backend: `./vendor/bin/sail bin pint` passed; `./vendor/bin/sail --profile tools run --rm --no-deps contracts` passed; `./vendor/bin/sail bin phpunit -c phpunit.postgres.xml tests/Feature/FlightTest.php` passed **5/5 tests (27 assertions)**; full PostgreSQL test suite (`phpunit.postgres.xml`) passed **179/179 tests (1,078 assertions)**.
  - Mobile: `dart format --output=none --set-exit-if-changed`, `flutter analyze` (`0 issues`), and `flutter test` (**247/247 tests passed**, including `flight_confirmation_parser_test.dart`, `trip_circle_slice6_test.dart`, `main_navigation_test.dart`, and `itinerary_test.dart`).

## Current milestone

- Milestone: **Trip Circles Collaboration (Track 1 / M10 Slice 6)**
- Status: **Completed (TC-9: temporary opt-in map-pin sharing and meeting assistance)**
- Basis: User-approved Trip Circles Slice 6 (`MASTER_PLAN.md` Section 14C `TC-9` / ADR [`0009-trip-circles-location-sharing.md`](decisions/0009-trip-circles-location-sharing.md)). Implemented explicit map-pin consent, fixed duration options, audience isolation, expiry/stale status, coordinate clearing when stopped, member-removal deletion, and safe external map handoff without fabricated GPS, ETAs, or routes.
- Boundary:
  - Slice 1 (`TC-0`, `TC-1`, `TC-3.1`, `TC-8.2` UI): Shareable Invite Links, Member Roles, Leave Guard & Shared Activity Feed UI — **Completed**.
  - Slice 2 (`TC-2`, `TC-3.2`–`TC-3.4`): Targeted Friend Code Invites, Circle Inbox, Explicit Two-Party Ownership Transfer, Account Deletion Orphan Guard & Sync Hardening — **Completed**.
  - Slice 3 (`TC-4`, `TC-5`): Multi-Device Sync Conflicts, Stay Privacy Redaction, Organizer Announcements & Notification Cleanup — **Completed**.
  - Slice 4 (`TC-6`): Managed Traveler Profiles & Collaborative Checklist Assignments — **Completed**.
  - Slice 5 (`TC-7`): Group Expense Splits & Multi-Currency Settlement UI — **Completed**.
  - Slice 6 (`TC-9`): Temporary Opt-In Map-Pin Sharing & Meeting Assistance — **Completed**.
- Next Boundary: Slice 6 complete; awaiting explicit approval before **M10: Voice & Camera Translation / Safety Intelligence** or **Flights & Booking Import**.

## 2026-11-11 — Trip Circles Slice 6: temporary opt-in map-pin sharing

- Added the `trip_location_shares` schema, contract, controller, Form Requests, API Resource, and `TripLocationShareService`. Active sharing now requires an explicit `enabled: true`, one of `60`/`240`/`480`/`1440` minutes, an audience, and a valid latitude/longitude pair. It is member-authorized, expires at a UTC timestamp, hides organizer-only shares from non-organizers, and clears stored coordinates immediately on stop. Removing a member physically deletes their share.
- Added the Flutter location-sharing section once on the Circle page, including explicit manual map-pin entry, audience and duration controls, stale/recent labels, member map-direction handoff, loading/error/empty states, and an honest notice that this build has no device-GPS or background-location capability. It never sends a placeholder coordinate.
- Updated ADR 0009, OpenAPI, Trip Circles feature documentation, migration, backend feature tests, and mobile widget/model tests. No device-location permission, GPS provider, durable offline coordinate queue, or background execution was added; coordinates are sensitive and are neither cached nor logged by this slice.
- Verification: `./vendor/bin/sail bin pint --test …` passed; `./vendor/bin/sail bin phpunit --configuration=phpunit.postgres.xml tests/Feature/TripCollaborationSlice6Test.php` passed **3 tests, 40 assertions**. Route discovery and OpenAPI semantic validation passed. From `client/`, `flutter analyze` passed with no issues and `flutter test test/trip_circle_slice6_test.dart test/trip_circle_test.dart test/trip_circle_slice4_test.dart` passed **17 tests**. `migrate:fresh` against `tapittrip_test` could not be completed because the runtime test role does not own the existing tables; no schema was changed to work around it. Device/GPS permission testing is intentionally not applicable to this manual-pin slice.

## 2026-11-11 — Bottom navigation and reported Flutter errors

- User approved wiring Home, Itinerary and Profile plus a saved-accommodation Bookings overview. Added localized navigation copy and `TripNavigationView`; wired the Home bottom bar, grouped stays by trip with independent loading/retry, and routed Bookings to the existing itinerary page's initial Stays tab via `?tab=stays`. Kept manual trip/stay organization available without activities. Existing APIs/providers/cache behavior reused; no backend contract changes.
- Fixed subsequent reported errors: removed the duplicate `TripLocationShareNotifier`, `tripLocationShareProvider`, and `activeLocationSharesProvider` block (retaining identical behavior); replaced the Profile Friend Code panel's colored decoration with Material so switch/ListTile ink is visible.
- Files: trip list/navigation view/copy, core router, itinerary page initial tab, Profile panel, circle providers, `main_navigation_test.dart`, and affected feature documents. See [trip navigation](features/trip-management.md#bottom-navigation-2026-11-11).
- Verification from `client/`: targeted `dart format` passed. `flutter analyze` passed with no issues after concurrently edited expense code resolved its temporary nullable-rate error. `flutter test test/main_navigation_test.dart test/trip_circle_slice6_test.dart test/trip_circle_slice4_test.dart` passed (19 tests at that point); after adding the real Stays route check, `flutter test test/main_navigation_test.dart test/itinerary_test.dart` passed (35 tests). The existing itinerary error test prints its synthetic failure text but passes. `git diff --check` passed.
- Tests cover real Profile rendering/return, actual Stays route with no activities, all four planning modes, multiple trip contexts, loading/errors/retry, narrow large text, and location-sharing/checklist regressions. No live provider or device verification performed. Security/offline: overview uses authorized providers and shows only stay names; no new location access or sharing behavior. No credentials needed beyond existing app setup. Next smallest check: hot restart and exercise all tabs on device. Scope stops here.

## 2026-11-10 — Trip Circles Slice 5: Group Expense Splits & Multi-Currency Settlement UI

### Completed
- **Architecture Decision & Schema (`docs/decisions/0008-trip-circles-group-expense-splits-and-currency-snapshots.md`)**:
  - Accepted ADR 0008 specifying accepted adult member splits (`single`, `equal`, `selected`, `custom`), exact minor-unit + largest-remainder base conversion, `viewer` read-only ledger permissions, attributed FX snapshots (`rate_source`, `rate_captured_at`, `conversion_status`), private vs shared visibility rules, and `version` / `client_operation_id` offline sync invariants.
  - Added migration [`2026_11_10_070000_add_trip_circles_slice5_expense_hardening.php`](../api/database/migrations/2026_11_10_070000_add_trip_circles_slice5_expense_hardening.php) (applied cleanly to both `tapittrip` and `tapittrip_test`).
- **Backend Domain, FX Honesty, Sync & Settlement Ledger (`api/`)**:
  - Added pure domain [`ExpenseSplitCalculator`](../api/app/Domain/Expenses/ExpenseSplitCalculator.php) (`allocateEqual()`, `allocateProportional()`).
  - Hardened [`ExchangeRateProviderInterface`](../api/app/Contracts/ExchangeRateProviderInterface.php), [`ExchangeRateData`](../api/app/DTOs/Expenses/ExchangeRateData.php), [`LiveExchangeRateProvider`](../api/app/Services/Expenses/LiveExchangeRateProvider.php), [`CurrencyExchangeRateService`](../api/app/Services/Expenses/CurrencyExchangeRateService.php), and [`CurrencyController`](../api/app/Http/Controllers/Api/V1/CurrencyController.php) so missing rates never fall back to `FakeExchangeRateProvider` or fabricate `1.0` (`503 exchange_rate_unavailable`).
  - Updated [`Expense`](../api/app/Models/Expense.php) (`scopeVisibleTo`, `isVisibleTo`, Slice 5 casts), [`ExpenseSettlement`](../api/app/Models/ExpenseSettlement.php), [`ExpenseFactory`](../api/database/factories/ExpenseFactory.php), Expense/Settlement DTOs, Form Requests, [`ExpenseResource`](../api/app/Http/Resources/Api/V1/ExpenseResource.php), [`ExpenseSettlementResource`](../api/app/Http/Resources/Api/V1/ExpenseSettlementResource.php), [`GroupSettlementResource`](../api/app/Http/Resources/Api/V1/GroupSettlementResource.php) (omitting companion `email` PII), [`ExpenseService`](../api/app/Services/Expenses/ExpenseService.php), [`TripExpenseController`](../api/app/Http/Controllers/Api/V1/TripExpenseController.php), [`TripService`](../api/app/Services/Trip/TripService.php), [`TripTodayController`](../api/app/Http/Controllers/Api/V1/TripTodayController.php), and [`SyncService`](../api/app/Services/SyncService.php) (`expense` push/pull + privacy filtering).
  - Updated [`docs/api/openapi.yaml`](api/openapi.yaml), [`docs/features/trip-circles.md`](features/trip-circles.md), and [`docs/features/README.md`](features/README.md).
- **Flutter Multi-Currency & Group Split UX (`client/`)**:
  - Removed hardcoded `_fallbackToUsd` matrix from [`CurrencyRepository`](../client/lib/features/expenses/data/currency_repository.dart), adding `CurrencyRateUnavailableException` and `tryGetRateDetails`.
  - Updated [`Expense`](../client/lib/features/expenses/domain/models/expense.dart), [`ExpenseSummary`](../client/lib/features/expenses/domain/models/expense_summary.dart), [`GroupBalances`](../client/lib/features/expenses/domain/models/group_balances.dart), [`ExpenseRepository`](../client/lib/features/expenses/data/expense_repository.dart) (`allocateEqualMinor`, offline cache, `403` purge), [`expense_provider.dart`](../client/lib/features/expenses/presentation/providers/expense_provider.dart) (`OutboxStorage` queueing + `base_version` `409` conflict capture), [`ConflictResolutionDialog`](../client/lib/features/sync/presentation/widgets/conflict_resolution_dialog.dart), [`AddExpenseBottomSheet`](../client/lib/features/expenses/presentation/widgets/add_expense_bottom_sheet.dart) (payer picker, `selected`/`custom` editors, honest offline FX UX), [`SettleUpDialog`](../client/lib/features/expenses/presentation/widgets/settle_up_dialog.dart) (non-transfer disclaimer + idempotency key), and [`TripExpensesPage`](../client/lib/features/expenses/presentation/pages/trip_expenses_page.dart) (viewer read-only banner, unconverted notices, departed companion badge, per-currency breakdown).
- **Verification**:
  - Backend: `./vendor/bin/sail pint --test` passed; `./vendor/bin/sail --profile tools run --rm --no-deps contracts` passed; full `./vendor/bin/sail exec -e DB_CONNECTION=pgsql -e DB_DATABASE=tapittrip_test laravel.test php artisan test` passed **206/206 tests (2,563 assertions)**, including `ExpenseSplitCalculatorTest` and `TripCollaborationSlice5Test` (`TC-7.1`, `TC-7.2`, `TC-7.3`).
  - Mobile: `dart format --output=none --set-exit-if-changed` on touched expenses/sync/Slice 5 files passed; `flutter analyze` passed (`0 issues`); targeted `flutter test test/trip_circle_slice5_test.dart test/expense_test.dart test/currency_test.dart test/sync_test.dart test/trip_circle_test.dart test/trip_circle_slice3_test.dart test/trip_circle_slice4_test.dart` passed **59/59 tests**. Full `flutter test` passed **233 tests** with **5 pre-existing failures** strictly in `client/test/itinerary_test.dart` (`A Timer is still pending even after the widget tree was disposed` from uncommitted `recommendations_provider.dart`).

## 2026-11-10 — Trip Circles Slice 4: Managed Traveler Profiles & Collaborative Checklist Assignments

### Completed
- **Architecture Decision & Schema (`docs/decisions/0007-trip-circles-managed-travelers-and-checklists.md`)**:
  - Accepted ADR 0007 specifying minimal non-account `trip_travelers` profiles (`child`/`infant`/`adult`/`companion`, encrypted `managing_user_id`-only `restricted_notes`, no credentials or location/document sharing), exclusive checklist assignees (`assigned_user_id` / `assigned_traveler_id`), completion attribution (`completed_by_user_id`), and `version` optimistic concurrency (`409 version_conflict`).
  - Added migration `2026_11_10_060000_add_trip_circles_slice4_tables.php` (applied cleanly to both `tapittrip` and `tapittrip_test`).
- **Backend API, Sync & Removal Lifecycle (`api/`)**:
  - Added `TripTraveler` model + factory, `CreateTripTravelerData` / `UpdateTripTravelerData`, `StoreTripTravelerRequest` / `UpdateTripTravelerRequest`, `TripTravelerResource`, `TripTravelerService`, and `TripTravelerController` (`GET/POST /trips/{trip}/travelers`, `PATCH/DELETE /travelers/{traveler}`).
  - Updated `ChecklistItem`, `ChecklistItemResource`, `CreateChecklistItemData` / `UpdateChecklistItemData`, `StoreChecklistItemRequest` / `UpdateChecklistItemRequest`, `ChecklistService`, `ChecklistController`, `ChecklistItemController`, and `SyncService` (`push()` viewer `checklist_item` `is_packed`-only authorization on own assigned items, cross-trip assignee validation, `base_version` `409` conflict handling, and safe conflict serialization).
  - Updated `TripCircleService::removeMember()` to clear `assigned_user_id` and soft-delete the departing adult's managed travelers while clearing their `assigned_traveler_id` tasks atomically.
  - Updated `docs/api/openapi.yaml`, `docs/features/trip-circles.md`, and `docs/features/README.md`.
- **Flutter Managed Travelers & Collaborative Checklists UI (`client/`)**:
  - Added `TripTraveler`, `TripCircleRepository` traveler CRUD + `cached_travelers_{tripId}` `403` purge, `tripTravelersProvider`, and `ManagedTravelersSection` inside `TripCirclePage` (privacy notice, organizer/editor profile creation, manager-only `restricted_notes` / edit / delete).
  - Updated `ChecklistItem`, `ChecklistRepository` (`cached_checklists_{tripId}` cache & `403` purge, `base_version` + assignee params), `ChecklistListNotifier` (offline `OutboxStorage` `checklist_item` queueing across restart + `409` conflict capture), `ChecklistItemTile` (`canToggle`, `canEdit`, assignee & `Packed by` badges, `colorScheme.error`), `AddChecklistItemBottomSheet` (`Assign to (optional)` dropdown preserving `onSubmit` & `onSubmitWithAssignee` compatibility), and `ChecklistsView` (assignee filter chips, viewer read-only notice & own-item toggle guard).
- **Verification**:
  - Backend: `./vendor/bin/sail pint --test` passed; `./vendor/bin/sail --profile tools run --rm --no-deps contracts` passed; full `./vendor/bin/sail exec -e DB_CONNECTION=pgsql -e DB_DATABASE=tapittrip_test laravel.test php artisan test` passed **199/199 tests (2,463 assertions)**, including `TripCollaborationSlice4Test` (`TC-6.1`, `TC-6.2`, `TC-6.3`).
  - Mobile: `dart format --output=none --set-exit-if-changed lib/features/circles/ lib/features/checklists/ test/trip_circle_slice4_test.dart` passed; `flutter analyze` passed (`0 issues`); targeted `flutter test test/trip_circle_slice4_test.dart test/trip_circle_slice3_test.dart test/trip_circle_test.dart test/checklist_test.dart test/sync_test.dart` passed **42/42 tests**. Full `flutter test` passed **216 tests** with **5 pre-existing failures** strictly in `client/test/itinerary_test.dart` (`A Timer is still pending even after the widget tree was disposed` from uncommitted `recommendations_provider.dart`).

## 2026-11-10 — Itinerary checklist callback compilation fix

- Updated the itinerary page's add-checklist callback to the sheet's assignment-aware `onSubmitWithAssignee` API, accepting assignment fields and forwarding selected member/traveler IDs (or null when cleared). Preserved concurrently updated legacy callback support in the sheet.
- From `client/`: `dart format lib/features/itinerary/presentation/pages/trip_itinerary_page.dart` passed; `flutter analyze` passed with no issues after the concurrent sheet update completed; `flutter test test/checklist_test.dart` passed (8 tests).
- No API, persistence, security, or offline contract changes. Next check: hot restart and add an item from the itinerary page. No milestone expansion.

## 2026-11-10 — Dedicated stay recommendation backend

- User-authorized API follow-up for the empty Stays UI. Added `POST /api/v1/trips/{trip}/stay-recommendations`, Application Service, provider interface/Gemini adapter, API Resource, thin authorized controller, provider binding, and per-user throttling. Server-owned prompt uses saved itinerary/destination context. Existing stays before/during generation suppress results; provider failure returns explicit unavailable state. No booking/stay mutations.
- Backend filters/deduplicates lodging cards, bounds/strips text and drops external URL fields. All results are unverified and no-store. Updated OpenAPI schema/example and [stay feature/rollout notes](features/stays-and-luggage-transport.md#stay-recommendations-api). No migrations or new environment variables; backend deploy precedes client.
- Flutter now uses `StayRecommendationRepository` and the dedicated endpoint instead of submitting a generic chat prompt. Updated provider/view and client contract test. Added `StayRecommendationTest.php` to `phpunit.postgres.xml`.
- From `api/`: `./vendor/bin/sail bin phpunit --configuration=phpunit.postgres.xml tests/Feature/StayRecommendationTest.php tests/Feature/TripAssistantTest.php` passed (25 tests, 96 assertions), covering all four planning modes, no itinerary, saved-stay race, member/viewer isolation, filtering, malformed/failed/missing AI, rate limit and safe errors. `./vendor/bin/sail artisan route:list --path=stay-recommendations --json` confirmed auth and throttle middleware. OpenAPI parsed via Sail PHP/Symfony YAML (syntax validation only).
- Pint `--dirty --format agent` was unavailable because Git metadata is not mounted in Sail; `./vendor/bin/sail bin pint --format agent` with the eight changed backend paths passed. No PHP static-analysis binary is installed.
- From `client/`: `dart format` on the four changed stay integration/test files passed; `flutter test test/stay_recommendations_test.dart test/recommendations_test.dart` passed (14 tests). Full `flutter analyze` reported an unrelated unused import in `features/checklists/data/checklist_repository.dart:10`; focused `flutter analyze lib/features/stays/data/stay_recommendation_repository.dart lib/features/stays/presentation/providers/stay_recommendations_provider.dart lib/features/stays/presentation/widgets/stay_recommendations_view.dart test/stay_recommendations_test.dart` passed.
- Security/offline: existing trip authorization and minimized provider context; no arbitrary AI URLs, private stay data, or new location access. Network/provider failures leave manual stay entry available. Tests use HTTP fakes; live Gemini/device output not verified. Next smallest task: hot restart and check the empty Stays flow against the new endpoint. Scope ends here.

## 2026-11-10 — Itinerary-based empty-stay ideas

- User-authorized follow-up: the empty Stays tab now automatically requests advisory lodging/area ideas from the existing assistant, using saved itinerary context or destination when no stops exist. Manual Add Accommodation remains available; saving a stay hides ideas and suppresses new calls. No milestone expansion or new API contract.
- Added `stay_recommendations_provider.dart`, `stay_recommendations_view.dart`, and `stay_recommendations_test.dart`; connected the existing itinerary page. Reused safe map actions and documented the flow in the [stays feature](features/stays-and-luggage-transport.md).
- From `client/`: `dart format lib/features/stays/presentation/providers/stay_recommendations_provider.dart lib/features/stays/presentation/widgets/stay_recommendations_view.dart lib/features/itinerary/presentation/pages/trip_itinerary_page.dart test/stay_recommendations_test.dart` passed; `flutter analyze` passed; `flutter test test/stay_recommendations_test.dart test/recommendations_test.dart` passed (13 tests). `git diff --check` passed.
- No backend changes, migrations, new dependencies, or credentials. Existing Gemini setup and internet are required for AI results. Suggestions are unverified, transient, and never save/book accommodation; offline/provider failure leaves manual entry available. Device/live-provider verification remains manual. Next smallest task: inspect stay ideas on-device and save a stay to confirm the section disappears.

## 2026-11-10 — Trip Circles Slice 3: Conflict Resolution, Stay Privacy, Announcements & Notification Cleanup

### Completed
- **Architecture Decision & Schema (`docs/decisions/0006-trip-circles-sync-conflicts-and-announcements.md`)**:
  - Accepted ADR 0006 specifying HTTP `409 version_conflict` envelopes (`VersionConflictException`), `StayPrivacy` owner-only redaction across REST and sync conflicts, organizer `trip_announcements` (`client_operation_id` idempotency), `trip_notifications` inbox deduplication, `circle_announcements_enabled`, `destination` vs `home` quiet-hours evaluation, automatic reminder rescheduling/cancellation on itinerary/stay edits, and removed-member notification + local cache purge.
  - Added migration `2026_11_10_050000_add_trip_circles_slice3_tables.php` (applied cleanly to both `tapittrip` and `tapittrip_test`).
- **Backend API, Sync & Notification Lifecycle (`api/`)**:
  - Added `VersionConflictException`, mapped `409 version_conflict` in `ApiExceptionResponse`, and added `base_version` / `expected_versions` optimistic concurrency locking across `ItineraryService`, `StayService`, `TripAnnouncementService`, Form Requests, and controllers.
  - Aligned `SyncService::handleItineraryItem()` and `handleStay()` with PostgreSQL columns (`create`/`update`/`delete`), enforced `trip_id` matching & `handleTrip()` authorization, and redacted sensitive `Stay` fields via `StayPrivacy` in both `StayResource` and sync conflict responses.
  - Added `TripAnnouncement` / `TripNotification` models + factories, `TripAnnouncementService` / `TripAnnouncementController`, `TripNotificationController` (`/trips/{trip}/announcements`, `/announcements/{announcement}`, `/me/notifications`, `/me/notifications/{notification}/read`), and hooked `NotificationService` into `ItineraryService`, `StayService`, and `TripCircleService::removeMember()`.
  - Updated `docs/api/openapi.yaml` and `docs/features/trip-circles.md`.
- **Flutter Conflict UX, Cache Isolation & Announcements/Notices UI (`client/`)**:
  - Added `ConflictException` (`409 version_conflict`) parsing in `api_exceptions.dart` and `ApiClient`.
  - Updated `ItineraryRepository`/`ItineraryListNotifier` and `StayRepository`/`StayListNotifier` to pass `base_version` / `expected_versions`, queue offline mutations into `OutboxStorage`, capture `409` conflicts for manual resolution, and purge all per-trip local caches (`TripCircleRepository.purgeAllTripCachesForStorage` across 16 keys + `LocalNotificationService.cancelRemindersForTrip`) on `403` or `SyncService` removal rejection.
  - Enhanced `ConflictResolutionDialog` (rich itinerary/stay fields) and `SyncStatusIndicator` (multi-conflict selector sheet + safe offline retry).
  - Added `TripAnnouncement` & `UserNotification` models, `CircleAnnouncementsSection` in `TripCirclePage`, `CircleNoticesSection` in `CircleInboxPage`, and `Circle Announcements` switch + `Quiet Hours Timezone` (`destination`/`home`/`device`) dropdown in `NotificationPreferencesPage`.
- **Verification**:
  - Backend: `./vendor/bin/sail pint --test` passed; `./vendor/bin/sail --profile tools run --rm --no-deps contracts` passed; full `./vendor/bin/sail exec -e DB_CONNECTION=pgsql -e DB_DATABASE=tapittrip_test laravel.test php artisan test` passed **181/181 tests (2,351 assertions)** including 7 Slice 3 integration tests in `tests/Feature/TripCollaborationSlice3Test.php`.
  - Mobile: targeted `dart format --output=none --set-exit-if-changed` across Slice 3 paths and `flutter analyze` (`0 issues`) passed; `flutter test test/trip_circle_slice3_test.dart test/trip_circle_test.dart test/sync_test.dart test/notification_test.dart test/stay_test.dart` passed **48/48 tests**. Running full `flutter test` passed **205 tests** with **5 pre-existing failures** strictly in `client/test/itinerary_test.dart` caused by uncommitted `recommendations_provider.dart` scheduling an uncancellable 600ms `Future.delayed` timer during widget disposal.

## 2026-11-10 — Recommendation place links and directions

- User-requested follow-up: added View place and Directions buttons to planned and suggested recommendation cards. Place/address/destination text feeds encoded map searches and the existing native-map/browser directions launcher. Launch failures show localized feedback; buttons wrap at narrow widths and large text sizes.
- Changed the recommendation view/strings and itinerary-page destination handoff; added `recommendation_link_service.dart` and `recommendation_link_actions.dart`; extended `recommendations_test.dart`. No backend/API or persistence changes.
- From `client/`, `dart format` passed on the six changed Dart files; `flutter analyze` passed with no issues; `flutter test test/recommendations_test.dart` passed (8 tests). Link tests cover planned/suggested actions, destination context, hostile query encoding, failure feedback, and 320 px/200% text layout. Native map launching was faked in tests.
- Privacy/offline: external actions require a tap, transmit only destination search text, and use no arbitrary provider URL. No app location permission or new credentials required. Offline maps depend on the installed map app. Next smallest check: tap both actions on the user's device and confirm the destination result; no milestone expansion.

## 2026-11-10 — Automatic itinerary recommendations

- Scope authorized by the user's request: populate Recommendations from the saved itinerary and automatically fetch additional advisory AI suggestions. This is a narrow itinerary follow-up, not approval for other milestone work.
- Added a Riverpod recommendations provider, responsive tab content, localized feature copy, and regression tests. Existing planned items render while suggestions load; edits refresh suggestions, duplicate stops are suppressed, failures expose manual retry, and empty itineraries need no AI request.
- Extended existing assistant context to 50 stops with day/place context; added backward-compatible `context_summary.source` in OpenAPI. Removed private stay addresses from prompts and raw provider failures from logs. No migrations/new endpoints or environment variables.
- Verification from `client/`: targeted `dart format` on the recommendations provider/view/strings, itinerary page, and test passed; `flutter analyze` passed; `flutter test test/recommendations_test.dart test/trip_assistant_test.dart test/activity_sheet_test.dart` passed (12 tests).
- Verification from `api/`: `./vendor/bin/sail bin phpunit --configuration=phpunit.postgres.xml tests/Feature/TripAssistantTest.php` passed (10 tests, 38 assertions). The initial default `artisan test --filter=TripAssistantTest` run failed because SQLite had no application tables; the PostgreSQL test configuration resolved this. Existing PHPUnit conventions were retained; Pest/static-analysis binaries are not installed.
- `./vendor/bin/sail bin pint --test app/Services/Itinerary/AskTapItTripService.php app/Services/Itinerary/GeminiAssistantService.php tests/Feature/TripAssistantTest.php` passed. OpenAPI YAML parsed successfully through Sail PHP with `Symfony\Component\Yaml\Yaml::parseFile('/var/www/docs/openapi.yaml')`; this is syntax validation, not a full OpenAPI semantic validator. `git diff --check` passed.
- Limitations and next check: Gemini credentials/connectivity are required for AI output. Tests use fakes; device/live-provider verification remains manual. Suggestions are page-session state and do not persist across sessions or run in the background. Next smallest task: verify creating/editing a stop and opening Recommendations on device. Details: [AI planner feature](features/ai-smart-itinerary-planner.md#automatic-itinerary-recommendations-2026-11-10).

## 2026-11-10 — Activity day dropdown overflow fix

- Constrained the add/edit activity day selector to available width; selected labels ellipsize and open menu labels wrap with variable row heights.
- Extended `client/test/activity_sheet_test.dart` with long day labels and day selection at 320 logical pixels / 200% text scaling in both themes, retaining keyboard coverage.
- Verification from `client/`: `dart format lib/features/itinerary/presentation/widgets/add_activity_bottom_sheet.dart test/activity_sheet_test.dart` passed; `flutter analyze` passed with no issues; `flutter test test/activity_sheet_test.dart` passed (2 tests). SDK cache access required sandbox escalation.
- Security/offline/API contracts unchanged. No credentials required. Device verification not performed; next smallest check is reopening the activity sheet on the reported device after hot reload. No milestone expansion.

## 2026-11-10 — Trip Circles Slice 2: Friend Code Invites, Circle Inbox, Ownership Transfer & Sync/Account Hardening

### Completed
- **Architecture Decision & Migration (`docs/decisions/0005-trip-circles-targeted-invites-and-ownership-transfer.md`)**:
  - Accepted ADR 0005 specifying server-assigned `TRP-XXXXXX` friend codes (`users.friend_code`), direct invite opt-out (`accepts_direct_invites`), recipient-side sender blocks (`user_blocks`), uniform `422` anti-enumeration failure responses, direct invitation inbox isolation, explicit two-party `trip_ownership_transfers`, and `DELETE /me` shared-trip protection.
  - Added migration `2026_11_10_040000_add_trip_circles_slice2_tables.php` (applied cleanly to both `tapittrip` and `tapittrip_test`).
- **Backend API & Security Hardening (`api/`)**:
  - Added `User::generateUniqueFriendCode()`, `UserBlock`, `TripOwnershipTransfer`, DTOs under `app/DTOs/Circles/`, Form Requests, Resources (`IncomingTripInvitationResource`, `TripOwnershipTransferResource`), `TripOwnershipService`, `InvitationInboxController`, and endpoints `POST /me/friend-code/regenerate`, `POST /trips/{trip}/invitations/direct`, `GET/POST/DELETE /trips/{trip}/ownership-transfer`, `GET/POST /me/invitations`, and `GET/POST /me/ownership-transfers`.
  - Hardened `ProfileService::deleteAccount()` to lock owned trips and block (`422`) deletion while shared trips remain owned (`TC-3.4`), while cleaning up solo owned trips and companion memberships cleanly.
  - Hardened `TripJournalController`, Journal Form Requests, and `SyncService::pull()` so non-accepted or removed travelers cannot read/write journals or pull previously touched trip operations globally.
  - Updated `docs/api/openapi.yaml` and `docs/features/trip-circles.md`.
- **Flutter UI, Profile & Offline Sync Hardening (`client/`)**:
  - Updated `AuthUser`, `AuthRepository`, `AuthNotifier`, and `ProfilePage` with Friend Code copy/rotation, `Allow direct Friend Code invites` toggle, and safe blocked-deletion dialog handling in both `ProfilePage` and `TripListPage`.
  - Added `CircleInboxPage` (`/invitations/inbox`), `TripListPage` inbox badge icon, `Friend Code` invite mode and organizer `Transfer Ownership` workflow + pending banner in `TripCirclePage`.
  - Updated mobile `SyncService`, `SyncNotifier`, and `SyncStatusIndicator` to retain server-`rejected` outbox operations with their reason and let users inspect/dismiss them rather than discarding silently (`TC-3.2`).
- **Verification**:
  - Backend Sail Pint (`./vendor/bin/sail pint --test`), OpenAPI `contracts`, and PHPUnit/Pest suite (`173` tests, `2,213` assertions; includes 15 tests / 199 assertions in `TripCircleTest`) passed.
  - Mobile `dart format --output=none --set-exit-if-changed lib/ test/` (`163` files), `flutter analyze` (`0` issues), and `flutter test` (`195/195` passed, including updated `auth_test.dart`, `sync_test.dart`, and 9 tests in `trip_circle_test.dart`).

## 2026-11-10 — Trip Circles: Shareable Invite Links, Member Role Management & Shared Activity Feed UI

### Completed
- **Architecture Decision & Schema (`docs/decisions/0004-trip-circles-invitations-and-membership.md`)**:
  - Accepted ADR 0004 specifying CSPRNG 24-byte URL-safe invite tokens with SHA-256 hashing at rest, bounded `max_uses` concurrency, safe redacted preview before acceptance, soft-delete rejoin restore, and sole-organizer leave/removal protection (`TC-0.2`).
  - Added `2026_11_10_030000_create_trip_invitations_table.php` (applied to both `tapittrip` and `tapittrip_test`) plus `invite_base_url` config (`INVITE_LINK_BASE_URL` in `.env.example`).
- **Backend API & Membership Hardening (`api/`)**:
  - Implemented `TripInvitation` model/factory, DTOs under `app/DTOs/Circles/`, `TripCircleService`, Form Requests, `TripCircleMemberResource` / `TripInvitationResource`, `TripCircleController`, and `InvitationRedemptionController` covering `GET/PATCH/DELETE /trips/{trip}/members`, `GET/POST/DELETE /trips/{trip}/invitations`, `GET /invitations/{token}`, and `POST /invitations/{token}/accept`.
  - Hardened `Trip::hasMember()`, `Trip::memberRole()`, `Trip::users()`, `User::trips()`, and `SyncService` to strictly require `invitation_status = 'accepted'` and non-deleted (`deleted_at IS NULL`) membership rows.
  - Updated `docs/api/openapi.yaml` (including `components.responses.ValidationError`) and added `docs/features/trip-circles.md`.
- **Flutter UI & Offline Handling (`client/`)**:
  - Added `client/lib/features/circles/` models, `trip_circle_repository.dart` (with offline cache and `403` access-revocation cache purging via `purgeTripCircleCaches`), Riverpod providers, `TripCirclePage` (Activity Feed tab + Members & Invites tab), and `JoinTripSheet`.
  - Wired `/trips/:tripId/circle` route, `Trip Circle & Feed` menu item in `trip_itinerary_page.dart`, `Join Invite` / `Join via Invite Code` entry points in `trip_list_page.dart`, and overflow-safe shared role badge pills (`SHARED • EDITOR` / `SHARED • VIEWER`) on `TripCard`.
- **Verification**:
  - Backend Sail Pint (`./vendor/bin/sail pint --test`), OpenAPI `contracts`, and PHPUnit/Pest suite (`167` tests, `2,103` assertions) passed.
  - Mobile `dart format`, `flutter analyze` (`0` issues), and `flutter test` (`188/188` passed, including `client/test/trip_circle_test.dart`).

## 2026-11-10 — Interactive Card Drag & Drop and Ordinal Number Reordering in Your Itinerary

### Completed

- **Backend Reorder & Day-Reassignment Endpoint (`api/app/Services/Itinerary/ItineraryService.php`, `ReorderItineraryItemsRequest`, `ItineraryItemController`)**:
  - Updated `POST /api/v1/trips/{trip}/itinerary-items/reorder` to accept optional `day_assignments` (`item_id => trip_day_id|null`) alongside `item_ids` (enforcing `distinct` item UUIDs).
  - Validates that every target `trip_day_id` belongs to the trip (blocking cross-trip IDOR with HTTP 422), transactionally updates both `sort_order` and `trip_day_id`, increments `version`, and persists cleanly.
  - Updated `docs/api/openapi.yaml` and added feature tests in `tests/Feature/ItineraryItemTest.php` (12/12 tests, 65 assertions).
- **Mobile Timeline Drag & Drop and Ordinal Position Sheet (`client/lib/features/itinerary/`)**:
  - Added drag handle (`Icons.drag_indicator_rounded`) support to `ActivityTimelineCard` and `LiveWeatherActivityTimelineCard`, plus interactive ordinal tap support on `TimelineDayBadge`.
  - Replaced the flat plain-`ListTile` reorder fallback in `TripItineraryPage` with unified, in-place `ReorderableListView.builder` timeline drag-and-drop supporting:
    - Dragging cards directly within any Day section (`Day 1`, `Day 2`, ...) or dateless list via immediate `⋮⋮` drag handle or long-press, updating ordinal numbers (`1`, `2`, `3`...) immediately.
    - Dragging cards across Day headers (`Day 2` $\leftrightarrow$ `Day 1` or unscheduled) to update both ordinal stop position and day assignment atomically.
    - Preserving hidden days' items intact when a single Day filter chip is selected.
    - Optimistic local updates in `ItineraryListNotifier` (`applyReorderedItems`, `moveItemToOrdinal`) with cache persistence and automatic rollback + snackbar warning on network failure.
    - Accessible **Change Stop Order** bottom sheet when tapping any ordinal badge circle (`1`, `2`, `3`) to jump a stop directly to position `#N` or change its Day.
- **Verification & Feature Docs**:
  - Updated `docs/features/itinerary-and-places.md`.
  - Backend: `./vendor/bin/sail pint --test` clean; full suite **158/158 tests (2,014 assertions)** passed.
  - Mobile: `dart format lib/ test/` (154 files), `flutter analyze` (**0 issues**), `flutter test` (**182/182 tests passed**, including 7 new drag-and-drop / ordinal sheet tests in `client/test/itinerary_test.dart`).

## 2026-11-10 — Milestone M9, Slice 3: Automated Trip Recap & Story Album

### Completed

- **Backend Recap Aggregation (`app/DTOs/Recap/TripRecapData.php`, `app/Services/Recap/TripRecapService.php`)**:
  - Created `TripRecapService` with constructor DI (`ExpenseService`).
  - `getRecap(Trip $trip, User $user)` enforces trip membership (`403` for non-members) and aggregates:
    - **Trip Metadata**: ID, title, destination, start/end dates, calculated duration days, and status.
    - **Trip Highlights**: Visited vs. planned itinerary stops count, completion percentage, stays count, calculated total lodging nights across all stays, and accepted circle companion count.
    - **Photo Story Album & Emotional Journey**: Extracts accessible photos (`photos` array), top moments, mood frequency breakdown, and top mood highlight across own and shared (`is_shared = true`) journal entries. Strictly excludes unshared reflections from other companions (TC-8.1) and soft-deleted records.
    - **Expense Footprint Summary**: Aggregates trip total spent in base destination/budget currency with symbol formatting (supporting both zero-decimal currencies like JPY/KRW and cent-based currencies like USD/PHP), expense count, top spending category, and budget utilization percentage.
- **API Controller, Resource, & Contract (`TripRecapController`, `TripRecapResource`, `docs/api/openapi.yaml`)**:
  - Registered `GET /api/v1/trips/{trip}/recap` under `auth:sanctum` middleware.
  - Normalized empty `mood_breakdown` maps to JSON `{}` in `TripRecapResource` to prevent client deserialization errors.
  - Updated `docs/api/openapi.yaml` with `GET /trips/{trip}/recap` and schemas (`TripRecap`, `TripRecapPhoto`, `TripRecapMoment`).
- **Mobile Client (`client/lib/features/journal/`)**:
  - Created domain models (`TripRecap`, `TripRecapInfo`, `TripRecapHighlights`, `TripRecapStoryAlbum`, `TripRecapPhoto`, `TripRecapMoment`, `TripRecapExpenseSummary`).
  - Extended `JournalRepository` with `getTripRecap(tripId)` and `FlutterSecureStorage` caching (`cached_recap_{tripId}`) for offline viewing.
  - Added `tripRecapProvider` Riverpod `FutureProvider.family`.
  - Implemented `TripRecapPage` with hero showcase banner (country flag emoji, duration badge), 4-card highlights stat grid with progress indicator, horizontal Photo Story Album gallery with tap-to-zoom preview, Emotional Journey mood breakdown chips, and Top Moments story stream.
  - Wired `/trips/:tripId/recap` into `AppRouter`, `TripItineraryPage` overflow menu (*"Story Album & Recap"*), and `TripJournalPage` app bar.
- **Automated Verification**:
  - Backend Feature Tests (`api/tests/Feature/TripRecapTest.php`, 8 tests, 52 assertions): verified highlights, stays/nights math, currency formatting, empty trip safety, `401` unauthenticated, `403` outsider denial, strict exclusion of unshared entries from other users, and exclusion of soft-deleted items.
  - Full backend suite: `./vendor/bin/sail exec -e DB_CONNECTION=pgsql -e DB_DATABASE=tapittrip_test laravel.test php artisan test` $\rightarrow$ **155/155 tests passed (2,000 assertions)**.
  - Backend Pint: `./vendor/bin/sail pint` $\rightarrow$ **0 style issues**.
  - Mobile Flutter Tests (`client/test/trip_recap_test.dart`, 6 tests): model serialization, null-safe deserialization, repository caching & offline fallback, and `TripRecapPage` widget rendering/error recovery.
  - Full mobile suite: `cd client && flutter test` $\rightarrow$ **175/175 tests passed**.
  - Mobile Analyzer & Formatter: `cd client && dart format lib/ test/ && flutter analyze` $\rightarrow$ **0 issues found**.
- **Feature Documentation**: Updated `docs/features/travel-journal-and-memories.md`.

## 2026-11-10 — Milestone M9, Slice 2: Trip Circles Shared Activity Feed & Moments Stream (TC-8.2)

### Completed

- **Database Migration (`database/migrations/2026_11_10_020000_create_activity_events_table.php`)**:
  - Created `activity_events` table with UUID primary key, `trip_id` foreign key, `actor_id` foreign key, `event_type`, `title`, `summary`, `entity_type`, `entity_id`, `metadata` (jsonb), `occurred_at` (timestamptz), timestamps, and `softDeletes()`.
  - Added indexes on `['trip_id', 'occurred_at']` and `['entity_type', 'entity_id']`.
  - Migrated both `tapittrip` and `tapittrip_test` PostgreSQL databases.
- **Eloquent Models & DTOs**:
  - Created `app/Models/ActivityEvent.php` with `SoftDeletes`, `HasUuids`, factory, and relationships `trip(): BelongsTo` and `actor(): BelongsTo`.
  - Created `database/factories/ActivityEventFactory.php`.
  - Created `app/DTOs/Activity/RecordActivityEventData.php` with typed properties.
  - Added `activityEvents(): HasMany` relationship to `app/Models/Trip.php`.
- **Application Services (`app/Services/Activity/ActivityService.php`)**:
  - `getTripFeed(Trip $trip, User $user, int $limit = 30, ?string $beforeId = null)`: Enforces trip membership, provides cursor pagination with deterministic `occurred_at DESC, id DESC` sorting, and loads actor data.
  - `recordEvent(Trip $trip, User $actor, RecordActivityEventData $data)`: Idempotently creates or updates activity events per entity, preventing duplicate event spam per TC-8.2.
  - `removeEventForEntity(string $entityType, string $entityId)`: Soft-deletes events when shared entities are unshared or deleted.
- **Journal Integration (`app/Services/Journal/JournalService.php`)**:
  - Injected `ActivityService`.
  - Automatically records `moment_shared` activity events when a journal reflection is created with `is_shared = true` or photo uploaded.
  - Automatically soft-deletes activity events when author unshares (`is_shared = false`) or deletes a journal entry, preventing past cached summaries or companion leaks (TC-8.1 & TC-8.2).
- **API Controller & Resource (`app/Http/Controllers/Api/V1/ActivityFeedController.php`)**:
  - Injected `ActivityService` and `ApiResponse` via constructor DI.
  - `GET /api/v1/trips/{trip}/feed`: Supports query parameters `limit` and `before` cursor.
  - Returns `ActivityEventResource` collection conforming to public API response envelope.
- **Routes & OpenAPI (`routes/api.php`, `docs/api/openapi.yaml`)**:
  - Registered `Route::get('/trips/{trip}/feed', [ActivityFeedController::class, 'index'])->name('trips.feed.index')`.
  - Documented `GET /trips/{trip}/feed` and `ActivityEvent` schema in OpenAPI.
- **Automated Verification**:
  - Created `tests/Feature/ActivityFeedTest.php` (8 tests, 36 assertions):
    - Member feed access with actor and metadata.
    - Outsider access blocked (HTTP 403).
    - Shared journal creation triggers activity event.
    - Private journal creation records zero events (TC-8.2).
    - Unsharing journal immediately soft-deletes event from feed (TC-8.1 & TC-8.2).
    - Deleting journal soft-deletes event from feed.
    - Cursor pagination with before query parameter.
    - Idempotent recording updates in-place without duplicates (TC-8.2).
  - Full backend test suite passes: **145/145 tests passed (1,933 assertions)**.
  - Laravel Pint verified: 0 style issues.

## 2026-11-10 — Universal Soft Deletes Across All Database Tables and Models

### Completed

- **Database Migration (`database/migrations/2026_11_10_010000_add_soft_deletes_to_all_tables.php`)**:
  - Added `softDeletes()` (`deleted_at` timestamp) to all remaining 19 application tables: `trip_members`, `places`, `trip_days`, `checklists`, `checklist_items`, `media_attachments`, `user_devices`, `notification_preferences`, `reminders`, `visit_events`, `sync_operations`, `sync_cursors`, `airports`, `airport_terminals`, `airport_lounges`, `trip_budgets`, `expense_splits`, `expense_settlements`, and `countries`.
  - Migrated both development (`tapittrip`) and test (`tapittrip_test`) databases.
- **Eloquent Models (`app/Models/`)**:
  - Added `Illuminate\Database\Eloquent\SoftDeletes` trait to all 19 previously unsoft-deleted models.
  - **100% of application models (25 of 25)** now use `SoftDeletes`, preventing any accidental hard deletes.
- **Test Suite Updates**:
  - Updated `ChecklistTest` to assert `$this->assertSoftDeleted(...)`.
  - Added soft delete verification in `MediaAttachmentTest`.
  - All 137 tests passed (1,897 assertions) with 0 failures.
  - Laravel Pint verified with 0 formatting issues.

## 2026-11-10 — Architecture Simplification: Feature 11 (Weather) & Feature 12 (Identity) — Complete Backend Migration

### Completed

- **Feature 11 (Weather)**:
  - **DTOs (`app/DTOs/Weather/`)**: Created typed `TripWeatherData`, `DailyForecastData`, and `WeatherConditionData`.
  - **Services (`app/Services/Weather/`)**: Migrated `GetTripWeatherService` to `WeatherService` (`getWeather`, `getCurrentWeather`).
  - **Externalized Reference Data**: Extracted 70+ global city/destination coordinates to `database/data/city_coordinates.json`, loaded with `Cache::rememberForever`.
  - **Controllers (`app/Http/Controllers/Api/V1/`)**: Updated `TripWeatherController` with constructor DI.
  - **Cleanup**: Removed `app/Application/Weather/`.

- **Feature 12 (Identity / Auth & Profile) & Legacy Removal**:
  - **DTOs (`app/DTOs/Identity/`)**: Created `AuthTokenResult`, `RegisterUserData`, `LoginUserData`, and `UpdateProfileData`.
  - **Exceptions (`app/Exceptions/`)**: Moved `InvalidCredentials` to `app/Exceptions/InvalidCredentials.php`, updated `ApiExceptionResponse`.
  - **Services (`app/Services/Identity/`)**:
    - `AuthService` (`register`, `login`, `logout`).
    - `ProfileService` (`update`, `deleteAccount`).
  - **Controllers (`app/Http/Controllers/Api/V1/`)**: Refactored `AuthController` and `ProfileController` to use constructor dependency injection.
  - **Legacy Removal**: Fully purged `app/Application/` and `app/Domain/` directories. All 12 domain features now run on the unified Service-Model-DTO architecture.

- **Verification**:
  - 100% test pass rate across the entire test suite: 137 tests passed (1,896 assertions) in 14.35s.
  - Auth and Profile test suite: 15 passed (97 assertions).
  - Weather test suite: 7 passed (125 assertions).
  - Formatting: Laravel Pint passed with 0 style errors.

## 2026-11-10 — Architecture Simplification: Feature 3 (Stays) to Service-Model-DTO Pattern

### Completed

- **Feature-by-Feature Architecture Migration**:
  - Migrated `Stays` (accommodations & luggage-aware transport comparison) from DDD layer to standard Laravel Service-Model-DTO architecture.
  - **Models (`app/Models/`)**:
    - Moved `Stay.php` to `app/Models/` (namespace `App\Models`).
    - Decoupled and updated relationships in `Trip.php`, `ItineraryItem.php`, `Expense.php`, and `TodaySummaryResult.php`.
  - **DTOs (`app/DTOs/Stays/`)**:
    - Consolidated `CreateStayData`, `UpdateStayData`, and `CompareStayTransportData` into `app/DTOs/Stays/`.
  - **Services (`app/Services/Stays/`)**:
    - Created unified `StayService` (`create`, `update`, `delete`, `compareTransport`).
    - Moved `CompareStayTransportService`, `StayTransitService`, and `GeminiTransitService` under `app/Services/Stays/`.
  - **Controllers (`app/Http/Controllers/Api/V1/`)**:
    - Simplified `StayController` and `StayTransportController` to inject unified `StayService` directly.
  - **Removed Legacy Paths**:
    - Removed `app/Domain/Stays/` and `app/Application/Stays/`.
- **Verification**:
  - Ran `php artisan test`: All 127 tests passed (787 assertions) in 14.14s.
  - Ran `./vendor/bin/pint`: Formatted and cleaned all modified files.

## 2026-11-10 — Architecture Simplification: Feature 2 (Itinerary) to Service-Model-DTO Pattern

### Completed

- **Feature-by-Feature Architecture Migration**:
  - Migrated `Itinerary` from DDD/Modular Monolith layer to standard Laravel Service-Model-DTO architecture.
  - **Models (`app/Models/`)**:
    - Moved `ItineraryItem.php`, `TripDay.php`, `Place.php`, and `VisitEvent.php` to `app/Models/` (namespace `App\Models`).
    - Updated relationships and imports across all models, factories, and resources.
  - **DTOs (`app/DTOs/Itinerary/`)**:
    - Consolidated 10 DTO classes into `app/DTOs/Itinerary/` (`CreateItineraryItemData`, `UpdateItineraryItemData`, `CreatePlaceData`, `RecordVisitEventData`, `GenerateAiItineraryData`, `ApplyAiItineraryData`, `AiItineraryPlanResult`, `AiDaySuggestionData`, `AiActivitySuggestionData`, `TripAssistantResult`).
  - **Services (`app/Services/Itinerary/`)**:
    - Created unified `ItineraryService` (`createItem`, `updateItem`, `deleteItem`, `reorderItems`, `ensureTripDay`, `recordVisitEvent`).
    - Created unified `PlaceService` (`createPlace`, `search`).
    - Moved AI services (`GenerateAiItineraryService`, `ApplyAiItineraryService`, `GeminiItineraryService`, `AskTapItTripService`, `GeminiAssistantService`) under `app/Services/Itinerary/`.
  - **Controllers (`app/Http/Controllers/Api/V1/`)**:
    - Simplified `ItineraryItemController`, `TripDayController`, `VisitEventController`, `PlaceController`, and `AiItineraryController` to inject unified services directly.
  - **Removed Legacy Paths**:
    - Safely removed `app/Domain/Itinerary/` and `app/Application/Itinerary/`.
- **Verification**:
  - Ran `php artisan test`: All 127 tests passed (787 assertions) in 25.38s.
  - Ran `./vendor/bin/pint`: Formatted and cleaned all modified files.

## 2026-11-10 — Architecture Simplification: Feature 1 (Trips) to Service-Model-DTO Pattern

### Completed

- **Feature-by-Feature Architecture Migration**:
  - Migrated `Trips` from DDD/Modular Monolith layer to standard Laravel Service-Model-DTO architecture.
  - **Models (`app/Models/`)**:
    - Moved `Trip.php` and `TripMember.php` to `app/Models/` (namespace `App\Models`).
    - Updated `User.php` and all relational models across the backend to reference `App\Models\Trip` directly.
  - **Policies (`app/Policies/`)**:
    - Moved `TripPolicy.php` to standard `app/Policies/TripPolicy.php` (namespace `App\Policies`).
    - Configured gate policy registration in `AppServiceProvider`.
  - **DTOs (`app/DTOs/Trip/`)**:
    - Created `app/DTOs/Trip/CreateTripData.php`, `UpdateTripData.php`, and `TodaySummaryResult.php` (namespace `App\DTOs\Trip`).
  - **Services (`app/Services/Trip/`)**:
    - Unified `CreateTrip`, `UpdateTrip`, `DeleteTrip`, and `GetTodaySummaryService` into a cohesive `TripService` under `app/Services/Trip/TripService.php` (`create`, `update`, `delete`, `getTodaySummary`).
  - **Controllers (`app/Http/Controllers/Api/V1/`)**:
    - Simplified `TripController` and `TripTodayController` to inject and delegate directly to `TripService`.
  - **Factories & Tests**:
    - Updated `TripFactory.php`, `TripMemberFactory.php`, and all 25+ test suites referencing `Trip` to use the new namespaces.
- **Verification**:
  - Ran `php artisan test`: All 127 tests passed (787 assertions) in 14.73s.
  - Ran `./vendor/bin/pint`: Fixed styling and imports across modified files.

## 2026-11-09 — Destination Country Flag in Trip Card and Itinerary Header

### Completed

- **Country Flag Resolution (`CountryCurrencyHelper.resolveFlag`)**:
  - Implemented `resolveFlag` in `client/lib/core/constants/countries.dart` supporting:
    - 2-letter ISO country codes (`PH`, `JP`, `HK`, `US`, `FR`, `SG`, etc.) with fallback conversion to Unicode regional indicator symbols for any arbitrary valid 2-letter country code.
    - Full country names and keyword matches across all supported international destinations.
    - City / region landmarks (e.g. `BGC`, `Taguig`, `Manila` $\rightarrow$ 🇵🇭, `Tokyo`, `Osaka`, `Kyoto`, `Hakone` $\rightarrow$ 🇯🇵, `Hong Kong` $\rightarrow$ 🇭🇰, `Paris` $\rightarrow$ 🇫🇷, `Seoul` $\rightarrow$ 🇰🇷, `Bali` $\rightarrow$ 🇮🇩, etc.).
- **Trip Card Flag Display (`TripCard`)**:
  - Displayed the resolved country flag emoji directly adjacent to `trip.title` with clean typography and spacing.
  - Added flag badge next to `trip.destinationCountry` in the bottom tag row of the trip card.
  - Avoids duplicate emojis if the user-inputted title already begins with the flag emoji.
- **Itinerary Header Flag Display (`TripItineraryPage`)**:
  - Displayed the destination country flag emoji before the trip title in the main itinerary header.
- **Verification**:
  - Added unit tests in `currency_test.dart` verifying flag resolution across country codes, country names, and cities.
  - Updated widget test in `trip_test.dart` verifying flag rendering inside `TripCard`.
  - Ran `flutter test`: 166/166 passed.
  - Ran `flutter analyze`: 0 issues found.

## 2026-11-09 — Automatic AI Starter Itinerary Generation on Trip Creation Fix

### Completed

- **Trip Creation AI Starter Itinerary Pipeline (`TripCreatePage`)**:
  - Mapped user-selected trip types (`leisure`, `business`, `group`, `solo`, `family`) to valid domain travel party identifiers (`couple`, `solo`, `friends`, `solo`, `family_kids`) prior to invoking AI generation.
  - Automatically invokes `aiRepo.generatePlan` and `aiRepo.applyPlan` when `_autoGenerateItinerary` is toggled on during trip creation.
  - Invalidates cache and safely passes populated trip state so the itinerary timeline immediately renders all AI-generated activities upon navigation.
  - Added test in `trip_test.dart` verifying that `TripCreatePage` triggers both `/ai-plan/generate` and `/ai-plan/apply` with correctly mapped travel party (`couple` for `leisure`).
- **Backend AI Plan Request Normalization (`GenerateAiItineraryRequest`)**:
  - Added request normalization mapping `leisure`, `group`, `business`, `family`, `couple`, and `solo` aliases to valid travel parties.
  - Expanded validation rules to accept `leisure`, `business`, and `group` as valid inputs without throwing 422 `validation_failed`.
  - Added feature test `test_user_can_generate_ai_itinerary_with_trip_type_as_travel_party` in `AiItineraryTest.php`.
- **Verification**:
  - Backend PHPUnit `AiItineraryTest.php`: 6/6 tests passed (28 assertions).
  - Client Flutter test suite: 165/165 tests passed.
  - `flutter analyze`: 0 issues found.

## 2026-11-09 — Destination Forex Currency Alignment & Permanent Address in Profile & Registration

### Completed

- **Database & Identity Schema (`users` table, `UserResource`)**:
  - Added migration `2026_11_09_142647_add_permanent_address_to_users_table.php` adding `permanent_address` to `users`.
  - Added `permanent_address` to `$fillable` in `User.php` and serialized in `UserResource.php`.
- **Registration & Profile API (`RegisterRequest`, `RegisterUserService`, `UpdateProfileRequest`, `UpdateProfileService`)**:
  - Enhanced `RegisterRequest` and `RegisterUserService` to accept and persist `permanent_address`, `home_country`, and `home_currency`.
  - Auto-resolves `home_currency` via `CountryCurrencyResolver` from permanent address or country if not explicitly specified.
  - Enhanced `UpdateProfileRequest` and `UpdateProfileService` to support updating `permanent_address`, `home_country` (string), and `home_currency`.
  - Added feature tests `test_user_can_register_with_permanent_address_and_auto_resolved_currency` and `test_authenticated_user_can_update_profile_permanent_address` in `AuthTest.php` (15/15 passed, 97 assertions).
  - Updated `docs/api/openapi.yaml` with `permanent_address` in `User`, `RegisterRequest`, and `PATCH /me`.
- **Mobile Registration Flow (`RegisterPage`)**:
  - Added Permanent Address text field (`_permanentAddressController`) with real-time country & currency matching.
  - Added Country of Residence & Home Currency selector tile with country flag and detected home currency badge.
  - Added prominent advisory/warning card: *"Setting your permanent address helps TapItTrip automatically detect your home currency and convert prices accurately based on your travel destinations."*
- **Mobile Profile & Settings Flow (`ProfilePage`)**:
  - Created dedicated `ProfilePage` (`/profile`) accessible from the account popup menu on `TripListPage` and by tapping the traveler greeting.
  - Displays user avatar, display name, email, editable permanent address, country selector dialog, and home currency dropdown.
  - Features dedicated forex conversion explainer banner highlighting how permanent address sets base currency for automated travel conversion.
- **Expense & Budget Forex Alignment (`TripExpensesPage`, `SetBudgetDialog`)**:
  - Aligned default budget currency with `destinationCurrency` so trip budgets directly reflect the destination country (e.g. PHP in Philippines, JPY in Japan, HKD in Hong Kong), while allowing travelers to select their home currency if preferred.
  - Added prominent permanent address setup banner with a 1-tap shortcut to `/profile` when permanent address is unset.
- **Verification**:
  - Backend PHPUnit `AuthTest.php`, `CurrencyTest.php`, `TripExpenseTest.php`: 27/27 tests passed (166 assertions).
  - Pint code styling: 327 files passed cleanly.
  - Client Flutter test suite: 165/165 tests passed.
  - `flutter analyze`: 0 issues found.

## 2026-11-09 — Itinerary Activity Stop Weather Forecasts & Location Resolution

### Completed

- **Backend Location & Sub-Destination Weather API (`GetTripWeatherService`, `TripWeatherController`)**:
  - Enhanced `GET /api/v1/trips/{trip}/weather` to accept optional `latitude`, `longitude`, and `location` query parameters.
  - Generates location-specific cache keys (`trip_weather_{tripId}_{locKey}_{dateKey}`) enabling separate caching for individual itinerary stops (e.g. Hakone / Mt. Fuji vs Tokyo, or Taguig / BGC vs Manila).
  - Implemented `resolveCoordinatesForLocation` with place matching from existing itinerary items and city coordinates dictionary covering international and domestic destinations (Tokyo, Hakone, Kyoto, Osaka, Taguig/BGC, Makati, Manila, Cebu, Boracay, Baguio, Seoul, Bangkok, Singapore, Bali, etc.).
  - Added feature test `test_trip_weather_with_custom_coordinates_and_location` in `TripWeatherTest.php` (4/4 tests pass, 104 assertions).
- **Client Offline-First Repository & Riverpod Providers**:
  - `WeatherRepository.fetchTripWeather`: Accepts optional `latitude`, `longitude`, and `location` parameters with sub-location secure storage caching keys and fallback to main trip weather cache when offline.
  - `itemLocationWeatherProvider`: Added family provider resolving location-specific forecasts for individual itinerary items.
- **Itinerary Activity Timeline Card Weather Badges**:
  - `ActivityTimelineCard`: Added `final TripWeather? weather;` and `final VoidCallback? onWeatherTap;` parameters (100% backward-compatible `StatelessWidget`).
  - Added `_buildWeatherBadge` displaying scheduled day forecast matching (`item.day?.localDate` or `item.startsAtUtc`): day name prefix, temperature, weather icon, condition text, rain probability badge when $>15\%$, and offline sync indicator.
  - `LiveWeatherActivityTimelineCard`: Implemented `ConsumerWidget` that automatically watches `itemLocationWeatherProvider` for the venue and gracefully falls back to `tripWeatherProvider`.
  - Wired `LiveWeatherActivityTimelineCard` into `TripItineraryPage` timeline list; tapping the weather badge navigates directly to the whole-week destination Weather tab.
- **UI Polish**:
  - `NextStopCard`: Fixed button styling and padding for `Directions` and `Visited` to prevent font scaling clipping on smaller devices.
- **Verification**:
  - `client/test/itinerary_test.dart`: 14/14 tests pass.
  - `client/test/weather_test.dart`: 10/10 tests pass.
  - Total Flutter client tests: 161/161 tests pass.
  - `flutter analyze`: 0 issues found.
  - Backend PHPUnit `TripWeatherTest`: 4/4 tests pass (104 assertions).

## 2026-11-09 — Ask TapItTrip AI Assistant with Travel Scoping & Practical Suggestions

### Completed

- **Backend AI Assistant Service (`GeminiAssistantService`, `AskTapItTripService`)**:
  - Implemented `GeminiAssistantService` integrating Google Gemini live internet AI (`gemini-flash-lite-latest`) for open-ended traveler Q&A and concierge advice.
  - Injects full trip context: title, destination country/city, travel dates, trip type, accommodations/stays, and currently planned stops.
  - **Strict Travel Scoping & Guardrails**:
    - AI is bounded strictly to travel-related inquiries: itineraries, dining & local food, packing & seasonal gear, cultural etiquette & tipping, transit/navigation, hidden gems, and traveler safety.
    - Out-of-scope non-travel prompts (e.g. programming/code, homework, math, politics, unrelated news) trigger a polite redirection back to trip advice, with `category: out_of_scope` and empty actions.
  - **Practical Suggestions & Action Buttons**:
    - Generates actionable travel advice with clean Markdown headings and bullet points.
    - Emits structured `suggested_actions` for recommended stops, automatically normalized to canonical kinds (`attraction`, `meal`, `transport`, `hotel`) so travelers can add them directly to their itinerary in one tap.
  - **Offline-First Fallback**:
    - Seamlessly falls back to local deterministic rule heuristics (terminal lounges, toddler buffers, stays proximity, and weather arcades) when offline or when no API key is provided.
- **Mobile Client Enhancements (`AskTapItTripSheet`)**:
  - Upgraded to a conversational chat history thread where user questions and AI suggestions stay visible and scrollable.
  - User messages appear in right-aligned primary bubbles; assistant responses render in rich cards with category badges, advisory notice, and one-tap action buttons.
  - **In-Sheet Action State & Live Success Feedback**:
    - Replaced hidden background Scaffold SnackBar with an in-sheet animated notification banner pinned prominently inside the bottom sheet with a direct "View" shortcut.
    - Added live button state transitions: button disables and displays a spinner with *"Adding to itinerary..."* during execution, then smoothly transitions into a green completed badge (*"Added to Itinerary ✓"*) to prevent duplicate taps and reassure the traveler.
    - Added in-sheet error banner with human-readable error descriptions if validation fails.
  - Expanded quick suggestion chips: *"What should I pack for this trip?"*, *"Local tipping & payment etiquette"*, *"Top hidden gems and spots to visit"*, etc.
  - Added visual guardrail indicator styling when an out-of-scope prompt is entered.
- **OpenAPI & Automated Verification**:
  - Updated `docs/api/openapi.yaml` with expanded categories (`packing`, `culture`, `transit`, `itinerary`, `safety`, `out_of_scope`).
  - Added unit test suite `tests/Unit/GeminiAssistantServiceTest.php` testing key absence, travel query resolution, suggested actions normalization, out-of-scope redirection, and error resilience.
  - Expanded `tests/Feature/TripAssistantTest.php` testing live AI mocking and guardrail redirects.
  - Added Flutter widget test `renders out of scope response with travel guardrail category label` and `tapping action button adds stop, shows in-sheet success banner, and updates button state` in `client/test/trip_assistant_test.dart`.
  - Backend PHPUnit: 135/135 tests pass (754 assertions).
  - Backend Pint: 0 style issues across 318 files.
  - Mobile Flutter: 143/143 tests pass.
  - Mobile Analyzer: 0 issues found.

## 2026-11-09 — Itinerary Activity Kind Alias Normalization & AI Assistant Feedback Hardening

### Completed

- **Form Requests & Validation Normalization**:
  - `StoreItineraryItemRequest` & `UpdateItineraryItemRequest`: Added `prepareForValidation` hooks mapping natural language activity categories to canonical OpenAPI values:
    - `sightseeing`, `activity`, `nature`, `culture`, `shopping` $\rightarrow$ `attraction`
    - `dining`, `food`, `restaurant`, `cafe`, `bar` $\rightarrow$ `meal`
    - `transit`, `train`, `bus`, `taxi`, `rideshare` $\rightarrow$ `transport`
    - `stay`, `accommodation`, `resort` $\rightarrow$ `hotel`
  - Expanded `in:...` validation rule to accept all common aliases before database persistence.
- **AI Assistant Defaults**:
  - `AskTapItTripService`: Updated quick action suggestions to emit canonical kinds (`attraction`, `meal`) directly.
- **Mobile Client Normalization & Error Parsing**:
  - `AskTapItTripSheet`: Added `_normalizeActivityKind` helper before dispatching `addItem`.
  - Added structured unwrapping of `ValidationException` (displaying specific field errors) and `ApiException` in the user-facing SnackBar.
- **Automated Verification**:
  - Backend PHPUnit: Added `test_user_can_create_itinerary_item_with_kind_aliases_normalized` in `tests/Feature/ItineraryItemTest.php`. 133/133 tests pass (745 assertions).
  - Backend Pint: 0 style issues across 316 files.
  - Mobile Flutter: 141/141 tests pass.
  - Mobile Analyzer: 0 issues found.

## 2026-11-09 — Live Internet Gemini AI Travel & Ground Transit Intelligence

### Completed

- **Live Internet AI Integration (`GeminiTransitService`, `GeminiItineraryService`)**:
  - Implemented `GeminiTransitService` connecting to Google Gemini API (`models/gemini-flash-lite-latest`) with JSON mode schema enforcement.
  - Dynamically evaluates ANY airport and destination worldwide (e.g. Zurich ZRH -> SBB train & tram in CHF; Manila NAIA -> Grab & UBE Express in PHP; BGC Taguig -> local rideshare).
  - Normalizes and sanitizes untrusted AI output: validates transit modes, sets luggage-aware convenience scores (`isHeavyLuggage`, strollers, party size), checks step-free accessibility, and accurately calculates lowest-fare and fastest routes.
  - Transparent attribution: tags live results with `'provider_attribution' => 'AI Transit Intelligence via Google Gemini (Live Internet Sourced)'`.
  - Implemented `GeminiItineraryService` dynamically generating multi-day neighborhood-clustered itineraries with verified places, coordinates, start/end times, and local currency estimates.
  - Preserved offline-first resilience: if offline, rate-limited, or unconfigured, gracefully falls back to deterministic regional heuristic analyzers.
- **Configuration & Environment**:
  - Updated `api/config/services.php` with `gemini` config block (`api_key`, `model` defaulting to `gemini-flash-lite-latest`).
  - Documented `GEMINI_API_KEY=` and `GEMINI_MODEL=` in `api/.env.example`.
- **Automated Verification**:
  - Added unit test suite `tests/Unit/GeminiTransitServiceTest.php` testing API key absence, response parsing, scoring, and timeout handling.
  - Added unit test suite `tests/Unit/GeminiItineraryServiceTest.php` testing live itinerary JSON mapping.
  - Full backend test suite passing: 132/132 tests, 741 assertions. Pint clean across 316 files.
  - Mobile Flutter Analyzer: 0 issues.

## 2026-11-09 — AI Arrival Transport Intelligence, Non-Rail Regional Hubs & Client Currency Hardening

### Completed

- **AI Arrival Transport Intelligence & Regional Hubs (`CompareStayTransportService`, `StayTransitService`)**:
  - Dynamically detects airport transit capability and regional reality rather than proposing hardcoded express rail everywhere.
  - **Manila / NAIA (MNL)**: Accurately identifies that no airport rail station exists at Ninoy Aquino International Airport; recommends `GrabCar / NAIA Airport Taxi` (rideshare with Skyway routing in PHP), `UBE Express / P2P Premium Airport Bus` (public transit to Makati/BGC in PHP), and `NAIA Airport Loop & City Bus Network`.
  - **Bali / Ngurah Rai (DPS)**: Identifies absence of passenger trains; recommends `Pre-Arranged Private Driver / Hotel Transfer`, `Grab / Gojek Airport Pick-Up Lounge`, and `Ngurah Rai Airport Fixed-Rate Taxi` in IDR.
  - **Tokyo / Haneda & Narita (HND/NRT)**: Models authentic `Airport Express Rail` (Keikyu Line / Tokyo Monorail / JR East), `Direct Private Taxi / Airport Transfer` (Tokyo MK Taxi), and `Airport Limousine Bus` in JPY.
  - **London / Singapore / Paris**: Localized modes with authentic currency (GBP, SGD, EUR) and regional operators.
  - Generates transparent provider attribution: `'provider_attribution' => 'AI Transit Intelligence (TapItTrip Verified Regional Advisory)'`.
- **Currency & Residing Country Alignment**:
  - Transport options now return local destination currency (JPY, PHP, IDR, GBP, EUR) instead of hardcoded USD.
  - Mobile sheet calculates dual-currency conversion against user's residing/home currency (e.g. `¥2,200 (≈ ₱875.54)`).
  - Itinerary header displays destination currency with residing country conversion subtitle (`formatDual`).
- **Client Deserialization Hardening (`TripRepository`)**:
  - Replaced unsafe `response as Map<String, dynamic>` type casts with `Map<String, dynamic>.from(response as Map)` across `getTrips`, `getTrip`, `createTrip`, and `updateTrip`, preventing `TypeError` on runtime dynamic map deserialization.
  - Enhanced `TripCreatePage` error handling to surface actionable error descriptions if unexpected exceptions occur.
- **Automated Verification**:
  - Backend PHPUnit: Added `test_manila_arrival_transport_does_not_suggest_rail_and_recommends_grab_and_p2p_bus` and `test_bali_arrival_transport_does_not_suggest_rail_and_recommends_private_driver` in `StayTransportComparisonTest.php`. 132/132 tests pass (741 assertions).
  - Backend Pint: 0 style issues across 312 files.
  - Mobile Flutter: 141/141 tests pass.
  - Mobile Analyzer: 0 issues found.

## 2026-11-09 — Trip Destination Length & Client Error Feedback Hardening

### Completed

- **Database Migration & Schema**:
  - Migration `2026_11_09_060117_widen_destination_country_on_trips_table`: Widened `destination_country` and `origin_country` on table `trips` from `varchar(2)` to `varchar(100)` nullable.
  - Executed on dev (`tapittrip`) and test (`tapittrip_test`) PostgreSQL databases with `tapittrip_migrator` credentials.
- **Backend Validation & Form Requests**:
  - Updated `StoreTripRequest` and `UpdateTripRequest`: Changed `destination_country` and `origin_country` validation rules from `size:2` to `max:100` so travelers can enter city/district names (e.g. "Taguig", "BGC", "Tokyo, Japan") directly from autocomplete or input fields without 422 errors.
  - Updated `CountryCurrencyResolver`: Added common Philippine destination keywords (`taguig`, `bgc`, `makati`, `davao`, `siargao`, `bohol`, `baguio`, `pasig`, `quezon city` -> `PHP`).
  - OpenAPI Specification: Updated `docs/api/openapi.yaml` to document `destination_country` and `origin_country` as strings up to 100 characters.
- **Mobile Client Enhancements**:
  - `CountryCurrencyHelper`: Added corresponding city/district keywords (`taguig`, `bgc`, `makati`, `davao`, etc.) to map cleanly to `PHP`.
  - `TripListNotifier`: Propagated API exceptions on `createTrip` and `updateTrip` via `rethrow`.
  - `TripCreatePage` & `EditTripBottomSheet`: Updated form submission error handlers to inspect `ValidationException` (extracting field error details) and `ApiException` rather than masking server errors with generic connection errors.
- **Automated Verification**:
  - Backend PHPUnit: Added `test_user_can_create_and_update_trip_with_named_city_destination` in `TripTest.php`. Full test suite passes: 129/129 tests, 717 assertions.
  - Backend Pint: 0 style issues.
  - Mobile Flutter Tests: 140/140 tests pass.
  - Mobile Flutter Analyzer: 0 issues.

## 2026-11-09 — Milestone M9 (Slice 1): Personal & Group Travel Journal Entries and Photo Reflections

### Completed

- **Database Migrations & Schema**:
  - `journal_entries`: UUID primary key, `trip_id` FK cascade (`trips.id`), `user_id` FK cascade (`users.id`), `itinerary_item_id` FK nullable (`itinerary_items.id`), `title` string(255), `content` text, `entry_date` date, `location_name` string(255) nullable, `weather` string(64) nullable, `mood` string(32) nullable, `is_shared` boolean default false, `photos` jsonb default '[]', timestamps, softDeletes.
  - Indexed on `[trip_id, entry_date]` and `[user_id, is_shared]`.
  - Applied to `tapittrip` dev and `tapittrip_test` PostgreSQL databases with privileged migrator credentials.
- **Backend Application Services & Domain Architecture**:
  - Domain Model: `JournalEntry` (`App\Domain\Journal\Models\JournalEntry`).
  - Relation: `journalEntries(): HasMany` on `Trip`.
  - Factory: `JournalEntryFactory` (`Database\Factories\JournalEntryFactory`).
  - DTOs: `CreateJournalEntryData`, `UpdateJournalEntryData` under `App\Application\Journal\Data`.
  - Application Services:
    - `CreateJournalEntryService`: Creates journal reflection with transaction boundary and author attribution.
    - `UpdateJournalEntryService`: Enforces author-only modifications and handles `is_shared` circle sharing toggles.
    - `DeleteJournalEntryService`: Author and trip-owner soft deletion.
    - `GetTripJournalService`: Enforces TC-8.1 personal privacy filtering: returns author's personal entries + entries shared with circle (`where('user_id', $user->id)->orWhere('is_shared', true)`).
    - `UploadJournalPhotoService`: Validates image MIME/size and uploads to storage disk with UUID paths.
- **Backend HTTP Layer & OpenAPI**:
  - Form Requests: `CreateJournalEntryRequest`, `UpdateJournalEntryRequest`, `UploadJournalPhotoRequest`.
  - API Resource: `JournalEntryResource` exposing author metadata, mood, weather, privacy flag, and photo list.
  - Controller: `TripJournalController` registering:
    - `GET /api/v1/trips/{trip}/journal`
    - `POST /api/v1/trips/{trip}/journal`
    - `GET /api/v1/journal-entries/{entry}`
    - `PATCH /api/v1/journal-entries/{entry}`
    - `DELETE /api/v1/journal-entries/{entry}`
    - `POST /api/v1/journal-entries/{entry}/photos`
  - Routes registered in `api/routes/api.php` and `phpunit.postgres.xml`.
  - Documented all endpoints and schemas in `docs/api/openapi.yaml`.
- **Mobile Client Integration**:
  - Domain Model: `JournalEntry` with mood emoji helpers (`amazed` 🤩, `happy` 😊, `peaceful` 😌, `excited` 🎉, `tired` 😴, `grateful` 🙏, `adventurous` 🏔️), weather icons, and privacy labels.
  - Repository: `JournalRepository` with encrypted secure storage caching (`cached_journal_{tripId}`) and automatic offline fallback.
  - Provider: `tripJournalProvider(tripId)` with Riverpod `AsyncNotifier` handling listing, filtering, creating, editing, deleting, and sharing toggles.
  - Presentation Widgets:
    - `JournalEntryCard`: Author avatar, date, mood/weather chips, location chip, privacy badge (`🔒 Only You` vs `👥 Shared with Circle`), and photo thumbnail gallery.
    - `AddJournalEntrySheet`: Interactive reflection composer with mood selector, weather picker, photo input, and "Share with Circle" toggle (defaulting to private).
    - `TripJournalPage`: Journal feed with stats summary header (Total Moments, Shared Circle, Only You), filter chips, and empty state.
    - Router & Navigation: Added `/trips/:tripId/journal` to `AppRouter` and "Memories & Journal" to the Itinerary page overflow menu.
- **Automated Verification**:
  - Backend PHPUnit: Added `TripJournalTest.php` (5 tests, 25 assertions). Full suite passes: 125/125 tests, 700 assertions.
  - Backend Pint: 0 style issues.
  - Mobile Flutter Tests: Added `journal_test.dart` (10 tests). Full suite passes: 136/136 tests.
  - Mobile Flutter Analyzer: 0 issues.
  - Feature Document: Created `docs/features/travel-journal-and-memories.md`.

## 2026-11-09 — Itinerary Weather Tab Layout Fix & Whole-Week Forecast Display

### Completed

- **Itinerary Page Weather Tab Layout Fix (`TripWeatherView`)**:
  - Identified cause of blank white screen when selecting the "Weather" tab on `TripItineraryPage`: `TripWeatherView` was returning an unconstrained `ListView` inside the outer page `ListView`, which triggered Flutter's unhandled `Vertical viewport was given unbounded height` layout error and caused the tab's contents to collapse into a blank area.
  - Replaced the inner `ListView` with a responsive `Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [...])`, allowing current weather metrics and the 7-day forecast to lay out and scroll naturally within the page.
  - Updated forecast header to display expected weather for the whole week with daily temperature highs, lows, condition icons, and precipitation probability badges.
  - Added `weatherColor` mapping on `DailyForecast` model for consistent, accessible condition styling.
  - Extended fallback/offline weather generator in `GetTripWeatherService.php` from 5 days to 7 full days so travelers always see the complete week.
- **Automated Verification**:
  - Mobile Flutter Tests: 160/160 tests passed (`flutter test`), including test specifically asserting that switching to the Weather tab in `TripItineraryPage` renders current conditions and whole-week forecast cards without layout or unbounded height errors.
  - Mobile Analyzer: 0 issues found (`flutter analyze`).
  - Backend PHPUnit: 139/139 tests passed.

## 2026-11-09 — Automatic AI & Manual Itinerary Setup in Trip Creation Flow

### Completed

- **Automatic Itinerary Setup in Trip Creation**:
  - Implemented the user-requested automatic itinerary generation upon creating a new trip/travel in `TripCreatePage` (`client/lib/features/trips/presentation/pages/trip_create_page.dart`).
  - Added dedicated **"Itinerary Setup"** card with modern, intuitive options:
    - **✨ Auto-generate starter itinerary with AI (Recommended/Default)**:
      - Automatically generates curated stops, daily schedules, and neighborhood clusters tailored to the destination, trip duration, and party size upon trip creation.
      - Includes customizable quick interest chips (`Sightseeing`, `Food & Dining`, `Culture & Arts`, `Nature & Parks`, `Shopping`, `Relaxation`).
      - Calls `GenerateAiItineraryService` (`/trips/{trip}/ai-plan/generate`) and immediately persists stops via `ApplyAiItineraryService` (`/trips/{trip}/ai-plan/apply`).
    - **✍️ Add first stop manually instead**:
      - Allows travelers to manually input their initial stop (title, location/address with autocomplete, and category dropdown) directly on the creation form.
      - Automatically persists the activity via `ItineraryRepository.createItem` before redirecting.
    - **Blank / Clean Slate**:
      - Travelers can opt to start with an empty itinerary if preferred.
  - **Seamless Navigation & Transition**:
    - Replaced the generic `context.pop()` with direct replacement navigation to `TripItineraryPage` (`/trips/:tripId/itinerary`).
    - The traveler immediately lands on their newly populated itinerary timeline with all activities, places, and schedules ready to explore or edit.
    - Loading button reflects real-time status (`Creating your trip...` -> `Crafting your AI starter itinerary...`).
    - Offline and error-resilient: if the user is offline or the AI service fails, the trip is still created safely and the user transitions smoothly.
- **Backend Currency Rate String Type Cast Fix**:
  - `CurrencyExchangeRateService`: Fixed `TypeError` on `ExchangeRateData` constructor where cached rates retrieved from Redis/cache were returned as strings, causing strict type mismatch with `float $rate`. Added explicit float casting on cache retrieval and reciprocal computation.
- **Automated Verification**:
  - Backend PHPUnit: 139/139 tests passed (865 assertions) on PostgreSQL test database.
  - Mobile Flutter Tests: 158/158 tests passed (`flutter test`).
  - Mobile Analyzer: 0 issues found (`flutter analyze`).

## 2026-11-09 — Trip Weather Integration, AI Stop Creation & Trip Form Robustness

### Completed

- **Trip & Dashboard Live Weather**:
  - Backend Service (`GetTripWeatherService`): Resolves destination coordinates from active stays, itinerary places, or destination city dictionary; fetches current conditions and 7-day daily forecast via Open-Meteo with 30-minute caching, WMO weather code mapping, and offline seasonal fallback.
  - Endpoints: `GET /api/v1/trips/{trip}/weather` (`TripWeatherController`) and embedded `weather` object in `GET /api/v1/trips/{trip}/today`.
  - Mobile Client:
    - Domain models: `WeatherCondition`, `DailyForecast`, `TripWeather`.
    - `TodayWeatherCard`: Embedded in `TodayDashboardPage` showing temperature, feels-like, humidity, rain probability, and weather advisory tip.
    - `TodayHeroCard`: Status row compact weather badge with responsive wrap layout.
    - `TripWeatherView`: Dedicated tab in `TripItineraryPage` displaying destination climate, current metrics, trip day forecast cards, and one-tap rainy-day alternative planner.
    - `ItineraryFilterTabs`: Added `'Weather'` tab alongside Itinerary, Transport, Stay, Checklists, and Recommendations.
    - Trip Header: Added compact weather pill next to trip date/style in `TripItineraryPage`.
    - Trips List Page (`TripListPage`): Added `LiveWeatherTripCard` displaying live temperature pill (e.g. `☀️ 28°C` / `🌤️ 18°C`) beside the destination on each trip card in "Your Trips", with interactive tooltip, color-coded status, and responsive overflow safety.
- **AI Suggested Activities & Itinerary Validation Fix**:
  - Problem: When adding AI-suggested activities from Ask TapItTrip, non-whitelisted categories (e.g. `museum`, `coffee`, `park`, `entertainment`) or empty/unformatted place maps triggered `422 validation_failed: The given data was invalid`.
  - Fix in `StoreItineraryItemRequest` & `UpdateItineraryItemRequest`:
    - In `prepareForValidation`: Intelligently maps any activity description/category to canonical kinds (`attraction`, `meal`, `transport`, `flight`, `hotel`, `custom`).
    - Maps `place.address` to `place.formatted_address` and defaults provider to `manual`.
    - Handles empty place names by cleanly merging null place instead of throwing required-field validation errors.
  - Fix in `AskTapItTripSheet` & `AddActivityBottomSheet`:
    - Normalized category handling in `_normalizeActivityKind`.
    - Sanitized place payload with `name`, `formatted_address`, `address`, and `provider: 'manual'`.
    - Replaced raw exception string printing with clean user feedback and inline success feedback (`Added "[Name]" to your itinerary!`).
- **Trip Creation & API Exception Resilience**:
  - `ApiClient`: Safely decodes `DioException.response.data` maps without strict type assumptions that previously swallowed validation errors or caused generic connection error messages.
  - `TripCreatePage`: Cleaned exception display to show exact server error messages rather than confusing connection prompts.
- **Automated Verification**:
  - Backend PHPUnit: 139/139 tests passed (847 assertions) on PostgreSQL test database.
  - Backend Pint: 326 files pass code style checks cleanly.
  - Mobile Flutter Tests: 150/150 tests passed.
  - Mobile Analyzer: 0 issues found.

## 2026-11-08 — Milestone M9: Travel Journal, Timeline Memories & Trip Export

### Completed

- **Backend Architecture & Forex Services**:
  - Database Migration: Added `home_country` (string(2) nullable) and `home_currency` (string(3) nullable) to `users` table. Applied on dev and test databases.
  - Domain Services:
    - `CountryCurrencyResolver`: Standardized mapping between ISO country codes, popular country names, and major city keywords to primary ISO 4217 currencies.
    - `ExchangeRateProviderInterface`: Pluggable contract for currency exchange rate fetching.
    - `LiveExchangeRateProvider`: Connects to live market exchange rate feed with timeout, retry, and built-in fallback.
    - `FakeExchangeRateProvider`: Deterministic rate provider for unit and feature tests.
    - `CurrencyExchangeRateService`: Coordinates provider, caching (1-hour TTL), and reciprocal rate calculations ($1 / \text{rate}$).
    - `UpdateProfileService`: In-place updates for traveler profile fields (`home_country`, `home_currency`, `display_name`, `home_timezone`, `locale`) with automatic currency derivation.
  - Routes & Endpoints:
    - `PATCH /api/v1/me`: Update profile attributes via `UpdateProfileRequest`.
    - `GET /api/v1/currencies/rates`: Fetch live or cached exchange rates between any two currencies via `CurrencyController`.
    - `UserResource` & `TripResource`: Exposed `home_country`, `home_currency`, and dynamically resolved `destination_currency`.
    - Documented all endpoints and schema updates in `docs/api/openapi.yaml`.
- **Mobile Client Integration**:
  - Models: Added `homeCountry` and `homeCurrency` to `AuthUser`, `destinationCurrency` to `Trip`.
  - Helpers: Created `CountryCurrencyHelper` in `client/lib/core/constants/countries.dart` with supported countries list, flags, and currency resolution.
  - Data: Created `CurrencyRepository` with encrypted secure storage caching (`cached_forex_{from}_{to}`) and offline snapshot fallbacks. Added `updateProfile` to `AuthRepository` and `authProvider`.
  - UI & Widgets:
    - `CountryResidenceDialog`: Searchable country picker displaying flags, countries, and currencies with one-tap profile persistence.
    - Prompt Banner: Non-intrusive prompt in `TripExpensesPage` inviting travelers to configure their residence when not yet set.
    - Live Market Rate Pill: Embedded indicator in `TripExpensesPage` showing real-time market rate between destination currency and home currency (`1 JPY ≈ ₱0.3800 PHP • Live/Cached`).
    - `AddExpenseBottomSheet`: Automatically defaults currency to the trip's destination currency; calculates and displays real-time conversion badge (`≈ ₱1,140.00 PHP • 1 JPY = 0.3800 PHP`) as amounts are typed, and supplies `exchange_rate` automatically.
    - `TodayBudgetCard`: Passes destination currency and home currency when launching "Log Expense" from the Today dashboard.
- **Automated Verification**:
  - Backend PHPUnit: Added `CurrencyTest.php` (4 tests) and updated `AuthTest.php`. Full suite passes: 120/120 tests, 675 assertions.
  - Backend Pint: 0 style issues.
  - Mobile Flutter Tests: Added `currency_test.dart` (8 tests). Full suite passes: 126/126 tests.
  - Mobile Analyzer: 0 issues.
  - Documentation: Updated `docs/features/expenses-and-budgeting.md` and `docs/api/openapi.yaml`.

## 2026-11-08 — Milestone M8 (Slice 3): Today Dashboard Budget Pacing & Receipt Capture

### Completed

- **Backend Application Services & Today Integration**:
  - `GetTodaySummaryService`: Integrated real-time budget pacing into today's dashboard response (`currency`, `total_budget_minor`, `daily_budget_minor`, `spent_today_minor`, `total_spent_minor`, `remaining_budget_minor`, `daily_utilization_percent`).
  - `TodaySummaryResult` & `TodaySummaryResource`: Added `budget_pacing` contract.
  - Receipt Upload: `POST /api/v1/expenses/{expense}/receipt` via `UploadReceiptRequest` with validation (mimes: jpeg, png, webp, pdf up to 10MB) and public storage disk integration.
  - OpenAPI Specification: Documented receipt endpoint in `docs/api/openapi.yaml`.
- **Mobile Client Today Budget Card & Receipt Support**:
  - Models: Added `BudgetPacing` model with minor-unit getters to `TodayDashboardSummary`.
  - `TodayBudgetCard`: Embedded card in `TodayDashboardPage` showing daily spending progress bar, color-coded threshold indicator (green under budget, red over daily target), remaining daily limit, and quick one-tap "Log Expense" / "All Expenses" actions.
  - `ExpenseRepository`: Added `uploadReceipt(expenseId, filePath)` method.
- **Automated Verification**:
  - Backend PHPUnit: Added `test_today_dashboard_includes_budget_pacing_when_budget_is_configured` to `TripTodayTest.php` and `test_can_upload_receipt_image_for_expense` to `TripExpenseTest.php`. Full suite passes: 115/115 tests, 636 assertions.
  - Backend Pint: 0 style issues.
  - Mobile Flutter Tests: Added `TodayBudgetCard` test in `today_test.dart`. Full suite passes: 118/118 tests.
  - Mobile Analyzer: 0 issues.
  - Documentation: Updated `docs/features/expenses-and-budgeting.md`.

## 2026-11-08 — Milestone M8 (Slice 2): Trip Circles Group Expense Splitting & Debt Settlement

### Completed

- **Database Migrations & Schema**:
  - `expense_splits`: UUID primary key, `expense_id` FK cascade (`expenses.id`), `user_id` FK cascade (`users.id`), `amount_minor` integer, `base_amount_minor` integer nullable, `shares` integer default 1, `settled` boolean default false, timestamps. Unique on `[expense_id, user_id]`.
  - `expense_settlements`: UUID primary key, `trip_id` FK cascade (`trips.id`), `payer_id` FK cascade (`users.id`), `payee_id` FK cascade (`users.id`), `amount_minor` integer, `currency` char(3), `settled_at` timestamp, `notes` text nullable, timestamps. Indexed on `[trip_id, settled_at]`, `[trip_id, payer_id]`, `[trip_id, payee_id]`.
  - Applied on dev (`tapittrip`) and test (`tapittrip_test`) PostgreSQL databases with privileged migrator tools container.
- **Backend Application Services & Domain Architecture**:
  - Domain models: `ExpenseSplit`, `ExpenseSettlement` under `App\Domain\Expenses\Models`.
  - Relations: `splits(): HasMany` on `Expense`, `settlements(): HasMany` on `Trip`.
  - Factories: `ExpenseSplitFactory`, `ExpenseSettlementFactory`, `TripMemberFactory`.
  - DTOs: `RecordSettlementData`, `GroupSettlementResult` under `App\Application\Expenses\Data`.
  - Application Services:
    - `CalculateGroupSettlementService`: Calculates net spending balances for every trip companion in base currency; runs a **Greedy Cash-Flow Minimization Algorithm** reducing mutual debts into minimal suggested transfers (`payer_id`, `payee_id`, `amount_minor`); includes past settlement history.
    - `RecordSettlementService`: Validates companion membership, ensures distinct non-self payer/payee, verifies positive amounts, and records `ExpenseSettlement` within `TripPolicy` bounds.
    - Enhanced `CreateExpenseService`: Automatic equal splitting across all trip members with remainder distribution or custom split arrays.
- **Backend API & Route Registration**:
  - Form Requests: `RecordSettlementRequest`, enhanced `CreateExpenseRequest` with `splits` array.
  - API Resources: `ExpenseSettlementResource`, `GroupSettlementResource`.
  - Controller: `GroupSettlementController` registering `GET /api/v1/trips/{trip}/settlements` and `POST /api/v1/trips/{trip}/settlements`.
  - OpenAPI Specification: Documented settlement endpoints and schemas in `docs/api/openapi.yaml`.
- **Mobile Client Balances & Settle Up UI**:
  - Models: `GroupBalances`, `MemberBalance`, `SuggestedSettlement`, `SettlementRecord` with JSON serialization, balance getters, and multi-currency formatting.
  - `ExpenseRepository`: Added `getGroupBalances(tripId)` with encrypted local cache fallback (`cached_settlements_{tripId}`) and `recordSettlement(...)`.
  - Providers: Added `groupBalancesProvider(tripId)` and cache invalidation on expense mutations.
  - Widgets & UI:
    - `TripExpensesPage`: Tabbed interface with `Expenses` and `Balances & Settle` tabs.
    - "Balances & Settle" tab:
      - Member balances list with colored status pills (`is_owed`, `owes`, `settled`).
      - Suggested settlement transfers with "Settle Up" action button.
      - "All Settled Up!" green card when zero debts exist.
      - Past settlement history records.
    - `SettleUpDialog`: Interactive modal dialog to review payer, payee, pre-filled amount, and payment notes with real-time settlement submission.
    - `AddExpenseBottomSheet`: Added split-type selection (`Just me` vs `Split equally`).
- **Automated Verification**:
  - Backend PHPUnit: Added `GroupSettlementTest.php` (5 tests). Full suite passes: 113/113 tests, 624 assertions.
  - Backend Pint: 0 style issues.
  - Mobile Flutter Tests: Added GroupBalances and UI settlement tests to `expense_test.dart` (9 tests). Full suite passes: 117/117 tests.
  - Mobile Analyzer: 0 issues.
  - Documentation: Updated `docs/features/expenses-and-budgeting.md` and `docs/api/openapi.yaml`.

## 2026-11-08 — Milestone M8 (Slice 1): Core Trip Budget & Categorized Expense Tracking

### Completed

- **Database Migrations & Schema**:
  - `trip_budgets`: UUID primary key, `trip_id` FK cascade (`trips.id`), `currency` (char 3), `total_budget_minor` integer, `daily_budget_minor` integer nullable, timestamps. Unique on `[trip_id]`.
  - `expenses`: UUID primary key, `trip_id` FK cascade, `payer_id` FK cascade (`users.id`), `category` string (`transport`, `accommodation`, `dining`, `activities`, `shopping`, `other`), `title` string (255), `amount_minor` integer, `currency` char(3), `exchange_rate` decimal(12,6) nullable, `base_amount_minor` integer, `expense_date` date, `notes` text nullable, `itinerary_item_id` FK nullable, `stay_id` FK nullable, `split_type` string default 'single', `receipt_url` string nullable, `version` integer default 1, timestamps. Indexed on `[trip_id, expense_date]` and `[trip_id, category]`.
  - Applied on dev (`tapittrip`) and test (`tapittrip_test`) PostgreSQL databases with privileged migrator tools container.
- **Backend Application Services & Domain Architecture**:
  - Domain models: `TripBudget`, `Expense` under `App\Domain\Expenses\Models`.
  - Relations: `budget(): HasOne` and `expenses(): HasMany` on `Trip`.
  - Factories: `TripBudgetFactory`, `ExpenseFactory`.
  - DTOs: `SetTripBudgetData`, `CreateExpenseData`, `UpdateExpenseData`, `TripExpensesSummaryResult` under `App\Application\Expenses\Data`.
  - Application Services:
    - `SetTripBudgetService`: Sets or updates trip budget target in integer minor units with `TripPolicy` authorization.
    - `CreateExpenseService`: Records new expense, handles foreign currency conversion to trip base currency, and increments version.
    - `UpdateExpenseService`: Updates expense details and recalculates converted base amounts.
    - `DeleteExpenseService`: Deletes an expense with member authorization.
    - `GetTripExpensesSummaryService`: Aggregates total spent in base currency, calculates remaining budget and utilization percentage, and computes category breakdown percentages and daily spending trends.
- **Backend API & Route Registration**:
  - Form Requests: `SetTripBudgetRequest`, `CreateExpenseRequest`, `UpdateExpenseRequest`.
  - API Resources: `TripBudgetResource`, `ExpenseResource`, `TripExpenseSummaryResource`.
  - Controllers:
    - `TripBudgetController`: `GET /api/v1/trips/{trip}/budget`, `PUT /api/v1/trips/{trip}/budget`.
    - `TripExpenseController`: `GET /api/v1/trips/{trip}/expenses`, `POST /api/v1/trips/{trip}/expenses`, `GET /api/v1/trips/{trip}/expenses/summary`, `GET /api/v1/expenses/{expense}`, `PATCH /api/v1/expenses/{expense}`, `DELETE /api/v1/expenses/{expense}`.
  - OpenAPI Specification: Documented all endpoints, parameters, request bodies, and schemas in `docs/api/openapi.yaml`.
- **Mobile Client Budgeting & Expense Logging**:
  - Models: `TripBudget`, `Expense`, `ExpenseSummary`, `ExpenseCategoryBreakdown`, `DailySpendingItem` with JSON serialization, minor unit conversions, and currency formatting (including zero-decimal JPY).
  - `ExpenseRepository`: API requests with encrypted offline storage fallback via `FlutterSecureStorage` (`cached_budget_{tripId}`, `cached_expenses_{tripId}`, `cached_summary_{tripId}`).
  - Providers: `tripBudgetProvider`, `tripExpensesProvider`, `expenseSummaryProvider`, `selectedExpenseCategoryFilterProvider`.
  - Widgets & UI:
    - `TripExpensesPage`: Header budget overview card with utilization progress bar and remaining headroom, category filter chips (`All`, `Dining`, `Transport`, etc.), formatted expense list with category icons and multi-currency badges, and empty states.
    - `SetBudgetDialog`: Modal dialog to configure trip base currency, total budget target, and optional daily spending limit.
    - `AddExpenseBottomSheet`: Clean bottom sheet for quickly logging expenses with category selector, title, amount, currency, and date.
    - Navigation: Added `/trips/:tripId/expenses` route in `AppRouter` and "Expenses & Budget" entry in `TripItineraryPage` overflow menu.
- **Automated Verification**:
  - Backend PHPUnit: Added `TripBudgetTest.php` (5 tests) and `TripExpenseTest.php` (6 tests). Full suite passes: 108/108 tests, 587 assertions.
  - Backend Pint: 0 style issues.
  - Mobile Flutter Tests: Added `expense_test.dart` (6 tests). Full suite passes: 114/114 tests.
  - Mobile Analyzer: 0 issues.
  - Documentation: Created `docs/features/expenses-and-budgeting.md`.

## 2026-11-08 — Milestone M7: Smart Airport Experience & AI Travel Assistant (Full Delivery)

### Completed

- **Slice 1: Smart Airport Lounge Finder**:
  - PostgreSQL schema and migrations for `airports`, `airport_terminals`, and `airport_lounges`.
  - Application services: `SearchAirportLoungesService`, `GetAirportLoungeDetailsService`.
  - API endpoints: `GET /api/v1/airports/{iata}/lounges` and `GET /api/v1/lounges/{lounge}`.
  - Mobile client: `LoungeRepository` with encrypted offline caching, `AirportLoungeFinderPage`, `LoungeCard`, `LoungeDetailSheet`, launcher in `TodayDashboardPage`.
- **Slice 2: AI Smart Itinerary Planner & Route Clustering**:
  - Application services: `GenerateAiItineraryService` (neighborhood clustering, budget tiering, family tips, weather fallbacks), `ApplyAiItineraryService` (atomic non-destructive persistence).
  - API endpoints: `POST /api/v1/trips/{trip}/ai-plan/generate`, `POST /api/v1/trips/{trip}/ai-plan/apply`.
  - Invariant strictly enforced: **"AI suggests; the user approves"**. Existing bookings and activities are never overwritten.
  - Mobile client: `AiItineraryPlan` and `AiActivitySuggestion` domain models, `AiItineraryRepository`, `AiItineraryPlannerDialog`, `AiItineraryPreviewSheet`, launcher button on `TripItineraryPage` and empty itinerary states.
- **Slice 3: "Ask TapItTrip" Contextual In-Trip Assistant**:
  - Application service: `AskTapItTripService` ingests active trip context (stays, schedule, party mode, terminal) and answers queries (`dining`, `lounge`, `toddler_friendly`, `weather`, `general`).
  - API endpoint: `POST /api/v1/trips/{trip}/assistant/query` with `TripPolicy` authorization gate.
  - Mobile client: `TripAssistantResponse` model, `AskTapItTripSheet` bottom sheet with quick-prompt chips, advisory badge, and actionable buttons. Launcher cards integrated on `TodayDashboardPage` and `TripItineraryPage`.
- **Automated Verification**:
  - Backend PHPUnit: 97/97 tests passing (545 assertions) across PostgreSQL and Redis.
  - Backend Pint: 0 formatting/linter issues.
  - Mobile Flutter: 108/108 tests passing.
  - Mobile Analyzer: 0 issues.
  - Documentation: Created `docs/features/airport-lounge-finder.md`, `docs/features/ai-smart-itinerary-planner.md`, updated `docs/api/openapi.yaml`.

## 2026-11-08 — Milestone M7 (Slice 1): Smart Airport Lounge Finder

### Completed

- **Database Migrations & Schema**:
  - `airports`: UUID primary key, `iata_code` (unique char 3), `name`, `city`, `country`, `latitude`, `longitude`, `timezone`, timestamps.
  - `airport_terminals`: UUID primary key, `airport_id` FK cascade (`airports.id`), `name` (e.g. "Terminal 3"), `code` (e.g. "T3"), timestamps. Unique on `[airport_id, code]`.
  - `airport_lounges`: UUID primary key, `airport_id` FK cascade, `terminal_id` FK cascade, `name`, `operator`, `location_description`, `is_airside` boolean, `opening_hours` jsonb, `amenities` jsonb array (`buffet`, `bar`, `showers`, `wifi`, `power_outlets`, `quiet_area`, `family_room`), `access_methods` jsonb array (`priority_pass`, `dragon_pass`, `lounge_key`, `star_alliance_gold`, `business_class`, `paid_walkin`), `estimated_price` jsonb nullable, `booking_url` string nullable, `transit_warning` text nullable, `disclaimer` text nullable, timestamps. Indexed on `[airport_id, terminal_id]` and `[airport_id, is_airside]`.
  - Applied on dev (`tapittrip`) and test (`tapittrip_test`) PostgreSQL databases with privileged tools container.
  - Seeder: `AirportLoungeSeeder` populated verified lounge directories for key hubs (MNL T3 & T1, NRT T1).
- **Backend Application Services & Domain Architecture**:
  - Domain models: `Airport`, `AirportTerminal`, `AirportLounge`.
  - Factories: `AirportFactory`, `AirportTerminalFactory`, `AirportLoungeFactory`.
  - Application Services:
    - `SearchAirportLoungesService`: Searches lounges by airport IATA code with case-insensitive normalization, terminal filtering, airside status, and access method matching.
    - `GetAirportLoungeDetailsService`: Retrieves detailed lounge record with terminal and airport relationships.
- **Backend API & Route Registration**:
  - `AirportLoungeController`:
    - `GET /api/v1/airports/{iata}/lounges`: Search airport lounges with terminal/airside query parameters.
    - `GET /api/v1/lounges/{lounge}`: Retrieve detailed lounge data.
  - Form request: `SearchAirportLoungesRequest`.
  - API Resources: `AirportResource`, `AirportTerminalResource`, `AirportLoungeResource`.
  - Updated `docs/api/openapi.yaml` with lounge endpoints and schemas.
- **Mobile Client Lounge Finder & In-Flight Caching**:
  - Models: `Airport`, `AirportTerminal`, `AirportLounge` with JSON serialization.
  - `LoungeRepository`: Secure local storage caching (`cached_lounges_{iata}`) with automatic offline fallback when roaming or in-flight without connection.
  - Providers: `airportLoungesProvider`, `selectedAirportIataProvider`, `selectedTerminalFilterProvider`, `selectedAirsideFilterProvider`.
  - `LoungeCard`: Compact card showing terminal badge, airside pill, walking directions, and amenities preview.
  - `LoungeDetailSheet`: Interactive modal sheet detailing location, full amenities, entry programs, walk-in pricing, official booking links, transit warnings, and boarding gate reminder notices.
  - `AirportLoungeFinderPage`: Hub search with popular airport chips, terminal filter chips, and airside toggle.
  - Dashboard Integration: Added "Airport Lounge Finder" launcher card to `TodayDashboardPage` and registered `/lounges` in `AppRouter`.
- **Automated Verification**:
  - Backend PHPUnit: Added `AirportLoungeTest.php` (5 tests, 18 assertions). Full suite passes: 86/86 tests, 502 assertions.
  - Backend Pint: Passed with 0 style issues.
  - Mobile Flutter Tests: Added `airport_lounge_test.dart` (6 tests). Full suite passes: 100/100 tests.
  - Mobile Flutter Analyzer: 0 issues.
  - Mobile Dart Formatter: 100% formatted.
  - Feature document created: `docs/features/airport-lounge-finder.md`.

### Security and offline considerations

- Airport lounge directory data is cached securely in `FlutterSecureStorage` so travelers can view accessible lounges and terminal walking directions while offline or in airplane mode.
- Access restrictions, airside/landside zones, and inter-terminal security re-clearance warnings are prominently highlighted to prevent travelers from becoming stranded across terminals.
- All endpoints enforce authenticated requests via Sanctum.

## 2026-11-08 — Milestone M6: Sync Hardening, Durable Outbox & MVP Beta Packaging

### Completed

- **Database Migrations & Schema**:
  - `sync_server_sequence`: PostgreSQL monotonic sequence incrementing sequentially for global order.
  - `sync_operations`: UUID primary key, `operation_id` (unique client UUID), `user_id` FK cascade, `trip_id` FK cascade nullable, `device_key`, `entity_type` (`trip`, `itinerary_item`, `stay`, `checklist_item`), `entity_id` UUID, `operation_type` (`create`, `update`, `delete`), `payload` jsonb, `base_version` integer, `server_sequence` bigInteger (default `nextval('sync_server_sequence')`), `status` (`accepted`, `conflict`, `rejected`), `conflict_details` jsonb nullable, `processed_at`, timestamps. Indexed on `[user_id, trip_id, server_sequence]` and `[entity_type, entity_id]`.
  - `sync_cursors`: UUID primary key, `user_id` FK cascade, `device_key`, `trip_id` FK cascade nullable, `last_server_sequence` bigInteger default 0, timestamps. Unique on `[user_id, device_key, trip_id]`.
  - Applied on dev (`tapittrip`) and test (`tapittrip_test`) PostgreSQL databases with privileged tools container.
- **Backend Application Services & Domain Architecture**:
  - Domain models: `SyncOperation`, `SyncCursor`.
  - Factories: `SyncOperationFactory`, `SyncCursorFactory`.
  - Application Services:
    - `PushSyncOperationsService`: Processes offline mutation batches inside a database transaction; enforces idempotency deduplication by `operation_id`; checks trip membership authorization via `TripPolicy`; performs optimistic concurrency control / version conflict detection (`base_version < current_version`); applies valid entity mutations and increments entity version; records monotonic `server_sequence`; records conflict details when stale.
    - `PullSyncChangesService`: Fetches operations where `server_sequence > cursor` scoped by user or trip; returns ordered mutations, deletion tombstones, and updated sequence cursor.
- **Backend API & Route Registration**:
  - `SyncController`:
    - `POST /api/v1/sync/push`: Batch push offline mutations.
    - `GET /api/v1/sync/pull`: Pull server updates using monotonic cursors.
  - Updated `docs/api/openapi.yaml` with both sync endpoints, request/response bodies, and schemas.
- **Mobile Client Durable Outbox & Sync Engine**:
  - Models: `OutboxOperation`, `SyncOperationResult`, `PullResult` with full JSON serialization and copyWith.
  - `OutboxStorage`: Encrypted local persistence using `FlutterSecureStorage` (`tapittrip_outbox_queue`, `tapittrip_sync_cursor_${tripId}`). Survives app kill, memory pressure, and device reboot.
  - `SyncService`:
    - `queueMutation`: Enqueues offline changes with unique UUID and base version.
    - `pushPending`: Batches pending outbox operations to server, removing accepted items and updating conflict records.
    - `pullLatest`: Retrieves remote changes from cursor and advances local cursor.
    - `syncAll`: Push-then-pull bidirectional reconciliation.
    - `resolveConflict`: Interactive resolution allowing user to "Keep My Offline Edit" (re-applies on top of server version) or "Keep Server Version" (discards local edit).
  - Riverpod State: `syncProvider` exposing `SyncStatus` (`synced`, `pending`, `syncing`, `conflict`, `offline`), counts, and error tracking.
- **Mobile UI & Conflict Resolution**:
  - `SyncStatusIndicator`: Compact badge embedded in `TodayDashboardPage` and `TripItineraryPage` AppBars showing:
    - 🟢 Green cloud: "All changes synced"
    - 🟡 Amber pill: "${count} pending sync"
    - 🔴 Red warning pill: "Conflict (${count})" with one-tap resolution dialog
    - ⚪ Grey cloud: "Offline mode"
  - `ConflictResolutionDialog`: Visual diff dialog presenting server version vs traveler offline edit with "Keep Server Version" and "Keep My Offline Edit" actions.
- **Automated Verification**:
  - Backend PHPUnit: Added `SyncTest.php` (5 tests, 38 assertions). Full suite passes: 81/81 tests, 484 assertions.
  - Backend Pint: Passed with 0 style issues.
  - Mobile Flutter Tests: Added `sync_test.dart` (11 tests). Full suite passes: 94/94 tests.
  - Mobile Flutter Analyzer: 0 issues.
  - Mobile Dart Formatter: 100% formatted.
  - Feature document created: `docs/features/offline-sync-and-outbox.md`.

### Security and offline considerations

- In strict compliance with `AGENTS.md`, mutations queued offline survive device restarts and reboots via hardware-backed encrypted storage (`FlutterSecureStorage`).
- Retrying sync operations never duplicates entities or side-effects due to strict client UUID `operation_id` deduplication.
- Version conflict detection prevents silent overwrite of concurrent edits; conflicts are cleanly presented to the traveler.
- Monotonic server cursors ensure multi-device sync completeness and proper deletion tombstone propagation.
- All sync operations enforce trip membership authorization via `TripPolicy`. Sensitive auth credentials and tokens are never queued in the outbox.

## 2026-11-08 — Milestone M5: Notifications, Reminders & Geofenced Arrival Suggestions

### Completed

- **Database Migrations & Schema**:
  - `user_devices`: UUID primary key, `user_id` FK cascade (`users.id`), `platform` (`ios`, `android`, `web`), `device_key`, `push_token`, `last_seen_at`, timestamps. Unique on `(user_id, device_key)`.
  - `notification_preferences`: UUID primary key, `user_id` FK cascade (unique), `morning_summary_enabled`, `morning_summary_time` (`08:00`), `activity_reminders_enabled`, `activity_reminder_lead_minutes` (`30`), `checklist_reminders_enabled`, `stay_reminders_enabled`, `quiet_hours_enabled`, `quiet_hours_start` (`22:00`), `quiet_hours_end` (`07:00`), `geofence_arrival_enabled`, `timezone_behavior` (`destination`), timestamps.
  - `reminders`: UUID primary key, `trip_id` FK cascade, `itinerary_item_id` FK cascade nullable, `checklist_id` FK cascade nullable, `type` (`morning_summary`, `activity_reminder`, `departure_checklist`, `stay_checkin`, `stay_checkout`, `custom`), `title`, `body`, `trigger_at_utc`, `timezone`, `delivery_channel` (`local`, `push`), `status` (`scheduled`, `cancelled`, `delivered`, `dismissed`), `dedupe_key` (indexed, unique per trip), `source_version`, timestamps.
  - `visit_events`: UUID primary key, `itinerary_item_id` FK cascade, `user_id` FK cascade, `event_type` (`suggested`, `confirmed`, `revoked`), `method` (`manual`, `geofence`), `detected_at`, `accuracy_m`, timestamps.
  - Applied on dev (`tapittrip`) and test (`tapittrip_test`) PostgreSQL databases with privileged tools container.
- **Backend Application Services & Domain Architecture**:
  - Domain models: `UserDevice`, `NotificationPreference`, `Reminder`, `VisitEvent`.
  - Wired relationships: `devices()` and `notificationPreference()` on `User`; `reminders()` on `Trip`; `reminders()` and `visitEvents()` on `ItineraryItem`.
  - Application Services:
    - `RegisterDeviceService`: Upserts device push tokens and updates `last_seen_at`.
    - `GetNotificationPreferencesService` & `UpdateNotificationPreferencesService`: Manages traveler notification preferences and quiet hours.
    - `GetTripRemindersService`: Fetches active trip reminders.
    - `ScheduleTripRemindersService`: Calculates upcoming reminders for morning summaries, planned activities (with configurable lead time), stay check-in/out deadlines, and departure packing lists; enforces quiet hours; uses deterministic `dedupe_key` hashing (`{trip_id}:{type}:{target_id}:{trigger_utc}`) to prevent duplicates; automatically marks outdated reminders `cancelled` when activities/stays are rescheduled.
    - `RecordVisitEventService`: Records geofence arrival detection or manual check-in; transitions `itinerary_item.status` to `visited` on confirmation or back to `planned` on revocation.
- **Backend API & Route Registration**:
  - `DeviceController`: `POST /api/v1/devices/register`
  - `NotificationPreferenceController`: `GET /api/v1/me/notification-preferences` and `PUT /api/v1/me/notification-preferences`
  - `ReminderController`: `GET /api/v1/trips/{trip}/reminders` and `POST /api/v1/trips/{trip}/reminders/generate`
  - `VisitEventController`: `POST /api/v1/itinerary-items/{item}/visit-events`
  - Centralized JSON responses and strict `TripPolicy` authorization.
  - Updated `docs/api/openapi.yaml` with all new reminder, preference, and visit-event paths and schemas.
- **Mobile Client Architecture & UI**:
  - Models: `NotificationPreference`, `TripReminder`, `VisitEvent` with JSON serialization.
  - `NotificationRepository`: Secure local storage caching (`cached_notification_preferences`, `cached_reminders_$tripId`) with automatic offline fallback.
  - `LocalNotificationService`: Offline scheduling engine with quiet hours verification (overnight and same-day) and secure offline persistence (`scheduled_local_notifications_$tripId`).
  - `GeofenceService`: Haversine proximity detection (250m radius) against upcoming itinerary stops.
  - `NotificationPreferencesPage`: Full preferences management screen (morning summary time picker, departure alert lead-time chips, quiet hours time pickers, checklist/stay alerts, arrival suggestions switch).
  - `NotificationPermissionBanner`: Non-blocking informative banner shown when notification permissions are disabled.
  - `ArrivalSuggestionDialog`: Interactive arrival prompt with place name, address, and estimated distance; confirms arrival via one-tap "Mark Visited" without silently modifying visited state.
  - Registered `/notifications/preferences` route and quick-action icon in `TripItineraryPage`.
- **Automated Verification**:
  - Backend PHPUnit: Added `NotificationTest.php` (6 tests) and `VisitEventTest.php` (4 tests). Full suite passes: 76/76 tests, 446 assertions.
  - Backend Pint: Passed with 0 style issues.
  - Mobile Flutter Tests: Added `notification_test.dart` (7 tests) and `geofence_test.dart` (6 tests). Full suite passes: 83/83 tests.
  - Mobile Flutter Analyzer: 0 issues.
  - Feature document created: `docs/features/notifications-and-geofencing.md`.

### Security and offline considerations

- In strict compliance with `AGENTS.md`, arrival detection **never** silently marks activities as visited; travelers are prompted to confirm arrival explicitly.
- Local notification schedules and user preferences persist in encrypted `FlutterSecureStorage` so offline travel experiences remain functional during flights or disconnected periods.
- Quiet hours suppression prevents untimely disruption to travelers.
- All endpoints enforce trip membership authorization via `TripPolicy`. Sensitive details (booking references, room keys) are never exposed in push notification payloads.

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

## 2026-11-10 — Backend architecture simplification and database-driven reference data (ADR 0003)

### Completed

1. **Simplified Backend Pattern (Features 1–9 Refactored)**:
   - Refactored backend from separated `Domain/{Feature}` and `Application/{Feature}` layers into cohesive `app/Services/{Feature}/`, `app/Models/`, `app/DTOs/{Feature}/`, and `app/Policies/`:
     - **Trips**: `TripService`, `CreateTripData`, `UpdateTripData`, `TodaySummaryResult`, models `Trip`, `TripMember`.
     - **Itinerary**: `ItineraryService`, `PlaceService`, Gemini AI assistant & transit services, models `ItineraryItem`, `TripDay`, `Place`, `VisitEvent`.
     - **Stays**: `StayService`, `CreateStayData`, `UpdateStayData`, `CompareStayTransportData`, model `Stay`.
     - **Expenses**: `ExpenseService`, `CurrencyExchangeRateService`, `LiveExchangeRateProvider`, `FakeExchangeRateProvider`, models `Expense`, `TripBudget`, `ExpenseSplit`, `ExpenseSettlement`.
     - **Checklists**: `ChecklistService`, `CreateChecklistData`, `CreateChecklistItemData`, `UpdateChecklistItemData`, models `Checklist`, `ChecklistItem`.
     - **Journal**: `JournalService`, `CreateJournalEntryData`, `UpdateJournalEntryData`, model `JournalEntry`.
     - **Lounges**: `AirportLoungeService`, `AirportLoungeDirectoryService`, `SearchAirportLoungesData`, models `Airport`, `AirportTerminal`, `AirportLounge`.
     - **Notifications**: `NotificationService`, `RegisterDeviceData`, `UpdateNotificationPreferencesData`, models `Reminder`, `NotificationPreference`, `UserDevice`.
     - **Media**: `MediaService`, `UploadMediaData`, model `MediaAttachment`.
   - Unified flat models in `app/Models/` eliminating verbose cross-domain namespace imports.

2. **Updatable Reference Data Moved to Database**:
   - Added migration `2026_11_10_000000_create_countries_table.php` with `code` (unique), `name`, `currency_code`, `flag_emoji`, `is_zero_decimal`, and `aliases` (`jsonb`).
   - Added model `App\Models\Country` with automated cache invalidation on save/delete.
   - Added `CountrySeeder` and `database/data/countries.json` covering 215 global countries and destination aliases.
   - Refactored `CountryCurrencyResolver` to query the database with `Cache::rememberForever` for sub-millisecond lookups.
   - Added public `GET /api/v1/countries` endpoint with optional `?search=` filter via `CountryController` and `CountryResource`.

3. **Static Constants Extraction**:
   - Extracted 850+ lines of raw lounge catalog constants from `AirportLoungeDirectoryService` into `database/data/airports_catalog.json`.
   - Extracted 160+ lines of starter templates from `ChecklistService` into `database/data/checklist_templates.json`.

4. **Documentation & Architecture Decision**:
   - Authored [ADR 0003](decisions/0003-simplified-backend-architecture-and-dynamic-reference-data.md).
   - Updated `docs/architecture.md`, `docs/features/expenses-and-budgeting.md`, and `docs/api/openapi.yaml`.

### Verification

- Fast & PostgreSQL Test Suite: **129 passed (1875 assertions)** via Sail (`php artisan test`).
- Code Formatting: Laravel Pint clean across 299 files.
- Zero breaking changes to API JSON response contracts or client integrations.

### Next steps

- Refactor Feature 10 (Sync: `SyncService`, `SyncPushData`, `SyncPullData`, `SyncCursor`, `SyncOperation`).
- Refactor Feature 11 (Weather: `WeatherService`).
- Refactor Feature 12 (Identity: `AuthService`, `ProfileService`, `User`).
