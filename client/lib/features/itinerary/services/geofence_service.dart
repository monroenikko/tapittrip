import 'dart:math' as math;

import '../domain/models/itinerary_item.dart';

class GeofenceService {
  const GeofenceService();

  static const double earthRadiusMeters = 6371000.0;

  /// Calculate Haversine distance in meters between two lat/lng coordinates.
  double calculateDistanceMeters(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    final dLat = _degToRad(lat2 - lat1);
    final dLon = _degToRad(lon2 - lon1);

    final a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degToRad(lat1)) *
            math.cos(_degToRad(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusMeters * c;
  }

  /// Check if user's coordinates are within [radiusMeters] of target.
  bool checkProximity({
    required double userLat,
    required double userLng,
    required double targetLat,
    required double targetLng,
    double radiusMeters = 250.0,
  }) {
    final distance = calculateDistanceMeters(
      userLat,
      userLng,
      targetLat,
      targetLng,
    );
    return distance <= radiusMeters;
  }

  /// Find the first planned itinerary stop within proximity of the user's location.
  ItineraryItem? findNearbyUpcomingItem({
    required double userLat,
    required double userLng,
    required List<ItineraryItem> items,
    double radiusMeters = 250.0,
  }) {
    for (final item in items) {
      if (item.status == 'visited') {
        continue;
      }

      final place = item.place;
      if (place == null || place.latitude == null || place.longitude == null) {
        continue;
      }

      final inProximity = checkProximity(
        userLat: userLat,
        userLng: userLng,
        targetLat: place.latitude!,
        targetLng: place.longitude!,
        radiusMeters: radiusMeters,
      );

      if (inProximity) {
        return item;
      }
    }

    return null;
  }

  double _degToRad(double deg) => deg * (math.pi / 180.0);
}
