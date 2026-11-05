import 'place.dart';
import 'trip_day.dart';

class ItineraryItem {
  const ItineraryItem({
    required this.id,
    required this.tripId,
    required this.title,
    this.tripDayId,
    this.placeId,
    this.kind = 'attraction',
    this.notes,
    this.startsAtUtc,
    this.endsAtUtc,
    this.timezone = 'UTC',
    this.sortOrder = 0,
    this.status = 'planned',
    this.version = 1,
    this.place,
    this.day,
  });

  final String id;
  final String tripId;
  final String? tripDayId;
  final String? placeId;
  final String kind;
  final String title;
  final String? notes;
  final String? startsAtUtc;
  final String? endsAtUtc;
  final String timezone;
  final int sortOrder;
  final String status;
  final int version;
  final Place? place;
  final TripDay? day;

  factory ItineraryItem.fromJson(Map<String, dynamic> json) {
    return ItineraryItem(
      id: json['id'] as String,
      tripId: json['trip_id'] as String,
      tripDayId: json['trip_day_id'] as String?,
      placeId: json['place_id'] as String?,
      kind: json['kind'] as String? ?? 'attraction',
      title: json['title'] as String,
      notes: json['notes'] as String?,
      startsAtUtc: json['starts_at_utc'] as String?,
      endsAtUtc: json['ends_at_utc'] as String?,
      timezone: json['timezone'] as String? ?? 'UTC',
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
      status: json['status'] as String? ?? 'planned',
      version: (json['version'] as num?)?.toInt() ?? 1,
      place: json['place'] != null
          ? Place.fromJson(json['place'] as Map<String, dynamic>)
          : null,
      day: json['day'] != null
          ? TripDay.fromJson(json['day'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'trip_id': tripId,
      if (tripDayId != null) 'trip_day_id': tripDayId,
      if (placeId != null) 'place_id': placeId,
      'kind': kind,
      'title': title,
      if (notes != null) 'notes': notes,
      if (startsAtUtc != null) 'starts_at_utc': startsAtUtc,
      if (endsAtUtc != null) 'ends_at_utc': endsAtUtc,
      'timezone': timezone,
      'sort_order': sortOrder,
      'status': status,
      'version': version,
      if (place != null) 'place': place!.toJson(),
      if (day != null) 'day': day!.toJson(),
    };
  }

  ItineraryItem copyWith({
    String? id,
    String? tripId,
    String? tripDayId,
    String? placeId,
    String? kind,
    String? title,
    String? notes,
    String? startsAtUtc,
    String? endsAtUtc,
    String? timezone,
    int? sortOrder,
    String? status,
    int? version,
    Place? place,
    TripDay? day,
  }) {
    return ItineraryItem(
      id: id ?? this.id,
      tripId: tripId ?? this.tripId,
      tripDayId: tripDayId ?? this.tripDayId,
      placeId: placeId ?? this.placeId,
      kind: kind ?? this.kind,
      title: title ?? this.title,
      notes: notes ?? this.notes,
      startsAtUtc: startsAtUtc ?? this.startsAtUtc,
      endsAtUtc: endsAtUtc ?? this.endsAtUtc,
      timezone: timezone ?? this.timezone,
      sortOrder: sortOrder ?? this.sortOrder,
      status: status ?? this.status,
      version: version ?? this.version,
      place: place ?? this.place,
      day: day ?? this.day,
    );
  }
}
