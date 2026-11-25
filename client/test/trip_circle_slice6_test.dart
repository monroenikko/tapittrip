import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapittrip/features/circles/domain/models/trip_location_share.dart';
import 'package:tapittrip/features/circles/presentation/providers/trip_circle_provider.dart';
import 'package:tapittrip/features/circles/presentation/widgets/location_sharing_section.dart';

class _FakeLocationShareNotifier extends TripLocationShareNotifier {
  _FakeLocationShareNotifier(super.tripId, this.initialShare);

  final TripLocationShare initialShare;

  @override
  Future<TripLocationShare> build() async {
    return initialShare;
  }

  @override
  Future<TripLocationShare> enable({
    int durationMinutes = 60,
    String audience = 'circle',
    required double latitude,
    required double longitude,
  }) async {
    final updated = state.asData!.value.copyWith(
      enabled: true,
      isActive: true,
      durationMinutes: durationMinutes,
      audience: audience,
      latitude: latitude,
      longitude: longitude,
      lastSharedAt: DateTime.now(),
      expiresAt: DateTime.now().add(Duration(minutes: durationMinutes)),
    );
    state = AsyncData(updated);
    return updated;
  }

  @override
  Future<TripLocationShare> disable() async {
    final updated = state.asData!.value.copyWith(
      enabled: false,
      isActive: false,
    );
    state = AsyncData(updated);
    return updated;
  }
}

void main() {
  group('TripLocationShare Model', () {
    test('serializes and deserializes accurately', () {
      final json = {
        'id': 'share-1',
        'trip_id': 'trip-100',
        'user_id': 'user-1',
        'user_name': 'Ken',
        'enabled': true,
        'is_active': true,
        'is_stale': false,
        'duration_minutes': 120,
        'expires_at': '2026-11-11T12:00:00.000Z',
        'audience': 'circle',
        'latitude': 35.6762,
        'longitude': 139.6503,
        'last_shared_at': '2026-11-11T10:00:00.000Z',
      };

      final share = TripLocationShare.fromJson(json);

      expect(share.id, 'share-1');
      expect(share.tripId, 'trip-100');
      expect(share.userName, 'Ken');
      expect(share.enabled, isTrue);
      expect(share.isActive, isTrue);
      expect(share.isStale, isFalse);
      expect(share.durationMinutes, 120);
      expect(share.latitude, 35.6762);
      expect(share.longitude, 139.6503);

      final out = share.toJson();
      expect(out['id'], 'share-1');
      expect(out['trip_id'], 'trip-100');
      expect(out['duration_minutes'], 120);
      expect(out['latitude'], 35.6762);
    });

    test('defaults to inactive and stale when null', () {
      final share = TripLocationShare.fromJson({});
      expect(share.enabled, isFalse);
      expect(share.isActive, isFalse);
      expect(share.isStale, isTrue);
      expect(share.durationMinutes, 60);
      expect(share.audience, 'circle');
    });
  });

  group('LocationSharingSection Widget', () {
    testWidgets('renders off by default and allows enabling sharing', (
      tester,
    ) async {
      const tripId = 'trip-123';
      final defaultShare = TripLocationShare(
        id: 'share-1',
        tripId: tripId,
        userId: 'user-me',
        userName: 'Me',
        enabled: false,
        isActive: false,
        isStale: true,
        durationMinutes: 60,
      );

      final otherMembersShares = [
        TripLocationShare(
          id: 'share-2',
          tripId: tripId,
          userId: 'user-bob',
          userName: 'Bob',
          enabled: true,
          isActive: true,
          isStale: false,
          durationMinutes: 60,
          latitude: 35.6800,
          longitude: 139.7600,
          lastSharedAt: DateTime.now(),
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            tripLocationShareProvider(tripId).overrideWith(
              () => _FakeLocationShareNotifier(tripId, defaultShare),
            ),
            activeLocationSharesProvider(tripId)
                .overrideWith((ref) async => otherMembersShares),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: LocationSharingSection(tripId: tripId),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Meeting Assistance'), findsOneWidget);
      expect(find.text('Share My Location'), findsOneWidget);
      expect(find.text('Sharing is currently off'), findsOneWidget);

      // Verify other member is visible
      expect(find.text('Circle Members Sharing a Location'), findsOneWidget);
      expect(find.text('Bob'), findsOneWidget);
      expect(find.byIcon(Icons.directions_outlined), findsOneWidget);

      // Toggle switch to ON
      final switchFinder = find.byType(Switch);
      expect(switchFinder, findsOneWidget);
      await tester.tap(switchFinder);
      await tester.pumpAndSettle();

      expect(find.text('Share a map pin'), findsOneWidget);
      expect(
        find.textContaining(
          'TapItTrip does not send a placeholder or synthetic location.',
        ),
        findsOneWidget,
      );
      await tester.enterText(find.byType(TextFormField).at(0), '35.6762');
      await tester.enterText(find.byType(TextFormField).at(1), '139.6503');
      await tester.tap(find.text('Start sharing'));
      await tester.pumpAndSettle();

      // Once explicitly enabled, duration chips and audience selector appear.
      expect(find.text('Duration'), findsOneWidget);
      expect(find.text('1 hr'), findsOneWidget);
      expect(find.text('4 hrs'), findsOneWidget);
      expect(find.text('Audience'), findsOneWidget);
      expect(find.text('Entire Circle'), findsOneWidget);
      expect(find.text('Organizer Only'), findsOneWidget);
    });
  });
}
