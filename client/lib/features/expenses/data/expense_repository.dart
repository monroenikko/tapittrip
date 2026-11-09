import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../core/network/api_client.dart';
import '../domain/models/expense.dart';
import '../domain/models/expense_summary.dart';
import '../domain/models/group_balances.dart';
import '../domain/models/trip_budget.dart';

class ExpenseRepository {
  ExpenseRepository({required this.apiClient, FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  final ApiClient apiClient;
  final FlutterSecureStorage _storage;

  dynamic _extractData(dynamic response) {
    if (response is Map<String, dynamic> && response.containsKey('data')) {
      return response['data'];
    }
    return response;
  }

  Future<TripBudget?> getBudget(String tripId) async {
    try {
      final response = await apiClient.get('/trips/$tripId/budget');
      final data = _extractData(response);
      if (data == null || data is! Map) return null;
      final budget = TripBudget.fromJson(Map<String, dynamic>.from(data));
      await _storage.write(
        key: 'cached_budget_$tripId',
        value: jsonEncode(budget.toJson()),
      );
      return budget;
    } catch (_) {
      final cached = await _storage.read(key: 'cached_budget_$tripId');
      if (cached != null) {
        return TripBudget.fromJson(jsonDecode(cached) as Map<String, dynamic>);
      }
      rethrow;
    }
  }

  Future<TripBudget> setBudget(
    String tripId, {
    required String currency,
    required int totalBudgetMinor,
    int? dailyBudgetMinor,
  }) async {
    final payload = <String, dynamic>{
      'currency': currency,
      'total_budget_minor': totalBudgetMinor,
    };
    if (dailyBudgetMinor != null) {
      payload['daily_budget_minor'] = dailyBudgetMinor;
    }

    final response = await apiClient.put(
      '/trips/$tripId/budget',
      data: payload,
    );
    final data = _extractData(response) as Map<String, dynamic>;
    final budget = TripBudget.fromJson(data);
    await _storage.write(
      key: 'cached_budget_$tripId',
      value: jsonEncode(budget.toJson()),
    );
    return budget;
  }

  Future<List<Expense>> getExpenses(
    String tripId, {
    String? category,
    String? date,
  }) async {
    final queryParams = <String, dynamic>{};
    if (category != null && category.isNotEmpty) {
      queryParams['category'] = category;
    }
    if (date != null && date.isNotEmpty) {
      queryParams['expense_date'] = date;
    }

    try {
      final response = await apiClient.get(
        '/trips/$tripId/expenses',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );
      final rawData = _extractData(response);
      final list = (rawData as List<dynamic>? ?? [])
          .map((e) => Expense.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();

      if (category == null && date == null) {
        await _storage.write(
          key: 'cached_expenses_$tripId',
          value: jsonEncode(list.map((e) => e.toJson()).toList()),
        );
      }
      return list;
    } catch (_) {
      final cached = await _storage.read(key: 'cached_expenses_$tripId');
      if (cached != null) {
        final list = (jsonDecode(cached) as List<dynamic>)
            .map((e) => Expense.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
        if (category != null) {
          return list.where((e) => e.category == category).toList();
        }
        return list;
      }
      rethrow;
    }
  }

  Future<Expense> createExpense(
    String tripId, {
    required String category,
    required String title,
    required int amountMinor,
    required String currency,
    double? exchangeRate,
    required String expenseDate,
    String? notes,
    String? itineraryItemId,
    String? stayId,
    String splitType = 'single',
    String? receiptUrl,
  }) async {
    final payload = <String, dynamic>{
      'category': category,
      'title': title,
      'amount_minor': amountMinor,
      'currency': currency,
      'expense_date': expenseDate,
      'split_type': splitType,
    };
    if (exchangeRate != null) payload['exchange_rate'] = exchangeRate;
    if (notes != null) payload['notes'] = notes;
    if (itineraryItemId != null) payload['itinerary_item_id'] = itineraryItemId;
    if (stayId != null) payload['stay_id'] = stayId;
    if (receiptUrl != null) payload['receipt_url'] = receiptUrl;

    final response = await apiClient.post(
      '/trips/$tripId/expenses',
      data: payload,
    );
    final data = _extractData(response) as Map<String, dynamic>;
    return Expense.fromJson(data);
  }

  Future<Expense> updateExpense(
    String expenseId, {
    String? category,
    String? title,
    int? amountMinor,
    String? currency,
    double? exchangeRate,
    String? expenseDate,
    String? notes,
    String? itineraryItemId,
    String? stayId,
  }) async {
    final payload = <String, dynamic>{};
    if (category != null) payload['category'] = category;
    if (title != null) payload['title'] = title;
    if (amountMinor != null) payload['amount_minor'] = amountMinor;
    if (currency != null) payload['currency'] = currency;
    if (exchangeRate != null) payload['exchange_rate'] = exchangeRate;
    if (expenseDate != null) payload['expense_date'] = expenseDate;
    if (notes != null) payload['notes'] = notes;
    if (itineraryItemId != null) payload['itinerary_item_id'] = itineraryItemId;
    if (stayId != null) payload['stay_id'] = stayId;

    final response = await apiClient.patch(
      '/expenses/$expenseId',
      data: payload,
    );
    final data = _extractData(response) as Map<String, dynamic>;
    return Expense.fromJson(data);
  }

  Future<void> deleteExpense(String expenseId) async {
    await apiClient.delete('/expenses/$expenseId');
  }

  Future<ExpenseSummary> getSummary(String tripId) async {
    try {
      final response = await apiClient.get('/trips/$tripId/expenses/summary');
      final data = _extractData(response) as Map<String, dynamic>;
      final summary = ExpenseSummary.fromJson(data);
      await _storage.write(
        key: 'cached_summary_$tripId',
        value: jsonEncode(data),
      );
      return summary;
    } catch (_) {
      final cached = await _storage.read(key: 'cached_summary_$tripId');
      if (cached != null) {
        return ExpenseSummary.fromJson(
          jsonDecode(cached) as Map<String, dynamic>,
        );
      }
      rethrow;
    }
  }

  Future<GroupBalances> getGroupBalances(String tripId) async {
    try {
      final response = await apiClient.get('/trips/$tripId/settlements');
      final data = _extractData(response) as Map<String, dynamic>;
      final balances = GroupBalances.fromJson(data);
      await _storage.write(
        key: 'cached_settlements_$tripId',
        value: jsonEncode(data),
      );
      return balances;
    } catch (_) {
      final cached = await _storage.read(key: 'cached_settlements_$tripId');
      if (cached != null) {
        return GroupBalances.fromJson(
          jsonDecode(cached) as Map<String, dynamic>,
        );
      }
      rethrow;
    }
  }

  Future<SettlementRecord> recordSettlement(
    String tripId, {
    required String payerId,
    required String payeeId,
    required int amountMinor,
    required String currency,
    String? settledAt,
    String? notes,
  }) async {
    final payload = <String, dynamic>{
      'payer_id': payerId,
      'payee_id': payeeId,
      'amount_minor': amountMinor,
      'currency': currency,
    };
    if (settledAt != null) payload['settled_at'] = settledAt;
    if (notes != null) payload['notes'] = notes;

    final response = await apiClient.post(
      '/trips/$tripId/settlements',
      data: payload,
    );
    final data = _extractData(response) as Map<String, dynamic>;
    return SettlementRecord.fromJson(data);
  }

  Future<Expense> uploadReceipt(String expenseId, String filePath) async {
    final response = await apiClient.post(
      '/expenses/$expenseId/receipt',
      data: {'file_path': filePath},
    );
    final data = _extractData(response) as Map<String, dynamic>;
    return Expense.fromJson(data);
  }
}
