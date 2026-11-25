import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapittrip/features/itinerary/data/ai_itinerary_repository.dart';
import 'package:tapittrip/features/itinerary/services/recommendation_link_service.dart';
import 'package:tapittrip/features/itinerary/domain/models/itinerary_item.dart';
import 'package:tapittrip/features/itinerary/domain/models/trip_assistant_response.dart';
import 'package:tapittrip/features/itinerary/presentation/providers/itinerary_provider.dart';
import 'package:tapittrip/features/itinerary/presentation/widgets/trip_recommendations_view.dart';

import 'package:tapittrip/features/itinerary/presentation/localization/recommendations_strings.dart';

import 'trip_assistant_test.dart' show FakeAssistantApiClient;

class _Links extends RecommendationLinkService {
  String? viewed;
  String? routed;
  bool fail = false;

  @override
  Future<bool> viewPlace(String query) async {
    viewed = query;
    return !fail;
  }

  @override
  Future<bool> directions(String query) async {
    routed = query;
    if (fail) throw Exception('No map handler');
    return true;
  }
}

class _Items extends ItineraryListNotifier {
  _Items(this.items) : super('trip-1');
  final List<ItineraryItem> items;

  @override
  Future<List<ItineraryItem>> build() async => items;

  void replace(List<ItineraryItem> items) => state = AsyncData(items);
}

class _Assistant extends AiItineraryRepository {
  _Assistant() : super(apiClient: FakeAssistantApiClient());
  int calls = 0;
  bool fail = false;
  String source = 'gemini';

  @override
  Future<TripAssistantResponse> askAssistant(
    String tripId, {
    required String query,
    String? contextDate,
    String? terminalCode,
  }) async {
    calls++;
    if (fail) throw Exception('offline');
    return TripAssistantResponse(
      reply: 'Ideas',
      category: 'itinerary',
      contextSummary: {'source': source, 'destination': 'Kyoto, Japan'},
      suggestedActions: const [
        AssistantSuggestedAction(
          label: 'Museum',
          kind: 'add_activity',
          payload: {'title': 'Museum'},
        ),
        AssistantSuggestedAction(
          label: 'Garden',
          kind: 'add_activity',
          payload: {'title': 'Garden', 'place_name': 'Kyoto Botanical Gardens'},
        ),
        AssistantSuggestedAction(
          label: 'Garden duplicate',
          kind: 'add_activity',
          payload: {'title': 'Garden'},
        ),
      ],
    );
  }
}

void main() {
  test(
    'feature copy resolves Filipino and defaults other locales to English',
    () {
      expect(
        const RecommendationsStrings(Locale('fil')).planned,
        'Nakaplano na',
      );
      expect(
        const RecommendationsStrings(Locale('en')).planned,
        'Already planned',
      );
      expect(
        const RecommendationsStrings(Locale('fr')).planned,
        'Already planned',
      );
    },
  );

  const museum = ItineraryItem(id: 'one', tripId: 'trip-1', title: 'Museum');

  Future<void> mount(
    WidgetTester tester,
    _Items items,
    _Assistant assistant, {
    _Links? links,
  }) async {
    tester.view.physicalSize = const Size(320, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          itineraryListProvider('trip-1').overrideWith(() => items),
          aiItineraryRepositoryProvider.overrideWithValue(assistant),
          if (links != null)
            recommendationLinkServiceProvider.overrideWithValue(links),
        ],
        child: MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(2)),
            child: child!,
          ),
          home: const Scaffold(
            body: SingleChildScrollView(
              child: TripRecommendationsView(
                tripId: 'trip-1',
                destination: 'Kyoto, Japan',
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets(
    'shows planned stops immediately, deduplicates AI ideas and refreshes after edits',
    (tester) async {
      final items = _Items([museum]);
      final assistant = _Assistant();
      await mount(tester, items, assistant);
      expect(find.text('Museum'), findsOneWidget);
      expect(assistant.calls, 0);
      await tester.pump(const Duration(milliseconds: 650));
      await tester.pumpAndSettle();
      expect(find.text('Garden'), findsOneWidget);
      expect(find.text('Museum'), findsOneWidget);
      expect(assistant.calls, 1);
      items.replace([
        museum,
        const ItineraryItem(id: 'two', tripId: 'trip-1', title: 'Garden'),
      ]);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 650));
      await tester.pumpAndSettle();
      expect(assistant.calls, 2);
      expect(find.text('Garden'), findsOneWidget);
      expect(find.text('No additional suggestions yet.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  test('map URLs encode untrusted text under a fixed host', () {
    const query = 'Cafe & Garden / 京都?url=javascript:alert(1)';
    final uri = RecommendationLinkService.placeUri(query);
    expect(uri.scheme, 'https');
    expect(uri.host, 'www.google.com');
    expect(uri.path, '/maps/search/');
    expect(uri.queryParameters, {'api': '1', 'query': query});
  });

  testWidgets('planned and suggested cards open place details and directions', (
    tester,
  ) async {
    final links = _Links();
    await mount(tester, _Items([museum]), _Assistant(), links: links);
    await tester.pump(const Duration(milliseconds: 650));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('View place').first);
    await tester.tap(find.text('View place').first);
    await tester.pumpAndSettle();
    expect(links.viewed, 'Museum, Kyoto, Japan');
    await tester.ensureVisible(find.text('View place').last);
    await tester.tap(find.text('View place').last);
    await tester.pumpAndSettle();
    expect(links.viewed, 'Kyoto Botanical Gardens, Kyoto, Japan');
    await tester.ensureVisible(find.text('Directions').last);
    await tester.tap(find.text('Directions').last);
    await tester.pumpAndSettle();
    expect(links.routed, 'Kyoto Botanical Gardens, Kyoto, Japan');
    expect(tester.takeException(), isNull);
  });

  testWidgets('failed map launches show a retryable error', (tester) async {
    final links = _Links()..fail = true;
    await mount(tester, _Items([museum]), _Assistant(), links: links);
    await tester.pump(const Duration(milliseconds: 650));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Directions').last);
    await tester.tap(find.text('Directions').last);
    await tester.pumpAndSettle();
    expect(find.text('Could not open maps. Please try again.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('no itinerary needs no AI call', (tester) async {
    final assistant = _Assistant();
    await mount(tester, _Items([]), assistant);
    await tester.pumpAndSettle();
    expect(assistant.calls, 0);
    expect(find.textContaining('without an itinerary'), findsOneWidget);
  });

  testWidgets('offline failure preserves itinerary and allows retry', (
    tester,
  ) async {
    final assistant = _Assistant()..fail = true;
    await mount(tester, _Items([museum]), assistant);
    await tester.pump(const Duration(milliseconds: 650));
    await tester.pumpAndSettle();
    expect(find.text('Museum'), findsOneWidget);
    assistant.fail = false;
    await tester.ensureVisible(find.text('Retry suggestions'));
    await tester.tap(find.text('Retry suggestions'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 650));
    await tester.pumpAndSettle();
    expect(find.text('Garden'), findsOneWidget);
    expect(assistant.calls, 2);
  });

  testWidgets('fallback ideas are not labeled AI generated', (tester) async {
    await mount(
      tester,
      _Items([museum]),
      _Assistant()..source = 'local_fallback',
    );
    await tester.pump(const Duration(milliseconds: 650));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('AI suggestions are unavailable'),
      findsOneWidget,
    );
    expect(find.textContaining('AI-generated ideas'), findsNothing);
  });
}
