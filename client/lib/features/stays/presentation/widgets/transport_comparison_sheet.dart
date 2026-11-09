import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/map_launcher.dart';
import '../../../auth/domain/models/auth_state.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../expenses/data/currency_repository.dart';
import '../../domain/models/luggage_profile.dart';
import '../../domain/models/stay.dart';
import '../../domain/models/transport_option.dart';
import '../providers/stay_provider.dart';
import 'luggage_preset_selector.dart';

class TransportComparisonSheet extends ConsumerStatefulWidget {
  const TransportComparisonSheet({super.key, required this.stay});

  final Stay stay;

  static Future<void> show(BuildContext context, Stay stay) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TransportComparisonSheet(stay: stay),
    );
  }

  @override
  ConsumerState<TransportComparisonSheet> createState() =>
      _TransportComparisonSheetState();
}

class _TransportComparisonSheetState
    extends ConsumerState<TransportComparisonSheet> {
  late LuggageProfile _currentProfile;
  String? _selectedOrigin;
  final TextEditingController _customOriginController = TextEditingController();
  bool _isEditingCustomOrigin = false;

  @override
  void initState() {
    super.initState();
    _currentProfile =
        widget.stay.luggageProfile ?? LuggageProfile.fromPreset('standard');
  }

  @override
  void dispose() {
    _customOriginController.dispose();
    super.dispose();
  }

  Future<void> _launchDirections(String url) async {
    final success = await MapLauncher.launchDirections(rawUrl: url);
    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to launch maps navigation.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final comparisonAsync = ref.watch(
      transportComparisonProvider(
        TransportQueryParams(
          stayId: widget.stay.id,
          origin: _selectedOrigin,
          preset: _currentProfile.preset,
        ),
      ),
    );

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              // Drag handle
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Title header
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Arrival Transport',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'How to get to ${widget.stay.name}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              // Departure / Arrival Origin Selector
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.flight_land_rounded,
                          size: 16,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Arrival Origin / Departure Terminal:',
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Builder(
                      builder: (context) {
                        final defaultAirportLabel =
                            widget.stay.nearestTransit?.nearestAirportName !=
                                null
                            ? '✈️ ${widget.stay.nearestTransit!.nearestAirportName}${widget.stay.nearestTransit!.nearestAirportCode != null ? " (${widget.stay.nearestTransit!.nearestAirportCode})" : ""}'
                            : '✈️ Airport / Terminal';
                        final defaultAirportValue =
                            widget.stay.nearestTransit?.nearestAirportName !=
                                null
                            ? '${widget.stay.nearestTransit!.nearestAirportName}${widget.stay.nearestTransit!.nearestAirportCode != null ? " (${widget.stay.nearestTransit!.nearestAirportCode})" : ""}'
                            : 'Airport Terminal';

                        final defaultStationLabel =
                            widget.stay.nearestTransit?.stationName != null
                            ? '🚆 ${widget.stay.nearestTransit!.stationName}'
                            : '🚆 Train Station';
                        final defaultStationValue =
                            widget.stay.nearestTransit?.stationName ??
                            'Central Train Station';

                        return SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              ChoiceChip(
                                label: Text(defaultAirportLabel),
                                selected:
                                    _selectedOrigin == defaultAirportValue &&
                                    !_isEditingCustomOrigin,
                                onSelected: (selected) {
                                  setState(() {
                                    _isEditingCustomOrigin = false;
                                    _selectedOrigin = selected
                                        ? defaultAirportValue
                                        : null;
                                  });
                                },
                              ),
                              const SizedBox(width: 8),
                              ChoiceChip(
                                label: Text(defaultStationLabel),
                                selected:
                                    _selectedOrigin == defaultStationValue &&
                                    !_isEditingCustomOrigin,
                                onSelected: (selected) {
                                  setState(() {
                                    _isEditingCustomOrigin = false;
                                    _selectedOrigin = selected
                                        ? defaultStationValue
                                        : null;
                                  });
                                },
                              ),
                              const SizedBox(width: 8),
                              ChoiceChip(
                                label: const Text('✏️ Custom Terminal'),
                                selected: _isEditingCustomOrigin,
                                onSelected: (selected) {
                                  setState(() {
                                    _isEditingCustomOrigin = selected;
                                    if (!selected) {
                                      _selectedOrigin = null;
                                    } else if (_customOriginController.text
                                        .trim()
                                        .isNotEmpty) {
                                      _selectedOrigin = _customOriginController
                                          .text
                                          .trim();
                                    }
                                  });
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    if (_isEditingCustomOrigin) ...[
                      const SizedBox(height: 8),
                      TextField(
                        controller: _customOriginController,
                        decoration: InputDecoration(
                          hintText: 'e.g. Narita Airport Terminal 1, Haneda, Tokyo Station',
                          isDense: true,
                          prefixIcon: const Icon(
                            Icons.place_outlined,
                            size: 18,
                          ),
                          suffixIcon: IconButton(
                            icon: const Icon(
                              Icons.arrow_forward_rounded,
                              size: 18,
                            ),
                            onPressed: () {
                              if (_customOriginController.text
                                  .trim()
                                  .isNotEmpty) {
                                setState(() {
                                  _selectedOrigin = _customOriginController.text
                                      .trim();
                                });
                              }
                            },
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onSubmitted: (val) {
                          if (val.trim().isNotEmpty) {
                            setState(() {
                              _selectedOrigin = val.trim();
                            });
                          }
                        },
                      ),
                    ],
                  ],
                ),
              ),

              const Divider(height: 1),

              // Luggage Preset Filter Selector
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Luggage profile:',
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    LuggagePresetSelector(
                      profile: _currentProfile,
                      onProfileChanged: (profile) {
                        setState(() {
                          _currentProfile = profile;
                        });
                      },
                    ),
                  ],
                ),
              ),

              // Content: Options List or Fallback
              Expanded(
                child: comparisonAsync.when(
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  error: (error, _) {
                    return ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.all(20),
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: colorScheme.errorContainer.withValues(
                              alpha: 0.3,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: colorScheme.error.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.info_outline_rounded,
                                    color: colorScheme.error,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Transit comparison unavailable',
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: colorScheme.error,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Unable to calculate pre-configured transit routes for this stay. You can use Google Maps for live directions.',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 16),
                              if (widget.stay.googleMapsDirectionsUrl != null)
                                FilledButton.icon(
                                  onPressed: () => _launchDirections(
                                    widget.stay.googleMapsDirectionsUrl!,
                                  ),
                                  icon: const Icon(
                                    Icons.directions_rounded,
                                    size: 18,
                                  ),
                                  label: const Text('Open in Google Maps'),
                                ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                  data: (result) {
                    final options = result.options;

                    if (!result.verified || options.isEmpty) {
                      return ListView(
                        controller: scrollController,
                        padding: const EdgeInsets.all(20),
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: colorScheme.surfaceContainerHigh,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: colorScheme.outlineVariant.withValues(
                                  alpha: 0.5,
                                ),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.map_outlined,
                                      color: colorScheme.primary,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Direct Route Navigation',
                                      style: theme.textTheme.titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  result.message.isNotEmpty ? result.message : 'No fixed transit presets for this location. We do not fabricate schedules or fares.',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                if (_selectedOrigin == null) ...[
                                  const SizedBox(height: 10),
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: colorScheme.primary.withValues(
                                        alpha: 0.08,
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.info_outline_rounded,
                                          size: 16,
                                          color: colorScheme.primary,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            'Select an arrival hub above (✈️ Airport or 🚆 Station) to compare routes to ${widget.stay.name}.',
                                            style: theme.textTheme.bodySmall
                                                ?.copyWith(
                                                  color: colorScheme.primary,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 16),
                                if (_selectedOrigin == null) ...[
                                  FilledButton.icon(
                                    onPressed: () {
                                      setState(() {
                                        _selectedOrigin = 'Airport Terminal';
                                      });
                                    },
                                    icon: const Icon(
                                      Icons.flight_land_rounded,
                                      size: 18,
                                    ),
                                    label: const Text(
                                      'Compare from Airport / Terminal',
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                ],
                                OutlinedButton.icon(
                                  onPressed: () => _launchDirections(
                                    result.googleMapsDirectionsUrl,
                                  ),
                                  icon: const Icon(
                                    Icons.directions_rounded,
                                    size: 18,
                                  ),
                                  label: const Text('Get Live Directions'),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    }

                    return ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 8,
                      ),
                      itemCount: options.length + 1,
                      itemBuilder: (context, index) {
                        if (index == options.length) {
                          // Attribution footer
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 24),
                            child: Column(
                              children: [
                                Text(
                                  'Provider: ${result.providerAttribution}',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Refreshed ${result.lastRefreshedAt.month}/${result.lastRefreshedAt.day}/${result.lastRefreshedAt.year}',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: colorScheme.outline,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        final option = options[index];
                        return _buildOptionCard(
                          context,
                          option,
                          result.googleMapsDirectionsUrl,
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOptionCard(
    BuildContext context,
    TransportOption option,
    String mapsDirectionsUrl,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final authState = ref.watch(authProvider);
    final authUser = authState is Authenticated ? authState.user : null;
    final homeCurrency = authUser?.homeCurrency;

    String? convertedCost;
    if (homeCurrency != null &&
        homeCurrency.toUpperCase() != option.currency.toUpperCase()) {
      final rateAsync = ref.watch(
        currencyRateProvider((from: option.currency, to: homeCurrency)),
      );
      final rate = rateAsync.asData?.value;
      if (rate != null) {
        final zeroDec = CurrencyFormatter.isZeroDecimal(option.currency);
        final baseUnits = zeroDec
            ? option.estimatedCostMinor.toDouble()
            : (option.estimatedCostMinor / 100.0);
        final converted = baseUnits * rate.rate;
        convertedCost = '≈ ${CurrencyFormatter.formatAmount(converted, homeCurrency, isMinor: false)}';
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: option.isMostConvenient
              ? colorScheme.primary
              : colorScheme.outlineVariant.withValues(alpha: 0.6),
          width: option.isMostConvenient ? 2 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ranking badges
            Row(
              children: [
                if (option.isMostConvenient) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          size: 14,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Most Convenient',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
                if (option.isFastest) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.teal.shade700,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Fastest',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
                if (option.isCheapest) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.secondary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Best Value',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            if (option.isMostConvenient ||
                option.isFastest ||
                option.isCheapest)
              const SizedBox(height: 12),

            // Option title and icon
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    option.modeIcon,
                    color: colorScheme.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        option.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        option.provider,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                // Cost badge
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      option.formattedCost,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                    ),
                    if (convertedCost != null)
                      Text(
                        convertedCost,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),

            // Metrics row: Duration, Transfers, Luggage
            Row(
              children: [
                Icon(
                  Icons.access_time_rounded,
                  size: 16,
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Text(
                  option.formattedDuration,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 16),
                Icon(
                  Icons.alt_route_rounded,
                  size: 16,
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Text(
                  option.transfers == 0
                      ? 'Direct (0 transfers)'
                      : '${option.transfers} transfer${option.transfers > 1 ? 's' : ''}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),

            if (option.luggageCapacity.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.luggage_outlined,
                    size: 16,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      option.luggageCapacity,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ],

            // Boarding, Drop-off & Last-Mile Walk guidance
            if (option.boardingLocation != null ||
                option.dropoffLocation != null) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.35,
                  ),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.4),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (option.boardingLocation != null) ...[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.trip_origin_rounded,
                            size: 14,
                            color: colorScheme.primary,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Board: ${option.boardingLocation}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                    ],
                    if (option.dropoffLocation != null) ...[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.location_on_rounded,
                            size: 14,
                            color: colorScheme.secondary,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Drop off: ${option.dropoffLocation}',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (option.dropoffAddress != null &&
                                    option.dropoffAddress !=
                                        option.dropoffLocation)
                                  Text(
                                    option.dropoffAddress!,
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (option.lastMileWalkMeters != null &&
                        option.lastMileWalkMeters! > 30) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.directions_walk_rounded,
                            size: 14,
                            color: colorScheme.primary,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              '${option.lastMileWalkMeters}m walk from station to stay (~${option.lastMileWalkMinutes ?? 4} min)',
                              style: theme.textTheme.labelSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: colorScheme.primary,
                              ),
                            ),
                          ),
                          if (option.lastMileDirectionsUrl != null)
                            TextButton(
                              style: TextButton.styleFrom(
                                visualDensity: VisualDensity.compact,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                              ),
                              onPressed: () => _launchDirections(
                                option.lastMileDirectionsUrl!,
                              ),
                              child: const Text(
                                'Walk Map',
                                style: TextStyle(fontSize: 11),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],

            if (option.explanation.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.5,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  option.explanation,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
