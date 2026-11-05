# Start Here — TapItTrip with Codex

1. Create/open a repository for `travel-companion` (working repository name; the user-facing app and visual wordmark are **TapItTrip**).
2. Copy `MASTER_PLAN.md` and `AGENTS.md` to the repository root.
3. Start Codex from that repository.
4. Use this first prompt:

> Read AGENTS.md and MASTER_PLAN.md completely. We are starting milestone M0 only. Inspect the repository, identify missing prerequisites, propose the smallest implementation sequence, and then scaffold the Flutter + Laravel monorepo, Docker Compose PostgreSQL/PostGIS + Redis, environment examples, CI, and health checks. Do not implement later milestones. Run available checks, record results in docs/milestone-log.md, and stop for review.

5. After reviewing M0, explicitly approve M1, and continue one milestone at a time.

Note: Version choices and provider terms should be revalidated at implementation time. Credentials, app identifiers, and budgets must be supplied through secure configuration, not committed to source control.

Accommodation & Stay Management is part of the MVP in milestone M2b (after itinerary/maps, before today dashboard). See MASTER_PLAN.md for stay data, APIs, offline behavior, navigation, reminders, and acceptance criteria.

### v1.2: Already-booked stays and luggage-aware arrival routes
M2b now includes saving existing accommodation reservations, trip luggage and group presets, and an explainable airport/station-to-stay transportation comparison. Provider-backed prices, travel times, accessibility and luggage restrictions must be verified; otherwise show an honest fallback and navigation link. Do not begin this milestone until M0–M2 are approved.

### Branding update (v1.3)
The product is provisionally named and styled **TapItTrip**, with the tagline **Your trip. One tap away.** Keep the current repository name unless instructed otherwise. Before public release, verify trademarks, app-store naming, domain ownership, and final bundle/application identifiers. No domain or trademark availability has been confirmed.

### Audience expansion (v1.4)
TapItTrip supports DIY planners, already-booked trips, guided/package tours, and simple travel organization. The selected trip mode is a changeable onboarding preference, not an account type. Core booking/stay/reminder screens must work even when no itinerary has been created. Read MASTER_PLAN.md section 1a before designing trip creation and home navigation.
