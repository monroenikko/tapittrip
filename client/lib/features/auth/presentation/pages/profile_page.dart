import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/countries.dart';
import '../../domain/models/auth_state.dart';
import '../providers/auth_provider.dart';
import '../widgets/country_residence_dialog.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _displayNameController;
  late final TextEditingController _addressController;
  String? _selectedCountryCode;
  String? _selectedCurrency;
  bool _isSaving = false;

  final List<String> _popularCurrencies = const [
    'PHP',
    'USD',
    'JPY',
    'EUR',
    'GBP',
    'SGD',
    'AUD',
    'CAD',
    'HKD',
    'THB',
    'KRW',
    'TWD',
    'IDR',
    'MYR',
    'AED',
    'VND',
    'CHF',
  ];

  @override
  void initState() {
    super.initState();
    final auth = ref.read(authProvider);
    final user = auth is Authenticated ? auth.user : null;

    _nameController = TextEditingController(text: user?.name ?? '');
    _displayNameController = TextEditingController(
      text: user?.displayName ?? user?.name ?? '',
    );
    _addressController = TextEditingController(
      text: user?.permanentAddress ?? '',
    );
    _selectedCountryCode = user?.homeCountry ?? 'PH';
    _selectedCurrency = user?.homeCurrency ?? 'PHP';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _displayNameController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final success = await ref
        .read(authProvider.notifier)
        .updateProfile(
          displayName: _displayNameController.text.trim(),
          permanentAddress: _addressController.text.trim(),
          homeCountry: _selectedCountryCode,
          homeCurrency: _selectedCurrency,
        );

    if (mounted) {
      setState(() => _isSaving = false);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile and travel currency settings updated!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update profile. Please try again.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final authState = ref.watch(authProvider);
    final user = authState is Authenticated ? authState.user : null;

    final countryItem = CountryCurrencyHelper.findByCode(_selectedCountryCode);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile & Settings'),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _saveProfile,
            child: _isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: user == null
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // User Avatar & Email Header
                  Center(
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: colorScheme.primaryContainer,
                          child: Text(
                            (user.displayName.isNotEmpty
                                    ? user.displayName[0]
                                    : user.name[0])
                                .toUpperCase(),
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          user.displayName.isNotEmpty
                              ? user.displayName
                              : user.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          user.email,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Forex Conversion Advisory Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          colorScheme.primaryContainer.withValues(alpha: 0.45),
                          colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: colorScheme.primary.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.currency_exchange_rounded,
                          size: 24,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Travel Currency & Forex Conversion',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.primary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Your permanent address and country of residence determine your home currency '
                                '(${_selectedCurrency ?? 'PHP'}). When you travel abroad, TapItTrip automatically converts destination '
                                'expenses and daily budget limits into this currency so you always have full visibility over your spending.',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  height: 1.35,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Display Name
                  TextFormField(
                    controller: _displayNameController,
                    decoration: const InputDecoration(
                      labelText: 'Display Name',
                      prefixIcon: Icon(Icons.badge_outlined),
                    ),
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 16),

                  // Permanent Address
                  TextFormField(
                    controller: _addressController,
                    decoration: const InputDecoration(
                      labelText: 'Permanent Address / Home City',
                      hintText: 'e.g. Taguig City, Philippines',
                      prefixIcon: Icon(Icons.home_outlined),
                      helperText:
                          'Used to automatically detect your local home currency',
                    ),
                    textInputAction: TextInputAction.next,
                    onChanged: (val) {
                      final currency = CountryCurrencyHelper.resolveCurrency(val);
                      for (final c in CountryCurrencyHelper.supportedCountries) {
                        if (c.currency == currency) {
                          setState(() {
                            _selectedCountryCode = c.code;
                            _selectedCurrency = c.currency;
                          });
                          break;
                        }
                      }
                    },
                  ),
                  const SizedBox(height: 16),

                  // Country of Residence Tile
                  InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () async {
                      final picked = await CountryResidenceDialog.show(
                        context,
                        currentCountryCode: _selectedCountryCode,
                      );
                      if (picked != null) {
                        setState(() {
                          _selectedCountryCode = picked.code;
                          _selectedCurrency = picked.currency;
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest.withValues(
                          alpha: 0.45,
                        ),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: colorScheme.outlineVariant.withValues(alpha: 0.6),
                        ),
                      ),
                      child: Row(
                        children: [
                          Text(
                            countryItem?.flag ?? '🌏',
                            style: const TextStyle(fontSize: 26),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Country of Residence',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  countryItem?.name ??
                                      _selectedCountryCode ??
                                      'Select Country',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Change',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.onPrimaryContainer,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.chevron_right,
                                  size: 16,
                                  color: colorScheme.onPrimaryContainer,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Home Currency Dropdown
                  DropdownButtonFormField<String>(
                    initialValue: _selectedCurrency,
                    decoration: const InputDecoration(
                      labelText: 'Home Base Currency',
                      prefixIcon: Icon(Icons.attach_money_rounded),
                      helperText:
                          'All foreign expenses are converted to this currency',
                    ),
                    items: _popularCurrencies.map((c) {
                      return DropdownMenuItem(
                        value: c,
                        child: Text(
                          '$c (${CountryCurrencyHelper.supportedCountries.firstWhere((item) => item.currency == c, orElse: () => const CountryItem(name: '', code: '', currency: '', flag: '🌐')).flag})',
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedCurrency = val);
                    },
                  ),
                  const SizedBox(height: 28),

                  // Save Button
                  FilledButton.icon(
                    onPressed: _isSaving ? null : _saveProfile,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.save_rounded),
                    label: Text(_isSaving ? 'Saving...' : 'Save Profile'),
                  ),
                  const SizedBox(height: 32),

                  // Account Actions Section
                  const Divider(),
                  const SizedBox(height: 12),
                  Text(
                    'Account',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),

                  ListTile(
                    leading: const Icon(Icons.logout),
                    title: const Text('Log out'),
                    onTap: () async {
                      await ref.read(authProvider.notifier).logout();
                      if (context.mounted) {
                        context.go('/login');
                      }
                    },
                  ),
                  ListTile(
                    leading: Icon(
                      Icons.delete_forever,
                      color: colorScheme.error,
                    ),
                    title: Text(
                      'Delete account',
                      style: TextStyle(color: colorScheme.error),
                    ),
                    onTap: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Delete Account'),
                          content: const Text(
                            'Are you sure you want to delete your account? All trips and offline data will be removed permanently.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text('Cancel'),
                            ),
                            FilledButton(
                              style: FilledButton.styleFrom(
                                backgroundColor: colorScheme.error,
                              ),
                              onPressed: () => Navigator.pop(ctx, true),
                              child: const Text('Delete'),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        await ref.read(authProvider.notifier).deleteAccount();
                        if (context.mounted) {
                          context.go('/login');
                        }
                      }
                    },
                  ),
                ],
              ),
            ),
    );
  }
}
