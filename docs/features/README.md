# Feature Documentation

Feature documents explain how TapItTrip behavior works across the traveler experience, mobile application, API, persistence, offline sync, security, and operations. They complement `MASTER_PLAN.md`; they do not approve a milestone or replace OpenAPI.

## Feature catalog and direction

| Area | What it does | How it works | Delivery direction | Status |
| --- | --- | --- | --- | --- |
| M0 foundation | Provides buildable mobile/API shells and local infrastructure. | Laravel Sail runs the API against local PostgreSQL/PostGIS and Redis with a tested health check; Flutter mobile shell (`com.tapittrip.app`) is scaffolded with format/analyze/test verification. | Establish reproducible development and documentation gates before product behavior. | Foundation slices implemented; awaiting M0 final acceptance gate |
| M1 authentication and trips | Creates secure sessions and basic trip organization for all starting modes. | Laravel Sanctum personal access tokens authenticate UUID users; policies isolate trip data; trip mode remains an editable preference. | Deliver auth foundation and trip CRUD slices without requiring itinerary data. | Completed (Backend APIs & Flutter mobile integration verified) |
| M2 itinerary, places, and maps | Organizes optional activities and opens trusted directions. | Local-first activities sync to versioned API records; provider place IDs, constrained route optimization, stop-to-stop transit comparisons, and restaurant discovery remain explicit. | Support DIY and guided items together while keeping itinerary optional. | Completed (Backend APIs & Flutter mobile timeline verified) |
| M2b stays and arrival transport | Saves already-booked accommodation and luggage-aware arrival options. | Protected stay details remain available offline; verified route snapshots are ranked deterministically or shown as unknown. | Start with honest maps handoff and provider-backed comparisons; no invented fares or policies. | Completed (Backend Stays, Luggage-Aware Transport & Zero-Typing Waypoint Guidance verified) |
| M3 today dashboard | Shows the most relevant trip/stay/activity information now. | Renders local data first using trip-local time, then refreshes with explicit offline or stale state. | Remain useful for trips with no itinerary activities. | Completed (Backend Today Summary API & Flutter TodayDashboardPage verified) |
| M4 checklists and media | Supports packing and trip-stage tasks with permitted attachments. | Local edits persist and later sync; files use private storage and trip-scoped access. | Prioritize durable offline completion and simple stage templates. | Completed (Checklists, Templates, Collaborative Assignments & Media Attachments verified) |
| M5 notifications and arrival suggestions | Reminds travelers without duplicate or privacy-leaking alerts. | Local scheduling is authoritative offline; remote push complements it; geofence arrival requires confirmation. | Prove device behavior and permission-denied UX before claiming reliability. | Completed (Destination Quiet Hours, Auto-Rescheduling & Geofence Confirmation verified) |
| M6 sync hardening and beta | Makes retries, conflicts, multiple devices, and recovery dependable. | Durable outbox, idempotent push, cursored pull, tombstones, and explicit conflict handling are exercised under failure. | Gate beta on measured reliability, security checks, and restore/rollback readiness. | Completed (Row-Locked Push, Tombstone Conflict Recovery, PII Redaction & Chunked Outbox verified) |
| M7+ advanced features & monetization | Adds imports, discovery, AI, collaboration, translation, budgets, journal, subscriptions/IAP, and safety capabilities. | Each capability uses provider boundaries, consent, validation, freshness, and its own acceptance criteria. | Requires separate approval, ADRs, provider/cost review, and narrow vertical slices. | Future; not approved |

## Per-feature documents

- [`trip-circles.md`](trip-circles.md) — implemented Trip Circles private invite links, Friend Code direct invites, Circle Inbox, two-party ownership transfer, multi-device conflict resolution, stay privacy redaction, organizer announcements, timezone-aware quiet hours, revocation cleanup, managed traveler profiles (`TC-6`), collaborative checklist assignments, and group expense splits / multi-currency settlement (`TC-7`).
- [`api-health.md`](api-health.md) — implemented M0 Laravel liveness contract and security boundary.
- [`identity-and-auth.md`](identity-and-auth.md) — implemented M1 Laravel identity, Sanctum auth, and profile lifecycle.
- [`trip-management.md`](trip-management.md) — implemented M1 Laravel trips, planning modes, and membership policies.
- [`itinerary-and-places.md`](itinerary-and-places.md) — implemented M2 Laravel itinerary items, trip days, places with Google Maps deep linking, constrained route optimization (`POST /api/v1/trips/{trip}/itinerary-items/optimize-route`), stop-to-stop transit mode comparisons, and curated restaurant/food discovery (`GET /api/v1/trips/{trip}/food-suggestions`).
- [`stays-and-luggage-transport.md`](stays-and-luggage-transport.md) — implemented M2b Laravel accommodation, encrypted booking details, and luggage-aware transport comparison.
- [`flights-and-bookings.md`](flights-and-bookings.md) — implemented manual multi-leg flight bookings, protected booking references, versioned API changes, and secure cached schedule lists; live airline data is excluded.
- [`destination-safety-directory.md`](destination-safety-directory.md) — implemented Destination Safety & Official Emergency Directory with curated emergency numbers, offline emergency phrasebook, official portal links with `last_verified_at` dates, and non-fabrication fallback.
- [`translator-and-phrasebook.md`](translator-and-phrasebook.md) — implemented Translator & Offline Phrasebook with curated multi-category destination phrasebooks, phonetic pronunciation guides, full-screen show cards, and consented `TranslationProviderInterface` text translation.
- [`travel-documents-vault.md`](travel-documents-vault.md) — implemented Encrypted Travel Documents Vault with at-rest encryption for `reference_number` and `notes_private`, `owner_only` default visibility, Circle summary sharing with `reference_number` redaction, and offline secure-storage cache.
- [`trip-inbox-and-booking-imports.md`](trip-inbox-and-booking-imports.md) — implemented Trip Inbox & Smart Booking Imports with encrypted confirmation storage at rest, pluggable `BookingExtractorInterface` (Fake & Gemini AI), explainable confidence scores, human review dialog, optimistic concurrency, and materialization into Flights, Stays, or Itinerary items.

Create a document from [`_template.md`](_template.md) when a feature slice begins. Name it after the stable capability, not a ticket number—for example, `trip-creation.md` or `offline-checklist-sync.md`.

- Keep the status and milestone accurate.
- Explain the traveler flow and implementation behavior in plain language.
- Link to OpenAPI operations, ADRs, migrations, and tests instead of copying them.
- Clearly separate implemented behavior, approved next work, and unapproved ideas.
- Update the same document as behavior, limitations, or direction changes.
- Avoid empty placeholder documents for features that have not entered an approved milestone.

