import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapittrip/features/itinerary/data/ai_itinerary_repository.dart';
import 'package:tapittrip/features/itinerary/data/itinerary_repository.dart';
import 'package:tapittrip/features/itinerary/domain/models/itinerary_item.dart';
import 'package:tapittrip/features/itinerary/domain/models/smart_replan_result.dart';
import 'package:tapittrip/features/itinerary/presentation/providers/itinerary_provider.dart';
import 'package:tapittrip/features/itinerary/presentation/widgets/activity_timeline_card.dart';
import 'package:tapittrip/features/itinerary/presentation/widgets/smart_replan_sheet.dart';

import 'trip_assistant_test.dart' show FakeAssistantApiClient;

class _FakeAiReplanRepository extends AiItineraryRepository {
  _FakeAiReplanRepository() : super(apiClient: FakeAssistantApiClient());

  String lastTrigger = 'rain_weather';
  bool lastApply = false;
  int replanCalls = 0;

  @override
  Future<SmartReplanResult> replanItinerary(
    String tripId, {
    required String triggerReason,
    String? tripDayId,
    bool apply = false,
    int? delayMinutes,
  }) async {
    replanCalls++;
    lastTrigger = triggerReason;
    lastApply = apply;
    return SmartReplanResult.fromJson({
      'trip_id': tripId,
      'trip_day_id': tripDayId,
      'trigger_reason': triggerReason,
      'applied': apply,
      'preserved_visited_count': 2,
      'summary': 'Rainy-weather adjustment: preserved 2 visited stop(s) and added sheltered indoor alternatives.',
      'proposed_changes': [
        {
          'action': 'keep_visited',
          'target_item_id': 'item-1',
          'title': 'Fushimi Inari Morning Shrine Walk',
          'kind': 'attraction',
          'place_name': 'Fushimi Inari',
          'notes': null,
          'reason': 'Completed activity & past memory preserved untouched.',
          'starts_at_utc': null,
          'ends_at_utc': null,
        },
        {
          'action': 'add_alternative',
          'target_item_id': null,
          'title': 'Covered Arcade & Indoor Cultural Hall (Kyoto)',
          'kind': 'attraction',
          'place_name': 'Nishiki Covered Arcade',
          'notes': 'Sheltered all-weather gallery and indoor food hall backup.',
          'reason': 'All-weather indoor alternative for rain forecast.',
          'starts_at_utc': null,
          'ends_at_utc': null,
        },
      ],
      'items': const [],
      'provider_attribution': 'TapItTrip Smart Replanning Engine',
      'verified': false,
      'advisory_notice':
          'Replanning proposals never delete or overwrite visited stops.',
    });
  }
}

class _FakeVotingItineraryRepository extends ItineraryRepository {
  _FakeVotingItineraryRepository() : super(apiClient: FakeAssistantApiClient());

  @override
  Future<List<ItineraryItem>> fetchItems(
    String tripId, {
    String? tripDayId,
  }) async {
    return const [];
  }
}

void main() {
  test(
    'ItineraryItem parses and serializes group vote counts and viewerVote',
    () {
      final item = ItineraryItem.fromJson({
        'id': 'item-1',
        'trip_id': 'trip-1',
        'title': 'Tokyo DisneySea',
        'upvotes_count': 4,
        'downvotes_count': 1,
        'viewer_vote': 'up',
      });

      expect(item.upvotesCount, 4);
      expect(item.downvotesCount, 1);
      expect(item.viewerVote, 'up');

      final json = item.toJson();
      expect(json['upvotes_count'], 4);
      expect(json['downvotes_count'], 1);
      expect(json['viewer_vote'], 'up');
    },
  );

  testWidgets(
    'ActivityTimelineCard renders thumbs up and thumbs down vote counts and triggers vote callbacks',
    (tester) async {
      int upTaps = 0;
      int downTaps = 0;

      const item = ItineraryItem(
        id: 'item-1',
        tripId: 'trip-1',
        title: 'Ueno Park Picnic',
        upvotesCount: 3,
        downvotesCount: 1,
        viewerVote: 'up',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ActivityTimelineCard(
              item: item,
              onVoteUp: () => upTaps++,
              onVoteDown: () => downTaps++,
            ),
          ),
        ),
      );

      expect(find.text('3'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);

      await tester.tap(find.byKey(const Key('vote_up_item-1')));
      await tester.pump();
      expect(upTaps, 1);

      await tester.tap(find.byKey(const Key('vote_down_item-1')));
      await tester.pump();
      expect(downTaps, 1);
    },
  );

  testWidgets(
    'SmartReplanSheet previews non-destructive adjustments, switches trigger reason, and applies on approval',
    (tester) async {
      final aiRepo = _FakeAiReplanRepository();
      final itemRepo = _FakeVotingItineraryRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            aiItineraryRepositoryProvider.overrideWithValue(aiRepo),
            itineraryRepositoryProvider.overrideWithValue(itemRepo),
          ],
          child: const MaterialApp(
            home: Scaffold(body: SmartReplanSheet(tripId: 'trip-1')),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Smart In-Trip Replanning'), findsOneWidget);
      expect(
        find.text('Preserves 2 visited stop(s) & past memories'),
        findsOneWidget,
      );
      expect(
        find.text('Covered Arcade & Indoor Cultural Hall (Kyoto)'),
        findsOneWidget,
      );
      expect(aiRepo.lastTrigger, 'rain_weather');
      expect(aiRepo.lastApply, isFalse);

      // Switch trigger to Flight Delay
      await tester.tap(find.text('Flight Delay'));
      await tester.pumpAndSettle();
      expect(aiRepo.lastTrigger, 'flight_delay');

      // Approve & Apply Replan
      await tester.ensureVisible(find.text('Approve & Apply Replan'));
      await tester.tap(find.text('Approve & Apply Replan'));
      await tester.pumpAndSettle();

      expect(aiRepo.lastApply, isTrue);
    },
  );
}
