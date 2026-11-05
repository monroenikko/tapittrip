# Flutter Riverpod, Service, and Reusable Widget Patterns

Apply these patterns inside the root `client/` Flutter project. Inspect the installed Riverpod/Flutter versions and existing generator conventions before choosing exact APIs or annotations.

## Default dependency flow

```text
Page / Reusable Widget
  -> Riverpod Provider + Notifier/AsyncNotifier (UI state and commands)
  -> Application Use Case (optional cross-repository orchestration)
  -> Repository (feature source of truth)
  -> Local Data Source / Remote Data Source / Platform Service
  -> Drift / Dio / platform plugin
```

Dependencies point inward. Widgets do not call Dio, Drift DAOs, secure storage, or platform plugins. Data sources do not read Riverpod providers or build widgets.

## Riverpod state-management pattern

Use one state owner for each feature/screen responsibility. Keep state immutable and expose intent-named commands.

### Provider selection

- `Provider`: dependency injection, repositories/services, configuration, clocks, UUID factories, and pure derived values.
- `StreamProvider`: read-only reactive streams, especially Drift-backed local state.
- `FutureProvider`: read-only async lookup with no user-driven mutation lifecycle.
- `NotifierProvider`: mutable synchronous UI/application state.
- `AsyncNotifierProvider`: async initialization and user commands that need loading/error/data state.
- `family`: parameterized state such as one trip/stay ID; use stable value equality.
- automatic disposal: default for screen/parameter-scoped state unless preservation is a proven requirement. Keep state alive only deliberately.

Do not introduce BLoC, Provider/ChangeNotifier, GetX, or another global state system beside Riverpod without an approved migration decision.

### State shape

Prefer a feature-specific immutable state when `AsyncValue<T>` alone cannot express refresh, offline, stale, sync, validation, or partial-data status.

```dart
class TripListState {
  const TripListState({
    required this.trips,
    this.isRefreshing = false,
    this.isOffline = false,
    this.lastUpdatedAt,
    this.message,
  });

  final List<TripSummary> trips;
  final bool isRefreshing;
  final bool isOffline;
  final DateTime? lastUpdatedAt;
  final String? message;
}
```

Use an enum/sealed state when states are mutually exclusive; use fields when data and statuses must coexist. Do not encode business state in several unrelated booleans that permit impossible combinations.

### Notifier shape

```dart
class TripListNotifier extends AsyncNotifier<TripListState> {
  late final TripRepository _repository;

  @override
  Future<TripListState> build() async {
    _repository = ref.watch(tripRepositoryProvider);
    final local = await _repository.readLocalTrips();
    unawaited(refresh());
    return TripListState(trips: local);
  }

  Future<void> refresh() async {
    // Preserve usable local data while representing refresh/failure explicitly.
  }

  Future<void> createTrip(CreateTripInput input) async {
    // Delegate local transaction + outbox behavior to the repository.
  }
}
```

Treat this as a responsibility example, not copy-ready code. Adapt to the installed Riverpod API, lint rules, local stream design, and error model. Avoid triggering duplicate side effects from `build`; use explicit lifecycle/command coordination where required.

### Riverpod rules

- Use `ref.watch` for reactive dependencies during build/provider evaluation, `ref.read` for event-time commands, and `ref.listen` for one-off UI effects such as navigation or snackbars.
- Keep navigation, dialogs, snackbars, and localization out of Notifiers; emit state/events the presentation layer interprets.
- Keep provider definitions near their feature unless truly application-wide.
- Override repository/service providers in tests; test real Notifiers through a `ProviderContainer` rather than mocking Notifiers.
- Cancel or ignore stale async results when parameters/session change. Prevent double-submit commands and make retry behavior explicit.

## Service and repository pattern

Use role-specific names instead of a generic `TripService` that mixes HTTP, database, state, and platform behavior.

### Remote data source/API service

- Own Dio endpoint calls, request/response DTOs, transport errors, headers, and status codes.
- Do not expose Dio `Response` objects outside the data layer.
- Do not decide UI messages, offline truth, or domain policy.

### Local data source/DAO

- Own Drift queries, transactions, local DTO/row mapping, migrations, and watch streams.
- Provide the primitives the repository needs; do not call the network.

### Platform service

- Wrap secure storage, connectivity signals, notifications, maps, location, background work, camera/OCR, sharing, and device clock behind small interfaces.
- Expose capability/permission limitations explicitly and provide deterministic fakes.

### Repository

- Be the feature's data source of truth and the only layer that coordinates local and remote sources.
- For offline-capable writes, persist the entity change and durable outbox record in one local transaction, return local state immediately, then synchronize separately.
- Map DTOs/rows to domain models and preserve freshness, sync, conflict, and deletion state.
- Translate technical errors into typed application failures without destroying useful cause/context.

### Application use case

Add only when behavior coordinates multiple repositories or contains reusable workflow logic that would make a Notifier too complex. Examples: `CreateTripWithImportedStay` or `ResolveItineraryConflict`. Do not create a use-case class for every repository method.

## Feature structure

```text
client/lib/features/trips/
  presentation/
    pages/trip_list_page.dart
    providers/trip_list_notifier.dart
    widgets/trip_card.dart
  application/                  # only when needed
    create_trip_with_stay.dart
  domain/
    models/trip.dart
    failures/trip_failure.dart
  data/
    repositories/drift_trip_repository.dart
    local/trip_dao.dart
    remote/trip_api.dart
    dto/trip_dto.dart
```

Interfaces may live in `domain/` or `data/` based on the dependency they protect. Choose once after scaffolding and remain consistent.

## Reusable widget/component pattern

Flutter is widget-based and favors composition. Treat widgets as reusable components with explicit inputs and callbacks.

### Three reuse levels

1. **Page/screen**: route-aware composition; reads page-level providers and handles navigation/effects.
2. **Feature widget**: reusable within one capability, such as `TripCard`, `StaySummary`, or `SyncStatusBanner`; usually receives typed data/callbacks and does not know routing.
3. **Shared/design-system widget**: proven cross-feature primitive such as `TapItTripButton`, `TapItTripEmptyState`, `TapItTripErrorPanel`, or accessible form field; owns consistent tokens and semantics, not feature business rules.

### Widget rules

- Prefer small `StatelessWidget`/`ConsumerWidget` classes with `const` constructors over large build methods or widget-returning helper functions.
- Favor composition and slots (`child`, `leading`, `trailing`, builder) over inheritance and dozens of boolean styling flags.
- Make data flow down through immutable constructor inputs and events flow up through intent-named callbacks.
- Watch the smallest provider/state slice needed near the widget that changes; avoid rebuilding a whole page for a small status update.
- Keep domain decisions and data loading out of widgets. Local ephemeral animation/focus/controller state may remain in a stateful/hook widget.
- Centralize theme, spacing, typography, colors, radius, and motion tokens. Do not hard-code repeated visual constants across features.
- Include semantics, focus behavior, large text, localization, RTL/adaptive layout, loading, empty, error, offline/stale, and disabled states as part of the component contract.
- Extract a shared widget only after reuse or design-system ownership is real. Do not create a generic component that hides important feature differences.

Example controlled feature widget:

```dart
class TripCard extends StatelessWidget {
  const TripCard({
    required this.trip,
    required this.onOpen,
    super.key,
  });

  final TripSummary trip;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: trip.accessibleLabel,
      child: ListTile(
        title: Text(trip.name),
        subtitle: Text(trip.localizedDateRange),
        onTap: onOpen,
      ),
    );
  }
}
```

## Testing seams

- Repository tests: local-first ordering, mappings, transactions/outbox, retries, conflict/freshness state, and typed failures.
- Notifier tests: initial local state, refresh without losing data, commands, double-submit prevention, session/parameter changes, and recovery.
- Widget tests: render controlled components with plain inputs; render connected pages with provider overrides. Cover semantics, large text, localization, loading/empty/error/offline/success states.
- Integration tests: critical persistence/restart/reconnect and platform-permission journeys only.

## Avoid

- Network/database/plugin calls from widgets or Notifiers.
- A generic `ApiService` containing every endpoint or a generic `AppState` containing every feature.
- `ref.read` used to bypass needed reactivity, or `ref.watch` high in the tree without selecting the required state.
- Mutating lists/models in place and expecting Riverpod to detect changes.
- Storing `BuildContext`, widgets, controllers, or localized strings in providers/repositories.
- Swallowing errors into `null`, presenting cached data as live, or clearing useful local data when refresh fails.
- Shared widgets with business logic, feature widgets that depend on unrelated global providers, or premature design-system abstractions.

## Official references

- [Riverpod providers](https://riverpod.dev/docs/concepts2/providers)
- [Riverpod Notifier/AsyncNotifier](https://docs-v2.riverpod.dev/docs/providers/notifier_provider)
- [Riverpod provider testing](https://riverpod.dev/docs/how_to/testing)
- [Flutter app architecture](https://docs.flutter.dev/app-architecture/guide)
- [Flutter performance and reusable widgets](https://docs.flutter.dev/perf/best-practices)
- [Flutter adaptive widget composition](https://docs.flutter.dev/ui/adaptive-responsive/best-practices)

