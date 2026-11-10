import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exceptions.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../auth/domain/models/auth_state.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../circles/domain/models/circle_member.dart';
import '../../../circles/presentation/providers/trip_circle_provider.dart';
import '../../data/currency_repository.dart';
import '../../data/expense_repository.dart';
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
  late String _visibility;
  late DateTime _selectedDate;

  String? _selectedPayerId;
  final Set<String> _selectedParticipantIds = {};
  final Map<String, TextEditingController> _customControllers = {};

  bool _isLoading = false;
  bool _isRateUnavailable = false;
  String? _errorMessage;
  String? _convertedText;
  double? _currentRate = 1.0;
  String? _rateSource = 'identity';
  String? _rateCapturedAt;

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
      final isZeroDecimal = CurrencyFormatter.isZeroDecimal(expense.currency);
      _amountController = TextEditingController(
        text: isZeroDecimal
            ? expense.amountMinor.toString()
            : (expense.amountMinor / 100.0).toStringAsFixed(2),
      );
      _currentRate = expense.exchangeRate;
      _rateSource = expense.rateSource;
      _rateCapturedAt = expense.rateCapturedAt;
      _isRateUnavailable = expense.isConversionUnavailable;
      _selectedPayerId = expense.payerId;
      for (final split in expense.splits) {
        _selectedParticipantIds.add(split.userId);
        _customControllers[split.userId] = TextEditingController(
          text: isZeroDecimal
              ? split.amountMinor.toString()
              : (split.amountMinor / 100.0).toStringAsFixed(2),
        );
      }
    } else {
      _amountController = TextEditingController();
    }

    _notesController = TextEditingController(text: expense?.notes ?? '');
    _category = expense?.category ?? 'dining';
    _currency = expense?.currency ?? widget.defaultCurrency;
    _splitType = expense?.splitType ?? 'single';
    _visibility =
        expense?.visibility ?? (_splitType == 'single' ? 'private' : 'shared');
    _selectedDate = expense != null
        ? (DateTime.tryParse(expense.expenseDate) ?? DateTime.now())
        : DateTime.now();

    _amountController.addListener(_onAmountOrCurrencyChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateConversion());
  }

  @override
  void dispose() {
    _amountController.removeListener(_onAmountOrCurrencyChanged);
    _titleController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    for (final ctrl in _customControllers.values) {
      ctrl.dispose();
    }
    super.dispose();
  }

  void _onAmountOrCurrencyChanged() {
    _updateConversion();
    if (_splitType == 'custom' || _splitType == 'selected') {
      setState(() {});
    }
  }

  int _parseMinor(String raw, String currency) {
    final parsed = double.tryParse(raw.trim());
    if (parsed == null || parsed <= 0) return 0;
    return CurrencyFormatter.isZeroDecimal(currency)
        ? parsed.round()
        : (parsed * 100.0).round();
  }

  void _ensureCustomControllers(List<CircleMember> members) {
    final totalMinor = _parseMinor(_amountController.text, _currency);
    final isZeroDecimal = CurrencyFormatter.isZeroDecimal(_currency);
    final existingMissing = members.any(
      (m) => !_customControllers.containsKey(m.userId),
    );
    if (!existingMissing) return;

    final equalMap = totalMinor > 0
        ? ExpenseRepository.allocateEqualMinor(
            totalMinor,
            members.map((m) => m.userId).toList(),
          )
        : const <String, int>{};

    for (final m in members) {
      _customControllers.putIfAbsent(m.userId, () {
        final seedMinor = equalMap[m.userId] ?? 0;
        final text = seedMinor > 0
            ? (isZeroDecimal
                  ? seedMinor.toString()
                  : (seedMinor / 100.0).toStringAsFixed(2))
            : (isZeroDecimal ? '0' : '0.00');
        final ctrl = TextEditingController(text: text);
        ctrl.addListener(() {
          if (mounted && _splitType == 'custom') {
            setState(() {});
          }
        });
        return ctrl;
      });
    }
  }

  Future<void> _updateConversion() async {
    final amountText = _amountController.text.trim();
    final parsed = double.tryParse(amountText);

    if (_currency.toUpperCase() == widget.homeCurrency.toUpperCase()) {
      if (mounted) {
        setState(() {
          _convertedText = null;
          _currentRate = 1.0;
          _rateSource = 'identity';
          _isRateUnavailable = false;
          _rateCapturedAt = DateTime.now().toUtc().toIso8601String();
        });
      }
      return;
    }

    if (parsed == null || parsed <= 0) {
      if (mounted) {
        setState(() {
          _convertedText = null;
          _isRateUnavailable = false;
        });
      }
      return;
    }

    final repo = ref.read(currencyRepositoryProvider);
    final details = await repo.tryGetRateDetails(
      _currency,
      widget.homeCurrency,
    );
    if (!mounted) return;

    if (details.isUnavailable) {
      setState(() {
        _currentRate = null;
        _rateSource = 'unavailable';
        _rateCapturedAt = null;
        _isRateUnavailable = true;
        _convertedText = null;
      });
      return;
    }

    final rate = details.rate;
    final converted = parsed * rate;
    final symbol = CurrencyFormatter.symbol(widget.homeCurrency);
    final rateStr = rate < 0.01
        ? rate.toStringAsFixed(6)
        : rate.toStringAsFixed(4);
    final formattedAmount = CurrencyFormatter.isZeroDecimal(widget.homeCurrency)
        ? converted.round().toString()
        : converted.toStringAsFixed(2);

    setState(() {
      _currentRate = rate;
      _rateSource = details.provider;
      _rateCapturedAt = details.asOf;
      _isRateUnavailable = false;
      _convertedText =
          '≈ $symbol$formattedAmount ${widget.homeCurrency} (1 $_currency = $rateStr ${widget.homeCurrency})';
    });
  }

  Future<void> _submit(List<CircleMember> acceptedMembers) async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      setState(() => _errorMessage = 'Please enter a title or description.');
      return;
    }

    final amountMinor = _parseMinor(_amountController.text, _currency);
    if (amountMinor <= 0) {
      setState(() => _errorMessage = 'Please enter a valid amount.');
      return;
    }

    List<String>? participantIds;
    List<Map<String, dynamic>>? customSplitsPayload;

    if (_splitType == 'selected' && acceptedMembers.isNotEmpty) {
      final selected = acceptedMembers
          .where((m) => _selectedParticipantIds.contains(m.userId))
          .map((m) => m.userId)
          .toList();
      if (selected.isEmpty) {
        setState(
          () => _errorMessage =
              'Select at least one companion to include in this split.',
        );
        return;
      }
      participantIds = selected;
    } else if (_splitType == 'custom' && acceptedMembers.isNotEmpty) {
      final splitsList = <Map<String, dynamic>>[];
      var sumMinor = 0;
      for (final member in acceptedMembers) {
        final shareMinor = _parseMinor(
          _customControllers[member.userId]?.text ?? '',
          _currency,
        );
        if (shareMinor > 0) {
          sumMinor += shareMinor;
          splitsList.add({
            'user_id': member.userId,
            'amount_minor': shareMinor,
          });
        }
      }
      if (splitsList.isEmpty || sumMinor != amountMinor) {
        final expectedStr = CurrencyFormatter.formatAmount(
          amountMinor,
          _currency,
          isMinor: true,
        );
        final assignedStr = CurrencyFormatter.formatAmount(
          sumMinor,
          _currency,
          isMinor: true,
        );
        setState(
          () => _errorMessage =
              'Custom shares ($assignedStr) must equal total ($expectedStr).',
        );
        return;
      }
      customSplitsPayload = splitsList;
    }

    final resolvedVisibility = _splitType == 'single' ? _visibility : 'shared';
    final dateStr =
        '${_selectedDate.year.toString().padLeft(4, '0')}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final conversionStatus = _isRateUnavailable ? 'unavailable' : 'converted';
      final payerIdToSend = acceptedMembers.isNotEmpty
          ? _selectedPayerId
          : null;

      if (widget.initialExpense != null) {
        await ref
            .read(tripExpensesProvider(widget.tripId).notifier)
            .updateExpense(
              widget.initialExpense!.id,
              payerId: payerIdToSend,
              title: title,
              amountMinor: amountMinor,
              currency: _currency,
              exchangeRate: _currentRate,
              rateSource: _rateSource,
              rateCapturedAt: _rateCapturedAt,
              conversionStatus: conversionStatus,
              category: _category,
              expenseDate: dateStr,
              splitType: _splitType,
              visibility: resolvedVisibility,
              participantIds: participantIds,
              splits: customSplitsPayload,
              notes: _notesController.text.trim().isNotEmpty
                  ? _notesController.text.trim()
                  : null,
            );
      } else {
        await ref
            .read(tripExpensesProvider(widget.tripId).notifier)
            .addExpense(
              payerId: payerIdToSend,
              category: _category,
              title: title,
              amountMinor: amountMinor,
              currency: _currency,
              exchangeRate: _currentRate,
              rateSource: _rateSource,
              rateCapturedAt: _rateCapturedAt,
              conversionStatus: conversionStatus,
              expenseDate: dateStr,
              splitType: _splitType,
              visibility: resolvedVisibility,
              participantIds: participantIds,
              splits: customSplitsPayload,
              notes: _notesController.text.trim().isNotEmpty
                  ? _notesController.text.trim()
                  : null,
            );
      }

      if (mounted) {
        final messenger = ScaffoldMessenger.of(context);
        final colorScheme = Theme.of(context).colorScheme;
        Navigator.of(context).pop();
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              widget.initialExpense != null
                  ? 'Expense updated!'
                  : 'Expense logged successfully!',
            ),
            backgroundColor: colorScheme.primary,
          ),
        );
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.message;
        });
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

    final authState = ref.watch(authProvider);
    final currentUserId = authState is Authenticated ? authState.user.id : null;
    final allMembers = currentUserId != null
        ? ref.watch(circleMembersProvider(widget.tripId)).asData?.value ??
              const <CircleMember>[]
        : const <CircleMember>[];
    final acceptedMembers = allMembers
        .where((m) => m.invitationStatus == 'accepted' && m.userId.isNotEmpty)
        .toList();

    if (acceptedMembers.isNotEmpty) {
      _selectedPayerId ??= acceptedMembers.any((m) => m.userId == currentUserId)
          ? currentUserId
          : acceptedMembers.first.userId;
      if (_selectedParticipantIds.isEmpty) {
        _selectedParticipantIds.addAll(acceptedMembers.map((m) => m.userId));
      }
      if (_splitType == 'custom') {
        _ensureCustomControllers(acceptedMembers);
      }
    }

    final totalMinor = _parseMinor(_amountController.text, _currency);
    final isGroupSplit = _splitType != 'single';

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Material(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: colorScheme.onSurfaceVariant.withValues(
                        alpha: 0.3,
                      ),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

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
                        color: colorScheme.outlineVariant.withValues(
                          alpha: 0.5,
                        ),
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
                ] else if (_isRateUnavailable) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.secondaryContainer.withValues(
                        alpha: 0.45,
                      ),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: colorScheme.secondary.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.cloud_off_rounded,
                          size: 16,
                          color: colorScheme.onSecondaryContainer,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Conversion rate unavailable offline. Stored in $_currency without inventing a conversion rate.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSecondaryContainer,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 16),

                if (acceptedMembers.isNotEmpty) ...[
                  DropdownButtonFormField<String>(
                    initialValue:
                        acceptedMembers.any((m) => m.userId == _selectedPayerId)
                        ? _selectedPayerId
                        : acceptedMembers.first.userId,
                    decoration: InputDecoration(
                      labelText: 'Paid by',
                      prefixIcon: const Icon(Icons.person_outline_rounded),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    items: acceptedMembers.map((member) {
                      final label = member.userId == currentUserId
                          ? '${member.displayName} (You)'
                          : member.displayName;
                      return DropdownMenuItem(
                        value: member.userId,
                        child: Text(label, overflow: TextOverflow.ellipsis),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _selectedPayerId = val);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                ],

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
                        color: isSelected
                            ? colorScheme.onPrimaryContainer
                            : colorScheme.primary,
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

                Text(
                  'Split with group',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ChoiceChip(
                      label: const Text('Just me'),
                      selected: _splitType == 'single',
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _splitType = 'single';
                            _visibility = 'private';
                          });
                        }
                      },
                    ),
                    ChoiceChip(
                      label: const Text('Split equally'),
                      selected: _splitType == 'equal',
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _splitType = 'equal';
                            _visibility = 'shared';
                          });
                        }
                      },
                    ),
                    if (acceptedMembers.isNotEmpty) ...[
                      ChoiceChip(
                        label: const Text('Select travelers'),
                        selected: _splitType == 'selected',
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _splitType = 'selected';
                              _visibility = 'shared';
                            });
                          }
                        },
                      ),
                      ChoiceChip(
                        label: const Text('Custom amounts'),
                        selected: _splitType == 'custom',
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _splitType = 'custom';
                              _visibility = 'shared';
                              _ensureCustomControllers(acceptedMembers);
                            });
                          }
                        },
                      ),
                    ],
                  ],
                ),

                if (!isGroupSplit && acceptedMembers.length > 1) ...[
                  const SizedBox(height: 8),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    value: _visibility == 'shared',
                    onChanged: (shared) {
                      setState(
                        () => _visibility = shared ? 'shared' : 'private',
                      );
                    },
                    title: const Text('Share with companions'),
                    subtitle: Text(
                      _visibility == 'private'
                          ? 'Private personal expense — hidden from companions'
                          : 'Visible to circle companions without splitting debt',
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                ],

                if (acceptedMembers.isNotEmpty && _splitType == 'equal') ...[
                  const SizedBox(height: 8),
                  _buildSplitPreviewBanner(
                    theme,
                    colorScheme,
                    totalMinor,
                    acceptedMembers.map((m) => m.userId).toList(),
                  ),
                ],

                if (acceptedMembers.isNotEmpty && _splitType == 'selected') ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: acceptedMembers.map((m) {
                      final selected = _selectedParticipantIds.contains(
                        m.userId,
                      );
                      return FilterChip(
                        label: Text(m.displayName),
                        selected: selected,
                        onSelected: (val) {
                          setState(() {
                            if (val) {
                              _selectedParticipantIds.add(m.userId);
                            } else {
                              _selectedParticipantIds.remove(m.userId);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 8),
                  _buildSplitPreviewBanner(
                    theme,
                    colorScheme,
                    totalMinor,
                    acceptedMembers
                        .where(
                          (m) => _selectedParticipantIds.contains(m.userId),
                        )
                        .map((m) => m.userId)
                        .toList(),
                  ),
                ],

                if (acceptedMembers.isNotEmpty && _splitType == 'custom') ...[
                  const SizedBox(height: 12),
                  _buildCustomSplitInputs(
                    theme,
                    colorScheme,
                    acceptedMembers,
                    totalMinor,
                  ),
                ],

                const SizedBox(height: 16),

                TextField(
                  controller: _notesController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: 'Notes (Optional)',
                    hintText: 'Split note, cash payment, etc.',
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
                        onPressed: _isLoading
                            ? null
                            : () => _submit(acceptedMembers),
                        icon: _isLoading
                            ? SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: colorScheme.onPrimary,
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
      ),
    );
  }

  Widget _buildSplitPreviewBanner(
    ThemeData theme,
    ColorScheme colorScheme,
    int totalMinor,
    List<String> participantIds,
  ) {
    if (participantIds.isEmpty) {
      return Text(
        'Select at least 1 traveler to include in the split.',
        style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.error),
      );
    }

    final allocations = ExpenseRepository.allocateEqualMinor(
      totalMinor,
      participantIds,
    );
    final perShareMinor = totalMinor > 0 ? allocations.values.first : 0;
    final formatted = CurrencyFormatter.formatAmount(
      perShareMinor,
      _currency,
      isMinor: true,
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        totalMinor > 0
            ? 'Split across ${participantIds.length} travelers • ~$formatted each (exact integer minor units)'
            : 'Split equally across ${participantIds.length} travelers',
        style: theme.textTheme.bodySmall?.copyWith(
          color: colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildCustomSplitInputs(
    ThemeData theme,
    ColorScheme colorScheme,
    List<CircleMember> members,
    int totalMinor,
  ) {
    var assignedMinor = 0;
    for (final m in members) {
      assignedMinor += _parseMinor(
        _customControllers[m.userId]?.text ?? '',
        _currency,
      );
    }
    final remainingMinor = totalMinor - assignedMinor;
    final isBalanced = totalMinor > 0 && remainingMinor == 0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isBalanced
              ? colorScheme.primary.withValues(alpha: 0.4)
              : colorScheme.error.withValues(alpha: 0.45),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Custom Split Shares ($_currency)',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                isBalanced
                    ? 'Exact match'
                    : 'Diff: ${CurrencyFormatter.formatAmount(remainingMinor, _currency, isMinor: true)}',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isBalanced ? colorScheme.primary : colorScheme.error,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...members.map(
            (m) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(
                      m.displayName,
                      style: theme.textTheme.bodyMedium,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: _customControllers[m.userId],
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        isDense: true,
                        prefixText: CurrencyFormatter.symbol(_currency),
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
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
