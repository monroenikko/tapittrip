import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapittrip/core/network/api_client.dart';
import 'package:tapittrip/core/storage/token_storage.dart';
import 'package:tapittrip/features/itinerary/data/ai_itinerary_repository.dart';
import 'package:tapittrip/features/itinerary/domain/models/ai_itinerary_plan.dart';
import 'package:tapittrip/features/itinerary/presentation/providers/itinerary_provider.dart';
import 'package:tapittrip/features/itinerary/presentation/widgets/ai_itinerary_planner_dialog.dart';
import 'package:tapittrip/features/itinerary/presentation/widgets/ai_itinerary_preview_sheet.dart';

class FakeAiApiClient extends ApiClient {
  FakeAiApiClient() : super(tokenStorage: InMemoryTokenStorage());

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
            'destination': 'Tokyo, Japan',
            'summary': 'A balanced 2-day family journey through Tokyo.',
            'travel_party': 'family',
            'pace': 'balanced',
            'total_estimated_budget': {'currency': 'JPY', 'amount': 24000},
            'days': [
              {
                'day_number': 1,
                'title': 'Day 1: Historic Asakusa',
                'theme': 'Historic Asakusa & Riverside Stroll',
                'primary_neighborhood': 'Asakusa & Taito',
                'budget_estimate': {'currency': 'JPY', 'amount': 10000},
                'family_tip':
                    'Flat pavements around Senso-ji are stroller friendly.',
                'activities': [
                  {
                    'title': 'Senso-ji Temple & Nakamise-dori',
                    'kind': 'sightseeing',
                    'neighborhood': 'Asakusa & Taito',
                    'planned_start_time': '09:00',
                    'planned_end_time': '11:30',
                    'place_name': 'Senso-ji',
                    'place_address': '2-3-1 Asakusa, Taito, Tokyo',
                    'latitude': 35.7148,
                    'longitude': 139.7967,
                    'cost_estimate': {'currency': 'JPY', 'amount': 0},
                    'description': 'Tokyo\'s oldest temple.',
                  },
                ],
              },
            ],
            'weather_alternative_note': 'If it rains, consider teamLab Planets or Tokyo National Museum.',
          },
        };
  }
}

void main() {
  group('AiItineraryPlan Model & Deserialization', () {
    test('deserializes JSON plan correctly', () {
      final json = {
        'destination': 'Tokyo, Japan',
        'summary': 'Tokyo sample',
        'travel_party': 'family',
        'pace': 'balanced',
        'total_estimated_budget': {'currency': 'JPY', 'amount': 12000},
        'days': [
          {
            'day_number': 1,
            'title': 'Day 1',
            'theme': 'Asakusa',
            'primary_neighborhood': 'Asakusa',
            'budget_estimate': {'currency': 'JPY', 'amount': 12000},
            'family_tip': 'Kids love the street snacks',
            'activities': [
              {
                'title': 'Senso-ji',
                'kind': 'sightseeing',
                'neighborhood': 'Asakusa',
                'planned_start_time': '09:00',
                'planned_end_time': '10:30',
                'place_name': 'Senso-ji',
                'place_address': 'Tokyo',
                'latitude': 35.71,
                'longitude': 139.79,
                'description': 'Temple',
              },
            ],
          },
        ],
        'weather_alternative_note': 'Indoor museum option',
      };

      final plan = AiItineraryPlan.fromJson(json);

      expect(plan.destination, 'Tokyo, Japan');
      expect(plan.days.length, 1);
      expect(plan.days.first.theme, 'Asakusa');
      expect(plan.days.first.activities.first.title, 'Senso-ji');
      expect(plan.weatherAlternativeNote, 'Indoor museum option');

      // Test activity toJson conversion
      final actJson = plan.days.first.activities.first.toJson();
      expect(actJson['title'], 'Senso-ji');
      expect(actJson['kind'], 'sightseeing');
      expect(actJson['place_name'], 'Senso-ji');
    });
  });

  group('AiItineraryRepository', () {
    test('generatePlan posts parameters and parses response', () async {
      final fakeApi = FakeAiApiClient();
      final repo = AiItineraryRepository(apiClient: fakeApi);

      final plan = await repo.generatePlan(
        'trip-123',
        destination: 'Tokyo, Japan',
        durationDays: 2,
        budgetTier: 'moderate',
        travelParty: 'family',
        pace: 'balanced',
        interests: ['food', 'culture'],
      );

      expect(fakeApi.lastPath, '/trips/trip-123/ai-plan/generate');
      expect(fakeApi.lastData['destination'], 'Tokyo, Japan');
      expect(fakeApi.lastData['duration_days'], 2);
      expect(fakeApi.lastData['budget_tier'], 'moderate');
      expect(plan.destination, 'Tokyo, Japan');
      expect(plan.days.length, 1);
    });

    test('applyPlan posts structured days to apply endpoint', () async {
      final fakeApi = FakeAiApiClient();
      fakeApi.postResponse = {'data': []};
      final repo = AiItineraryRepository(apiClient: fakeApi);

      final days = [
        const AiDaySuggestion(
          dayNumber: 1,
          title: 'Day 1',
          theme: 'Asakusa exploration',
          primaryNeighborhood: 'Asakusa',
          activities: [
            AiActivitySuggestion(
              title: 'Senso-ji',
              kind: 'sightseeing',
              neighborhood: 'Asakusa',
              placeName: 'Senso-ji',
            ),
          ],
        ),
      ];

      final result = await repo.applyPlan('trip-123', days);

      expect(fakeApi.lastPath, '/trips/trip-123/ai-plan/apply');
      expect(result, isEmpty);
    });
  });

  group('AiItineraryPreviewSheet Widget', () {
    testWidgets(
      'renders itinerary days, activities, and non-destructive notice',
      (tester) async {
        final fakeApi = FakeAiApiClient();
        final repo = AiItineraryRepository(apiClient: fakeApi);

        const plan = AiItineraryPlan(
          destination: 'Tokyo, Japan',
          summary: 'Explore Asakusa with your family',
          travelParty: 'family',
          pace: 'balanced',
          days: [
            AiDaySuggestion(
              dayNumber: 1,
              title: 'Day 1',
              theme: 'Historic Asakusa & Riverside Stroll',
              primaryNeighborhood: 'Asakusa & Taito',
              familyTip: 'Stroller friendly pavements',
              activities: [
                AiActivitySuggestion(
                  title: 'Senso-ji Temple',
                  kind: 'sightseeing',
                  neighborhood: 'Asakusa & Taito',
                  plannedStartTime: '09:00',
                  plannedEndTime: '11:00',
                  placeName: 'Senso-ji',
                  description: 'Ancient Buddhist temple.',
                ),
              ],
            ),
          ],
          weatherAlternativeNote: 'Visit Tokyo Skytree Town if it rains.',
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [aiItineraryRepositoryProvider.overrideWithValue(repo)],
            child: const MaterialApp(
              home: Scaffold(
                body: AiItineraryPreviewSheet(tripId: 'trip-123', plan: plan),
              ),
            ),
          ),
        );

        // Verify header and destination
        expect(find.text('Suggested Itinerary'), findsOneWidget);
        expect(find.text('Tokyo, Japan'), findsOneWidget);

        // Verify non-destructive invariant notice
        expect(find.textContaining('AI Suggests, You Approve'), findsOneWidget);

        // Verify day theme and activity
        expect(
          find.text('Historic Asakusa & Riverside Stroll'),
          findsOneWidget,
        );
        expect(find.text('Asakusa & Taito'), findsOneWidget);
        expect(find.text('Senso-ji Temple'), findsOneWidget);
        expect(find.text('Stroller friendly pavements'), findsOneWidget);
        // Scroll down to check weather note
        await tester.drag(find.byType(ListView), const Offset(0, -300));
        await tester.pumpAndSettle();

        expect(find.textContaining('Visit Tokyo Skytree Town'), findsOneWidget);

        // Verify Action buttons
        expect(find.text('Discard'), findsOneWidget);
        expect(find.text('Accept Full Plan'), findsOneWidget);
      },
    );
  });

  group('AiItineraryPlannerDialog Widget', () {
    testWidgets('renders controls and triggers plan generation', (
      tester,
    ) async {
      final fakeApi = FakeAiApiClient();
      final repo = AiItineraryRepository(apiClient: fakeApi);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [aiItineraryRepositoryProvider.overrideWithValue(repo)],
          child: const MaterialApp(
            home: Scaffold(
              body: AiItineraryPlannerDialog(
                tripId: 'trip-123',
                initialDestination: 'Tokyo, Japan',
                initialDays: 2,
              ),
            ),
          ),
        ),
      );

      // Check title and destination prefill
      expect(find.text('Plan Trip with AI'), findsOneWidget);
      expect(find.text('Tokyo, Japan'), findsOneWidget);

      // Check duration display
      expect(find.text('2 days'), findsOneWidget);

      // Tap duration + button
      await tester.tap(find.byIcon(Icons.add));
      await tester.pump();
      expect(find.text('3 days'), findsOneWidget);

      // Check budget chips
      expect(find.text('Moderate'), findsOneWidget);
      expect(find.text('Luxury'), findsOneWidget);

      // Tap "Preview Plan"
      await tester.tap(find.text('Preview Plan'));
      await tester.pump();

      expect(fakeApi.lastPath, '/trips/trip-123/ai-plan/generate');
      expect(fakeApi.lastData['destination'], 'Tokyo, Japan');
      expect(fakeApi.lastData['duration_days'], 3);
    });
  });
}
