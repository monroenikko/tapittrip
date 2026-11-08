class CategorySpending {
  const CategorySpending({
    required this.category,
    required this.amountMinor,
    required this.count,
    required this.percent,
  });

  final String category;
  final int amountMinor;
  final int count;
  final double percent;

  double get amount => amountMinor / 100.0;

  factory CategorySpending.fromJson(Map<String, dynamic> json) {
    return CategorySpending(
      category: (json['category'] as String?) ?? 'other',
      amountMinor: (json['amount_minor'] as num?)?.toInt() ?? 0,
      count: (json['count'] as num?)?.toInt() ?? 0,
      percent: (json['percent'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class DailySpending {
  const DailySpending({
    required this.date,
    required this.amountMinor,
    required this.count,
  });

  final String date;
  final int amountMinor;
  final int count;

  double get amount => amountMinor / 100.0;

  factory DailySpending.fromJson(Map<String, dynamic> json) {
    return DailySpending(
      date: (json['date'] as String?) ?? '',
      amountMinor: (json['amount_minor'] as num?)?.toInt() ?? 0,
      count: (json['count'] as num?)?.toInt() ?? 0,
    );
  }
}

class ExpenseSummary {
  const ExpenseSummary({
    required this.tripId,
    required this.baseCurrency,
    this.totalBudgetMinor,
    this.dailyBudgetMinor,
    required this.totalSpentBaseMinor,
    this.remainingBudgetMinor,
    this.budgetUtilizationPercent,
    required this.expensesCount,
    this.categoryBreakdown = const [],
    this.dailySpending = const [],
  });

  final String tripId;
  final String baseCurrency;
  final int? totalBudgetMinor;
  final int? dailyBudgetMinor;
  final int totalSpentBaseMinor;
  final int? remainingBudgetMinor;
  final double? budgetUtilizationPercent;
  final int expensesCount;
  final List<CategorySpending> categoryBreakdown;
  final List<DailySpending> dailySpending;

  double get totalSpentBase => totalSpentBaseMinor / 100.0;
  double? get totalBudget =>
      totalBudgetMinor != null ? totalBudgetMinor! / 100.0 : null;
  double? get remainingBudget =>
      remainingBudgetMinor != null ? remainingBudgetMinor! / 100.0 : null;

  factory ExpenseSummary.fromJson(Map<String, dynamic> json) {
    return ExpenseSummary(
      tripId: (json['trip_id'] as String?) ?? '',
      baseCurrency: (json['base_currency'] as String?) ?? 'USD',
      totalBudgetMinor: (json['total_budget_minor'] as num?)?.toInt(),
      dailyBudgetMinor: (json['daily_budget_minor'] as num?)?.toInt(),
      totalSpentBaseMinor:
          (json['total_spent_base_minor'] as num?)?.toInt() ?? 0,
      remainingBudgetMinor: (json['remaining_budget_minor'] as num?)?.toInt(),
      budgetUtilizationPercent: (json['budget_utilization_percent'] as num?)
          ?.toDouble(),
      expensesCount: (json['expenses_count'] as num?)?.toInt() ?? 0,
      categoryBreakdown: (json['category_breakdown'] as List<dynamic>? ?? [])
          .map(
            (e) =>
                CategorySpending.fromJson(Map<String, dynamic>.from(e as Map)),
          )
          .toList(),
      dailySpending: (json['daily_spending'] as List<dynamic>? ?? [])
          .map(
            (e) => DailySpending.fromJson(Map<String, dynamic>.from(e as Map)),
          )
          .toList(),
    );
  }
}
