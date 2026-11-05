# TapItTrip — Master Product & Engineering Plan

Status: Planning baseline v1.4 (2026-11-03). This is a living specification, not authorization to implement all features simultaneously.

## Product identity and naming

- **Working product name and visual wordmark:** **TapItTrip**.
- **Tagline:** **Your trip. One tap away.**
- **Short positioning:** An all-in-one, offline-first smart travel companion for DIY, organized-tour, leisure, family, group, business, domestic, and international travelers.
- **Naming usage:** Use **TapItTrip** in user-facing copy, product documentation, and the visual wordmark. Keep `travel-companion` as the existing repository directory unless the owner explicitly approves a rename.
- **Brand direction:** clear, approachable, modern, internationally understandable; minimal taps, high contrast, accessible text, localization-ready UI. Do not embed English-only text in imagery or hard-code slogans in widgets.
- **Provisional status:** The name, stylization, tagline, domain, app-store listing, package/bundle identifiers, and trademark clearance have **not** been verified. Treat them as working branding, not an assertion of legal availability. Do not purchase domains, register trademarks, publish store listings, or rename bundle IDs without owner approval.
- **Identifiers:** Keep Android application ID, iOS bundle ID, OAuth redirect domains, and deep-link host configurable; do not assume a TapItTrip domain is owned or valid as a redirect URL.

## 1. Vision and product principles

Build an offline-first, AI-assisted mobile travel companion that reduces repetitive typing and keeps a trip organized before departure, during travel, and after returning home. The primary home screen shows **today's itinerary**, next action, progress, and relevant reminders. Travelers can import tickets and reservations, plan destinations, navigate, translate, track spending, manage documents, collaborate, and capture memories.

Principles:
1. **Low-friction input**: share a link, import a screenshot/PDF, scan, or speak; always review uncertain extracted data.
2. **Offline-first**: saved itineraries, checklists, and scheduled reminders remain useful without connectivity; show explicit offline/stale status.
3. **One source of truth**: itinerary activities connect transport, places, budgets, reminders, and visit status.
4. **Privacy by design**: location history, passport data, imported emails, and documents require purpose limitation and user controls.
5. **Incremental delivery**: working vertical slices with tests; no speculative microservices.
6. **Explain recommendations**: travel times, fares, opening hours, transit, food, and AI suggestions disclose source/freshness/uncertainty.

## 1a. Audience, flexible travel modes, and inclusive onboarding (v1.4)

**Product promise:** TapItTrip is for DIY travelers **and travelers in general**, including those who do not want to plan an itinerary. No user must create a detailed itinerary to access essential travel information.

- **Plan my own trip (DIY):** Build activities, routes, budgets and checklists from scratch, optionally assisted by AI.
- **I already booked my trip:** Import or manually add existing flights, accommodation, and schedules; display a useful home dashboard immediately.
- **I'm joining a guided/package tour:** Import an operator-provided itinerary, meeting points, pickup times, hotel details and group instructions; allow personal free-time activities without overwriting the tour schedule. Do not assume tour operator integrations exist.
- **Just organize my travel:** Minimal dashboard for flight, stay, documents, transport, checklists and reminders, with itinerary creation optional.
- **Mixed-mode trip:** A traveler can combine guided days and independent days; modes are editable trip-level starting preferences, **not** immutable user roles or separate account types.

**UX acceptance principles:** Ask at most for essential information to create a trip; offer "skip for now" for optional inputs. Prefer share-sheet, scanned/uploaded confirmations, pasted links and suggested defaults over repetitive forms. Never request the same confirmed information twice. Keep the primary navigation small (Home, Trips, Explore, Translate, Profile as a candidate IA), with stage-aware home actions for pre-departure, arrival, in-trip, return and post-trip. Offer direct access to flight, stay and emergency information even without an itinerary. Make important tasks reachable without deep navigation; avoid notification overload. Do not assume all travelers are international, have flights, have a hotel, or have internet access.

**International readiness:** Locale-aware formatting; translated/local-script addresses; destination and origin time zones; multiple currencies; international phone numbers; accessibility and large text; family, mobility and luggage needs; offline saved trip essentials. Localize UI separately from destination-language translation. Official travel requirements must link to authoritative sources and clearly disclose freshness and limitations.

**Data implications:** Add an optional `planning_mode` enum to `trips` (`diy`, `existing`, `guided`, `simple`, with mixed-mode represented by activity source/type), plus optional `source_type` on itinerary activities (`manual`, `imported`, `tour`, `suggested`) and tour meeting point details when implemented. Do not force an itinerary-day record for trips with only a flight or stay. Preserve user control over imported data and avoid unnecessary personal profiling.

**Tests:** Create a trip in each mode; switch modes without data loss; import an existing booking without making an itinerary; add a personal activity alongside a guided-tour schedule; view an arrival home card when no activities exist; confirm domestic/non-flight journeys remain usable; validate locale, timezone, accessibility, and offline essentials.

## 2. Users and journeys

Personas: independent/DIY traveler, traveler with an already-booked trip, guided or package-tour participant, solo traveler, family with children, group organizer/member, business traveler, domestic traveler, first-time international traveler, and frequent traveler. A person may use multiple modes on the same trip.

Journeys:
- **Pre-trip**: sign in; create trip with origin, destinations, dates and timezone; import booking; confirm extracted flight and accommodation details; create arrival/departure and packing checklists; save map area where licensed; schedule reminders.
- **During trip**: home opens to today's activities in destination-local time; view next stop or current accommodation; navigate airport-to-stay; choose train/bus/car/walking; get Google Maps directions; receive departure/arrival suggestions; mark visited; find nearby food; use translator; log expense; share changes.
- **Return**: departure/home arrival checklists, luggage recheck, trip recap, travel journal and expense settlement.
- **Offline**: access previously synced trip, modify checklists and itinerary, view saved attachments, receive supported local notifications, and sync queued changes when connectivity returns.

## 3. Scope and release gates

### Release 0 — Foundation / technical spikes
- Flutter app shell, Laravel modular monolith, PostgreSQL/PostGIS, Drift, local dev, CI.
- OAuth provider setup and callback flow spike (Google, Facebook, Apple as applicable).
- Real-device geofence/background notification feasibility spike (Android/iOS).
- Provider proof-of-concepts for maps/transit/offline map licensing and offline translation language coverage.
- Define security, observability, API budget caps and consent UX.

### MVP — First usable trip companion
- Social login, profile, session management, account deletion.
- Create/edit/archive trips, date ranges, trip timezone, itinerary days and activities.
- Destination search and map pin, place photos with permitted attribution, open directions in Google Maps.
- Accommodation/stay management: add one or more **already booked** stays (manual entry, place search, address or shared maps link), dates, check-in/out local times, address and map pin, contact details, booking reference (protected), stay-to-itinerary links, airport-to-stay directions, and offline stay card. Capture party and luggage profile to personalize arrival transport suggestions.
- Today's dashboard: active trip, date, next activity, progress, action shortcuts, offline indicator.
- Morning itinerary summary, activity reminders and local notification rescheduling; optional remote pushes.
- Manual mark visited, opt-in arrival suggestion where supported.
- Packing checklist with categories, quantities, photos, packed/unpacked; departure/arrival stage checklists for one-way/round-trip/domestic journeys.
- Local read/write and sync for core trip/checklist data, with conflict UI for material conflicts.
- Basic accessibility, localization readiness, permission prompts, analytics opt-in where applicable.

### Release 1 — Smart imports and discovery
- Trip Inbox: share sheet, upload image/PDF, paste link; parse flight/hotel/accommodation confirmations; review extracted fields before save. Include accommodation booking imports, duplicates and changes/cancellations.
- Flights and flight segments with local-time + timezone fields, airport codes, status freshness and reminder links.
- Transit mode comparisons and restaurant discovery where provider coverage supports it; route optimization with constraints.
- Trip documents with encrypted storage and access controls; per-document retention and deletion.
- AI itinerary drafting and adjustments with explicit user approval; AI-generated content is advisory.

### Release 2 — Collaboration and travel utilities
- Invite members, roles, shared trip editing, sync conflict handling, collaborative checklists.
- Budgets, multi-currency expenses, exchange rate snapshots, group expense splits.
- Travel journal, memories, saved photos and optional trip recap.
- Safety information, user-controlled location sharing, official source links and expiry dates.
- Voice, camera and conversation translation; offline language packs only where tested and licensed.
- Optional Gmail import with separate OAuth scopes and explicit opt-in; never assume social login grants email access.

### Later / experimental
- Live flight alerts via licensed provider; proactive traffic/weather rerouting; advanced personalized discovery; home-screen widgets; reusable templates; travel achievements.
- Subscriptions and travel passes: Free trial (2-3 days), monthly subscription or 1-month single-trip pass (target ~₱269/month), store IAP integration (Apple In-App Purchase / Google Play Billing). Core offline essentials (saved trips, stay details, tickets) remain accessible if subscription expires; deferred to late pre-release phase.

**Not in MVP**: automatic visa eligibility determination, guarantees of immigration compliance, unconsented email scanning, guaranteed background geofence triggers, unrestricted offline Google Maps tile caching, live transit/flight claims without verified provider.

## 4. Recommended stack and versions

- **Mobile**: Flutter (current stable at implementation time), Dart, Riverpod, GoRouter, Dio, Drift/SQLite, secure storage, platform notification APIs, platform location/geofencing integrations.
- **Backend**: Laravel 12 (or currently supported version approved at kickoff), PHP 8.3+ subject to framework compatibility, REST JSON API, Sanctum for API tokens/session architecture as appropriate, Laravel Socialite/provider adapters for OAuth, Policies, Form Requests, Jobs, Events.
- **Data**: PostgreSQL 17+ with PostGIS, Redis for cache/queues, S3-compatible private object storage.
- **Async**: Laravel queues and Horizon on a worker-capable environment; scheduler for due jobs and reconciliation.
- **Realtime**: Laravel Reverb later, not required for MVP.
- **Maps**: Google Maps SDK + Places + Maps URLs; evaluate Routes API and regional transit provider. For offline map tiles, select a separately licensed offline-capable SDK.
- **AI**: provider-agnostic service interfaces; cloud multimodal model for ticket extraction/itinerary drafting; on-device OCR/translation where available. Validate language support, model download sizes and offline performance.
- **Push**: Firebase Cloud Messaging/APNs for online remote pushes; platform local notifications for offline scheduled reminders.
- **Quality/ops**: PHPUnit/Pest, Flutter tests, static analysis (PHPStan/Larastan, Dart analyzer), GitHub Actions, Sentry, structured logs, OpenAPI, Docker Compose for local services.

Provider APIs, SDK terms, prices, platform permissions and store policies must be rechecked before implementation.

## 5. Repository layout

```text
travel-companion/
  AGENTS.md
  MASTER_PLAN.md
  docs/
    architecture.md
    decisions/ (ADRs)
    api/openapi.yaml
    privacy-and-threat-model.md
    provider-evaluation.md
    milestone-log.md
  client/
    lib/
      app/ (router, theme, bootstrap)
      core/ (network, auth, storage, sync, permissions, notifications)
      features/
        auth/ trips/ itinerary/ today/ places/ maps/ stays/ checklists/
        flights/ imports/ reminders/ translation/ budget/ collaboration/
        documents/ journal/ safety/
      shared/
    test/
    integration_test/
  api/
    app/
      Domain/ (Trips, Itinerary, Places, Checklists, Reminders, ...)
      Http/Controllers/Api/V1/
      Jobs/ Policies/ Providers/ Support/
    database/migrations/
    routes/api.php
    tests/Feature/ tests/Unit/
  api/compose.yaml                # Sail local stack
  .local/                         # ignored local provisioning credentials
  scripts/
```

Prefer feature-first modules with clear domain boundaries. Avoid unnecessary abstraction layers; introduce provider interfaces at external boundaries.

## 6. Domain model and database blueprint

All mutable aggregate records: UUID primary keys, `created_at`, `updated_at`, optional `deleted_at`, `version` integer for sync, and relevant audit metadata. Use foreign keys, unique constraints, indexed owner/member lookups, and explicit UTC storage with IANA timezone identifiers. Store money as minor units plus ISO 4217 currency; avoid floating-point amounts.

### Identity
- `users`: id, display_name, email nullable, avatar_url nullable, locale, home_timezone, deleted_at.
- `social_accounts`: user_id, provider, provider_subject, email_at_link_time; unique(provider, provider_subject); encrypt credentials if stored; prefer not storing access tokens when unnecessary.
- `user_devices`: user_id, platform, device_key, push_token encrypted/rotatable, last_seen_at.
- `notification_preferences`: user_id, morning_summary_enabled, local_time, quiet_hours, category toggles, timezone_behavior.

### Trips and activities
- `trips`: owner_id, title, start_date, end_date, primary_timezone, origin_country, destination_country, trip_type, status.
- `trip_members`: trip_id, user_id, role(owner/editor/viewer), invitation_status; unique(trip_id,user_id).
- `trip_days`: trip_id, local_date, notes; unique(trip_id,local_date).
- `places`: provider, provider_place_id, name, formatted_address, country_code, lat/lng, optional PostGIS geography, photo_reference, attribution, last_refreshed_at.
- `itinerary_items`: trip_id, trip_day_id, place_id nullable, kind(attraction/meal/transport/flight/hotel/custom), title, notes, starts_at_utc nullable, ends_at_utc nullable, timezone, sort_order, status(planned/visited/skipped), version.
- `visit_events`: itinerary_item_id, user_id, event_type(suggested/confirmed/revoked), detected_at, accuracy_m nullable, method(manual/geofence), optional coarse location with retention policy.
- `stays`: trip_id, place_id nullable, name, accommodation_type(hotel/hostel/rental/family/other), address_text, latitude/longitude nullable, contact_phone nullable, contact_url nullable, check_in_at_utc nullable, check_out_at_utc nullable, check_in_local_date, check_out_local_date, timezone, booking_reference_encrypted nullable, booking_status(planned/confirmed/cancelled/completed), source_import_id nullable, notes_private_encrypted nullable, version. A trip can have multiple stays; do not assume all stays are in the same city or timezone.
- `stay_guests` (optional later): stay_id, trip_member_id, access_scope; do not store passport numbers or identity documents in this table.
- `itinerary_items`: for kind=hotel, optional stay_id FK (or a typed relation chosen in ADR) to connect check-in/check-out activities without duplicating reservation data.
- `transport_segments`: from_item_id, to_item_id, mode, provider_ref, duration_seconds nullable, estimated_cost_minor nullable, currency nullable, retrieved_at.
- `trip_travel_profiles`: trip_id, traveler_count, adult_count, child_count, infant_count, checked_bag_count, carry_on_count, oversized_bag_count, stroller_count, mobility_needs_private_encrypted nullable, walking_tolerance_meters nullable, budget_preference nullable, comfort_preference nullable, version. Treat accessibility and child details as optional, private, editable trip-scoped preferences; do not infer sensitive conditions.
- `stay_transport_preferences`: stay_id, arrival_origin_type(airport/station/custom), arrival_origin_place_id nullable, arrival_flight_id nullable, preferred_mode nullable, luggage_profile_override_json nullable, arrival_at_utc nullable, version.
- `transport_option_snapshots`: trip_id, stay_id, origin_place_id nullable, provider, mode, duration_seconds nullable, walking_meters nullable, transfer_count nullable, fare_minor nullable, currency nullable, luggage_policy_summary nullable, step_free_status(verified/unknown/not_available), fetched_at, expires_at nullable, source_url nullable. Snapshots are advisory and can expire; do not treat them as booked transport.

### Bookings, packing, documents
- `booking_imports`: trip_id, user_id, source(upload/share/email/link), file_id nullable, extraction_status, extracted_json encrypted, confidence_json, reviewed_at, error_code.
- `flights`: trip_id, airline, booking_reference encrypted nullable, source_import_id nullable.
- `flight_segments`: flight_id, flight_number, origin_airport, destination_airport, scheduled_departure_utc, scheduled_arrival_utc, origin_timezone, destination_timezone, terminal/gate nullable, status_updated_at nullable.
- `checklists`: trip_id, type(packing/outbound_departure/destination_arrival/return_departure/home_arrival/custom), title, stage_order.
- `checklist_items`: checklist_id, title, description, quantity, category, bag_label nullable, is_done, completed_at, assigned_to nullable, sort_order.
- `attachments`: owner_id, trip_id, attachable_type/id, object_key, mime_type, byte_size, encryption_metadata, privacy_class, retention_until nullable.
- `travel_documents`: trip_id, attachment_id, document_type, display_name, expires_on nullable, access_policy.

### Expenses, reminders, journal, sync
- `trip_budgets`: trip_id, category, amount_minor, currency.
- `expenses`: trip_id, paid_by, category, amount_minor, currency, rate_snapshot nullable, occurred_at, note.
- `expense_splits`: expense_id, user_id, owed_minor, currency.
- `reminders`: trip_id, itinerary_item_id nullable, type, trigger_at_utc, timezone, delivery_channel, status, dedupe_key, source_version.
- `notification_deliveries`: reminder_id, device_id nullable, channel, attempted_at, result, provider_message_id nullable; unique appropriate dedupe key.
- `user_notifications`: user_id, type, payload_json, read_at.
- `journal_entries`: trip_id, user_id, itinerary_item_id nullable, text, visited_at nullable.
- `sync_operations`: operation_id UUID unique, user_id, device_id, entity_type, entity_id, operation_type, payload, base_version, result, processed_at.
- `sync_cursors`: user_id, device_id, trip_id, last_server_sequence.

**Design decisions before migrations**: choose aggregate boundaries, version conflict semantics, soft-delete tombstone retention, document encryption key management, attachment upload flows, and audit log minimization.

## 7. API contract outline (`/api/v1`)

Use JSON, predictable error envelopes, pagination, idempotency keys for writes, policy authorization, validation, API versioning and OpenAPI docs.

```text
POST   /auth/{provider}/exchange        # validated provider token/code exchange
GET    /me
DELETE /me                           # account deletion workflow
GET    /trips
POST   /trips
GET    /trips/{trip}
PATCH  /trips/{trip}
GET    /trips/{trip}/days
POST   /trips/{trip}/itinerary-items
PATCH  /itinerary-items/{item}
POST   /itinerary-items/{item}/visit-events
GET    /trips/{trip}/today?date=YYYY-MM-DD
GET    /places/search?q=...
GET    /places/{place}
GET    /trips/{trip}/stays
POST   /trips/{trip}/stays
GET    /stays/{stay}
PATCH  /stays/{stay}
DELETE /stays/{stay}
GET    /trips/{trip}/checklists
POST   /trips/{trip}/checklists
PATCH  /checklist-items/{item}
POST   /attachments/upload-intent
POST   /attachments/complete
GET    /trips/{trip}/reminders
PUT    /me/notification-preferences
POST   /devices/register
POST   /sync/push
GET    /sync/pull?cursor=...

# Release 1+
POST   /trips/{trip}/imports
POST   /imports/{import}/confirm
GET    /trips/{trip}/flights
GET    /trips/{trip}/transport-options
GET    /trips/{trip}/travel-profile
PUT    /trips/{trip}/travel-profile
GET    /stays/{stay}/arrival-transport-options
PUT    /stays/{stay}/transport-preferences
GET    /trips/{trip}/food-suggestions
POST   /trips/{trip}/ai-itinerary-drafts
POST   /trips/{trip}/members/invite
GET    /trips/{trip}/expenses
```

Auth implementation must validate OAuth issuer/audience/nonce or PKCE as relevant, prevent account takeover during social account linking, and support provider revocation.

## 8. Today's dashboard and notification rules

Dashboard priority: active trip selector; local date and day index; current/next accommodation card with directions and check-in/out status; next upcoming item; chronological activities; completion progress; route CTA; packing/departure alerts; import prompts; offline/stale badge; quick translator. Handle no active trip, multiple trips, no itinerary, timezone change, and overnight activities.

Notification types: daily summary, next activity, leave-soon (only with fresh trustworthy route estimate), geofence arrival suggestion, flight prep, departure/arrival checklist, packing reminder, accommodation check-in/check-out, booking update (verified feed only), collaboration changes.

- User opts in per category and controls summary time/quiet hours.
- Local notification scheduling is authoritative for offline reminders; remote push complements it and must not duplicate it.
- Use `dedupe_key`, source version, scheduled time and device to prevent repeats.
- On itinerary edits or timezone changes, cancel and reschedule affected local notifications.
- Respect OS notification limits, exact-alarm restrictions, battery policies and disabled permissions; never guarantee exact delivery.
- Geofence arrival only suggests marking visited; confirm explicitly. Monitor only relevant upcoming stops and respect OS geofence limits.
- Home screen always renders from local database first, then refreshes from server.

## 9. Offline sync contract

Introduce this contract with the first offline-capable write slice, including any M1 trip creation that works offline, and no later than M2b. M6 hardens the existing mechanism; it does not postpone outbox durability, idempotency, versions, or conflict handling until beta.

1. Persist user mutations transactionally to Drift and an outbox (`operation_id`, entity, base_version, timestamp).
2. Display optimistic local state and sync status.
3. On connectivity, authenticated foreground/resumable sync pushes idempotent operations; server returns accepted/conflict/rejected.
4. Pull changes by monotonic server cursor; include deletion tombstones; apply transactionally.
5. Conflict policy: checklists can use item-level versioning; shared itinerary time/order changes require conflict UI or deterministic domain rules. Do not silently overwrite important edits.
6. Attachments use separate resumable upload intents; queue metadata and upload only when network and user settings allow.
7. Sync should tolerate retries, app termination, partial batches, token expiry, and multiple devices.
8. Test clock drift, timezone shifts, reconnect, duplicate operations, and simultaneous edits.

## 10. Integrations and reliability

- **Maps/Places**: persist provider IDs, coordinates, photo attribution and permitted references; don't assume permanent photo caching rights. Deep link to Google Maps for directions.
- **Transit**: coverage varies by country and API; compare modes only when data exists. Present source, fetched time, and uncertainty.
- **Food**: place search, budget/dietary filters, freshness of hours; never claim restaurant availability without booking integration.
- **Flights**: import ticket's scheduled details; distinguish from live gate/delay data. No live alerts until licensed feed integrated.
- **Ticket OCR/AI**: antivirus/file validation, OCR, schema-constrained extraction, confidence, field-level review, never invent missing booking details.
- **Translation**: text/voice/camera flows; on-device pack download and coverage matrix; fallback to cloud only with user consent and network.
- **Official requirements**: link to current government/airline sources, show last-verified date; no definitive visa or immigration eligibility claims.
- **AI**: protect PII, redact where possible, schema validate output, show citations/source freshness where applicable, allow edits before saving.

## 11. Security, privacy, accessibility

- TLS, rate limiting, RBAC/Policies on every trip-scoped endpoint, least-privilege OAuth scopes, secure token storage and refresh strategy.
- Encrypt private documents at rest and in transit; short-lived signed URLs, malware scanning, no public buckets, encrypted backups and key rotation strategy.
- Never store passport images, precise movement history, or full email content by default. Obtain explicit consent and allow deletion/export.
- Avoid location collection when not necessary; geofence on device where possible; permission explanation and opt-out.
- Separate email-import consent from login; Google restricted/sensitive scopes may trigger verification requirements.
- Security review for upload parsing, SSRF in URL imports, malicious PDFs, prompt injection in imported text, IDOR, OAuth account linking, and notification payload PII.
- Accessibility: scalable text, screen readers, contrast, large touch targets, localization, 12/24-hour formats, IANA timezones and currencies.
- Publish privacy policy, retention schedule, consent controls and account deletion process before beta.

## 12. Nonfunctional goals (initial targets; measure in beta)

- Cached home dashboard interactive in <2 seconds on representative mid-range devices.
- Offline core reads/writes without network; queued writes survive force close and restart.
- API p95 <500ms for common CRUD excluding third-party requests under defined test load.
- Crash-free sessions >=99.5% during beta (aspirational).
- Idempotent retries and no duplicate reminder deliveries in deterministic tests.
- Monitor API costs per active user, external call quotas, storage growth, and background battery use.
- Daily backups with tested restore procedures; define RPO/RTO before production.

## 13. Testing strategy

- Backend: unit tests for domain rules; feature tests for auth, policy isolation, validation, CRUD, sync, and notifications; provider contract tests with mocks.
- Flutter: widget tests for today dashboard, itinerary, checklist, offline banners; repository tests with in-memory DB; integration tests for sign-in, offline edits, reconnect and deep links.
- Device matrix: current Android and iOS versions, low-memory Android, notification permission denied, location permission approximate/denied, battery saver, airplane mode, timezone change, app terminated.
- Security: unauthorized cross-trip access, malformed imports, upload type spoofing, signed URL expiry, provider token misuse, prompt-injection tests.
- Release gate: lint, tests, migrations, documentation, manual QA checklist, and product acceptance criteria pass.

## 14. Milestones and acceptance criteria

**Cross-cutting v1.4 release gate:** Each milestone must support the relevant DIY, already-booked, guided, and simple travel journeys without requiring unnecessary itinerary entry. Review navigation depth, optional fields, localization, accessibility, and empty states. Implement the mode selector as part of the earliest trip-creation milestone, not as a new standalone service.

### M0: Repo and infrastructure
- Monorepo structure, Docker Compose Postgres/PostGIS+Redis, Laravel health endpoint, Flutter shell, CI lint/test jobs, `.env.example`, README.
- **Accept**: fresh checkout boots locally with documented commands; no secrets committed; CI green.

### M1: Auth and trip CRUD
- OAuth flows (provider config behind flags), session handling, user profile, trip create/list/edit, policy enforcement.
- **Accept**: authenticated user can create trip; another user cannot read/edit it; logout/session expiry handled; auth tests pass.

### M2: Itinerary, places and maps
- Day/activity CRUD, place lookup, location pin, Google Maps deep link, sort order, local cache.
- **Accept**: create three stops, reorder, reopen offline, and open directions when online; attribution displayed.

### M2b: Accommodation and stays (MVP, after M2 and before M3)
- Stay CRUD for multiple stays per trip, address/place pin and Google Maps directions, check-in/out times in stay-local timezone, protected booking details, optional check-in/check-out itinerary activities, offline read/write and sync.
- Airport-to-stay navigation CTA using a maps deep link; capture traveler count and luggage (backpack, carry-ons, checked bags, oversized items, stroller) via quick presets and optional details. Show current stay, upcoming stay, and no-stay states.
- Build an MVP **explainable transport comparison UI** using provider-backed route options when configured, or clearly labeled unavailable states and maps handoff otherwise. Rank convenience/fastest/cheapest only when sufficient verified data exists. Do not invent duration, fare, elevator access or vehicle luggage capacity.
- **Accept**: add two already-booked stays in different cities without booking through our app, link to trip days, view details offline, launch maps directions, set a heavy-luggage profile, display a clear luggage-aware transport comparison with source/freshness or honest unknown states, change/cancel a stay without orphaning itinerary items, enforce membership permissions, and correctly display local check-in/out times.

### M3: Today's home dashboard
- Active trip, trip-local date, current/next stay and directions, next activity, progress, empty states, offline status, quick actions.
- **Accept**: correct for multiple timezones, overnight activities, completed items, no-trip state; widget tests.

### M4: Checklists and media
- Packing items with photo attachments, trip-stage checklist templates, round-trip/one-way logic, offline edits.
- **Accept**: create checklist, attach permitted photo, mark packed offline, sync later; access restricted to trip members.

### M5: Notifications and geofencing
- Preferences, local morning summary/activity reminder, rescheduling, push device registration, arrival suggestion proof.
- **Accept**: notification scheduling survives supported offline scenario; edit cancels old reminder; no duplicate notifications; permission-denied UX.

### M6: Sync hardening and MVP beta
- Outbox, cursors, idempotency, conflict handling, telemetry, security checks, beta packaging.
- **Accept**: offline multi-edit/reconnect, multi-device concurrent change, app restart and retry test matrix pass.

### M7+: Smart import (including accommodation confirmations), discovery, AI, collaboration, translation, budget, journal, safety
- Each requires its own ADR, provider cost/terms review, acceptance criteria, tests and explicit approval before coding.

## 14A. Accommodation/stay behavior and privacy
- Offer **Add Stay** on trip creation and after flight import; it is optional and never blocks trip creation.
- Low-friction entry: manual address/name or place search in MVP; share-sheet, screenshot/PDF and authorized email parsing in Release 1. Imported fields must be user-reviewed before saving.
- Support hotels, hostels, rentals, and staying with friends/family; multiple sequential or overlapping stays; changing cities; early arrival before check-in; late check-out; and overnight flights. Do not infer a hotel booking from a flight ticket.
- Home dashboard shows the relevant stay for the travel date, with a prominent **Directions to stay** action on arrival day, plus check-in/out reminders and hotel address accessible offline.
- Store booking references encrypted, do not display them on lock-screen notifications, redact them in logs, and ensure location-sharing/guest permissions do not expose private stay addresses by default.
- Check-in/out reminders use the stay's IANA timezone, respect quiet hours and local scheduling limitations, and are cancelled/rescheduled when a stay changes.
- A saved Google Maps deep link may open navigation when online; offline turn-by-turn directions require a separately supported offline maps provider. Do not claim routes, fares or travel times without live/saved provider evidence.

## 14B. Luggage-aware airport-to-stay transportation recommendations
- **Core journey**: user saves an already-booked hotel/rental/family stay -> selects arrival airport/station or links their arrival flight -> supplies party size and a low-friction luggage preset -> taps **How do I get to my stay?** -> sees route alternatives with explanations -> opens supported navigation provider.
- **Low-friction capture**: defaults are optional, never guess baggage from booking. Offer `Travel light`, `1–2 suitcases`, `Heavy luggage / stroller` presets with expandable counts, bag size, children, mobility/accessibility preferences, and walking tolerance. Save per-trip preferences; allow per-stay overrides. Users can skip and still see generic routes.
- **Comparison factors**: travel time, total group cost, transfer count, walking distance, stairs/elevators or step-free confidence, vehicle baggage capacity/policies, arrival hour, public transport service hours, weather only when reliable, check-in timing, and available baggage storage. For children, mention child-seat requirements only where jurisdiction/provider information is verified.
- **Output**: cards for `Most convenient`, `Fastest`, and `Lowest estimated cost` only when route evidence supports those labels; show estimated fare with currency, time, transfers, walking distance, baggage suitability, last refreshed time, and provider attribution. A single option may win multiple categories. Show an explanation such as `fewer transfers and shorter walks for 3 suitcases` without claiming verified step-free access if unknown.
- **Algorithm**: filter impossible or unverified-as-impossible options cautiously; compute normalized weighted scores from available metrics, with luggage and mobility preferences increasing transfer/walking penalties. Do not penalize missing data as if verified poor quality; instead mark confidence as low. Keep deterministic, testable scoring separate from provider adapters and AI-generated explanatory copy.
- **Provider constraints**: Google Maps URLs/SDK support navigation and place context but do not themselves guarantee comprehensive fares, baggage policies, lift accessibility, or real-time transit coverage. Use pluggable transit/routing/transfer providers with regional capability checks, caching, quota budgets, attribution and explicit data freshness. Do not scrape restricted map data or store prohibited tiles/routes.
- **Offline behavior**: saved stay address, trip luggage preferences, previously fetched route summary (clearly stale), and navigation links remain accessible. Do not claim fresh routing, operating schedules or online map directions while offline.
- **Privacy**: do not require detailed personal or disability information; minimize retention of travel profiles, protect booking references, and never expose private stay location in public/shared previews without permission.
- **Tests**: heavy bags prefer fewer transfers where comparable evidence exists; light bag scenario may prefer transit; multiple passengers compare group totals; unknown lift/capacity remains unknown; late-night routes are not assumed operational; missing provider response produces honest fallback; change of stay/flight invalidates stale recommendation; all trip data remains tenant/member authorized.

## 15. Work process for Codex

- Read `AGENTS.md` and this file before editing.
- Start with M0. Implement **one vertical slice at a time**; do not build later milestones without user approval.
- For each slice: inspect repo -> short plan -> tests -> implementation -> run checks -> update docs/milestone-log -> report files changed and blockers.
- Ask before changing stack, adding paid providers, requiring credentials, or making destructive schema changes.
- Prefer working mock adapters when provider credentials are unavailable; label mocks clearly.
- Never invent provider responses, API keys, actual flight schedules, fares, restaurant availability or location data.

## 16. Open decisions for product owner

1. Confirm TapItTrip brand clearance, app-store/domain availability, final package IDs, and supported launch markets/languages.
2. Solo developer vs team and hours/week.
3. MVP Android-first or simultaneous iOS/Android.
4. Initial map/places/AI budget ceilings and hosting provider.
5. Whether offline map tiles are MVP or later; supported regions.
6. Initial supported translation language pairs.
7. Geofencing permissions and privacy defaults.
8. Email integration launch scope and provider approval requirements.
9. Data retention, regional residency and deletion policy.
10. Whether collaboration and expense splitting ship before public beta.
11. Monetization & Subscriptions: Free trial duration (store-level ~3 days vs server-managed 2 days), auto-renewing monthly vs 1-month single-trip pass (~₱269), exact premium feature boundaries, and IAP gateway (direct store integration vs RevenueCat). Scheduled for implementation in the final pre-release phase (M6/M7+) so core traveler utility slices in M1–M5 are delivered unblocked.

These decisions are not blockers to M0 unless they affect a concrete implementation step.
