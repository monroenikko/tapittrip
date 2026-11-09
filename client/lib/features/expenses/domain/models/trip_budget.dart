class TripBudget {
  const TripBudget({
    required this.id,
    required this.tripId,
    required this.currency,
    required this.totalBudgetMinor,
    this.dailyBudgetMinor,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String tripId;
  final String currency;
  final int totalBudgetMinor;
  final int? dailyBudgetMinor;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  double get totalBudget => totalBudgetMinor / 100.0;
  double? get dailyBudget =>
      dailyBudgetMinor != null ? dailyBudgetMinor! / 100.0 : null;

  factory TripBudget.fromJson(Map<String, dynamic> json) {
    return TripBudget(
      id: json['id'] as String,
      tripId: json['trip_id'] as String,
      currency: (json['currency'] as String?) ?? 'USD',
      totalBudgetMinor: (json['total_budget_minor'] as num?)?.toInt() ?? 0,
      dailyBudgetMinor: (json['daily_budget_minor'] as num?)?.toInt(),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'trip_id': tripId,
      'currency': currency,
      'total_budget_minor': totalBudgetMinor,
      'daily_budget_minor': dailyBudgetMinor,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }
}
