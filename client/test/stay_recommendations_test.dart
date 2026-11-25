import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapittrip/features/stays/data/stay_recommendation_repository.dart';
import 'package:tapittrip/features/itinerary/domain/models/itinerary_item.dart';
import 'package:tapittrip/features/itinerary/domain/models/trip_assistant_response.dart';
import 'package:tapittrip/features/itinerary/presentation/providers/itinerary_provider.dart';
import 'package:tapittrip/features/stays/domain/models/stay.dart';
import 'package:tapittrip/features/stays/presentation/providers/stay_provider.dart';
import 'package:tapittrip/features/stays/presentation/widgets/stay_recommendations_view.dart';

import 'trip_assistant_test.dart' show FakeAssistantApiClient;

class _Stays extends StayListNotifier {
  _Stays(this.initial) : super('trip');
  final List<Stay> initial;
  @override
  Future<List<Stay>> build() async => initial;
  void save() => state = const AsyncData([
    Stay(id: 'stay', tripId: 'trip', name: 'Saved Stay'),
  ]);
}

class _Items extends ItineraryListNotifier {
  _Items(this.initial) : super('trip');
  final List<ItineraryItem> initial;
  @override
  Future<List<ItineraryItem>> build() async => initial;
  void change() => state = const AsyncData([
    ItineraryItem(id: 'new', tripId: 'trip', title: 'New stop'),
  ]);
}

class _Assistant extends StayRecommendationRepository {
  _Assistant() : super(apiClient: FakeAssistantApiClient());
  int calls = 0;
  bool fail = false;
  String source = 'gemini';
  @override
  Future<TripAssistantResponse> fetch(String tripId) async {
    calls++;
    if (fail) throw Exception('offline');
    return TripAssistantResponse(
      reply: 'Consider the station area to explore your planned neighborhoods.',
      category: 'general',
      contextSummary: {'source': source, 'destination': 'Kyoto, Japan'},
      suggestedActions: const [
        AssistantSuggestedAction(
          label: 'Hotel',
          kind: 'add_activity',
          payload: {
            'title': 'Example Hotel',
            'kind': 'hotel',
            'place_name': 'Example Hotel',
            'notes': 'Research this base for your route.',
          },
        ),
        AssistantSuggestedAction(
          label: 'Meal',
          kind: 'add_activity',
          payload: {'title': 'Unrelated lunch', 'kind': 'meal'},
        ),
      ],
    );
  }
}

void main() {
  test(
    'stay repository calls the dedicated endpoint without a chat prompt',
    () async {
      final api = FakeAssistantApiClient();
      final result = await StayRecommendationRepository(apiClient: api)
          .fetch('trip');
      expect(api.lastPath, '/trips/trip/stay-recommendations');
      expect(api.lastData, isNull);
      expect(result.reply, isNotEmpty);
    },
  );

  const stop = ItineraryItem(id: 'stop', tripId: 'trip', title: 'Museum');
  Future<void> mount(
    WidgetTester tester,
    _Stays stays,
    _Items items,
    _Assistant assistant,
  ) async {
    tester.view.physicalSize = const Size(320, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          stayListProvider('trip').overrideWith(() => stays),
          itineraryListProvider('trip').overrideWith(() => items),
          stayRecommendationRepositoryProvider.overrideWithValue(assistant),
        ],
        child: MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(2)),
            child: child!,
          ),
          home: const Scaffold(
            body: SingleChildScrollView(
              child: StayRecommendationsView(tripId: 'trip'),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 650));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'empty stays show lodging ideas and refresh when itinerary changes',
    (tester) async {
      final assistant = _Assistant();
      final items = _Items([stop]);
      final stays = _Stays([]);
      await mount(tester, stays, items, assistant);
      expect(find.text('Example Hotel'), findsOneWidget);
      expect(find.text('Unrelated lunch'), findsNothing);
      expect(find.text('View place'), findsOneWidget);
      expect(find.text('Directions'), findsOneWidget);
      expect(assistant.calls, 1);
      items.change();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 650));
      await tester.pumpAndSettle();
      expect(assistant.calls, 2);
      stays.save();
      await tester.pumpAndSettle();
      expect(find.text('Example Hotel'), findsNothing);
      expect(assistant.calls, 2);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('a saved stay does not trigger AI', (tester) async {
    final assistant = _Assistant();
    await mount(
      tester,
      _Stays([const Stay(id: 'stay', tripId: 'trip', name: 'Saved')]),
      _Items([stop]),
      assistant,
    );
    expect(assistant.calls, 0);
    expect(find.text('Ideas for where to stay'), findsNothing);
  });

  testWidgets(
    'no itinerary uses destination guidance without requiring planning',
    (tester) async {
      final assistant = _Assistant();
      await mount(tester, _Stays([]), _Items([]), assistant);
      expect(find.textContaining('Without itinerary stops'), findsOneWidget);
      expect(find.text('Example Hotel'), findsOneWidget);
      expect(assistant.calls, 1);
    },
  );

  testWidgets('offline failure offers manual retry', (tester) async {
    final assistant = _Assistant()..fail = true;
    await mount(tester, _Stays([]), _Items([stop]), assistant);
    expect(
      find.textContaining('You can still add your own accommodation'),
      findsOneWidget,
    );
    assistant.fail = false;
    await tester.ensureVisible(find.text('Retry stay ideas'));
    await tester.tap(find.text('Retry stay ideas'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 650));
    await tester.pumpAndSettle();
    expect(find.text('Example Hotel'), findsOneWidget);
    expect(assistant.calls, 2);
  });

  testWidgets('fallback does not pass off generic suggestions as AI lodging', (
    tester,
  ) async {
    await mount(
      tester,
      _Stays([]),
      _Items([stop]),
      _Assistant()..source = 'local_fallback',
    );
    expect(
      find.textContaining('AI stay ideas are unavailable'),
      findsOneWidget,
    );
    expect(find.text('Example Hotel'), findsNothing);
  });
}
