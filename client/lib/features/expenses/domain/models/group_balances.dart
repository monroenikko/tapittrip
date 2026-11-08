class MemberBalance {
  const MemberBalance({
    required this.userId,
    required this.name,
    required this.email,
    required this.netBalanceMinor,
    required this.status,
  });

  factory MemberBalance.fromJson(Map<String, dynamic> json) {
    return MemberBalance(
      userId: json['user_id'] as String,
      name: json['name'] as String? ?? 'Unknown',
      email: json['email'] as String? ?? '',
      netBalanceMinor: (json['net_balance_minor'] as num).toInt(),
      status: json['status'] as String? ?? 'settled',
    );
  }

  final String userId;
  final String name;
  final String email;
  final int netBalanceMinor;
  final String status;

  double get netBalance => netBalanceMinor / 100.0;

  bool get isOwed => netBalanceMinor > 0;
  bool get owes => netBalanceMinor < 0;
  bool get isSettled => netBalanceMinor == 0;

  String formatBalance([String currency = 'USD']) {
    final absAmount = (netBalanceMinor.abs() / 100.0).toStringAsFixed(2);
    final symbol = currency == 'EUR'
        ? '€'
        : currency == 'GBP'
        ? '£'
        : currency == 'JPY'
        ? '¥'
        : '\$';

    if (currency == 'JPY') {
      final jpyAbs = netBalanceMinor.abs().toString();
      if (netBalanceMinor > 0) return '+$symbol$jpyAbs';
      if (netBalanceMinor < 0) return '-$symbol$jpyAbs';
      return '$symbol$jpyAbs';
    }

    if (netBalanceMinor > 0) return '+$symbol$absAmount';
    if (netBalanceMinor < 0) return '-$symbol$absAmount';
    return '$symbol$absAmount';
  }

  Map<String, dynamic> toJson() => {
    'user_id': userId,
    'name': name,
    'email': email,
    'net_balance_minor': netBalanceMinor,
    'status': status,
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
      payerId: json['payer_id'] as String,
      payerName: json['payer_name'] as String? ?? 'Unknown',
      payeeId: json['payee_id'] as String,
      payeeName: json['payee_name'] as String? ?? 'Unknown',
      amountMinor: (json['amount_minor'] as num).toInt(),
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

  String formatAmount() {
    final symbol = currency == 'EUR'
        ? '€'
        : currency == 'GBP'
        ? '£'
        : currency == 'JPY'
        ? '¥'
        : '\$';

    if (currency == 'JPY') {
      return '$symbol$amountMinor';
    }
    return '$symbol${(amountMinor / 100.0).toStringAsFixed(2)}';
  }

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
    this.settledAt,
    this.notes,
  });

  factory SettlementRecord.fromJson(Map<String, dynamic> json) {
    return SettlementRecord(
      id: json['id'] as String,
      payerId: json['payer_id'] as String,
      payerName: json['payer_name'] as String? ?? 'Unknown',
      payeeId: json['payee_id'] as String,
      payeeName: json['payee_name'] as String? ?? 'Unknown',
      amountMinor: (json['amount_minor'] as num).toInt(),
      currency: json['currency'] as String? ?? 'USD',
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
  final String? settledAt;
  final String? notes;

  double get amount => amountMinor / 100.0;

  String formatAmount() {
    final symbol = currency == 'EUR'
        ? '€'
        : currency == 'GBP'
        ? '£'
        : currency == 'JPY'
        ? '¥'
        : '\$';

    if (currency == 'JPY') {
      return '$symbol$amountMinor';
    }
    return '$symbol${(amountMinor / 100.0).toStringAsFixed(2)}';
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'payer_id': payerId,
    'payer_name': payerName,
    'payee_id': payeeId,
    'payee_name': payeeName,
    'amount_minor': amountMinor,
    'currency': currency,
    'settled_at': settledAt,
    'notes': notes,
  };
}

class GroupBalances {
  const GroupBalances({
    required this.tripId,
    required this.baseCurrency,
    required this.balances,
    required this.suggestedSettlements,
    required this.settlementHistory,
  });

  factory GroupBalances.fromJson(Map<String, dynamic> json) {
    return GroupBalances(
      tripId: json['trip_id'] as String,
      baseCurrency: json['base_currency'] as String? ?? 'USD',
      balances: (json['balances'] as List<dynamic>? ?? [])
          .map((e) => MemberBalance.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      suggestedSettlements: (json['suggested_settlements'] as List<dynamic>? ?? [])
          .map((e) => SuggestedSettlement.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      settlementHistory: (json['settlement_history'] as List<dynamic>? ?? [])
          .map((e) => SettlementRecord.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
    );
  }

  final String tripId;
  final String baseCurrency;
  final List<MemberBalance> balances;
  final List<SuggestedSettlement> suggestedSettlements;
  final List<SettlementRecord> settlementHistory;

  bool get isAllSettled => suggestedSettlements.isEmpty;

  Map<String, dynamic> toJson() => {
    'trip_id': tripId,
    'base_currency': baseCurrency,
    'balances': balances.map((b) => b.toJson()).toList(),
    'suggested_settlements': suggestedSettlements.map((s) => s.toJson()).toList(),
    'settlement_history': settlementHistory.map((h) => h.toJson()).toList(),
  };
}

