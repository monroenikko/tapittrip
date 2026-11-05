# Feature Documentation

Feature documents explain how TapItTrip behavior works across the traveler experience, mobile application, API, persistence, offline sync, security, and operations. They complement `MASTER_PLAN.md`; they do not approve a milestone or replace OpenAPI.

## Feature catalog and direction

| Area | What it does | How it works | Delivery direction | Status |
| --- | --- | --- | --- | --- |
| M0 foundation | Provides buildable mobile/API shells and local infrastructure. | Laravel Sail runs the API against local PostgreSQL/PostGIS and Redis with a tested health check; Flutter mobile shell (`com.tapittrip.app`) is scaffolded with format/analyze/test verification. | Establish reproducible development and documentation gates before product behavior. | Foundation slices implemented; awaiting M0 final acceptance gate |
| M1 authentication and trips | Creates secure sessions and basic trip organization for all starting modes. | Laravel Sanctum personal access tokens authenticate UUID users; policies isolate trip data; trip mode remains an editable preference. | Deliver auth foundation and trip CRUD slices without requiring itinerary data. | Completed (Backend APIs & Flutter mobile integration verified) |
| M2 itinerary, places, and maps | Organizes optional activities and opens trusted directions. | Local-first activities sync to versioned API records; provider place IDs and attribution remain explicit. | Support DIY and guided items together while keeping itinerary optional. | Slice 1 (Backend Itinerary & Places foundation) implemented |
| M2b stays and arrival transport | Saves already-booked accommodation and luggage-aware arrival options. | Protected stay details remain available offline; verified route snapshots are ranked deterministically or shown as unknown. | Start with honest maps handoff and provider-backed comparisons; no invented fares or policies. | Planned |
| M3 today dashboard | Shows the most relevant trip/stay/activity information now. | Renders local data first using trip-local time, then refreshes with explicit offline or stale state. | Remain useful for trips with no itinerary activities. | Planned |
| M4 checklists and media | Supports packing and trip-stage tasks with permitted attachments. | Local edits persist and later sync; files use private storage and trip-scoped access. | Prioritize durable offline completion and simple stage templates. | Planned |
| M5 notifications and arrival suggestions | Reminds travelers without duplicate or privacy-leaking alerts. | Local scheduling is authoritative offline; remote push complements it; geofence arrival requires confirmation. | Prove device behavior and permission-denied UX before claiming reliability. | Planned |
| M6 sync hardening and beta | Makes retries, conflicts, multiple devices, and recovery dependable. | Durable outbox, idempotent push, cursored pull, tombstones, and explicit conflict handling are exercised under failure. | Gate beta on measured reliability, security checks, and restore/rollback readiness. | Planned |
| M7+ advanced features & monetization | Adds imports, discovery, AI, collaboration, translation, budgets, journal, subscriptions/IAP, and safety capabilities. | Each capability uses provider boundaries, consent, validation, freshness, and its own acceptance criteria. | Requires separate approval, ADRs, provider/cost review, and narrow vertical slices. | Future; not approved |

## Per-feature documents

- [`api-health.md`](api-health.md) — implemented M0 Laravel liveness contract and security boundary.
- [`identity-and-auth.md`](identity-and-auth.md) — implemented M1 Laravel identity, Sanctum auth, and profile lifecycle.
- [`trip-management.md`](trip-management.md) — implemented M1 Laravel trips, planning modes, and membership policies.
- [`itinerary-and-places.md`](itinerary-and-places.md) — implemented M2 Laravel itinerary items, trip days, and places with Google Maps deep linking.

Create a document from [`_template.md`](_template.md) when a feature slice begins. Name it after the stable capability, not a ticket number—for example, `trip-creation.md` or `offline-checklist-sync.md`.

- Keep the status and milestone accurate.
- Explain the traveler flow and implementation behavior in plain language.
- Link to OpenAPI operations, ADRs, migrations, and tests instead of copying them.
- Clearly separate implemented behavior, approved next work, and unapproved ideas.
- Update the same document as behavior, limitations, or direction changes.
- Avoid empty placeholder documents for features that have not entered an approved milestone.

