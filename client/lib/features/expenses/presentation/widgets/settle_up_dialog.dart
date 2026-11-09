import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/currency_formatter.dart';
import '../providers/expense_provider.dart';

class SettleUpDialog extends ConsumerStatefulWidget {
  const SettleUpDialog({
    super.key,
    required this.tripId,
    required this.payerId,
    required this.payerName,
    required this.payeeId,
    required this.payeeName,
    required this.initialAmountMinor,
    required this.currency,
  });

  final String tripId;
  final String payerId;
  final String payerName;
  final String payeeId;
  final String payeeName;
  final int initialAmountMinor;
  final String currency;

  static Future<bool?> show(
    BuildContext context, {
    required String tripId,
    required String payerId,
    required String payerName,
    required String payeeId,
    required String payeeName,
    required int initialAmountMinor,
    required String currency,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => SettleUpDialog(
        tripId: tripId,
        payerId: payerId,
        payerName: payerName,
        payeeId: payeeId,
        payeeName: payeeName,
        initialAmountMinor: initialAmountMinor,
        currency: currency,
      ),
    );
  }

  @override
  ConsumerState<SettleUpDialog> createState() => _SettleUpDialogState();
}

class _SettleUpDialogState extends ConsumerState<SettleUpDialog> {
  late final TextEditingController _amountController;
  late final TextEditingController _notesController;
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final isZeroDecimal = widget.currency == 'JPY';
    _amountController = TextEditingController(
      text: isZeroDecimal
          ? widget.initialAmountMinor.toString()
          : (widget.initialAmountMinor / 100.0).toStringAsFixed(2),
    );
    _notesController = TextEditingController(text: 'Direct payment');
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final amountText = _amountController.text.trim();
    final amountParsed = double.tryParse(amountText);
    if (amountParsed == null || amountParsed <= 0) {
      setState(() => _error = 'Please enter a valid amount.');
      return;
    }

    final isZeroDecimal = CurrencyFormatter.isZeroDecimal(widget.currency);
    final amountMinor = isZeroDecimal
        ? amountParsed.round()
        : (amountParsed * 100).round();

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      final repo = ref.read(expenseRepositoryProvider);
      await repo.recordSettlement(
        widget.tripId,
        payerId: widget.payerId,
        payeeId: widget.payeeId,
        amountMinor: amountMinor,
        currency: widget.currency,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );

      ref.invalidate(groupBalancesProvider(widget.tripId));
      ref.invalidate(expenseSummaryProvider(widget.tripId));

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _submitting = false;
          _error = 'Failed to record settlement: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AlertDialog(
      title: const Text('Record Settlement'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Payer',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        Text(
                          widget.payerName,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward_rounded, color: colorScheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Payee',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        Text(
                          widget.payeeName,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: 'Amount (${widget.currency})',
                prefixText: widget.currency == 'JPY' ? '¥ ' : '\$ ',
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Payment Note',
                hintText: 'e.g. Cash, Venmo, Revolut',
                border: OutlineInputBorder(),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.error,
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submitting ? null : _submit,
          child: _submitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Confirm Settle'),
        ),
      ],
    );
  }
}
