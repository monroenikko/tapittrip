import 'package:flutter/material.dart';

import '../../../itinerary/domain/models/place.dart';
import 'luggage_profile.dart';

class Stay {
  const Stay({
    required this.id,
    required this.tripId,
    this.placeId,
    required this.name,
    this.stayType = 'hotel',
    this.address,
    this.latitude,
    this.longitude,
    this.checkInAt,
    this.checkOutAt,
    this.timezone = 'UTC',
    this.phone,
    this.bookingReference,
    this.notes,
    this.luggageProfile,
    this.version = 1,
    this.googleMapsUrl,
    this.googleMapsDirectionsUrl,
    this.place,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String tripId;
  final String? placeId;
  final String name;
  final String stayType; // hotel, hostel, rental, friends_family
  final String? address;
  final double? latitude;
  final double? longitude;
  final DateTime? checkInAt;
  final DateTime? checkOutAt;
  final String timezone;
  final String? phone;
  final String? bookingReference;
  final String? notes;
  final LuggageProfile? luggageProfile;
  final int version;
  final String? googleMapsUrl;
  final String? googleMapsDirectionsUrl;
  final Place? place;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  String get stayTypeTitle {
    switch (stayType.toLowerCase()) {
      case 'hostel':
        return 'Hostel';
      case 'rental':
        return 'Vacation Rental';
      case 'friends_family':
        return 'Friends & Family';
      case 'hotel':
      default:
        return 'Hotel';
    }
  }

  IconData get stayTypeIcon {
    switch (stayType.toLowerCase()) {
      case 'hostel':
        return Icons.holiday_village_rounded;
      case 'rental':
        return Icons.home_work_rounded;
      case 'friends_family':
        return Icons.people_outline_rounded;
      case 'hotel':
      default:
        return Icons.hotel_rounded;
    }
  }

  int? get durationNights {
    if (checkInAt == null || checkOutAt == null) return null;
    final inDate = DateTime(checkInAt!.year, checkInAt!.month, checkInAt!.day);
    final outDate =
        DateTime(checkOutAt!.year, checkOutAt!.month, checkOutAt!.day);
    final diff = outDate.difference(inDate).inDays;
    return diff > 0 ? diff : 1;
  }

  String? get stayDurationSummary {
    final nights = durationNights;
    if (nights == null) return null;
    return nights == 1 ? '1 Night' : '$nights Nights';
  }

  String? get checkInFormatted {
    if (checkInAt == null) return null;
    return '${_monthName(checkInAt!.month)} ${checkInAt!.day}, ${checkInAt!.year}';
  }

  String? get checkOutFormatted {
    if (checkOutAt == null) return null;
    return '${_monthName(checkOutAt!.month)} ${checkOutAt!.day}, ${checkOutAt!.year}';
  }

  String? get dateRangeFormatted {
    if (checkInAt == null && checkOutAt == null) return null;
    if (checkInAt != null && checkOutAt == null) {
      return 'Check-in: ${_monthName(checkInAt!.month)} ${checkInAt!.day}';
    }
    if (checkInAt == null && checkOutAt != null) {
      return 'Check-out: ${_monthName(checkOutAt!.month)} ${checkOutAt!.day}';
    }
    final inM = _monthName(checkInAt!.month);
    final outM = _monthName(checkOutAt!.month);
    final nights = stayDurationSummary;
    if (inM == outM) {
      final range = '$inM ${checkInAt!.day} – ${checkOutAt!.day}';
      return nights != null ? '$range • $nights' : range;
    }
    final range = '$inM ${checkInAt!.day} – $outM ${checkOutAt!.day}';
    return nights != null ? '$range • $nights' : range;
  }

  static String _monthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    if (month >= 1 && month <= 12) return months[month - 1];
    return '';
  }

  factory Stay.fromJson(Map<String, dynamic> json) {
    return Stay(
      id: json['id'] as String? ?? '',
      tripId: json['trip_id'] as String? ?? '',
      placeId: json['place_id'] as String?,
      name: json['name'] as String? ?? '',
      stayType: json['stay_type'] as String? ?? 'hotel',
      address: json['address'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      checkInAt: DateTime.tryParse(json['check_in_at'] as String? ?? ''),
      checkOutAt: DateTime.tryParse(json['check_out_at'] as String? ?? ''),
      timezone: json['timezone'] as String? ?? 'UTC',
      phone: json['phone'] as String?,
      bookingReference: json['booking_reference'] as String?,
      notes: json['notes'] as String?,
      luggageProfile: json['luggage_profile'] != null
          ? LuggageProfile.fromJson(
              json['luggage_profile'] as Map<String, dynamic>,
            )
          : null,
      version: (json['version'] as num?)?.toInt() ?? 1,
      googleMapsUrl: json['google_maps_url'] as String?,
      googleMapsDirectionsUrl: json['google_maps_directions_url'] as String?,
      place: json['place'] != null
          ? Place.fromJson(json['place'] as Map<String, dynamic>)
          : null,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? ''),
      updatedAt: DateTime.tryParse(json['updated_at'] as String? ?? ''),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'trip_id': tripId,
      'place_id': placeId,
      'name': name,
      'stay_type': stayType,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'check_in_at': checkInAt?.toIso8601String(),
      'check_out_at': checkOutAt?.toIso8601String(),
      'timezone': timezone,
      'phone': phone,
      'booking_reference': bookingReference,
      'notes': notes,
      'luggage_profile': luggageProfile?.toJson(),
      'version': version,
      'google_maps_url': googleMapsUrl,
      'google_maps_directions_url': googleMapsDirectionsUrl,
      'place': place?.toJson(),
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  Stay copyWith({
    String? id,
    String? tripId,
    String? placeId,
    String? name,
    String? stayType,
    String? address,
    double? latitude,
    double? longitude,
    DateTime? checkInAt,
    DateTime? checkOutAt,
    String? timezone,
    String? phone,
    String? bookingReference,
    String? notes,
    LuggageProfile? luggageProfile,
    int? version,
    String? googleMapsUrl,
    String? googleMapsDirectionsUrl,
    Place? place,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Stay(
      id: id ?? this.id,
      tripId: tripId ?? this.tripId,
      placeId: placeId ?? this.placeId,
      name: name ?? this.name,
      stayType: stayType ?? this.stayType,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      checkInAt: checkInAt ?? this.checkInAt,
      checkOutAt: checkOutAt ?? this.checkOutAt,
      timezone: timezone ?? this.timezone,
      phone: phone ?? this.phone,
      bookingReference: bookingReference ?? this.bookingReference,
      notes: notes ?? this.notes,
      luggageProfile: luggageProfile ?? this.luggageProfile,
      version: version ?? this.version,
      googleMapsUrl: googleMapsUrl ?? this.googleMapsUrl,
      googleMapsDirectionsUrl:
          googleMapsDirectionsUrl ?? this.googleMapsDirectionsUrl,
      place: place ?? this.place,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
