import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exceptions.dart';
import '../../circles/data/trip_circle_repository.dart';
import '../domain/models/expense.dart';
import '../domain/models/expense_summary.dart';
import '../domain/models/group_balances.dart';
import '../domain/models/trip_budget.dart';

class ExpenseRepository {
  ExpenseRepository({required this.apiClient, FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  final ApiClient apiClient;
  final FlutterSecureStorage _storage;

  /// Deterministic equal minor-unit integer distribution (zero rounding loss).
  static Map<String, int> allocateEqualMinor(
    int totalMinor,
    List<String> participantIds,
  ) {
    final ordered = <String>[];
    final seen = <String>{};
    for (final id in participantIds) {
      if (id.isNotEmpty && seen.add(id)) {
        ordered.add(id);
      }
    }
    if (ordered.isEmpty || totalMinor <= 0) {
      return const {};
    }

    final base = totalMinor ~/ ordered.length;
    final remainder = totalMinor % ordered.length;
    final result = <String, int>{};
    for (var i = 0; i < ordered.length; i++) {
      result[ordered[i]] = base + (i < remainder ? 1 : 0);
    }
    return result;
  }

  dynamic _extractData(dynamic response) {
    if (response is Map<String, dynamic> && response.containsKey('data')) {
      return response['data'];
    }
    return response;
  }

  bool _isRevokedOrForbidden(Object error) {
    if (error is ApiException) {
      return error.statusCode == 403 ||
          error.statusCode == 401 ||
          error.code == 'forbidden' ||
          error.code == 'unauthorized';
    }
    return false;
  }

  Future<void> cacheExpenses(String tripId, List<Expense> expenses) async {
    await _storage.write(
      key: 'cached_expenses_$tripId',
      value: jsonEncode(expenses.map((e) => e.toJson()).toList()),
    );
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
    } catch (e) {
      if (_isRevokedOrForbidden(e)) {
        await TripCircleRepository.purgeAllTripCachesForStorage(
          storage: _storage,
          tripId: tripId,
        );
        rethrow;
      }
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
      'daily_budget_minor': ?dailyBudgetMinor,
    };

    final response = await apiClient.put(
      '/trips/$tripId/budget',
      data: payload,
    );
    final data = Map<String, dynamic>.from(_extractData(response) as Map);
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
        await cacheExpenses(tripId, list);
      }
      return list;
    } catch (e) {
      if (_isRevokedOrForbidden(e)) {
        await TripCircleRepository.purgeAllTripCachesForStorage(
          storage: _storage,
          tripId: tripId,
        );
        rethrow;
      }
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
    String? payerId,
    required String category,
    required String title,
    required int amountMinor,
    required String currency,
    double? exchangeRate,
    String? rateSource,
    String? rateCapturedAt,
    String? conversionStatus,
    required String expenseDate,
    String? notes,
    String? itineraryItemId,
    String? stayId,
    String splitType = 'single',
    String? visibility,
    List<String>? participantIds,
    List<Map<String, dynamic>>? splits,
    String? receiptUrl,
    String? clientOperationId,
  }) async {
    final payload = <String, dynamic>{
      'payer_id': ?payerId,
      'category': category,
      'title': title,
      'amount_minor': amountMinor,
      'currency': currency,
      'exchange_rate': ?exchangeRate,
      'rate_source': ?rateSource,
      'rate_captured_at': ?rateCapturedAt,
      'conversion_status': ?conversionStatus,
      'expense_date': expenseDate,
      'notes': ?notes,
      'itinerary_item_id': ?itineraryItemId,
      'stay_id': ?stayId,
      'split_type': splitType,
      'visibility': ?visibility,
      'participant_ids': ?participantIds,
      'splits': ?splits,
      'receipt_url': ?receiptUrl,
      'client_operation_id': ?clientOperationId,
    };

    final response = await apiClient.post(
      '/trips/$tripId/expenses',
      data: payload,
    );
    final data = Map<String, dynamic>.from(_extractData(response) as Map);
    return Expense.fromJson(data);
  }

  Future<Expense> updateExpense(
    String expenseId, {
    String? payerId,
    String? category,
    String? title,
    int? amountMinor,
    String? currency,
    double? exchangeRate,
    String? rateSource,
    String? rateCapturedAt,
    String? conversionStatus,
    String? expenseDate,
    String? notes,
    String? itineraryItemId,
    String? stayId,
    String? splitType,
    String? visibility,
    List<String>? participantIds,
    List<Map<String, dynamic>>? splits,
    int? baseVersion,
  }) async {
    final payload = <String, dynamic>{
      'payer_id': ?payerId,
      'category': ?category,
      'title': ?title,
      'amount_minor': ?amountMinor,
      'currency': ?currency,
      'exchange_rate': ?exchangeRate,
      'rate_source': ?rateSource,
      'rate_captured_at': ?rateCapturedAt,
      'conversion_status': ?conversionStatus,
      'expense_date': ?expenseDate,
      'notes': ?notes,
      'itinerary_item_id': ?itineraryItemId,
      'stay_id': ?stayId,
      'split_type': ?splitType,
      'visibility': ?visibility,
      'participant_ids': ?participantIds,
      'splits': ?splits,
      'base_version': ?baseVersion,
    };

    final response = await apiClient.patch(
      '/expenses/$expenseId',
      data: payload,
    );
    final data = Map<String, dynamic>.from(_extractData(response) as Map);
    return Expense.fromJson(data);
  }

  Future<void> deleteExpense(String expenseId, {int? baseVersion}) async {
    await apiClient.delete(
      '/expenses/$expenseId',
      queryParameters: baseVersion != null
          ? {'base_version': baseVersion}
          : null,
    );
  }

  Future<ExpenseSummary> getSummary(String tripId) async {
    try {
      final response = await apiClient.get('/trips/$tripId/expenses/summary');
      final data = Map<String, dynamic>.from(_extractData(response) as Map);
      final summary = ExpenseSummary.fromJson(data);
      await _storage.write(
        key: 'cached_summary_$tripId',
        value: jsonEncode(data),
      );
      return summary;
    } catch (e) {
      if (_isRevokedOrForbidden(e)) {
        await TripCircleRepository.purgeAllTripCachesForStorage(
          storage: _storage,
          tripId: tripId,
        );
        rethrow;
      }
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
      final data = Map<String, dynamic>.from(_extractData(response) as Map);
      final balances = GroupBalances.fromJson(data);
      await _storage.write(
        key: 'cached_settlements_$tripId',
        value: jsonEncode(data),
      );
      return balances;
    } catch (e) {
      if (_isRevokedOrForbidden(e)) {
        await TripCircleRepository.purgeAllTripCachesForStorage(
          storage: _storage,
          tripId: tripId,
        );
        rethrow;
      }
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
    double? exchangeRate,
    String? rateSource,
    String? rateCapturedAt,
    String? settledAt,
    String? notes,
    String? clientOperationId,
  }) async {
    final payload = <String, dynamic>{
      'payer_id': payerId,
      'payee_id': payeeId,
      'amount_minor': amountMinor,
      'currency': currency,
      'exchange_rate': ?exchangeRate,
      'rate_source': ?rateSource,
      'rate_captured_at': ?rateCapturedAt,
      'settled_at': ?settledAt,
      'notes': ?notes,
      'client_operation_id': ?clientOperationId,
    };

    final response = await apiClient.post(
      '/trips/$tripId/settlements',
      data: payload,
    );
    final data = Map<String, dynamic>.from(_extractData(response) as Map);
    return SettlementRecord.fromJson(data);
  }

  Future<Expense> uploadReceipt(String expenseId, String filePath) async {
    final response = await apiClient.post(
      '/expenses/$expenseId/receipt',
      data: {'file_path': filePath},
    );
    final data = Map<String, dynamic>.from(_extractData(response) as Map);
    return Expense.fromJson(data);
  }
}
