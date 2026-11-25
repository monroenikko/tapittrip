import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/map_launcher.dart';
import '../../data/safety_repository.dart';
import '../../domain/models/destination_safety_profile.dart';
import '../providers/safety_provider.dart';

class DestinationSafetyPage extends ConsumerStatefulWidget {
  const DestinationSafetyPage({super.key, this.tripId, this.initialCountry});

  final String? tripId;
  final String? initialCountry;

  @override
  ConsumerState<DestinationSafetyPage> createState() =>
      _DestinationSafetyPageState();
}

class _DestinationSafetyPageState extends ConsumerState<DestinationSafetyPage> {
  late String _selectedCountry;

  @override
  void initState() {
    super.initState();
    final init = widget.initialCountry?.trim();
    final hasTrip = widget.tripId != null && widget.tripId!.trim().isNotEmpty;
    _selectedCountry = (init != null && init.isNotEmpty)
        ? init
        : (hasTrip ? '' : 'JP');
  }

  Future<void> _copyNumber(
    BuildContext context,
    String label,
    String number,
  ) async {
    await Clipboard.setData(ClipboardData(text: number));
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Copied $label number: $number')));
    }
  }

  Future<void> _openMapQuery(BuildContext context, String query) async {
    final success = await MapLauncher.launchDirections(query: query);
    if (!success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to launch maps search.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final request = SafetyLookupRequest(
      tripId: widget.tripId,
      country: _selectedCountry,
    );
    final profileAsync = ref.watch(destinationSafetyProfileProvider(request));
    final directoryAsync = ref.watch(curatedSafetyDirectoryProvider);
    final curatedList =
        directoryAsync.value ?? SafetyRepository.bundledOfflineProfiles;
    final activeCountryCode =
        profileAsync.value?.countryCode ?? _selectedCountry.toUpperCase();

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(title: const Text('Safety & Emergency Directory')),
      body: Column(
        children: [
          // Country selector chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Row(
              children: [
                for (final item in curatedList) ...[
                  ChoiceChip(
                    label: Text('${item.flagEmoji} ${item.countryName}'),
                    selected:
                        activeCountryCode.toUpperCase() == item.countryCode ||
                        _selectedCountry.toUpperCase() == item.countryCode ||
                        _selectedCountry.toLowerCase() ==
                            item.countryName.toLowerCase(),
                    onSelected: (_) {
                      setState(() {
                        _selectedCountry = item.countryCode;
                      });
                    },
                  ),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: profileAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.error_outline_rounded,
                        size: 48,
                        color: colorScheme.error,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Unable to load safety directory',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        err.toString(),
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
              data: (profile) => _SafetyProfileView(
                profile: profile,
                onCopyNumber: (label, number) =>
                    _copyNumber(context, label, number),
                onSearchMaps: (query) => _openMapQuery(context, query),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SafetyProfileView extends StatelessWidget {
  const _SafetyProfileView({
    required this.profile,
    required this.onCopyNumber,
    required this.onSearchMaps,
  });

  final DestinationSafetyProfile profile;
  final void Function(String label, String number) onCopyNumber;
  final void Function(String query) onSearchMaps;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final numbers = profile.emergencyNumbers;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        // Country Header Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
          child: Row(
            children: [
              Text(profile.flagEmoji, style: const TextStyle(fontSize: 34)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.countryName,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      profile.isCurated
                          ? 'Verified directory • Last checked ${profile.lastVerifiedAt}'
                          : 'General emergency fallback • Verify local numbers on arrival',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Emergency Numbers Section
        Text(
          'Emergency Numbers',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        if (!numbers.hasAnyNumber)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              'Verified emergency numbers are not yet curated for ${profile.countryName}. Check with your hotel front desk or local carrier upon arrival.',
              style: theme.textTheme.bodyMedium,
            ),
          )
        else ...[
          if (numbers.police != null && numbers.police!.isNotEmpty)
            _EmergencyNumberTile(
              icon: Icons.local_police_outlined,
              label: 'Police',
              number: numbers.police!,
              onCopy: () => onCopyNumber('Police', numbers.police!),
            ),
          if (numbers.ambulance != null && numbers.ambulance!.isNotEmpty)
            _EmergencyNumberTile(
              icon: Icons.medical_services_outlined,
              label: 'Ambulance / Medical',
              number: numbers.ambulance!,
              onCopy: () => onCopyNumber('Ambulance', numbers.ambulance!),
            ),
          if (numbers.fire != null && numbers.fire!.isNotEmpty)
            _EmergencyNumberTile(
              icon: Icons.local_fire_department_outlined,
              label: 'Fire Rescue',
              number: numbers.fire!,
              onCopy: () => onCopyNumber('Fire', numbers.fire!),
            ),
          if (numbers.generalEmergency != null &&
              numbers.generalEmergency!.isNotEmpty)
            _EmergencyNumberTile(
              icon: Icons.emergency_outlined,
              label: 'General Emergency',
              number: numbers.generalEmergency!,
              onCopy: () =>
                  onCopyNumber('General Emergency', numbers.generalEmergency!),
            ),
          if (numbers.touristHotline != null &&
              numbers.touristHotline!.isNotEmpty)
            _EmergencyNumberTile(
              icon: Icons.support_agent_rounded,
              label: 'Tourist Helpline',
              number: numbers.touristHotline!,
              onCopy: () =>
                  onCopyNumber('Tourist Helpline', numbers.touristHotline!),
            ),
        ],

        const SizedBox(height: 20),

        // Nearby Care & Consular Map Handoff
        Text(
          'Find Nearby Assistance (Maps Handoff)',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ActionChip(
              avatar: const Icon(Icons.local_hospital_outlined, size: 18),
              label: const Text('Nearest Hospital'),
              onPressed: () =>
                  onSearchMaps('Emergency Hospital in ${profile.countryName}'),
            ),
            ActionChip(
              avatar: const Icon(Icons.local_pharmacy_outlined, size: 18),
              label: const Text('24h Pharmacy'),
              onPressed: () =>
                  onSearchMaps('24 hour pharmacy in ${profile.countryName}'),
            ),
            ActionChip(
              avatar: const Icon(Icons.account_balance_outlined, size: 18),
              label: const Text('Embassy / Consulate'),
              onPressed: () =>
                  onSearchMaps('Embassy consulate in ${profile.countryName}'),
            ),
            ActionChip(
              avatar: const Icon(Icons.shield_outlined, size: 18),
              label: const Text('Police Box / Station'),
              onPressed: () =>
                  onSearchMaps('Police station in ${profile.countryName}'),
            ),
          ],
        ),

        const SizedBox(height: 20),

        // Offline Emergency Phrases
        Text(
          'Offline Emergency Phrasebook',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        for (final phrase in profile.emergencyPhrases) ...[
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: colorScheme.outlineVariant, width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  phrase.english,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  phrase.localText,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  phrase.phonetic,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],

        if (profile.officialResources.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            'Official Travel & Entry Portals',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          for (final res in profile.officialResources)
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: colorScheme.outlineVariant, width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    res.title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${res.publisher} • Verified ${res.lastVerifiedAt}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  SelectableText(
                    res.url,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
        ],

        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.info_outline_rounded,
                size: 18,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  profile.disclaimer,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _EmergencyNumberTile extends StatelessWidget {
  const _EmergencyNumberTile({
    required this.icon,
    required this.label,
    required this.number,
    required this.onCopy,
  });

  final IconData icon;
  final String label;
  final String number;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colorScheme.outlineVariant, width: 1),
      ),
      child: Row(
        children: [
          Icon(icon, color: colorScheme.error),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  number,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Copy $label number',
            onPressed: onCopy,
            icon: const Icon(Icons.copy_rounded, size: 18),
          ),
        ],
      ),
    );
  }
}
