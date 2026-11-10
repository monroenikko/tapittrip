import '../../../../core/utils/currency_formatter.dart';

class MemberBalance {
  const MemberBalance({
    required this.userId,
    required this.name,
    this.email = '',
    required this.netBalanceMinor,
    required this.status,
    this.isDeparted = false,
  });

  factory MemberBalance.fromJson(Map<String, dynamic> json) {
    return MemberBalance(
      userId: (json['user_id'] ?? '').toString(),
      name: json['name'] as String? ?? 'Unknown',
      email: json['email'] as String? ?? '',
      netBalanceMinor: (json['net_balance_minor'] as num?)?.toInt() ?? 0,
      status: json['status'] as String? ?? 'settled',
      isDeparted: json['is_departed'] as bool? ?? false,
    );
  }

  final String userId;
  final String name;
  final String email;
  final int netBalanceMinor;
  final String status;
  final bool isDeparted;

  double get netBalance => netBalanceMinor / 100.0;

  bool get isOwed => netBalanceMinor > 0;
  bool get owes => netBalanceMinor < 0;
  bool get isSettled => netBalanceMinor == 0;

  String formatBalance([String currency = 'USD']) {
    final formatted = CurrencyFormatter.formatAmount(
      netBalanceMinor,
      currency,
      isMinor: true,
    );
    if (netBalanceMinor > 0) {
      return '+$formatted';
    }
    return formatted;
  }

  Map<String, dynamic> toJson() => {
    'user_id': userId,
    'name': name,
    if (email.isNotEmpty) 'email': email,
    'net_balance_minor': netBalanceMinor,
    'status': status,
    'is_departed': isDeparted,
  };
}

class SuggestedSettlement {
  const SuggestedSettlement({
    required this.payerId,
    required this.payerName,
    required this.payeeId,
    required this.payeeName,
    required this.amountMinor,
    required this.currency,
  });

  factory SuggestedSettlement.fromJson(Map<String, dynamic> json) {
    return SuggestedSettlement(
      payerId: (json['payer_id'] ?? '').toString(),
      payerName: json['payer_name'] as String? ?? 'Unknown',
      payeeId: (json['payee_id'] ?? '').toString(),
      payeeName: json['payee_name'] as String? ?? 'Unknown',
      amountMinor: (json['amount_minor'] as num?)?.toInt() ?? 0,
      currency: json['currency'] as String? ?? 'USD',
    );
  }

  final String payerId;
  final String payerName;
  final String payeeId;
  final String payeeName;
  final int amountMinor;
  final String currency;

  double get amount => amountMinor / 100.0;

  String formatAmount() =>
      CurrencyFormatter.formatAmount(amountMinor, currency, isMinor: true);

  Map<String, dynamic> toJson() => {
    'payer_id': payerId,
    'payer_name': payerName,
    'payee_id': payeeId,
    'payee_name': payeeName,
    'amount_minor': amountMinor,
    'currency': currency,
  };
}

class SettlementRecord {
  const SettlementRecord({
    required this.id,
    required this.payerId,
    required this.payerName,
    required this.payeeId,
    required this.payeeName,
    required this.amountMinor,
    required this.currency,
    this.exchangeRate,
    this.baseAmountMinor,
    this.baseCurrency,
    this.rateSource,
    this.settledAt,
    this.notes,
  });

  factory SettlementRecord.fromJson(Map<String, dynamic> json) {
    return SettlementRecord(
      id: (json['id'] ?? '').toString(),
      payerId: (json['payer_id'] ?? '').toString(),
      payerName: json['payer_name'] as String? ?? 'Unknown',
      payeeId: (json['payee_id'] ?? '').toString(),
      payeeName: json['payee_name'] as String? ?? 'Unknown',
      amountMinor: (json['amount_minor'] as num?)?.toInt() ?? 0,
      currency: json['currency'] as String? ?? 'USD',
      exchangeRate: (json['exchange_rate'] as num?)?.toDouble(),
      baseAmountMinor: (json['base_amount_minor'] as num?)?.toInt(),
      baseCurrency: json['base_currency'] as String?,
      rateSource: json['rate_source'] as String?,
      settledAt: json['settled_at'] as String?,
      notes: json['notes'] as String?,
    );
  }

  final String id;
  final String payerId;
  final String payerName;
  final String payeeId;
  final String payeeName;
  final int amountMinor;
  final String currency;
  final double? exchangeRate;
  final int? baseAmountMinor;
  final String? baseCurrency;
  final String? rateSource;
  final String? settledAt;
  final String? notes;

  double get amount => amountMinor / 100.0;

  String formatAmount() =>
      CurrencyFormatter.formatAmount(amountMinor, currency, isMinor: true);

  Map<String, dynamic> toJson() => {
    'id': id,
    'payer_id': payerId,
    'payer_name': payerName,
    'payee_id': payeeId,
    'payee_name': payeeName,
    'amount_minor': amountMinor,
    'currency': currency,
    'exchange_rate': ?exchangeRate,
    'base_amount_minor': ?baseAmountMinor,
    'base_currency': ?baseCurrency,
    'rate_source': ?rateSource,
    'settled_at': settledAt,
    'notes': notes,
  };
}

class UnconvertedExpenseNotice {
  const UnconvertedExpenseNotice({
    required this.id,
    required this.title,
    required this.amountMinor,
    required this.currency,
    required this.payerId,
    required this.payerName,
    required this.expenseDate,
    required this.reason,
  });

  final String id;
  final String title;
  final int amountMinor;
  final String currency;
  final String payerId;
  final String payerName;
  final String expenseDate;
  final String reason;

  String formatAmount() =>
      CurrencyFormatter.formatAmount(amountMinor, currency, isMinor: true);

  factory UnconvertedExpenseNotice.fromJson(Map<String, dynamic> json) {
    return UnconvertedExpenseNotice(
      id: (json['id'] ?? '').toString(),
      title: json['title'] as String? ?? 'Expense',
      amountMinor: (json['amount_minor'] as num?)?.toInt() ?? 0,
      currency: json['currency'] as String? ?? 'USD',
      payerId: (json['payer_id'] ?? '').toString(),
      payerName: json['payer_name'] as String? ?? 'Unknown',
      expenseDate: json['expense_date'] as String? ?? '',
      reason: json['reason'] as String? ?? 'exchange_rate_unavailable',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'amount_minor': amountMinor,
    'currency': currency,
    'payer_id': payerId,
    'payer_name': payerName,
    'expense_date': expenseDate,
    'reason': reason,
  };
}

class GroupBalances {
  const GroupBalances({
    required this.tripId,
    required this.baseCurrency,
    required this.balances,
    required this.suggestedSettlements,
    required this.settlementHistory,
    this.perCurrencyBalances = const {},
    this.unconvertedExpenses = const [],
    this.accountingNotice = 'Balances and settlements are trip ledger records only; TapItTrip does not transfer funds or verify external payments.',
  });

  factory GroupBalances.fromJson(Map<String, dynamic> json) {
    final rawPerCurrency = json['per_currency_balances'];
    final perCurrency = <String, List<MemberBalance>>{};
    if (rawPerCurrency is Map) {
      rawPerCurrency.forEach((key, value) {
        if (value is List) {
          perCurrency[key.toString()] = value
              .whereType<Map>()
              .map((e) => MemberBalance.fromJson(Map<String, dynamic>.from(e)))
              .toList();
        }
      });
    }

    return GroupBalances(
      tripId: (json['trip_id'] ?? '').toString(),
      baseCurrency: json['base_currency'] as String? ?? 'USD',
      balances: (json['balances'] as List<dynamic>? ?? [])
          .map(
            (e) => MemberBalance.fromJson(Map<String, dynamic>.from(e as Map)),
          )
          .toList(),
      suggestedSettlements:
          (json['suggested_settlements'] as List<dynamic>? ?? [])
              .map(
                (e) => SuggestedSettlement.fromJson(
                  Map<String, dynamic>.from(e as Map),
                ),
              )
              .toList(),
      settlementHistory: (json['settlement_history'] as List<dynamic>? ?? [])
          .map(
            (e) =>
                SettlementRecord.fromJson(Map<String, dynamic>.from(e as Map)),
          )
          .toList(),
      perCurrencyBalances: perCurrency,
      unconvertedExpenses:
          (json['unconverted_expenses'] as List<dynamic>? ?? [])
              .whereType<Map>()
              .map(
                (e) => UnconvertedExpenseNotice.fromJson(
                  Map<String, dynamic>.from(e),
                ),
              )
              .toList(),
      accountingNotice: json['accounting_notice'] as String? ?? 'Balances and settlements are trip ledger records only; TapItTrip does not transfer funds or verify external payments.',
    );
  }

  final String tripId;
  final String baseCurrency;
  final List<MemberBalance> balances;
  final List<SuggestedSettlement> suggestedSettlements;
  final List<SettlementRecord> settlementHistory;
  final Map<String, List<MemberBalance>> perCurrencyBalances;
  final List<UnconvertedExpenseNotice> unconvertedExpenses;
  final String accountingNotice;

  bool get isAllSettled => suggestedSettlements.isEmpty;

  Map<String, dynamic> toJson() => {
    'trip_id': tripId,
    'base_currency': baseCurrency,
    'balances': balances.map((b) => b.toJson()).toList(),
    'suggested_settlements': suggestedSettlements
        .map((s) => s.toJson())
        .toList(),
    'settlement_history': settlementHistory.map((h) => h.toJson()).toList(),
    if (perCurrencyBalances.isNotEmpty)
      'per_currency_balances': perCurrencyBalances.map(
        (cur, list) => MapEntry(cur, list.map((b) => b.toJson()).toList()),
      ),
    if (unconvertedExpenses.isNotEmpty)
      'unconverted_expenses': unconvertedExpenses
          .map((e) => e.toJson())
          .toList(),
    'accounting_notice': accountingNotice,
  };
}
