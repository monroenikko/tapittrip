class TripDay {
  const TripDay({
    required this.id,
    required this.tripId,
    required this.localDate,
    this.dayNumber = 1,
    this.title,
    this.notes,
  });

  final String id;
  final String tripId;
  final String localDate;
  final int dayNumber;
  final String? title;
  final String? notes;

  String get displayTitle => title ?? 'Day $dayNumber';

  String get formattedDate {
    final parsed = DateTime.tryParse(localDate);
    if (parsed == null) return localDate;
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
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final weekday = weekdays[(parsed.weekday - 1).clamp(0, 6)];
    final month = months[(parsed.month - 1).clamp(0, 11)];
    return '$weekday, $month ${parsed.day}';
  }

  String get displayHeader => '$displayTitle • $formattedDate';

  factory TripDay.fromJson(Map<String, dynamic> json) {
    return TripDay(
      id: json['id'] as String,
      tripId: json['trip_id'] as String,
      localDate: json['local_date'] as String,
      dayNumber: (json['day_number'] as int?) ?? 1,
      title: json['title'] as String?,
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'trip_id': tripId,
      'local_date': localDate,
      'day_number': dayNumber,
      if (title != null) 'title': title,
      if (notes != null) 'notes': notes,
    };
  }
}
