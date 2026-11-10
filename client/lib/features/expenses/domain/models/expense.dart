import 'package:flutter/material.dart';

import '../../../../core/utils/currency_formatter.dart';

class ExpenseSplitItem {
  const ExpenseSplitItem({
    this.id,
    required this.userId,
    this.userName,
    required this.amountMinor,
    this.baseAmountMinor,
    this.shares = 1,
    this.settled = false,
  });

  final String? id;
  final String userId;
  final String? userName;
  final int amountMinor;
  final int? baseAmountMinor;
  final int shares;
  final bool settled;

  factory ExpenseSplitItem.fromJson(Map<String, dynamic> json) {
    final userObj = json['user'];
    final userName = userObj is Map ? userObj['name'] as String? : null;

    return ExpenseSplitItem(
      id: json['id'] as String?,
      userId: (json['user_id'] ?? '').toString(),
      userName: userName,
      amountMinor: (json['amount_minor'] as num?)?.toInt() ?? 0,
      baseAmountMinor: (json['base_amount_minor'] as num?)?.toInt(),
      shares: (json['shares'] as num?)?.toInt() ?? 1,
      settled: json['settled'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': ?id,
    'user_id': userId,
    'amount_minor': amountMinor,
    'base_amount_minor': ?baseAmountMinor,
    'shares': shares,
    'settled': settled,
    if (userName != null) 'user': {'id': userId, 'name': userName},
  };
}

class Expense {
  const Expense({
    required this.id,
    required this.tripId,
    required this.payerId,
    this.createdByUserId,
    required this.category,
    required this.title,
    required this.amountMinor,
    required this.currency,
    this.exchangeRate = 1.0,
    this.rateSource,
    this.rateCapturedAt,
    this.conversionStatus = 'converted',
    this.baseAmountMinor,
    required this.expenseDate,
    this.itineraryItemId,
    this.stayId,
    this.splitType = 'single',
    this.visibility = 'shared',
    this.splits = const [],
    this.notes,
    this.receiptUrl,
    this.version = 1,
    this.clientOperationId,
    this.payerName,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String tripId;
  final String payerId;
  final String? createdByUserId;
  final String category;
  final String title;
  final int amountMinor;
  final String currency;
  final double? exchangeRate;
  final String? rateSource;
  final String? rateCapturedAt;
  final String conversionStatus;
  final int? baseAmountMinor;
  final String expenseDate;
  final String? itineraryItemId;
  final String? stayId;
  final String splitType;
  final String visibility;
  final List<ExpenseSplitItem> splits;
  final String? notes;
  final String? receiptUrl;
  final int version;
  final String? clientOperationId;
  final String? payerName;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isPrivate => visibility == 'private';
  bool get isShared => visibility == 'shared';
  bool get isConversionUnavailable =>
      conversionStatus != 'converted' || baseAmountMinor == null;

  double get amount => CurrencyFormatter.isZeroDecimal(currency)
      ? amountMinor.toDouble()
      : amountMinor / 100.0;

  double get baseAmount => (baseAmountMinor ?? 0) / 100.0;

  String formatAmount({String? baseCurrency, bool useBaseCurrency = false}) {
    if (useBaseCurrency && baseAmountMinor == null) {
      return 'Rate unavailable';
    }
    final cur =
        (useBaseCurrency && baseCurrency != null && baseCurrency.isNotEmpty)
        ? baseCurrency
        : (useBaseCurrency ? 'USD' : currency);
    final minor = useBaseCurrency ? (baseAmountMinor ?? 0) : amountMinor;
    return CurrencyFormatter.formatAmount(minor, cur, isMinor: true);
  }

  static IconData getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'dining':
        return Icons.restaurant_rounded;
      case 'transport':
        return Icons.directions_subway_rounded;
      case 'accommodation':
        return Icons.hotel_rounded;
      case 'activities':
        return Icons.attractions_rounded;
      case 'shopping':
        return Icons.shopping_bag_rounded;
      case 'other':
      default:
        return Icons.receipt_long_rounded;
    }
  }

  static Color getCategoryColor(String category, ColorScheme colorScheme) {
    switch (category.toLowerCase()) {
      case 'dining':
        return colorScheme.secondary;
      case 'transport':
        return colorScheme.primary;
      case 'accommodation':
        return colorScheme.tertiary;
      case 'activities':
        return colorScheme.primary;
      case 'shopping':
        return colorScheme.secondary;
      case 'other':
      default:
        return colorScheme.onSurfaceVariant;
    }
  }

  factory Expense.fromJson(Map<String, dynamic> json) {
    final payerObj = json['payer'];
    final payerName = payerObj is Map ? (payerObj['name'] as String?) : null;
    final splitType = (json['split_type'] as String?) ?? 'single';
    final rawVisibility = json['visibility'] as String?;

    return Expense(
      id: (json['id'] ?? '').toString(),
      tripId: (json['trip_id'] ?? '').toString(),
      payerId: (json['payer_id'] ?? '').toString(),
      createdByUserId: json['created_by_user_id'] as String?,
      category: (json['category'] as String?) ?? 'other',
      title: (json['title'] as String?) ?? 'Expense',
      amountMinor: (json['amount_minor'] as num?)?.toInt() ?? 0,
      currency: (json['currency'] as String?) ?? 'USD',
      exchangeRate: (json['exchange_rate'] as num?)?.toDouble(),
      rateSource: json['rate_source'] as String?,
      rateCapturedAt: json['rate_captured_at'] as String?,
      conversionStatus: (json['conversion_status'] as String?) ?? 'converted',
      baseAmountMinor: (json['base_amount_minor'] as num?)?.toInt(),
      expenseDate: (json['expense_date'] as String?) ?? '',
      itineraryItemId: json['itinerary_item_id'] as String?,
      stayId: json['stay_id'] as String?,
      splitType: splitType,
      visibility:
          rawVisibility ?? (splitType == 'single' ? 'private' : 'shared'),
      splits: (json['splits'] as List<dynamic>? ?? [])
          .whereType<Map>()
          .map((e) => ExpenseSplitItem.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      notes: json['notes'] as String?,
      receiptUrl: json['receipt_url'] as String?,
      version: (json['version'] as num?)?.toInt() ?? 1,
      clientOperationId: json['client_operation_id'] as String?,
      payerName: payerName,
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
      'payer_id': payerId,
      'created_by_user_id': ?createdByUserId,
      'category': category,
      'title': title,
      'amount_minor': amountMinor,
      'currency': currency,
      'exchange_rate': exchangeRate,
      'rate_source': ?rateSource,
      'rate_captured_at': ?rateCapturedAt,
      'conversion_status': conversionStatus,
      'base_amount_minor': baseAmountMinor,
      'expense_date': expenseDate,
      'itinerary_item_id': ?itineraryItemId,
      'stay_id': ?stayId,
      'split_type': splitType,
      'visibility': visibility,
      if (splits.isNotEmpty) 'splits': splits.map((s) => s.toJson()).toList(),
      'notes': ?notes,
      'receipt_url': ?receiptUrl,
      'version': version,
      'client_operation_id': ?clientOperationId,
      if (payerName != null) 'payer': {'id': payerId, 'name': payerName},
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }
}
