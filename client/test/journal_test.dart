import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapittrip/core/network/api_client.dart';
import 'package:tapittrip/core/storage/token_storage.dart';
import 'package:tapittrip/features/journal/data/journal_repository.dart';
import 'package:tapittrip/features/journal/domain/models/journal_entry.dart';
import 'package:tapittrip/features/journal/presentation/pages/trip_journal_page.dart';
import 'package:tapittrip/features/journal/presentation/providers/journal_provider.dart';
import 'package:tapittrip/features/journal/presentation/widgets/add_journal_entry_sheet.dart';
import 'package:tapittrip/features/journal/presentation/widgets/journal_entry_card.dart';

class FakeJournalApiClient extends ApiClient {
  FakeJournalApiClient() : super(tokenStorage: InMemoryTokenStorage());

  dynamic getResponse;
  dynamic postResponse;
  dynamic patchResponse;
  String? lastGetPath;
  String? lastPostPath;
  dynamic lastPostData;
  String? lastPatchPath;
  dynamic lastPatchData;
  String? lastDeletePath;

  @override
  Future<dynamic> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    lastGetPath = path;
    return getResponse ??
        {
          'data': [
            {
              'id': 'j-1',
              'trip_id': 'trip-1',
              'user_id': 'user-1',
              'author_name': 'Alice Smith',
              'title': 'Sunset at Senso-ji',
              'content': 'Lanterns glowing in the autumn breeze.',
              'entry_date': '2026-11-09',
              'location_name': 'Asakusa, Tokyo',
              'weather': 'sunny',
              'mood': 'amazed',
              'is_shared': false,
              'is_author': true,
              'photos': ['https://example.com/tokyo.jpg'],
            },
            {
              'id': 'j-2',
              'trip_id': 'trip-1',
              'user_id': 'user-2',
              'author_name': 'Bob Lee',
              'title': 'Shinjuku Ramen Run',
              'content': 'Late night ramen with the squad.',
              'entry_date': '2026-11-10',
              'location_name': 'Shinjuku, Tokyo',
              'weather': 'cloudy',
              'mood': 'happy',
              'is_shared': true,
              'is_author': false,
              'photos': <String>[],
            },
          ],
        };
  }

  @override
  Future<dynamic> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    lastPostPath = path;
    lastPostData = data;
    return postResponse ??
        {
          'data': {
            'id': 'j-new',
            'trip_id': 'trip-1',
            'user_id': 'user-1',
            'author_name': 'Alice Smith',
            'title': data is Map ? data['title'] : 'New Entry',
            'content': data is Map ? data['content'] : 'Content',
            'entry_date': data is Map ? data['entry_date'] : '2026-11-09',
            'location_name': data is Map ? data['location_name'] : null,
            'weather': data is Map ? data['weather'] : null,
            'mood': data is Map ? data['mood'] : null,
            'is_shared': data is Map ? (data['is_shared'] ?? false) : false,
            'is_author': true,
            'photos': data is Map ? (data['photos'] ?? []) : [],
          },
        };
  }

  @override
  Future<dynamic> patch(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    lastPatchPath = path;
    lastPatchData = data;
    return patchResponse ??
        {
          'data': {
            'id': 'j-1',
            'trip_id': 'trip-1',
            'user_id': 'user-1',
            'author_name': 'Alice Smith',
            'title': data is Map ? data['title'] ?? 'Updated' : 'Updated',
            'content': 'Lanterns glowing in the autumn breeze.',
            'entry_date': '2026-11-09',
            'is_shared': data is Map ? (data['is_shared'] ?? true) : true,
            'is_author': true,
            'photos': <String>[],
          },
        };
  }

  @override
  Future<dynamic> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    lastDeletePath = path;
    return null;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('JournalEntry Domain Model', () {
    test('parses JSON correctly and converts to JSON', () {
      final json = {
        'id': 'j-100',
        'trip_id': 't-100',
        'user_id': 'u-100',
        'author_name': 'Charlie',
        'title': 'Mount Fuji Hike',
        'content': 'Exhausting but totally worth the view!',
        'entry_date': '2026-11-11',
        'location_name': 'Fujiyoshida',
        'weather': 'sunny',
        'mood': 'adventurous',
        'is_shared': true,
        'is_author': true,
        'photos': ['https://example.com/fuji.jpg'],
        'created_at': '2026-11-11T10:00:00Z',
      };

      final entry = JournalEntry.fromJson(json);
      expect(entry.id, 'j-100');
      expect(entry.authorName, 'Charlie');
      expect(entry.moodEmoji, '🏔️');
      expect(entry.moodLabel, 'Adventurous');
      expect(entry.privacyLabel, 'Shared with Circle');
      expect(entry.isShared, isTrue);
      expect(entry.photos.length, 1);

      final outJson = entry.toJson();
      expect(outJson['title'], 'Mount Fuji Hike');
      expect(outJson['is_shared'], isTrue);
    });

    test('verifies mood emojis and defaults', () {
      const entryAmazed = JournalEntry(
        id: '1',
        tripId: 't',
        userId: 'u',
        title: 'T',
        content: 'C',
        entryDate: '2026-11-09',
        mood: 'amazed',
      );
      expect(entryAmazed.moodEmoji, '🤩');

      const entryHappy = JournalEntry(
        id: '2',
        tripId: 't',
        userId: 'u',
        title: 'T',
        content: 'C',
        entryDate: '2026-11-09',
        mood: 'happy',
      );
      expect(entryHappy.moodEmoji, '😊');

      const entryPeaceful = JournalEntry(
        id: '3',
        tripId: 't',
        userId: 'u',
        title: 'T',
        content: 'C',
        entryDate: '2026-11-09',
        mood: 'peaceful',
      );
      expect(entryPeaceful.moodEmoji, '😌');

      const entryDefault = JournalEntry(
        id: '4',
        tripId: 't',
        userId: 'u',
        title: 'T',
        content: 'C',
        entryDate: '2026-11-09',
      );
      expect(entryDefault.moodEmoji, '✨');
      expect(entryDefault.privacyLabel, 'Only You');
    });
  });

  group('JournalRepository', () {
    late FakeJournalApiClient apiClient;
    late FlutterSecureStorage storage;
    late JournalRepository repository;

    setUp(() {
      FlutterSecureStorage.setMockInitialValues({});
      apiClient = FakeJournalApiClient();
      storage = const FlutterSecureStorage();
      repository = JournalRepository(apiClient: apiClient, storage: storage);
    });

    test('getJournalEntries fetches and caches entries', () async {
      final entries = await repository.getJournalEntries('trip-1');
      expect(entries.length, 2);
      expect(entries[0].title, 'Sunset at Senso-ji');
      expect(apiClient.lastGetPath, '/trips/trip-1/journal');

      // Verify cached in secure storage
      final cached = await storage.read(key: 'cached_journal_trip-1');
      expect(cached, isNotNull);
      expect(cached, contains('Sunset at Senso-ji'));
    });

    test('getJournalEntries falls back to cache on network failure', () async {
      await storage.write(
        key: 'cached_journal_trip-offline',
        value: '[{"id":"j-cached","trip_id":"trip-offline","user_id":"u-1","title":"Cached Memory","content":"Read offline","entry_date":"2026-11-09","is_shared":false,"is_author":true,"photos":[]}]',
      );

      // Force API failure
      apiClient.getResponse = Exception('Network error');

      final entries = await repository.getJournalEntries('trip-offline');
      expect(entries.length, 1);
      expect(entries[0].title, 'Cached Memory');
    });

    test('createJournalEntry sends correct payload', () async {
      final entry = await repository.createJournalEntry(
        'trip-1',
        title: 'Kyoto Bamboo Forest',
        content: 'Peaceful morning walk through Arashiyama.',
        entryDate: '2026-11-12',
        locationName: 'Kyoto',
        weather: 'cloudy',
        mood: 'peaceful',
        isShared: false,
      );

      expect(entry.title, 'Kyoto Bamboo Forest');
      expect(apiClient.lastPostPath, '/trips/trip-1/journal');
      expect((apiClient.lastPostData as Map)['is_shared'], isFalse);
    });

    test('updateJournalEntry and deleteJournalEntry work correctly', () async {
      final updated = await repository.updateJournalEntry(
        'j-1',
        title: 'Updated Sunset',
        isShared: true,
      );
      expect(updated.isShared, isTrue);
      expect(apiClient.lastPatchPath, '/journal-entries/j-1');

      await repository.deleteJournalEntry('j-1');
      expect(apiClient.lastDeletePath, '/journal-entries/j-1');
    });
  });

  group('TripJournalNotifier State Management', () {
    test('manages journal entries and toggles sharing', () async {
      FlutterSecureStorage.setMockInitialValues({});
      final apiClient = FakeJournalApiClient();
      final repo = JournalRepository(apiClient: apiClient);

      final container = ProviderContainer(
        overrides: [journalRepositoryProvider.overrideWithValue(repo)],
      );

      // Read initial state
      final entries = await container.read(
        tripJournalProvider('trip-1').future,
      );
      expect(entries.length, 2);

      // Toggle share on first entry
      final notifier = container.read(tripJournalProvider('trip-1').notifier);
      final toggled = await notifier.toggleShare(entries[0]);
      expect(toggled.isShared, isTrue);

      // Add a new entry
      final created = await notifier.createEntry(
        title: 'New Memory',
        content: 'Lovely experience',
        entryDate: '2026-11-15',
        isShared: false,
      );
      expect(created.title, 'New Memory');

      final currentList = container
          .read(tripJournalProvider('trip-1'))
          .asData!
          .value;
      expect(currentList.length, 3);
      expect(currentList[0].title, 'New Memory');

      // Delete an entry
      await notifier.deleteEntry('j-new');
      final afterDelete = container
          .read(tripJournalProvider('trip-1'))
          .asData!
          .value;
      expect(afterDelete.length, 2);
    });
  });

  group('Journal Presentation Widgets', () {
    testWidgets(
      'JournalEntryCard displays author, mood, title, and privacy badge',
      (tester) async {
        const entry = JournalEntry(
          id: 'j-1',
          tripId: 't-1',
          userId: 'u-1',
          authorName: 'Alice',
          title: 'Sunset at Senso-ji',
          content: 'Magical lantern reflection in the evening light.',
          entryDate: '2026-11-09',
          locationName: 'Asakusa',
          weather: 'sunny',
          mood: 'amazed',
          isShared: false,
          isAuthor: true,
          photos: ['https://example.com/sensoji.jpg'],
        );

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(body: JournalEntryCard(entry: entry)),
          ),
        );

        expect(find.text('Sunset at Senso-ji'), findsOneWidget);
        expect(find.text('Alice'), findsOneWidget);
        expect(find.text('Only You'), findsOneWidget);
        expect(find.text('Amazed'), findsOneWidget);
        expect(find.text('sunny'), findsOneWidget);
        expect(find.text('Asakusa'), findsOneWidget);
        expect(
          find.text('Magical lantern reflection in the evening light.'),
          findsOneWidget,
        );
      },
    );

    testWidgets('AddJournalEntrySheet validates and submits', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      String? savedTitle;
      String? savedContent;
      bool? savedIsShared;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AddJournalEntrySheet(
              tripId: 't-1',
              onSave:
                  ({
                    required String title,
                    required String content,
                    required String entryDate,
                    String? locationName,
                    String? weather,
                    String? mood,
                    required bool isShared,
                    List<String>? photos,
                  }) async {
                    savedTitle = title;
                    savedContent = content;
                    savedIsShared = isShared;
                  },
            ),
          ),
        ),
      );

      // Verify privacy default is private
      expect(find.text('Keep Private (Only You)'), findsOneWidget);

      // Try saving without entering title/content (validation error)
      await tester.tap(find.text('Save Travel Memory'));
      await tester.pumpAndSettle();
      expect(find.text('Please enter a title'), findsOneWidget);

      // Enter title and content
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Reflection Title *'),
        'My First Day in Tokyo',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Reflection Notes *'),
        'Walked around Shibuya and crossed the famous intersection.',
      );

      // Toggle share switch
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();
      expect(find.text('Share with Circle'), findsOneWidget);

      // Submit
      await tester.tap(find.text('Save Travel Memory'));
      await tester.pumpAndSettle();

      expect(savedTitle, 'My First Day in Tokyo');
      expect(
        savedContent,
        'Walked around Shibuya and crossed the famous intersection.',
      );
      expect(savedIsShared, isTrue);
    });

    testWidgets('TripJournalPage renders stats, filters, and entries', (
      tester,
    ) async {
      FlutterSecureStorage.setMockInitialValues({});
      final apiClient = FakeJournalApiClient();
      final repo = JournalRepository(apiClient: apiClient);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [journalRepositoryProvider.overrideWithValue(repo)],
          child: const MaterialApp(home: TripJournalPage(tripId: 'trip-1')),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Travel Memories & Journal'), findsOneWidget);
      expect(find.text('Trip Travel Log'), findsOneWidget);
      expect(find.text('Total Moments'), findsOneWidget);
      expect(find.text('Shared Circle'), findsOneWidget);
      expect(find.text('Only You'), findsNWidgets(2));

      // Check entries are rendered
      expect(find.text('Sunset at Senso-ji'), findsOneWidget);
      expect(find.text('Shinjuku Ramen Run'), findsOneWidget);

      // Test filter by Shared
      await tester.tap(find.text('Shared (1)'));
      await tester.pumpAndSettle();

      expect(find.text('Shinjuku Ramen Run'), findsOneWidget);
      expect(find.text('Sunset at Senso-ji'), findsNothing);

      // Test filter by Only You
      await tester.tap(find.text('Only You (1)'));
      await tester.pumpAndSettle();

      expect(find.text('Sunset at Senso-ji'), findsOneWidget);
      expect(find.text('Shinjuku Ramen Run'), findsNothing);

      // Verify FAB
      expect(find.text('New Memory'), findsOneWidget);
    });
  });
}
