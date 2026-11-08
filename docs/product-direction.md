# TapItTrip Product and Engineering Direction

`MASTER_PLAN.md` remains the complete product and architecture source of truth. This page is the short direction map used when choosing the next slice.

## Product direction

TapItTrip should become useful before a traveler builds a detailed itinerary. The first durable experience is secure trip organization for DIY, already-booked, guided/package-tour, and simple organization modes, including domestic trips and journeys without flights or accommodation.

The product grows outward from that foundation:

1. Make the repository reproducible, testable, documented, and safe.
2. Establish secure identity and flexible trip records.
3. Add optional itinerary and maps, then already-booked stays and honest arrival directions.
4. Build a local-first today experience that works with sparse trip data.
5. Add checklists, reminders, and confirmed arrival assistance.
6. Harden sync and operational readiness before beta.
7. Add advanced providers, AI, collaboration, and travel utilities only through separately approved slices:
   - [Trip Circles](../MASTER_PLAN.md#14c-trip-circles--travel-together): planned family/group invitations and shared workspace.
   - [Smart Airport Lounge Finder](../MASTER_PLAN.md#14e-smart-airport-lounge-finder-proposed-module): proposed departure terminal filtering, lounge amenities, eligibility rules, and gate departure reminders.
   - [AI Smart Itinerary Planner & "Ask TapItTrip"](../MASTER_PLAN.md#14f-ai-smart-itinerary-planner--ask-tapittrip-assistant-proposed-module): proposed three-mode planning (manual, AI-generated, AI-assisted) with "AI suggests; user approves" invariant, neighborhood route clustering, weather/family-aware alternatives, and in-trip assistant.

## Engineering direction

- Prefer a modular monolith and feature-first mobile code until measured needs justify another boundary.
- Follow the shared implementation and quality guidance in [`docs/engineering/application-best-practices.md`](engineering/application-best-practices.md).
- Flutter remains the recommended mobile framework; [`ADR 0001`](decisions/0001-mobile-framework.md) records the proposed decision and the conditions that would justify React Native instead.
- Keep OpenAPI, feature documentation, tests, and implementation synchronized in each slice.
- Render local state first and preserve offline mutations durably; make freshness and conflicts visible.
- Treat provider responses and imported content as untrusted, attributed, and potentially stale.
- Make authorization, privacy, accessibility, localization, timezones, and currency correctness part of design and review.
- Use deterministic fakes in default tests; live-provider checks are explicit and never the only acceptance evidence.
- Stop at milestone gates. A future item in the plan is direction, not implementation authorization.

## Decision filter

Choose the next task that produces the smallest testable traveler or engineering outcome inside the current milestone. Defer work that depends on unapproved providers, credentials, package identifiers, deep links, legal claims, or later-milestone data models. Record durable tradeoffs as ADRs and report verification limits exactly.

