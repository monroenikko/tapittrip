import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/expense_provider.dart';

class SetBudgetDialog extends ConsumerStatefulWidget {
  const SetBudgetDialog({
    super.key,
    required this.tripId,
    this.initialCurrency = 'USD',
    this.initialTotalBudgetMinor,
    this.initialDailyBudgetMinor,
  });

  final String tripId;
  final String initialCurrency;
  final int? initialTotalBudgetMinor;
  final int? initialDailyBudgetMinor;

  static Future<void> show(
    BuildContext context, {
    required String tripId,
    String initialCurrency = 'USD',
    int? initialTotalBudgetMinor,
    int? initialDailyBudgetMinor,
  }) {
    return showDialog<void>(
      context: context,
      builder: (ctx) => SetBudgetDialog(
        tripId: tripId,
        initialCurrency: initialCurrency,
        initialTotalBudgetMinor: initialTotalBudgetMinor,
        initialDailyBudgetMinor: initialDailyBudgetMinor,
      ),
    );
  }

  @override
  ConsumerState<SetBudgetDialog> createState() => _SetBudgetDialogState();
}

class _SetBudgetDialogState extends ConsumerState<SetBudgetDialog> {
  late final TextEditingController _totalBudgetController;
  late final TextEditingController _dailyBudgetController;
  late String _currency;
  bool _isLoading = false;
  String? _errorMessage;

  final List<String> _currencies = const [
    'USD',
    'EUR',
    'JPY',
    'PHP',
    'GBP',
    'SGD',
    'AUD',
    'THB',
    'KRW',
    'CAD',
    'HKD',
    'TWD',
    'IDR',
    'MYR',
    'AED',
    'CHF',
  ];

  @override
  void initState() {
    super.initState();
    _currency = widget.initialCurrency;

    final isZeroDecimal = _currency.toUpperCase() == 'JPY';
    final total = widget.initialTotalBudgetMinor;
    _totalBudgetController = TextEditingController(
      text: total != null
          ? (isZeroDecimal
                ? total.toString()
                : (total / 100.0).toStringAsFixed(2))
          : '',
    );

    final daily = widget.initialDailyBudgetMinor;
    _dailyBudgetController = TextEditingController(
      text: daily != null
          ? (isZeroDecimal
                ? daily.toString()
                : (daily / 100.0).toStringAsFixed(2))
          : '',
    );
  }

  @override
  void dispose() {
    _totalBudgetController.dispose();
    _dailyBudgetController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final totalText = _totalBudgetController.text.trim();
    final parsedTotal = double.tryParse(totalText);

    if (parsedTotal == null || parsedTotal <= 0) {
      setState(() => _errorMessage = 'Please enter a valid total budget.');
      return;
    }

    final isZeroDecimal = _currency.toUpperCase() == 'JPY';
    final totalMinor = isZeroDecimal
        ? parsedTotal.round()
        : (parsedTotal * 100.0).round();

    final dailyText = _dailyBudgetController.text.trim();
    int? dailyMinor;
    if (dailyText.isNotEmpty) {
      final parsedDaily = double.tryParse(dailyText);
      if (parsedDaily != null && parsedDaily > 0) {
        dailyMinor = isZeroDecimal
            ? parsedDaily.round()
            : (parsedDaily * 100.0).round();
      }
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await ref
          .read(tripBudgetProvider(widget.tripId).notifier)
          .setBudget(
            currency: _currency,
            totalBudgetMinor: totalMinor,
            dailyBudgetMinor: dailyMinor,
          );

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Trip budget saved!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to save budget: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final isEditing = widget.initialTotalBudgetMinor != null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.account_balance_wallet_rounded,
                      color: colorScheme.onPrimaryContainer,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    isEditing ? 'Edit Trip Budget' : 'Set Trip Budget',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Currency Dropdown
              DropdownButtonFormField<String>(
                initialValue: _currency,
                decoration: InputDecoration(
                  labelText: 'Base Currency',
                  helperText: 'Currency follows your residency by default',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: _currencies.map((c) {
                  return DropdownMenuItem(value: c, child: Text(c));
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _currency = val);
                },
              ),
              const SizedBox(height: 16),

              // Total Budget Input
              TextField(
                controller: _totalBudgetController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: 'Total Trip Budget',
                  hintText: 'e.g. 1500.00',
                  prefixIcon: const Icon(Icons.savings_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Daily Target Budget Input (Optional)
              TextField(
                controller: _dailyBudgetController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: 'Daily Spending Cap (Optional)',
                  hintText: 'e.g. 150.00',
                  prefixIcon: const Icon(Icons.today_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onErrorContainer,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isLoading
                          ? null
                          : () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: FilledButton(
                      onPressed: _isLoading ? null : _submit,
                      child: Text(
                        _isLoading
                            ? 'Saving...'
                            : (isEditing ? 'Save Changes' : 'Set Budget'),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
