import '../../../itinerary/domain/models/itinerary_item.dart';
import '../../../stays/domain/models/stay.dart';
import '../../../trips/domain/models/trip.dart';

class ActiveDayInfo {
  const ActiveDayInfo({
    required this.dayNumber,
    required this.totalDays,
    required this.date,
    this.notes,
  });

  final int dayNumber;
  final int totalDays;
  final String date;
  final String? notes;

  factory ActiveDayInfo.fromJson(Map<String, dynamic> json) {
    return ActiveDayInfo(
      dayNumber: (json['day_number'] as num?)?.toInt() ?? 1,
      totalDays: (json['total_days'] as num?)?.toInt() ?? 1,
      date: json['date'] as String? ?? '',
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'day_number': dayNumber,
      'total_days': totalDays,
      'date': date,
      'notes': notes,
    };
  }
}

class DashboardMetrics {
  const DashboardMetrics({
    required this.totalActivities,
    required this.completedActivities,
    required this.progressPercentage,
  });

  final int totalActivities;
  final int completedActivities;
  final int progressPercentage;

  factory DashboardMetrics.fromJson(Map<String, dynamic> json) {
    return DashboardMetrics(
      totalActivities: (json['total_activities'] as num?)?.toInt() ?? 0,
      completedActivities: (json['completed_activities'] as num?)?.toInt() ?? 0,
      progressPercentage: (json['progress_percentage'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_activities': totalActivities,
      'completed_activities': completedActivities,
      'progress_percentage': progressPercentage,
    };
  }
}

class BudgetPacing {
  const BudgetPacing({
    required this.currency,
    required this.totalBudgetMinor,
    this.dailyBudgetMinor,
    required this.spentTodayMinor,
    required this.totalSpentMinor,
    required this.remainingBudgetMinor,
    this.dailyUtilizationPercent,
  });

  final String currency;
  final int totalBudgetMinor;
  final int? dailyBudgetMinor;
  final int spentTodayMinor;
  final int totalSpentMinor;
  final int remainingBudgetMinor;
  final double? dailyUtilizationPercent;

  double get spentToday => spentTodayMinor / 100.0;
  double get totalBudget => totalBudgetMinor / 100.0;
  double? get dailyBudget =>
      dailyBudgetMinor != null ? dailyBudgetMinor! / 100.0 : null;
  double get remainingBudget => remainingBudgetMinor / 100.0;

  factory BudgetPacing.fromJson(Map<String, dynamic> json) {
    return BudgetPacing(
      currency: json['currency'] as String? ?? 'USD',
      totalBudgetMinor: (json['total_budget_minor'] as num?)?.toInt() ?? 0,
      dailyBudgetMinor: (json['daily_budget_minor'] as num?)?.toInt(),
      spentTodayMinor: (json['spent_today_minor'] as num?)?.toInt() ?? 0,
      totalSpentMinor: (json['total_spent_minor'] as num?)?.toInt() ?? 0,
      remainingBudgetMinor:
          (json['remaining_budget_minor'] as num?)?.toInt() ?? 0,
      dailyUtilizationPercent:
          (json['daily_utilization_percent'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
    'currency': currency,
    'total_budget_minor': totalBudgetMinor,
    'daily_budget_minor': dailyBudgetMinor,
    'spent_today_minor': spentTodayMinor,
    'total_spent_minor': totalSpentMinor,
    'remaining_budget_minor': remainingBudgetMinor,
    'daily_utilization_percent': dailyUtilizationPercent,
  };
}

class TodayDashboardSummary {
  const TodayDashboardSummary({
    required this.trip,
    required this.tripStatus,
    this.daysUntilStart,
    this.activeDay,
    this.todayItems = const [],
    this.nextUpcomingItem,
    this.currentStay,
    required this.metrics,
    required this.timezone,
    this.localTime,
    this.budgetPacing,
  });

  final Trip trip;
  final String tripStatus; // 'pre_trip', 'active', 'post_trip'
  final int? daysUntilStart;
  final ActiveDayInfo? activeDay;
  final List<ItineraryItem> todayItems;
  final ItineraryItem? nextUpcomingItem;
  final Stay? currentStay;
  final DashboardMetrics metrics;
  final String timezone;
  final DateTime? localTime;
  final BudgetPacing? budgetPacing;

  bool get isPreTrip => tripStatus == 'pre_trip';
  bool get isActive => tripStatus == 'active';
  bool get isPostTrip => tripStatus == 'post_trip';

  String get statusBadgeText {
    if (isPreTrip) {
      final days = daysUntilStart ?? 1;
      return days == 1 ? 'Starts tomorrow' : 'Starts in $days days';
    } else if (isPostTrip) {
      return 'Trip Completed';
    } else {
      if (activeDay != null) {
        return 'Day ${activeDay!.dayNumber} of ${activeDay!.totalDays}';
      }
      return 'Active Journey';
    }
  }

  factory TodayDashboardSummary.fromJson(Map<String, dynamic> json) {
    final tripJson = json['trip'] as Map<String, dynamic>? ?? {};
    final activeDayJson = json['active_day'] as Map<String, dynamic>?;
    final metricsJson = json['metrics'] as Map<String, dynamic>? ?? {};
    final rawTodayItems = json['today_items'] as List<dynamic>? ?? [];

    return TodayDashboardSummary(
      trip: Trip.fromJson(tripJson),
      tripStatus: json['trip_status'] as String? ?? 'active',
      daysUntilStart: (json['days_until_start'] as num?)?.toInt(),
      activeDay: activeDayJson != null
          ? ActiveDayInfo.fromJson(activeDayJson)
          : null,
      todayItems: rawTodayItems
          .map((item) => ItineraryItem.fromJson(item as Map<String, dynamic>))
          .toList(),
      nextUpcomingItem: json['next_upcoming_item'] != null
          ? ItineraryItem.fromJson(
              json['next_upcoming_item'] as Map<String, dynamic>,
            )
          : null,
      currentStay: json['current_stay'] != null
          ? Stay.fromJson(json['current_stay'] as Map<String, dynamic>)
          : null,
      metrics: DashboardMetrics.fromJson(metricsJson),
      timezone: json['timezone'] as String? ?? 'UTC',
      localTime: DateTime.tryParse(json['local_time'] as String? ?? ''),
      budgetPacing: json['budget_pacing'] != null
          ? BudgetPacing.fromJson(json['budget_pacing'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'trip': trip.toJson(),
      'trip_status': tripStatus,
      'days_until_start': daysUntilStart,
      'active_day': activeDay?.toJson(),
      'today_items': todayItems.map((e) => e.toJson()).toList(),
      'next_upcoming_item': nextUpcomingItem?.toJson(),
      'current_stay': currentStay?.toJson(),
      'metrics': metrics.toJson(),
      'timezone': timezone,
      'local_time': localTime?.toIso8601String(),
      'budget_pacing': budgetPacing?.toJson(),
    };
  }
}
