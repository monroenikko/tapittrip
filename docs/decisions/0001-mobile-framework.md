# ADR 0001: Mobile framework for TapItTrip

- Status: **Accepted**
- Date: 2026-11-03 (Accepted 2026-11-05 with package ID `com.tapittrip.app`)
- Decision owners: project owner and mobile engineering lead
- Scope: mobile application framework only

## Context

TapItTrip needs one Android/iOS codebase with local-first SQL persistence, durable background-aware synchronization, maps, notifications, location/geofencing, camera/OCR, secure storage, localization, accessibility, and consistent traveler-facing UI.

`MASTER_PLAN.md` already proposes Flutter with Riverpod, GoRouter, Dio, and Drift. The approved mobile root is `client/`, which is currently empty, so changing framework direction is still technically possible but would require updating the master plan, skills, delivery documentation, and dependency strategy before scaffolding.

## Options considered

| Criterion | Flutter | React Native |
| --- | --- | --- |
| Existing TapItTrip plan | Already selected with named libraries and testing commands | Requires revising the approved architecture and repository skills |
| UI consistency | Flutter owns its rendering/widget layer and is well suited to a controlled cross-platform design | Uses React Native components and platform/native integration; excellent results are possible with deliberate platform testing |
| Offline-first fit | Drift/SQLite, streams, isolates, and typed Dart models fit the planned local-source-of-truth design | SQLite and offline libraries are available, but the project must choose and validate a coherent Expo/React Native data stack |
| Team skills | Best when the team is comfortable adopting Dart/Flutter | Strong advantage when the team already works deeply in React and TypeScript |
| Web code sharing | Flutter Web exists, but TapItTrip does not currently plan a shared web product | React/TypeScript knowledge and some non-UI code may align better with an existing React web organization |
| Native/platform features | Requires plugins or platform channels and real-device verification | Requires compatible modules/config plugins or native modules and real-device verification |
| Framework path | Flutter provides an integrated SDK, rendering, tooling, and official architecture guidance | React Native recommends using a framework such as Expo for new applications; the New Architecture is the current default direction |
| Migration cost now | Low because no client code exists, but all TapItTrip plans already align with Flutter | Low code-rewrite cost today, but meaningful planning, skill, dependency, and architecture changes |

Neither framework removes the need for native-device testing, permission design, background-execution constraints, provider evaluation, accessibility, or store compliance.

## Proposed decision

Use **Flutter** for TapItTrip.

This recommendation is project-specific, not a claim that Flutter is universally better. Flutter is the better fit here because:

1. The approved product/architecture plan, skills, tests, and offline model already converge on Flutter, Riverpod, GoRouter, Dio, and Drift.
2. TapItTrip prioritizes a consistent mobile travel experience and a local SQL source of truth more than web UI code sharing.
3. Flutter's official architecture and offline-first guidance map directly to the repository/service boundaries already documented.
4. No demonstrated React/TypeScript team constraint currently outweighs the existing alignment.

## When React Native would be the better decision

Choose React Native instead before scaffolding if the project confirms that most of the delivery team is substantially stronger in React/TypeScript, must share meaningful TypeScript domain code with an existing web application, or depends on a critical native/Expo integration that is materially better supported than its Flutter alternative.

If selected, use a framework-based React Native setup—normally Expo—unless an ADR documents why bare React Native is required. Re-evaluate SQLite/offline sync, routing, secure storage, notifications, background tasks, location, maps, testing, and update/release policy as one coherent stack rather than package by package.

## Consequences

- Flutter is accepted and scaffolded under `client/` with package/bundle identifier `com.tapittrip.app`.
- Preserve provider boundaries so native integrations can be replaced without changing domain/application logic.
- Validate background sync, notifications, geofencing, maps, and OCR on representative real devices.
- Do not scaffold both Flutter and React Native clients for comparison; use small technical spikes only for a specific unresolved capability.

## Validation before acceptance

- Confirm team Flutter/Dart capability and ownership.
- Spike Drift migration/outbox persistence and app-restart recovery.
- Verify notification, background work, location/geofence, maps, camera/OCR, secure storage, and localization requirements on Android and iOS.
- Confirm required plugins' maintenance, licenses, current platform support, and privacy implications.
- Scaffold the Flutter project only in the approved root `client/`.

## References

- [Flutter app architecture](https://docs.flutter.dev/app-architecture/guide)
- [Flutter offline-first support](https://docs.flutter.dev/app-architecture/design-patterns/offline-first)
- [React Native: use a framework to build apps](https://reactnative.dev/blog/2024/06/25/use-a-framework-to-build-react-native-apps)
- [React Native New Architecture](https://reactnative.dev/architecture/landing-page)

