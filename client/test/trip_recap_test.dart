import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapittrip/core/network/api_client.dart';
import 'package:tapittrip/core/storage/token_storage.dart';
import 'package:tapittrip/features/journal/data/journal_repository.dart';
import 'package:tapittrip/features/journal/domain/models/trip_recap.dart';
import 'package:tapittrip/features/journal/presentation/pages/trip_recap_page.dart';

class FakeRecapApiClient extends ApiClient {
  FakeRecapApiClient() : super(tokenStorage: InMemoryTokenStorage());

  dynamic getResponse;
  String? lastGetPath;
  bool shouldThrow = false;

  @override
  Future<dynamic> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    lastGetPath = path;
    if (shouldThrow) {
      throw Exception('Network connection error');
    }

    return getResponse ??
        {
          'data': {
            'trip': {
              'id': 'trip-tokyo',
              'title': 'Tokyo Golden Journey',
              'destination': 'Tokyo, Japan',
              'start_date': '2026-11-10',
              'end_date': '2026-11-16',
              'duration_days': 7,
              'status': 'completed',
            },
            'highlights': {
              'total_places_visited': 5,
              'total_places_planned': 8,
              'completion_rate_percentage': 63,
              'total_stays': 2,
              'total_nights': 6,
              'total_companions': 3,
            },
            'story_album': {
              'total_photos': 2,
              'photos': [
                {
                  'url': 'https://example.com/sensoji.jpg',
                  'caption': 'Senso-ji Morning Glow',
                  'date': '2026-11-11',
                  'author_name': 'Alice Wonder',
                  'mood': 'amazed',
                  'location_name': 'Asakusa',
                },
                {
                  'url': 'https://example.com/ramen.jpg',
                  'caption': 'Late Night Ichiran',
                  'date': '2026-11-12',
                  'author_name': 'Bob Builder',
                  'mood': 'happy',
                  'location_name': 'Shinjuku',
                },
              ],
              'moments': [
                {
                  'id': 'm-1',
                  'title': 'Senso-ji Morning Glow',
                  'content': 'Mesmerizing peaceful morning walk.',
                  'author_name': 'Alice Wonder',
                  'author_avatar_url': null,
                  'entry_date': '2026-11-11',
                  'mood': 'amazed',
                  'mood_emoji': '🤩',
                  'weather': 'sunny',
                  'location_name': 'Asakusa',
                  'cover_photo': 'https://example.com/sensoji.jpg',
                  'is_shared': true,
                },
              ],
              'mood_breakdown': {'amazed': 3, 'happy': 4, 'peaceful': 2},
              'top_mood': 'happy',
            },
            'expense_summary': {
              'currency': 'JPY',
              'total_spent_minor': 154200,
              'formatted_total_spent': '¥154,200',
              'expenses_count': 9,
              'top_category': 'dining',
              'has_budget': true,
              'budget_utilization_percent': 77.1,
            },
          },
        };
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
  });

  final sampleRecapJson = {
    'trip': {
      'id': 'trip-tokyo',
      'title': 'Tokyo Golden Journey',
      'destination': 'Tokyo, Japan',
      'start_date': '2026-11-10',
      'end_date': '2026-11-16',
      'duration_days': 7,
      'status': 'completed',
    },
    'highlights': {
      'total_places_visited': 5,
      'total_places_planned': 8,
      'completion_rate_percentage': 63,
      'total_stays': 2,
      'total_nights': 6,
      'total_companions': 3,
    },
    'story_album': {
      'total_photos': 2,
      'photos': [
        {
          'url': 'https://example.com/sensoji.jpg',
          'caption': 'Senso-ji Morning Glow',
          'date': '2026-11-11',
          'author_name': 'Alice Wonder',
          'mood': 'amazed',
          'location_name': 'Asakusa',
        },
      ],
      'moments': [
        {
          'id': 'm-1',
          'title': 'Senso-ji Morning Glow',
          'content': 'Mesmerizing peaceful morning walk.',
          'author_name': 'Alice Wonder',
          'author_avatar_url': null,
          'entry_date': '2026-11-11',
          'mood': 'amazed',
          'mood_emoji': '🤩',
          'weather': 'sunny',
          'location_name': 'Asakusa',
          'cover_photo': 'https://example.com/sensoji.jpg',
          'is_shared': true,
        },
      ],
      'mood_breakdown': {'amazed': 3, 'happy': 4},
      'top_mood': 'happy',
    },
    'expense_summary': {
      'currency': 'JPY',
      'total_spent_minor': 154200,
      'formatted_total_spent': '¥154,200',
      'expenses_count': 9,
      'top_category': 'dining',
      'has_budget': true,
      'budget_utilization_percent': 77.1,
    },
  };

  group('TripRecap Domain Model', () {
    test('parses JSON correctly and converts back to JSON', () {
      final recap = TripRecap.fromJson(sampleRecapJson);

      expect(recap.trip.id, 'trip-tokyo');
      expect(recap.trip.title, 'Tokyo Golden Journey');
      expect(recap.trip.destination, 'Tokyo, Japan');
      expect(recap.trip.durationDays, 7);
      expect(recap.trip.status, 'completed');

      expect(recap.highlights.totalPlacesVisited, 5);
      expect(recap.highlights.totalPlacesPlanned, 8);
      expect(recap.highlights.completionRatePercentage, 63);
      expect(recap.highlights.totalStays, 2);
      expect(recap.highlights.totalNights, 6);
      expect(recap.highlights.totalCompanions, 3);

      expect(recap.storyAlbum.totalPhotos, 2);
      expect(recap.storyAlbum.photos.length, 1);
      expect(recap.storyAlbum.photos[0].caption, 'Senso-ji Morning Glow');
      expect(recap.storyAlbum.photos[0].authorName, 'Alice Wonder');
      expect(recap.storyAlbum.moments.length, 1);
      expect(recap.storyAlbum.moments[0].title, 'Senso-ji Morning Glow');
      expect(recap.storyAlbum.moments[0].moodEmoji, '🤩');
      expect(recap.storyAlbum.topMood, 'happy');
      expect(recap.storyAlbum.topMoodEmoji, '😊');
      expect(recap.storyAlbum.moodBreakdown['happy'], 4);

      expect(recap.expenseSummary.currency, 'JPY');
      expect(recap.expenseSummary.totalSpentMinor, 154200);
      expect(recap.expenseSummary.formattedTotalSpent, '¥154,200');
      expect(recap.expenseSummary.expensesCount, 9);
      expect(recap.expenseSummary.topCategory, 'dining');
      expect(recap.expenseSummary.hasBudget, isTrue);

      final json = recap.toJson();
      expect(json['trip']['title'], 'Tokyo Golden Journey');
      expect(json['highlights']['total_places_visited'], 5);
    });

    test('handles empty or null attributes gracefully without exceptions', () {
      final emptyJson = <String, dynamic>{
        'trip': {},
        'highlights': {},
        'story_album': {},
        'expense_summary': {},
      };

      final recap = TripRecap.fromJson(emptyJson);

      expect(recap.trip.title, '');
      expect(recap.highlights.totalPlacesVisited, 0);
      expect(recap.highlights.totalCompanions, 1);
      expect(recap.storyAlbum.totalPhotos, 0);
      expect(recap.storyAlbum.photos, isEmpty);
      expect(recap.storyAlbum.moments, isEmpty);
      expect(recap.storyAlbum.topMood, isNull);
      expect(recap.storyAlbum.topMoodEmoji, isNull);
      expect(recap.expenseSummary.totalSpentMinor, 0);
    });
  });

  group('TripRecap Repository & Cache', () {
    test('fetches recap and caches response to secure storage', () async {
      final fakeApi = FakeRecapApiClient();
      const storage = FlutterSecureStorage();
      final repo = JournalRepository(apiClient: fakeApi, storage: storage);

      final recap = await repo.getTripRecap('trip-tokyo');

      expect(fakeApi.lastGetPath, '/trips/trip-tokyo/recap');
      expect(recap.trip.title, 'Tokyo Golden Journey');

      final cached = await storage.read(key: 'cached_recap_trip-tokyo');
      expect(cached, isNotNull);
      final decoded = jsonDecode(cached!) as Map<String, dynamic>;
      expect(decoded['trip']['title'], 'Tokyo Golden Journey');
    });

    test('falls back to secure storage cache on network failure', () async {
      final fakeApi = FakeRecapApiClient();
      const storage = FlutterSecureStorage();
      final repo = JournalRepository(apiClient: fakeApi, storage: storage);

      // Pre-seed storage cache
      await storage.write(
        key: 'cached_recap_offline-trip',
        value: jsonEncode(sampleRecapJson),
      );

      // Make API throw network error
      fakeApi.shouldThrow = true;

      final recap = await repo.getTripRecap('offline-trip');

      expect(recap.trip.title, 'Tokyo Golden Journey');
      expect(recap.highlights.totalStays, 2);
    });
  });

  group('TripRecapPage Widget', () {
    testWidgets('renders recap details, stats grid, and story album', (
      tester,
    ) async {
      final fakeApi = FakeRecapApiClient();
      const storage = FlutterSecureStorage();
      final repo = JournalRepository(apiClient: fakeApi, storage: storage);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [journalRepositoryProvider.overrideWithValue(repo)],
          child: const MaterialApp(home: TripRecapPage(tripId: 'trip-tokyo')),
        ),
      );

      // Initial loading
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.pumpAndSettle();

      // Hero Showcase
      expect(find.text('Tokyo Golden Journey'), findsOneWidget);
      expect(find.text('Tokyo, Japan'), findsOneWidget);
      expect(find.text('7 Days'), findsOneWidget);
      expect(find.text('COMPLETED'), findsOneWidget);

      // Highlights Stat Grid
      expect(find.text('Trip Highlights'), findsOneWidget);
      expect(find.text('5 / 8'), findsOneWidget);
      expect(find.text('63% Stops Visited'), findsOneWidget);
      expect(find.text('2 Stays'), findsOneWidget);
      expect(find.text('6 Nights Lodging'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
      expect(find.text('Circle Companions'), findsOneWidget);
      expect(find.text('¥154,200'), findsOneWidget);
      expect(find.text('Top: dining'), findsOneWidget);

      // Photo Story Album
      expect(find.text('📸 Photo Story Album'), findsOneWidget);
      expect(find.text('2 Photos'), findsOneWidget);

      // Emotional Journey
      expect(find.text('✨ Emotional Journey'), findsOneWidget);
      expect(find.text('Top Mood: HAPPY'), findsOneWidget);
      expect(find.text('Happy (4)'), findsOneWidget);
      expect(find.text('Amazed (3)'), findsOneWidget);

      // Top Moments
      expect(find.text('📖 Top Moments & Stories'), findsOneWidget);
      expect(find.text('Senso-ji Morning Glow'), findsWidgets);
      expect(find.text('Mesmerizing peaceful morning walk.'), findsOneWidget);

      // Action Button
      expect(find.text('Open Travel Journal & Memories'), findsOneWidget);
    });

    testWidgets('renders retry button when API fails and no cache exists', (
      tester,
    ) async {
      final fakeApi = FakeRecapApiClient()..shouldThrow = true;
      const storage = FlutterSecureStorage();
      final repo = JournalRepository(apiClient: fakeApi, storage: storage);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [journalRepositoryProvider.overrideWithValue(repo)],
          child: const MaterialApp(home: TripRecapPage(tripId: 'broken-trip')),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.textContaining('Failed to load trip recap'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Retry'), findsOneWidget);
    });
  });
}
