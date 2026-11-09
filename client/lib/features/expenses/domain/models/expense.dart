import 'package:flutter/material.dart';

import '../../../../core/utils/currency_formatter.dart';

class Expense {
  const Expense({
    required this.id,
    required this.tripId,
    required this.payerId,
    required this.category,
    required this.title,
    required this.amountMinor,
    required this.currency,
    this.exchangeRate = 1.0,
    required this.baseAmountMinor,
    required this.expenseDate,
    this.itineraryItemId,
    this.stayId,
    this.splitType = 'single',
    this.notes,
    this.receiptUrl,
    this.version = 1,
    this.payerName,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String tripId;
  final String payerId;
  final String category;
  final String title;
  final int amountMinor;
  final String currency;
  final double exchangeRate;
  final int baseAmountMinor;
  final String expenseDate;
  final String? itineraryItemId;
  final String? stayId;
  final String splitType;
  final String? notes;
  final String? receiptUrl;
  final int version;
  final String? payerName;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  double get amount => CurrencyFormatter.isZeroDecimal(currency)
      ? amountMinor.toDouble()
      : amountMinor / 100.0;
  double get baseAmount => baseAmountMinor / 100.0;

  String formatAmount({String? baseCurrency, bool useBaseCurrency = false}) {
    final cur = (useBaseCurrency && baseCurrency != null && baseCurrency.isNotEmpty)
        ? baseCurrency
        : (useBaseCurrency ? 'USD' : currency);
    final minor = useBaseCurrency ? baseAmountMinor : amountMinor;
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
        return Colors.deepOrange;
      case 'transport':
        return Colors.blue;
      case 'accommodation':
        return Colors.indigo;
      case 'activities':
        return Colors.teal;
      case 'shopping':
        return Colors.purple;
      case 'other':
      default:
        return colorScheme.secondary;
    }
  }

  factory Expense.fromJson(Map<String, dynamic> json) {
    final payerObj = json['payer'];
    final payerName = payerObj is Map ? (payerObj['name'] as String?) : null;

    return Expense(
      id: json['id'] as String,
      tripId: json['trip_id'] as String,
      payerId: (json['payer_id'] as String?) ?? '',
      category: (json['category'] as String?) ?? 'other',
      title: (json['title'] as String?) ?? 'Expense',
      amountMinor: (json['amount_minor'] as num?)?.toInt() ?? 0,
      currency: (json['currency'] as String?) ?? 'USD',
      exchangeRate: (json['exchange_rate'] as num?)?.toDouble() ?? 1.0,
      baseAmountMinor: (json['base_amount_minor'] as num?)?.toInt() ?? 0,
      expenseDate: (json['expense_date'] as String?) ?? '',
      itineraryItemId: json['itinerary_item_id'] as String?,
      stayId: json['stay_id'] as String?,
      splitType: (json['split_type'] as String?) ?? 'single',
      notes: json['notes'] as String?,
      receiptUrl: json['receipt_url'] as String?,
      version: (json['version'] as num?)?.toInt() ?? 1,
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
      'category': category,
      'title': title,
      'amount_minor': amountMinor,
      'currency': currency,
      'exchange_rate': exchangeRate,
      'base_amount_minor': baseAmountMinor,
      'expense_date': expenseDate,
      if (itineraryItemId != null) 'itinerary_item_id': itineraryItemId,
      if (stayId != null) 'stay_id': stayId,
      'split_type': splitType,
      if (notes != null) 'notes': notes,
      if (receiptUrl != null) 'receipt_url': receiptUrl,
      'version': version,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }
}
