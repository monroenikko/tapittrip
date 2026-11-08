import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapittrip/core/theme/app_theme.dart';
import 'package:tapittrip/features/itinerary/domain/models/itinerary_item.dart';
import 'package:tapittrip/features/itinerary/domain/models/place.dart';
import 'package:tapittrip/features/itinerary/domain/models/visit_event.dart';
import 'package:tapittrip/features/itinerary/presentation/widgets/arrival_suggestion_dialog.dart';
import 'package:tapittrip/features/itinerary/services/geofence_service.dart';

void main() {
  group('VisitEvent Model', () {
    test('parses from JSON and serializes correctly', () {
      final json = {
        'id': 'event-1',
        'itinerary_item_id': 'item-100',
        'user_id': 'user-200',
        'event_type': 'confirmed',
        'method': 'geofence',
        'detected_at': '2026-12-01T10:15:00Z',
        'accuracy_m': 12.5,
      };

      final event = VisitEvent.fromJson(json);

      expect(event.id, 'event-1');
      expect(event.itineraryItemId, 'item-100');
      expect(event.isConfirmed, isTrue);
      expect(event.isGeofence, isTrue);
      expect(event.accuracyM, 12.5);

      final serialized = event.toJson();
      expect(serialized['event_type'], 'confirmed');
      expect(serialized['method'], 'geofence');
    });
  });

  group('GeofenceService', () {
    const service = GeofenceService();

    test('calculateDistanceMeters measures distance accurately', () {
      // Tokyo Station coordinates: 35.681236, 139.767125
      const tokyoStationLat = 35.681236;
      const tokyoStationLng = 139.767125;

      // Point ~150 meters north: 35.682586, 139.767125
      const nearbyLat = 35.682586;
      const nearbyLng = 139.767125;

      final distance = service.calculateDistanceMeters(
        tokyoStationLat,
        tokyoStationLng,
        nearbyLat,
        nearbyLng,
      );

      expect(distance, greaterThan(140));
      expect(distance, lessThan(160));

      // Same location is 0m
      expect(
        service.calculateDistanceMeters(
          tokyoStationLat,
          tokyoStationLng,
          tokyoStationLat,
          tokyoStationLng,
        ),
        0.0,
      );
    });

    test('checkProximity respects 250m radius', () {
      const centerLat = 35.681236;
      const centerLng = 139.767125;

      // ~100m away
      const insideLat = 35.682000;
      const insideLng = 139.767125;

      // ~1km away
      const farLat = 35.690000;
      const farLng = 139.767125;

      expect(
        service.checkProximity(
          userLat: insideLat,
          userLng: insideLng,
          targetLat: centerLat,
          targetLng: centerLng,
        ),
        isTrue,
      );

      expect(
        service.checkProximity(
          userLat: farLat,
          userLng: farLng,
          targetLat: centerLat,
          targetLng: centerLng,
        ),
        isFalse,
      );
    });

    test('findNearbyUpcomingItem finds stop and skips visited stops', () {
      final visitedItem = ItineraryItem(
        id: 'item-visited',
        tripId: 'trip-1',
        title: 'Already Visited Cafe',
        status: 'visited',
        place: const Place(
          id: 'place-1',
          name: 'Cafe',
          latitude: 35.681500,
          longitude: 139.767125,
        ),
      );

      final plannedFarItem = ItineraryItem(
        id: 'item-far',
        tripId: 'trip-1',
        title: 'Distant Museum',
        status: 'planned',
        place: const Place(
          id: 'place-2',
          name: 'Museum',
          latitude: 35.750000,
          longitude: 139.767125,
        ),
      );

      final plannedNearbyItem = ItineraryItem(
        id: 'item-near',
        tripId: 'trip-1',
        title: 'Senso-ji Temple',
        status: 'planned',
        place: const Place(
          id: 'place-3',
          name: 'Senso-ji',
          latitude: 35.681800,
          longitude: 139.767125,
        ),
      );

      final found = service.findNearbyUpcomingItem(
        userLat: 35.681700,
        userLng: 139.767125,
        items: [visitedItem, plannedFarItem, plannedNearbyItem],
      );

      expect(found, isNotNull);
      expect(found!.id, 'item-near');
      expect(found.title, 'Senso-ji Temple');
    });
  });

  group('ArrivalSuggestionDialog Widget', () {
    testWidgets('renders arrival prompt and invokes onConfirm', (tester) async {
      bool confirmed = false;
      bool dismissed = false;

      final item = ItineraryItem(
        id: 'item-1',
        tripId: 'trip-1',
        title: 'Tokyo Skytree Observatory',
        status: 'planned',
        place: const Place(
          id: 'p-1',
          name: 'Tokyo Skytree',
          formattedAddress: '1-1-2 Oshiage, Sumida City, Tokyo',
          latitude: 35.7100,
          longitude: 139.8107,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  ArrivalSuggestionDialog.show(
                    context,
                    item: item,
                    distanceMeters: 180,
                    onConfirm: () => confirmed = true,
                    onDismiss: () => dismissed = true,
                  );
                },
                child: const Text('Open Arrival Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Arrival Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Arrival Detected'), findsOneWidget);
      expect(find.text('Tokyo Skytree Observatory'), findsOneWidget);
      expect(find.text('1-1-2 Oshiage, Sumida City, Tokyo'), findsOneWidget);
      expect(find.text('📍 ~180 meters away'), findsOneWidget);
      expect(find.text('Mark Visited'), findsOneWidget);
      expect(find.text('Not Yet'), findsOneWidget);

      // Tap Mark Visited
      await tester.tap(find.text('Mark Visited'));
      await tester.pumpAndSettle();

      expect(confirmed, isTrue);
      expect(dismissed, isFalse);
      expect(find.text('Arrival Detected'), findsNothing);
    });

    testWidgets('tapping Not Yet dismisses without confirmation', (
      tester,
    ) async {
      bool confirmed = false;
      bool dismissed = false;

      final item = ItineraryItem(
        id: 'item-1',
        tripId: 'trip-1',
        title: 'Meiji Shrine',
        status: 'planned',
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  ArrivalSuggestionDialog.show(
                    context,
                    item: item,
                    onConfirm: () => confirmed = true,
                    onDismiss: () => dismissed = true,
                  );
                },
                child: const Text('Open Arrival Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Arrival Dialog'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Not Yet'));
      await tester.pumpAndSettle();

      expect(confirmed, isFalse);
      expect(dismissed, isTrue);
      expect(find.text('Arrival Detected'), findsNothing);
    });
  });
}
