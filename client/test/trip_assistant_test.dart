import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapittrip/core/network/api_client.dart';
import 'package:tapittrip/core/storage/token_storage.dart';
import 'package:tapittrip/features/itinerary/data/ai_itinerary_repository.dart';
import 'package:tapittrip/features/itinerary/domain/models/trip_assistant_response.dart';
import 'package:tapittrip/features/itinerary/presentation/providers/itinerary_provider.dart';
import 'package:tapittrip/features/itinerary/presentation/widgets/ask_tapittrip_sheet.dart';

class FakeAssistantApiClient extends ApiClient {
  FakeAssistantApiClient() : super(tokenStorage: InMemoryTokenStorage());

  dynamic postResponse;
  String? lastPath;
  dynamic lastData;

  @override
  Future<dynamic> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    lastPath = path;
    lastData = data;
    return postResponse ??
        {
          'data': {
            'reply': 'Since you are staying at Shinjuku Granbell Hotel, here are local dining spots within 5 minutes walk.',
            'category': 'dining',
            'context_summary': {
              'has_stay': true,
              'stay_name': 'Shinjuku Granbell Hotel',
            },
            'suggested_actions': [
              {
                'label': 'Add Dinner near Hotel',
                'kind': 'add_activity',
                'payload': {
                  'title': 'Dinner near Shinjuku Granbell Hotel',
                  'kind': 'dining',
                },
              },
            ],
          },
        };
  }
}

void main() {
  group('TripAssistantResponse Model', () {
    test('deserializes JSON response and actions correctly', () {
      final json = {
        'reply': 'Accessible lounges in Terminal 3 include PAGSS Lounge.',
        'category': 'lounge',
        'context_summary': {'detected_terminal': 'T3'},
        'suggested_actions': [
          {
            'label': 'Open Lounge Finder',
            'kind': 'navigate_lounge_finder',
            'payload': {'terminal': 'T3'},
          },
        ],
      };

      final response = TripAssistantResponse.fromJson(json);

      expect(response.reply, contains('PAGSS Lounge'));
      expect(response.category, 'lounge');
      expect(response.suggestedActions.length, 1);
      expect(response.suggestedActions.first.label, 'Open Lounge Finder');
      expect(response.suggestedActions.first.kind, 'navigate_lounge_finder');
      expect(response.suggestedActions.first.payload['terminal'], 'T3');
    });
  });

  group('AiItineraryRepository askAssistant', () {
    test('posts query and returns TripAssistantResponse', () async {
      final fakeApi = FakeAssistantApiClient();
      final repo = AiItineraryRepository(apiClient: fakeApi);

      final result = await repo.askAssistant(
        'trip-456',
        query: 'Where should we eat near our hotel?',
      );

      expect(fakeApi.lastPath, '/trips/trip-456/assistant/query');
      expect(fakeApi.lastData['query'], 'Where should we eat near our hotel?');
      expect(result.category, 'dining');
      expect(result.reply, contains('Shinjuku Granbell Hotel'));
    });
  });

  group('AskTapItTripSheet Widget', () {
    testWidgets(
      'renders suggested questions, submits query, and displays reply',
      (tester) async {
        final fakeApi = FakeAssistantApiClient();
        final repo = AiItineraryRepository(apiClient: fakeApi);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [aiItineraryRepositoryProvider.overrideWithValue(repo)],
            child: const MaterialApp(
              home: Scaffold(body: AskTapItTripSheet(tripId: 'trip-456')),
            ),
          ),
        );

        // Verify header
        expect(find.text('Ask TapItTrip'), findsOneWidget);
        expect(find.text('Your contextual in-trip assistant'), findsOneWidget);

        // Verify suggested prompt chips
        expect(
          find.text('Where should we eat near our hotel?'),
          findsOneWidget,
        );
        expect(
          find.text('Which lounge can I use in Terminal 3?'),
          findsOneWidget,
        );

        // Tap on a suggested question chip
        await tester.tap(find.text('Where should we eat near our hotel?'));
        await tester.pump();
        await tester.pumpAndSettle();

        // Verify API was called
        expect(fakeApi.lastPath, '/trips/trip-456/assistant/query');

        // Verify category badge and response reply
        expect(find.text('Dining & Hotel'), findsOneWidget);
        expect(find.text('Advisory only'), findsOneWidget);
        expect(
          find.textContaining(
            'Since you are staying at Shinjuku Granbell Hotel',
          ),
          findsOneWidget,
        );

        // Verify suggested action button
        expect(find.text('Add Dinner near Hotel'), findsOneWidget);
      },
    );
  });
}
