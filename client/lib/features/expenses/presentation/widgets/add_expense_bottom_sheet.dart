import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/currency_repository.dart';
import '../../domain/models/expense.dart';
import '../providers/expense_provider.dart';

class AddExpenseBottomSheet extends ConsumerStatefulWidget {
  const AddExpenseBottomSheet({
    super.key,
    required this.tripId,
    this.initialExpense,
    this.defaultCurrency = 'USD',
    this.homeCurrency = 'USD',
  });

  final String tripId;
  final Expense? initialExpense;
  final String defaultCurrency;
  final String homeCurrency;

  static Future<void> show(
    BuildContext context, {
    required String tripId,
    Expense? initialExpense,
    String defaultCurrency = 'USD',
    String homeCurrency = 'USD',
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AddExpenseBottomSheet(
        tripId: tripId,
        initialExpense: initialExpense,
        defaultCurrency: defaultCurrency,
        homeCurrency: homeCurrency,
      ),
    );
  }

  @override
  ConsumerState<AddExpenseBottomSheet> createState() =>
      _AddExpenseBottomSheetState();
}

class _AddExpenseBottomSheetState extends ConsumerState<AddExpenseBottomSheet> {
  late final TextEditingController _titleController;
  late final TextEditingController _amountController;
  late final TextEditingController _notesController;
  late String _category;
  late String _currency;
  late String _splitType;
  late DateTime _selectedDate;
  bool _isLoading = false;
  String? _errorMessage;
  String? _convertedText;
  double _currentRate = 1.0;

  final List<String> _categories = const [
    'dining',
    'transport',
    'accommodation',
    'activities',
    'shopping',
    'other',
  ];

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
    final expense = widget.initialExpense;
    _titleController = TextEditingController(text: expense?.title ?? '');

    if (expense != null) {
      final isZeroDecimal = expense.currency.toUpperCase() == 'JPY';
      _amountController = TextEditingController(
        text: isZeroDecimal
            ? expense.amountMinor.toString()
            : (expense.amountMinor / 100.0).toStringAsFixed(2),
      );
      _currentRate = expense.exchangeRate;
    } else {
      _amountController = TextEditingController();
    }

    _notesController = TextEditingController(text: expense?.notes ?? '');
    _category = expense?.category ?? 'dining';
    _currency = expense?.currency ?? widget.defaultCurrency;
    _splitType = expense?.splitType ?? 'single';
    _selectedDate = expense != null
        ? (DateTime.tryParse(expense.expenseDate) ?? DateTime.now())
        : DateTime.now();

    _amountController.addListener(_updateConversion);
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateConversion());
  }

  @override
  void dispose() {
    _amountController.removeListener(_updateConversion);
    _titleController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _updateConversion() async {
    final amountText = _amountController.text.trim();
    final parsed = double.tryParse(amountText);
    if (parsed == null ||
        parsed <= 0 ||
        _currency.toUpperCase() == widget.homeCurrency.toUpperCase()) {
      if (mounted) {
        setState(() {
          _convertedText = null;
          _currentRate = 1.0;
        });
      }
      return;
    }

    try {
      final repo = ref.read(currencyRepositoryProvider);
      final details = await repo.getRateDetails(_currency, widget.homeCurrency);
      if (!mounted) return;

      final rate = details.rate;
      final converted = parsed * rate;
      final isTargetZeroDecimal = widget.homeCurrency.toUpperCase() == 'JPY';
      final symbol = _currencySymbol(widget.homeCurrency);
      final rateStr =
          rate < 0.01 ? rate.toStringAsFixed(6) : rate.toStringAsFixed(4);
      final formattedAmount = isTargetZeroDecimal
          ? converted.round().toString()
          : converted.toStringAsFixed(2);

      setState(() {
        _currentRate = rate;
        _convertedText =
            '≈ $symbol$formattedAmount ${widget.homeCurrency} (1 $_currency = $rateStr ${widget.homeCurrency})';
      });
    } catch (_) {}
  }

  String _currencySymbol(String curr) {
    switch (curr.toUpperCase()) {
      case 'PHP':
        return '₱';
      case 'JPY':
        return '¥';
      case 'EUR':
        return '€';
      case 'GBP':
        return '£';
      case 'SGD':
        return 'S\$';
      case 'AUD':
        return 'A\$';
      case 'THB':
        return '฿';
      case 'KRW':
        return '₩';
      case 'CAD':
        return 'C\$';
      case 'HKD':
        return 'HK\$';
      case 'USD':
      default:
        return '\$';
    }
  }

  Future<void> _submit() async {
    final title = _titleController.text.trim();
    final amountText = _amountController.text.trim();

    if (title.isEmpty) {
      setState(() => _errorMessage = 'Please enter a title or description.');
      return;
    }

    final parsedAmount = double.tryParse(amountText);
    if (parsedAmount == null || parsedAmount <= 0) {
      setState(() => _errorMessage = 'Please enter a valid amount.');
      return;
    }

    final isZeroDecimal = _currency.toUpperCase() == 'JPY';
    final amountMinor = isZeroDecimal
        ? parsedAmount.round()
        : (parsedAmount * 100.0).round();

    final dateStr =
        '${_selectedDate.year.toString().padLeft(4, '0')}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (widget.initialExpense != null) {
        await ref
            .read(tripExpensesProvider(widget.tripId).notifier)
            .updateExpense(
              widget.initialExpense!.id,
              title: title,
              amountMinor: amountMinor,
              currency: _currency,
              exchangeRate: _currentRate,
              category: _category,
              expenseDate: dateStr,
              notes: _notesController.text.trim().isNotEmpty
                  ? _notesController.text.trim()
                  : null,
            );
      } else {
        await ref
            .read(tripExpensesProvider(widget.tripId).notifier)
            .addExpense(
              category: _category,
              title: title,
              amountMinor: amountMinor,
              currency: _currency,
              exchangeRate: _currentRate,
              expenseDate: dateStr,
              splitType: _splitType,
              notes: _notesController.text.trim().isNotEmpty
                  ? _notesController.text.trim()
                  : null,
            );
      }

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.initialExpense != null
                  ? 'Expense updated!'
                  : 'Expense logged successfully!',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to save expense: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isEditing = widget.initialExpense != null;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Title Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.receipt_long_rounded,
                      color: colorScheme.onPrimaryContainer,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    isEditing ? 'Edit Expense' : 'Log Expense',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Title input
              TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'What did you pay for?',
                  hintText: 'e.g. Dinner in Shibuya, Taxi to airport',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Amount and Currency Row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: _amountController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Amount',
                        hintText: '0.00',
                        prefixIcon: const Icon(Icons.attach_money_rounded),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 1,
                    child: DropdownButtonFormField<String>(
                      initialValue: _currency,
                      decoration: InputDecoration(
                        labelText: 'Currency',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                      ),
                      items: _currencies.map((c) {
                        return DropdownMenuItem(value: c, child: Text(c));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _currency = val);
                          _updateConversion();
                        }
                      },
                    ),
                  ),
                ],
              ),
              if (_convertedText != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest.withValues(
                      alpha: 0.5,
                    ),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.currency_exchange_rounded,
                        size: 16,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _convertedText!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),

              // Category Selector
              Text(
                'Category',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _categories.map((cat) {
                  final isSelected = _category == cat;
                  return ChoiceChip(
                    avatar: Icon(
                      Expense.getCategoryIcon(cat),
                      size: 16,
                      color: isSelected ? Colors.white : colorScheme.primary,
                    ),
                    label: Text(_formatCategoryLabel(cat)),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) setState(() => _category = cat);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Split Type Selector
              Text(
                'Split with group',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: const Center(child: Text('Just me')),
                      selected: _splitType == 'single',
                      onSelected: (selected) {
                        if (selected) setState(() => _splitType = 'single');
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ChoiceChip(
                      label: const Center(child: Text('Split equally')),
                      selected: _splitType == 'equal',
                      onSelected: (selected) {
                        if (selected) setState(() => _splitType = 'equal');
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Notes Input
              TextField(
                controller: _notesController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Notes (Optional)',
                  hintText: 'Split with Alex, cash payment, etc.',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
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

              // Action Buttons
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
                    child: FilledButton.icon(
                      onPressed: _isLoading ? null : _submit,
                      icon: _isLoading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.check_rounded, size: 18),
                      label: Text(
                        _isLoading
                            ? 'Saving...'
                            : (isEditing ? 'Save Changes' : 'Log Expense'),
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

  String _formatCategoryLabel(String cat) {
    switch (cat.toLowerCase()) {
      case 'dining':
        return 'Dining';
      case 'transport':
        return 'Transport';
      case 'accommodation':
        return 'Stay';
      case 'activities':
        return 'Activities';
      case 'shopping':
        return 'Shopping';
      case 'other':
      default:
        return 'Other';
    }
  }
}
