import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/countries.dart';
import '../providers/auth_provider.dart';

class CountryResidenceDialog extends ConsumerStatefulWidget {
  const CountryResidenceDialog({super.key, this.currentCountryCode});

  final String? currentCountryCode;

  static Future<CountryItem?> show(
    BuildContext context, {
    String? currentCountryCode,
  }) {
    return showDialog<CountryItem>(
      context: context,
      builder: (ctx) =>
          CountryResidenceDialog(currentCountryCode: currentCountryCode),
    );
  }

  @override
  ConsumerState<CountryResidenceDialog> createState() =>
      _CountryResidenceDialogState();
}

class _CountryResidenceDialogState
    extends ConsumerState<CountryResidenceDialog> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  bool _isSaving = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final filtered = CountryCurrencyHelper.supportedCountries.where((c) {
      if (_query.isEmpty) return true;
      final q = _query.toLowerCase();
      return c.name.toLowerCase().contains(q) ||
          c.code.toLowerCase().contains(q) ||
          c.currency.toLowerCase().contains(q);
    }).toList();

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.public, color: colorScheme.primary),
              const SizedBox(width: 8),
              const Text('Country of Residence'),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Select where you reside to automatically configure your home currency and conversion rates.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        height: 380,
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search, size: 20),
                hintText: 'Search country or currency...',
                isDense: true,
                filled: true,
                fillColor: colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.4,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (val) => setState(() => _query = val),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _isSaving
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.separated(
                      itemCount: filtered.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (ctx, idx) {
                        final item = filtered[idx];
                        final isSelected =
                            item.code == widget.currentCountryCode;

                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          leading: Text(
                            item.flag,
                            style: const TextStyle(fontSize: 24),
                          ),
                          title: Text(
                            item.name,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: colorScheme.primaryContainer,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  item.currency,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.onPrimaryContainer,
                                  ),
                                ),
                              ),
                              if (isSelected) ...[
                                const SizedBox(width: 8),
                                Icon(
                                  Icons.check_circle,
                                  color: colorScheme.primary,
                                  size: 20,
                                ),
                              ],
                            ],
                          ),
                          onTap: () async {
                            final navigator = Navigator.of(context);
                            setState(() => _isSaving = true);
                            await ref
                                .read(authProvider.notifier)
                                .updateProfile(
                                  homeCountry: item.code,
                                  homeCurrency: item.currency,
                                );
                            if (mounted) {
                              navigator.pop(item);
                            }
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}
