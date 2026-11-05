---
name: tapittrip-flutter-mobile
description: Plan, implement, test, or review TapItTrip Flutter mobile slices using the repository's Riverpod state, service/repository, reusable-widget, accessibility, and offline-first patterns. Use for mobile work under the root client folder; do not use it to authorize a new milestone or assume provider/device capabilities.
---

# TapItTrip Flutter Mobile

Read `AGENTS.md`, the relevant `MASTER_PLAN.md` sections, `docs/kos/README.md`, `docs/kos/delivery-workflow.md`, and `docs/milestone-log.md`. Inspect installed Flutter/Dart versions, dependencies, generated-code conventions, and existing feature patterns before making changes.

## Repository location

- The Flutter mobile application lives at `<repository-root>/client`.
- Run Dart/Flutter format, analyze, test, build, and code-generation commands from `client/` unless the repository provides an explicit root-level wrapper.
- Do not create or use `apps/mobile` as an alternative mobile root.

## Required implementation pattern

For feature state, Riverpod providers, services/repositories, reusable widgets, or review, read and apply [`references/riverpod-service-widget-patterns.md`](references/riverpod-service-widget-patterns.md). Use its default dependency flow unless existing code establishes an equally safe convention. Explain a material deviation in the plan rather than mixing state-management or component patterns silently.

## Plan the slice

- Confirm the approved milestone and define one traveler outcome across UI, application state, repository, local data, and API boundaries.
- Include loading, empty, error, offline, stale, permission-denied, accessibility, localization, and no-itinerary behavior when applicable.
- Identify local schema/migration, durable outbox, sync/idempotency, secure storage, timezone, and navigation impacts.
- Name unit, widget, and any critical integration tests before coding. Do not introduce screens or abstractions for later milestones.

## Implement

- Organize by feature. Keep widgets focused on rendering and interaction; place commands and UI state in Riverpod `Notifier`/`AsyncNotifier` classes, orchestration in application/use-case classes only when it earns its cost, and local/remote/platform work behind repositories and focused services.
- Render saved Drift state before refreshing from the network. For offline-capable mutations, update local state and the durable outbox transactionally once that infrastructure exists.
- Model async state explicitly and make retry/sync/stale status understandable. Do not hide provider limitations or fabricate live data.
- Keep GoRouter navigation shallow and contextual. Do not require itinerary creation for basic trip, booking, stay, reminder, or essential-information flows.
- Use Dio through configured clients/adapters, secure storage for tokens, and deterministic clocks/providers in tests. Do not log tokens, booking references, private coordinates, or document contents.
- Use localized strings, semantic labels, scalable text, adequate contrast and touch targets, and locale-aware dates/currencies with explicit IANA timezones.
- For screens, widgets, and theming, follow `client/.agents/skills/flutter-premium-ui/SKILL.md` (brand colors: primary navy `#00376D`, secondary orange `#F76405`; read from `ColorScheme`, never hard-code hex in widgets).

## Test and verify

- Unit-test application state, domain decisions, mapping, repositories, and sync/outbox behavior with isolated dependencies.
- Widget-test loading, empty, error, offline/stale, and success states plus semantics and large-text behavior where relevant.
- Add integration tests for critical cross-layer journeys only, especially persistence across restart and offline edit/reconnect.
- Cover the relevant DIY, already-booked, guided, and simple modes and trips with no itinerary activities.
- Run `dart format`, `flutter analyze`, and `flutter test` using the installed project. Run integration/device checks when required and available; report device or credential limits honestly.

## Review

Review the final diff using `docs/kos/delivery-workflow.md`. Prioritize lost offline writes, state races, unsafe token/data storage, stale data presented as live, deep or blocking flows, missing accessibility/localization, navigation regressions, generated-code drift, and tests that assert implementation details instead of behavior. Record exact results and remaining limits in `docs/milestone-log.md`, then stop at the milestone boundary.
