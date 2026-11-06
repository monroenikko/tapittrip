# TapItTrip — Master Product & Engineering Plan

Status: Planning baseline v1.6 (2026-11-06). Incorporates in-place Trip and Activity editing mechanisms, location/hotel/address suggestions, and clean unselected luggage profile UX. This is a living specification, not authorization to implement all features simultaneously.

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
7. **Forgiving by default (In-place editability)**: Any inputted trip, activity, stay, or date must be easily editable in-place so travelers never get stuck with wrong inputs or typos.
8. **Smart suggestions over typing**: Location, hotel/stay name, and address fields must proactively suggest matching places, airports, hotels, and addresses as the traveler types to minimize manual keyboard entry.

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
- **Trip Circles — Travel Together:** invite friends and family through Messenger/share links or TapItTrip accounts, accept/decline invitations, and use one permission-controlled shared trip workspace. See [section 14C](#14c-trip-circles--travel-together) for phased scope, privacy, and acceptance criteria.
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

### Trip Circles collaboration (planned; see section 14C)
Reuse `trips`, `trip_members`, `itinerary_items`, checklists, expenses, attachments, and sync records; a Circle is the shared experience of an existing trip, not a duplicate trip aggregate. Existing membership records do not imply that invitations or collaborative workflows are implemented.

- `trip_invitations`: trip_id, inviter_id, intended recipient where applicable, proposed role, token hash, expiry, lifecycle status, acceptance/revocation timestamps, and usage/approval policy. Define targeted versus share-link redemption and concurrency rules in an ADR before migrations; never persist raw invite tokens or expose recipient identifiers through public lookup.
- `trip_travelers` (later): trip_id, optional linked member, managing adult, minimal display label, optional traveler category. Managed children/dependents are not authenticated members and gain no account or permission implicitly.
- `trip_activity_logs` (later): trip_id, actor, event type, entity reference, timestamp, and minimized safe change summary. Keep private journal content, booking references, invite tokens, and document contents out of the shared feed.
- Extend existing checklist assignment and expense split models only in their approved slices; resolve managed-traveler participation, personal completion state, and record visibility before defining public contracts.

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
- **Smart suggestions**: Hotel or stay name input proactively suggests verified accommodations; selecting a suggested hotel auto-fills formatted address, coordinates, and contact details. Address field also suggests geocoded addresses as the user types.
- **Clean luggage profile starting state**: Luggage selection chips start completely empty/unselected by default. Travelers are not confused by unwanted pre-selected baggage and explicitly select only the bags/strollers they are traveling with.
- Support hotels, hostels, rentals, and staying with friends/family; multiple sequential or overlapping stays; changing cities; early arrival before check-in; late check-out; and overnight flights. Do not infer a hotel booking from a flight ticket.
- Home dashboard shows the relevant stay for the travel date, with a prominent **Directions to stay** action on arrival day, plus check-in/out reminders and hotel address accessible offline.
- Store booking references encrypted, do not display them on lock-screen notifications, redact them in logs, and ensure location-sharing/guest permissions do not expose private stay addresses by default.
- Check-in/out reminders use the stay's IANA timezone, respect quiet hours and local scheduling limitations, and are cancelled/rescheduled when a stay changes.
- A saved Google Maps deep link may open navigation when online; offline turn-by-turn directions require a separately supported offline maps provider. Do not claim routes, fares or travel times without live/saved provider evidence.

## 14B. Luggage-aware airport-to-stay transportation recommendations
- **Core journey**: user saves an already-booked hotel/rental/family stay -> selects arrival airport/station or links their arrival flight -> supplies party size and a low-friction luggage preset -> taps **How do I get to my stay?** -> sees route alternatives with explanations -> opens supported navigation provider.
- **Nearest Transit Hubs & Airport Auto-Detection**: The app automatically identifies the closest metro/train station (station name, address/exit, walking distance in meters, walking time in minutes) and primary arrival airport (airport name, IATA code, distance in km) based on the stay location. Travelers do not need to search in third-party map apps to discover the nearest station or arrival airport.
- **Zero-typing Arrival Transport Suggestions**: When opening the Arrival Transport comparison sheet, the app automatically pre-fills the arrival origin using the detected city airport or main terminal. Travelers instantly see ranked routes without manually searching or typing terminal names.
- **End-to-End Waypoint Guidance & Last-Mile Walk**: Each ranked route explicitly surfaces the Boarding Point (e.g. Airport Arrival Taxi Stand / Express Train Platform), the Drop-off Station (e.g. Shinjuku Station South Exit), and last-mile walking metrics (e.g. 350m walk to hotel lobby, ~4 min). A dedicated one-tap action launches walking directions from the station straight to the hotel.
- **Low-friction capture**: defaults are optional, never guess baggage from booking. Offer `Travel light`, `1–2 suitcases`, `Heavy luggage / stroller` presets with expandable counts, bag size, children, mobility/accessibility preferences, and walking tolerance. Save per-trip preferences; allow per-stay overrides. Users can skip and still see generic routes.
- **Comparison factors**: travel time, total group cost, transfer count, walking distance, stairs/elevators or step-free confidence, vehicle baggage capacity/policies, arrival hour, public transport service hours, weather only when reliable, check-in timing, and available baggage storage. For children, mention child-seat requirements only where jurisdiction/provider information is verified.
- **Output**: cards for `Most convenient`, `Fastest`, and `Lowest estimated cost` only when route evidence supports those labels; show estimated fare with currency, time, transfers, walking distance, baggage suitability, last refreshed time, and provider attribution. A single option may win multiple categories. Show an explanation such as `fewer transfers and shorter walks for 3 suitcases` without claiming verified step-free access if unknown.
- **Algorithm**: filter impossible or unverified-as-impossible options cautiously; compute normalized weighted scores from available metrics, with luggage and mobility preferences increasing transfer/walking penalties. Do not penalize missing data as if verified poor quality; instead mark confidence as low. Keep deterministic, testable scoring separate from provider adapters and AI-generated explanatory copy.
- **Provider constraints**: Google Maps URLs/SDK support navigation and place context but do not themselves guarantee comprehensive fares, baggage policies, lift accessibility, or real-time transit coverage. Use pluggable transit/routing/transfer providers with regional capability checks, caching, quota budgets, attribution and explicit data freshness. Do not scrape restricted map data or store prohibited tiles/routes.
- **Offline behavior**: saved stay address, trip luggage preferences, previously fetched route summary (clearly stale), and navigation links remain accessible. Do not claim fresh routing, operating schedules or online map directions while offline.
- **Privacy**: do not require detailed personal or disability information; minimize retention of travel profiles, protect booking references, and never expose private stay location in public/shared previews without permission.
- **Tests**: heavy bags prefer fewer transfers where comparable evidence exists; light bag scenario may prefer transit; multiple passengers compare group totals; unknown lift/capacity remains unknown; late-night routes are not assumed operational; missing provider response produces honest fallback; change of stay/flight invalidates stale recommendation; all trip data remains tenant/member authorized.

## 14C. Trip Circles — Travel Together

**Product intent:** Friends, family members, and group travelers can join the organizer's existing trip and stay on the same page through shared plans and explicitly shared updates/logs. One personal TapItTrip account can belong to multiple Circles. Joining is optional; all four planning modes and trips with no itinerary remain supported. A Circle does not require a global friends list or a separate app.

**Delivery status and scope conflict:** This is planned product direction, not implemented functionality or approval to expand M2b. The supplied conversation recommends an MVP launch and no separate paid add-on; the existing roadmap places collaboration in Release 2 / M7+. Preserve that delivery boundary until the owner explicitly decides whether to bring a narrow collaboration slice forward. Launch timing and pricing remain open decisions (section 16). “Core feature” describes product intent, not an approved release date.

### Invitations and shared workspace

1. The organizer opens **Trip Circle** within an existing trip and chooses **Invite travelers**. Flights, stays, and itinerary activities are not prerequisites.
2. **Share invite:** use the native share sheet to send a private invitation link through Messenger when available, or copy it into WhatsApp, Viber, SMS, email, or another app. This does not require Messenger API access or automatic message sending. Provide copy-link fallback and require approved/configured link hosts before implementation.
3. **Invite a TapItTrip account:** send an in-app invitation using an exact, consent-controlled identifier such as a friend code or discoverable username. Email targeting is a candidate only after privacy review; avoid public email search, bulk contact access, account enumeration, and exposing whether an address is registered.
4. The recipient opens the invitation, signs in or creates an account through a supported flow, reviews a minimal safe invitation summary, and explicitly accepts or declines. Opening a link never grants membership. For shareable links, support expiry, revocation, bounded use, and organizer approval; forwarded links must not silently admit unintended travelers.
5. After server-confirmed acceptance (and approval when required), the trip appears in **Shared Trips** within the existing Trips navigation. Members see the same trip records according to their permissions; do not create separate itinerary copies. Show pending, expired, revoked, declined, already-joined, and offline states with clear recovery actions.

### Roles and membership lifecycle

- **Organizer** maps to the existing `owner` role; **Editor** and **Viewer** map to `editor` and `viewer`. Keep public role values compatible; this is a user-facing naming choice.
- The organizer manages invitations and roles, removes members, and can transfer ownership through an explicit confirmed handover. Members can leave; define ownership transfer/account-deletion behavior so no trip is left without an owner.
- Editors modify permitted shared plans; viewers read permitted content. Personal completion/check-off state must be separate from shared itinerary visit status; being a viewer must not grant shared editing rights.
- Parents may later manage minimal child/dependent traveler profiles without requiring child accounts. A managed profile never implies consent to share a child's location, documents, or identity details.
- Enforce accepted membership, role, and object/field visibility server-side on reads, writes, sync, downloads, and future realtime subscriptions. Invitation creation, acceptance, role changes, and ownership transfer require online server confirmation and idempotent handling.

### Visibility and privacy defaults

| Information | Planned default |
| --- | --- |
| Shared itinerary, destinations, and group announcements | Accepted members with permission |
| Shared stay and meeting-point details | Authorized members only; private stay addresses require explicit sharing |
| Booking references, passport/identity documents, personal notes and expenses | Private; separate explicit sharing controls, never automatically inherited from membership |
| Personal journal and photos | Private until the author explicitly shares selected content |
| Shared change/activity feed | Authorized members; safe summaries only |
| Live location | Off; per-person opt-in, limited audience and duration, easy stop |
| Managed child/dependent details | Minimal and restricted to authorized managing adults unless explicitly shared |

Invite previews must not reveal the itinerary, dates, private addresses, member identities, or sensitive documents. Use high-entropy expiring tokens stored as hashes, redact them from logs/analytics, rate-limit creation and redemption, and prevent repeat redemption or cross-trip escalation. Add invitation decline/block/report controls to limit unwanted contact. Membership never grants access to another traveler's full personal account.

### Offline collaboration and notifications

- Cache only permitted trip data and render it locally first. Offline edits use the durable outbox, idempotent operations, versions, and material-conflict handling in section 9. Show last-sync and pending-change states; realtime delivery is optional and must not be required for correctness.
- Recheck current membership on reconnect and reject queued edits after removal or role downgrade. On learning of revoked access, purge affected cached trip content and cancel its scheduled reminders. An offline device may retain previously downloaded data until reconnect; do not promise instant remote erasure or recall of exported copies. Define sensitive-cache retention before implementation.
- Shared schedule/stay changes and organizer announcements can generate per-member notifications with category controls, quiet hours, deduplication, and safe payloads. Store event instants with IANA timezones, display trip-local context and the member's chosen timezone, and reschedule stale reminders. No booking references or private addresses in push payloads.

### Phased delivery candidates

- **Core Trip Circles capability (steps 1–4 below):** begin with viewer-only private link invitations and safe shared access; then add direct account invitations, role management, and collaborative edits. Each is a separate vertical slice with its own gate. Invitation status works in-app; broader change notices follow in step 5 when notification infrastructure is approved.
- **Follow-up slices:** assigned family checklists with clear responsibility/completion; organizer announcements and meeting reminders; managed travelers; shared memories and a minimized activity feed; group expenses with equal, selected-traveler, or custom splits. Reuse integer minor units, explicit currencies, and attributed exchange-rate snapshots; do not invent conversion rates or promise payment settlement.
- **Advanced, separately approved:** time-limited live location sharing, group meeting assistance, and richer realtime collaboration, subject to consent, child privacy, battery, platform, and provider review.

### Step-by-step delivery and acceptance checklist

All items below are **planned and unchecked**. These steps refine section 14C; they do not change milestone order or authorize implementation. Implement one approved vertical slice at a time. Record criterion IDs, test evidence, limitations, and owner acceptance in the milestone log before advancing. Steps 1–4 form the proposed core invitation/shared-trip capability; steps 5–9 are separately approved extensions. Offline and security requirements apply from the first affected slice, not only at the final release gate.

#### Step 0 — Approve scope and contracts

**Outcome:** A small collaboration slice has an agreed place in the roadmap and clear rules before coding.

- [ ] **TC-0.1:** Owner records the target milestone and scope in the milestone log, resolving the M7+ versus pre-beta timing decision. Pricing remains separately decided and does not implicitly gate implementation.
- [ ] **TC-0.2:** An accepted ADR defines targeted versus share-link invitations, exact expiry/use limits, approval rules, discoverability, lifecycle transitions, role permissions, safe invitation summary fields, and ownership/account-deletion behavior.
- [ ] **TC-0.3:** Link host and mobile routing are approved; signed-out, app-installed, and app-not-installed paths have explicit behavior. No domain ownership or deferred deep-link support is assumed.
- [ ] **TC-0.4:** The slice defines sensitive-field visibility, cache retention/revocation, version conflicts, and rollout/migration compatibility against existing trip/member records. Missing registration, sync, or notification prerequisites are identified and scoped explicitly.

**Evidence:** Recorded owner decision, accepted ADR, and reviewed user-flow/permission matrix. Do not add unimplemented endpoints to the committed OpenAPI contract.

#### Step 1 — Invite by private link and join as a viewer

**Depends on:** Step 0. **Outcome:** An organizer can invite one traveler into an existing trip safely, end to end. Viewer-only admission keeps this first slice small.

- [ ] **TC-1.1:** Given an owned trip, the organizer can create, copy, share, inspect status, and revoke a viewer invitation. Nonowners cannot create or revoke invitations, including through direct API requests.
- [ ] **TC-1.2:** Native sharing can hand the link to Messenger when installed/available; otherwise copy-link remains usable. Cancelling the share sheet changes no membership and is not reported as confirmed delivery.
- [ ] **TC-1.3:** A signed-out recipient can authenticate through the supported flow and return to the invitation without exposing its token. An app-not-installed recipient sees the approved fallback; no unsupported automatic continuation is promised.
- [ ] **TC-1.4:** Opening or previewing the link reveals only approved summary fields and grants no trip access. Accepting, plus organizer approval where required, creates one accepted membership; declining grants none. Forwarded links cannot bypass the approved recipient/approval policy.
- [ ] **TC-1.5:** Expired, revoked, malformed, exhausted, and already-used links show safe actionable states. Concurrent/retried acceptance cannot create duplicate memberships or exceed the approved use limit; existing members retain their role.
- [ ] **TC-1.6:** After acceptance, the same trip appears in Shared Trips and permitted existing content is readable. Pending/declined users and other-trip members cannot read it; a viewer cannot mutate shared content. Personal documents, notes, booking details, and unshared stay addresses are excluded from responses and caches.
- [ ] **TC-1.7:** The organizer can remove an accepted member and a nonowner can leave. Subsequent server reads, downloads, and sync requests are denied; reconnection clears affected caches and reminders. Offline devices show freshness honestly, without a promise of immediate remote erasure.
- [ ] **TC-1.8:** Invite creation/redemption requires server confirmation; offline attempts never appear accepted. Previously authorized cached trip reads survive restart, with last-sync state and account-separated storage. Logging out removes access to that account's private cache.
- [ ] **TC-1.9:** Tokens are hashed at rest and absent from logs/analytics; creation/redemption limits and decline/block/report controls follow the approved abuse policy. Public link previews expose no dates, itinerary, private addresses, or member identities.

**Evidence:** API lifecycle, authorization, concurrency, redaction, and rate-limit tests; mobile authentication-return, cache/restart, and error-state tests; Android/iOS share and link checks on the supported device matrix. Unverified platform behavior remains a release blocker for that claimed platform.

#### Step 2 — Invite an existing TapItTrip account

**Depends on:** Step 1. **Outcome:** An organizer can invite a specific account without using an external messenger.

- [ ] **TC-2.1:** The organizer can target the approved exact identifier (friend code or opt-in username); the flow does not expose a searchable email directory or unrelated account details.
- [ ] **TC-2.2:** The intended recipient sees a pending in-app invitation, can accept/decline, and joins the same trip exactly once. Another account cannot redeem a targeted invitation even with its identifier or copied request.
- [ ] **TC-2.3:** Duplicate sends/retries do not create duplicate pending invitations or repeated notices. Revocation, expiry, blocking, rate limits, and already-member states produce the approved safe response without revealing private account existence.
- [ ] **TC-2.4:** Invitation inbox loading, empty, failed, and offline states are actionable. Push permission is optional: the inbox works without push delivery. Declined or revoked invitations cannot later grant access.

**Evidence:** Recipient-isolation and lifecycle API tests; inbox widget/integration tests; privacy and abuse scenarios with synthetic accounts.

#### Step 3 — Manage roles and ownership

**Depends on:** Step 2. **Outcome:** Organizers control who can edit and can hand over the trip safely.

- [ ] **TC-3.1:** Only the organizer can grant/revoke Editor access; Editors cannot invite, change roles, remove members, transfer ownership, or delete the trip. Viewer restrictions hold across every affected endpoint and sync operation.
- [ ] **TC-3.2:** Role changes require online confirmation. Downgrading/removing a member rejects stale queued writes on reconnect without applying them or silently discarding the user's conflict/rejection explanation.
- [ ] **TC-3.3:** Ownership transfer requires explicit confirmation by the parties specified in the ADR and an accepted eligible recipient. Atomic, retry-safe transfer leaves exactly one owner and applies the documented former-owner role.
- [ ] **TC-3.4:** The sole owner cannot leave or delete their account in a way that orphans the trip; the approved transfer-or-trip-deletion path is enforced transactionally. Concurrent removal/transfer requests preserve ownership invariants.

**Evidence:** Role matrix, stale authorization, ownership race, and account-deletion API tests; member-management UI tests. Editor access must not be released before Step 4's offline/conflict checks pass.

#### Step 4 — Collaborate on shared plans reliably

**Depends on:** Step 3. **Outcome:** Authorized editors work on one shared trip without losing offline edits.

- [ ] **TC-4.1:** An editor's authorized change appears for another member after refresh/sync without duplicating the trip or itinerary. Realtime infrastructure is not required for this outcome.
- [ ] **TC-4.2:** An offline edit persists with its outbox operation, survives force-close/restart, and syncs once on reconnect despite retries. The UI distinguishes pending, synced, rejected, and conflicting changes.
- [ ] **TC-4.3:** Two devices editing the same schedule/order or stay record cannot silently overwrite material changes. The approved conflict flow preserves enough information to resolve them and retries the resolution safely.
- [ ] **TC-4.4:** Removal/downgrade between download and sync blocks unauthorized edits and removes inaccessible data on reconnect. New permissions never disclose previously private fields implicitly.
- [ ] **TC-4.5:** One account can switch among at least two shared trips and its own trip without mixing members, records, caches, or outbox operations. All four planning modes and a trip with no itinerary remain usable.

**Evidence:** Two-account/two-device integration scenarios, deterministic conflict tests, offline restart/retry tests, and cross-trip/cache-isolation tests. Steps 1–4 plus the common completion gate define acceptance of the core capability.

#### Step 5 — Announcements and group reminders

**Depends on:** Step 4 and approved notification infrastructure. **Outcome:** Members receive useful, controllable updates.

- [ ] **TC-5.1:** An authorized organizer can post a group announcement; permitted members can read it in-app even if push permission is denied. Changes and retries create no duplicate feed entries or notices.
- [ ] **TC-5.2:** Each member's category preferences, quiet hours, chosen timezone, and trip-local event context are respected; editing/cancelling an event reschedules/cancels its reminders.
- [ ] **TC-5.3:** Removed members receive no new authorized delivery after revocation is known; scheduled local reminders are cleared on reconnect. Push payloads contain no booking references, private addresses, documents, or raw invite tokens.

**Evidence:** Deterministic scheduling/deduplication tests and device checks for denied permissions, timezone changes, offline scheduling, and reconnect.

#### Step 6 — Assign family checklists and manage travelers

**Depends on:** Step 4, approved checklist capability, and a managed-traveler privacy decision. **Outcome:** Families can coordinate responsibilities without creating child accounts.

- [ ] **TC-6.1:** An authorized member assigns a task to an eligible member or managed traveler; responsibility and completion are visible only to permitted members. Reassignment/removal leaves no inaccessible or orphaned task owner.
- [ ] **TC-6.2:** Personal completion actions do not alter group visit status or grant shared editing rights. Offline completion survives restart and resolves simultaneous updates under the approved item-version policy.
- [ ] **TC-6.3:** Authorized adults can create/edit/delete minimal managed-traveler profiles without a child account or mandatory sensitive details. Other members cannot read restricted fields, manage the profile, or enable location/document sharing on its behalf.

**Evidence:** Assignment/permission matrix, managed-profile lifecycle, and offline task tests. Keep this step split into smaller approved checklist and managed-profile slices if either dependency is unavailable.

#### Step 7 — Record and split group expenses

**Depends on:** Step 4 and an approved budget/currency slice. **Outcome:** Members see accurate shared balances without exposing private spending.

- [ ] **TC-7.1:** Authorized users record a payer and equal, selected-traveler, or custom splits. Integer minor-unit shares sum exactly to the expense total, including rounding; invalid totals and participants are rejected.
- [ ] **TC-7.2:** Different currencies remain explicit. Conversion uses an attributed dated rate snapshot or shows unavailable; it never invents a rate or silently changes historical balances.
- [ ] **TC-7.3:** Personal expenses stay private until shared. Retries, offline creation, edits, deletions, and member departure preserve auditable totals under the approved accounting rules; recording balances does not claim money was transferred.

**Evidence:** Split/rounding and currency tests, visibility tests, and offline duplicate/conflict scenarios.

#### Step 8 — Share memories and a safe activity feed

**Depends on:** Step 4 and approved private media/journal infrastructure. **Outcome:** Members share selected memories while personal content stays private.

- [ ] **TC-8.1:** A journal entry/photo is private on creation; the author explicitly selects content and audience before sharing. Unsharing removes server access and cleans permitted caches on reconnect, without promising recall of exported copies.
- [ ] **TC-8.2:** Shared activity summaries show only permitted changes, actors, and timestamps. They contain no raw private notes, documents, booking references, or tokens; retries do not duplicate events.
- [ ] **TC-8.3:** Upload interruption/retry creates no duplicate attachment; download URLs expire and require authorization. Removed members cannot obtain new access URLs or read the feed.

**Evidence:** Media authorization/expiry, feed redaction, consent/unsharing, and interrupted-upload tests.

#### Step 9 — Optional temporary location and meeting assistance

**Depends on:** Step 4 and separate platform/provider, consent, retention, and child-privacy approval. **Outcome:** A consenting traveler can share location temporarily with a chosen audience.

- [ ] **TC-9.1:** Sharing is off by default and starts only after explicit per-person consent, audience selection, duration selection, and platform permission. Denying permission leaves normal trip features usable.
- [ ] **TC-9.2:** Stop, expiry, or member removal ends server-authorized sharing; viewers cannot fetch new positions. Offline/old positions show their timestamp and stale/unavailable state, never a live claim.
- [ ] **TC-9.3:** Location collection stops under the approved lifecycle rules and retained data is deleted on schedule. Managing a child profile cannot bypass the separately approved consent policy.
- [ ] **TC-9.4:** Meeting assistance uses verified provider data or an honest maps handoff; no fabricated ETA, route safety, or guaranteed background tracking. Background/terminated-app limitations are verified on supported real devices and disclosed.

**Evidence:** Consent/audience/expiry/retention tests and real-device permission, offline, background, and battery checks before release.

#### Common completion gate — required for every implemented step

- [ ] **TC-G.1:** Applicable acceptance IDs have passing automated evidence; skipped checks are listed as unverified, not passed. Exercise success, validation, unauthenticated, unauthorized, not-found, conflict, rate-limit, and safe unexpected-error responses where relevant.
- [ ] **TC-G.2:** Relevant Flutter screens cover loading, empty, error, offline, and denied-access states; screen-reader labels, large text, localization, and all applicable trip modes/no-itinerary scenarios pass.
- [ ] **TC-G.3:** Implemented behavior, OpenAPI/examples, migrations/rollout notes, feature documentation, and milestone log agree. No planned endpoint is represented as implemented.
- [ ] **TC-G.4:** Applicable Sail formatter/static analysis/tests and Flutter format/analyze/tests pass, with exact commands/results and platform limitations recorded. Privacy checks cover payloads, caches, logs, notifications, and files.
- [ ] **TC-G.5:** Owner reviews the working slice and accepts its evidence before the next milestone boundary. Any next step outside approved scope receives explicit approval; unchecked extension steps do not block a narrower accepted release.

## 14D. In-Place Editing Mechanisms and Location/Stay Suggestion System (v1.6)

### 1. In-Place Trip Data Editing Mechanism
- **Core Principle**: Travelers must never be locked into mistakes. Changing trip dates, correcting destination typos, or altering planning modes must be frictionless without deleting or recreating the trip.
- **Editable Trip Fields**:
  - `title`: Trip name (e.g., "Tokyo Autumn Adventure").
  - `destination_country`: Target country/region with country picker/autocomplete.
  - `start_date` & `end_date`: Calendar date range pickers. Date shifts preserve all existing activities and recalculate daily buckets.
  - `primary_timezone`: Timezone selector ensuring proper local-time scheduling.
  - `planning_mode`: Switchable between DIY, Already Booked, Guided Tour, and Minimal organization without data loss.
  - `trip_type`: Leisure, business, family, or domestic.
- **Access Points**: "Edit Trip" accessible from trip settings, trip list card context menu, and dashboard header.

### 2. In-Place Activity & Itinerary Item Editing Mechanism
- **Core Principle**: If a traveler inputs the wrong time, title, location, or day for a stop, they can edit it immediately in-place.
- **Editable Activity Fields**:
  - `title`: Activity name (e.g., "Shibuya Sky Observation").
  - `kind`: Category selector (`attraction`, `meal`, `transport`, `hotel`, `custom`).
  - `place`: Name, address, coordinates, and place attribution.
  - `trip_day_id`: Day reassignment (e.g., moving an activity from Day 1 to Day 2).
  - `starts_at_utc` & `ends_at_utc`: Scheduled time.
  - `notes`: Personal notes, tips, and booking codes.
- **Access Points**: Tapping or selecting "Edit Activity" on any `ActivityTimelineCard` or from `NextStopCard` on the Today dashboard opens the pre-populated edit sheet.

### 3. Location, Hotel, and Address Suggestion Mechanisms
- **Activity Location Autocomplete**:
  - Real-time debounced suggestions (300ms) querying `GET /api/v1/places/search?q=...`.
  - Proactively suggests nearby landmarks, attractions, cafes, and stations based on the trip's destination city/country.
  - Selecting a suggestion automatically populates place name, formatted address, and geocoded coordinates.
- **Accommodation & Hotel Suggestions**:
  - When typing a hotel or stay name (e.g., "Hilton", "Cerulean", "Marriott"), the search suggests matching accommodations with verified names and addresses.
  - Reduces manual typing and spelling errors on mobile keyboards.
- **Address Autocomplete**:
  - Dedicated address suggestion field auto-completing street names, districts, and postal codes with maps handoff coordinates.

### 4. Clean Luggage Profile Initial State
- **Zero Pre-Selection Rule**: All luggage category chips (`backpack`, `carry_on`, `checked_bag`, `stroller`, `oversized`, `others`) start completely **empty / unselected** by default.
- **Eliminates Confusion**: Travelers are never confused by pre-checked items they do not carry; they explicitly tap and add only the specific bags they are bringing.

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
10. Trip Circles launch timing: keep Release 2 / M7+ or explicitly approve a narrow pre-beta invitation/shared-trip slice; decide expense-splitting timing separately. Resolve the conversation's proposed no-separate-paid-add-on launch policy alongside monetization. Before implementation, approve invite discovery/privacy, share-link redemption/approval defaults, managed-traveler consent, and ownership handover rules (section 14C).
11. Monetization & Subscriptions: Free trial duration (store-level ~3 days vs server-managed 2 days), auto-renewing monthly vs 1-month single-trip pass (~₱269), exact premium feature boundaries, and IAP gateway (direct store integration vs RevenueCat). Scheduled for implementation in the final pre-release phase (M6/M7+) so core traveler utility slices in M1–M5 are delivered unblocked.

These decisions are not blockers to M0 unless they affect a concrete implementation step.
