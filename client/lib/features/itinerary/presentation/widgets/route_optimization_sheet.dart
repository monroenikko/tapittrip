import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/itinerary_item.dart';
import '../../domain/models/route_optimization_result.dart';
import '../providers/itinerary_provider.dart';
import 'recommendation_link_actions.dart';

class LocalRouteMetrics {
  const LocalRouteMetrics({
    required this.totalDistanceKm,
    required this.co2SavedKg,
    required this.geocodedCount,
    required this.segments,
  });

  final double totalDistanceKm;
  final double co2SavedKg;
  final int geocodedCount;
  final List<ItineraryTransitSegment> segments;

  String get distanceLabel => geocodedCount >= 2
      ? '${totalDistanceKm.toStringAsFixed(1)} km'
      : '0.0 km';

  String get co2SavedLabel => '${co2SavedKg.toStringAsFixed(1)} kg';
}

class RouteMetricsCalculator {
  static const double _earthRadiusMeters = 6371000.0;
  static const double _urbanDetourFactor = 1.3;

  static LocalRouteMetrics computeForItems(
    List<ItineraryItem> items, {
    int maxWalkingMeters = 1500,
    String? destinationContext,
  }) {
    double totalMeters = 0.0;
    int geocodedCount = 0;
    final segments = <ItineraryTransitSegment>[];

    for (final item in items) {
      if (_hasCoords(item)) {
        geocodedCount++;
      }
    }

    for (int i = 0; i < items.length - 1; i++) {
      final from = items[i];
      final to = items[i + 1];
      if (from.tripDayId != to.tripDayId) {
        continue;
      }

      final fromPlace = from.place?.name ?? from.title;
      final toPlace = to.place?.name ?? to.title;

      if (_hasCoords(from) && _hasCoords(to)) {
        final distM = _urbanDistanceMeters(
          from.place!.latitude!,
          from.place!.longitude!,
          to.place!.latitude!,
          to.place!.longitude!,
        );
        totalMeters += distM;
        final roundedM = distM.round();
        final distKm = double.parse((roundedM / 1000.0).toStringAsFixed(2));
        final exceedsWalk = roundedM > maxWalkingMeters;
        final String recMode;
        if (!exceedsWalk) {
          recMode = 'walk';
        } else if (roundedM <= 8000) {
          recMode = 'public_transit';
        } else {
          recMode = 'taxi_rideshare';
        }

        final walkMin = math.max(2, (roundedM / 75.0).round());
        final transitMin = math.max(8, ((roundedM / 300.0) + 6).round());
        final rideMin = math.max(5, ((roundedM / 400.0) + 4).round());

        final recDuration = switch (recMode) {
          'walk' => walkMin,
          'public_transit' => transitMin,
          _ => rideMin,
        };

        segments.add(
          ItineraryTransitSegment(
            fromItemId: from.id,
            fromTitle: from.title,
            fromPlaceName: fromPlace,
            toItemId: to.id,
            toTitle: to.title,
            toPlaceName: toPlace,
            tripDayId: from.tripDayId,
            distanceMeters: roundedM,
            distanceKm: distKm,
            recommendedMode: recMode,
            estimatedDurationMinutes: recDuration,
            exceedsWalkingLimit: exceedsWalk,
            modeComparisons: [
              ItineraryTransitModeComparison(
                mode: 'walk',
                label: 'Walk',
                estimatedDurationMinutes: walkMin,
                suitability: !exceedsWalk ? 'recommended' : 'long_walk',
                advisoryNote: !exceedsWalk
                    ? 'Within comfortable walking threshold.'
                    : 'Exceeds $maxWalkingMeters m walking threshold.',
                googleMapsDirectionsUrl: '',
              ),
              ItineraryTransitModeComparison(
                mode: 'public_transit',
                label: 'Public Transit',
                estimatedDurationMinutes: transitMin,
                suitability: recMode == 'public_transit'
                    ? 'recommended'
                    : 'alternative',
                advisoryNote: 'Includes ~6 min station walk/transfer buffer.',
                googleMapsDirectionsUrl: '',
              ),
              ItineraryTransitModeComparison(
                mode: 'taxi_rideshare',
                label: 'Taxi / Ride',
                estimatedDurationMinutes: rideMin,
                suitability: recMode == 'taxi_rideshare'
                    ? 'recommended'
                    : 'alternative',
                advisoryNote: 'Direct point-to-point ride.',
                googleMapsDirectionsUrl: '',
              ),
            ],
            providerAttribution:
                'Haversine geometric estimate & Google Maps deep link',
            verified: false,
            limitationNotice: 'Estimated from coordinates with 1.3x urban route factor; live transit schedules and fares are not verified.',
          ),
        );
      } else {
        segments.add(
          ItineraryTransitSegment(
            fromItemId: from.id,
            fromTitle: from.title,
            fromPlaceName: fromPlace,
            toItemId: to.id,
            toTitle: to.title,
            toPlaceName: toPlace,
            tripDayId: from.tripDayId,
            distanceMeters: null,
            distanceKm: null,
            recommendedMode: 'unknown_coordinates',
            estimatedDurationMinutes: null,
            exceedsWalkingLimit: false,
            modeComparisons: const [],
            providerAttribution: 'Google Maps deep link',
            verified: false,
            limitationNotice: 'One or both stops lack saved coordinates; open Google Maps for live directions.',
          ),
        );
      }
    }

    final totalKm = double.parse((totalMeters / 1000.0).toStringAsFixed(2));
    // Walking legs save ~0.12 kg CO2/km compared to private car rides
    double walkableKm = 0.0;
    for (final seg in segments) {
      if (seg.recommendedMode == 'walk' && seg.distanceKm != null) {
        walkableKm += seg.distanceKm!;
      }
    }
    final co2Saved = double.parse((walkableKm * 0.12).toStringAsFixed(2));

    return LocalRouteMetrics(
      totalDistanceKm: totalKm,
      co2SavedKg: co2Saved,
      geocodedCount: geocodedCount,
      segments: segments,
    );
  }

  static bool _hasCoords(ItineraryItem item) =>
      item.place?.latitude != null && item.place?.longitude != null;

  static double _urbanDistanceMeters(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    final dLat = _degToRad(lat2 - lat1);
    final dLng = _degToRad(lng2 - lng1);
    final a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degToRad(lat1)) *
            math.cos(_degToRad(lat2)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(math.max(0.0, 1.0 - a)));
    return _earthRadiusMeters * c * _urbanDetourFactor;
  }

  static double _degToRad(double deg) => deg * (math.pi / 180.0);
}

class RouteOptimizationSheet extends ConsumerStatefulWidget {
  const RouteOptimizationSheet({
    super.key,
    required this.tripId,
    required this.currentItems,
  });

  final String tripId;
  final List<ItineraryItem> currentItems;

  @override
  ConsumerState<RouteOptimizationSheet> createState() =>
      _RouteOptimizationSheetState();
}

class _RouteOptimizationSheetState
    extends ConsumerState<RouteOptimizationSheet> {
  bool _preserveFixedTimes = true;
  int _maxWalkingMeters = 1500;
  bool _loading = true;
  bool _applying = false;
  String? _error;
  RouteOptimizationResult? _preview;

  @override
  void initState() {
    super.initState();
    _loadPreview();
  }

  Future<void> _loadPreview() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final repo = ref.read(itineraryRepositoryProvider);
      final res = await repo.optimizeRoute(
        widget.tripId,
        apply: false,
        preserveFixedTimes: _preserveFixedTimes,
        maxWalkingMetersPerLeg: _maxWalkingMeters,
      );
      if (!mounted) return;
      setState(() {
        _preview = res;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not evaluate route optimization right now.';
        _loading = false;
      });
    }
  }

  Future<void> _applyOptimization() async {
    if (_applying || _preview == null) return;
    setState(() => _applying = true);
    try {
      final expectedVersions = <String, int>{
        for (final item in widget.currentItems) item.id: item.version,
      };
      final repo = ref.read(itineraryRepositoryProvider);
      await repo.optimizeRoute(
        widget.tripId,
        apply: true,
        preserveFixedTimes: _preserveFixedTimes,
        maxWalkingMetersPerLeg: _maxWalkingMeters,
        expectedVersions: expectedVersions,
      );
      await ref.read(itineraryListProvider(widget.tripId).notifier).refresh();
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _applying = false;
        _error = 'Could not apply route optimization. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final itemsById = <String, ItineraryItem>{
      for (final item in widget.currentItems) item.id: item,
      if (_preview != null)
        for (final item in _preview!.items) item.id: item,
    };

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(Icons.alt_route_rounded, color: colorScheme.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Constrained Route Optimization',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              Text(
                'Groups nearby stops within each day to reduce backtracking while respecting fixed reservations.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: const Text('Preserve timed reservations & flights'),
                subtitle: const Text(
                  'Keeps items with fixed start times, hotels, and flights anchored in place',
                ),
                value: _preserveFixedTimes,
                onChanged: (val) {
                  setState(() => _preserveFixedTimes = val);
                  _loadPreview();
                },
              ),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Max comfortable walk per leg',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                  DropdownButton<int>(
                    value: _maxWalkingMeters,
                    items: const [
                      DropdownMenuItem(value: 800, child: Text('800 m')),
                      DropdownMenuItem(value: 1500, child: Text('1.5 km')),
                      DropdownMenuItem(value: 2500, child: Text('2.5 km')),
                    ],
                    onChanged: (val) {
                      if (val == null || val == _maxWalkingMeters) return;
                      setState(() => _maxWalkingMeters = val);
                      _loadPreview();
                    },
                  ),
                ],
              ),
              const Divider(height: 20),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_error != null)
                Column(
                  children: [
                    Text(_error!, style: TextStyle(color: colorScheme.error)),
                    TextButton(
                      onPressed: _loadPreview,
                      child: const Text('Retry'),
                    ),
                  ],
                )
              else if (_preview != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          Text('Current', style: theme.textTheme.labelSmall),
                          Text(
                            '${_preview!.currentTotalDistanceKm.toStringAsFixed(1)} km',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        children: [
                          Text('Optimized', style: theme.textTheme.labelSmall),
                          Text(
                            '${_preview!.optimizedTotalDistanceKm.toStringAsFixed(1)} km',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        children: [
                          Text('Saved', style: theme.textTheme.labelSmall),
                          Text(
                            '${_preview!.distanceSavedKm.toStringAsFixed(1)} km',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _preview!.isAlreadyOptimal
                      ? 'Your itinerary is already in the most direct geographic sequence for these constraints.'
                      : 'Proposed Stop Sequence:',
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                for (int i = 0; i < _preview!.proposedItemIds.length; i++)
                  Builder(
                    builder: (context) {
                      final id = _preview!.proposedItemIds[i];
                      final item = itemsById[id];
                      final isPinned = _preview!.pinnedItemIds.contains(id);
                      return ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          radius: 13,
                          backgroundColor: colorScheme.primary,
                          child: Text(
                            '${i + 1}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(item?.title ?? 'Stop ${i + 1}'),
                        subtitle: item?.place?.name != null
                            ? Text(item!.place!.name)
                            : null,
                        trailing: isPinned
                            ? Chip(
                                label: const Text('Pinned constraint'),
                                visualDensity: VisualDensity.compact,
                                labelStyle: theme.textTheme.labelSmall,
                              )
                            : null,
                      );
                    },
                  ),
                const SizedBox(height: 12),
                if (_preview!.advisoryNotice.isNotEmpty)
                  Text(
                    _preview!.advisoryNotice,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 11,
                    ),
                  ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _preview!.isAlreadyOptimal || _applying
                      ? null
                      : _applyOptimization,
                  icon: const Icon(Icons.check_circle_outline_rounded),
                  label: Text(
                    _preview!.isAlreadyOptimal
                        ? 'Route Already Optimal'
                        : (_applying
                              ? 'Applying...'
                              : 'Approve & Apply Route Order'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class ItineraryTransitSegmentsSection extends StatelessWidget {
  const ItineraryTransitSegmentsSection({
    super.key,
    required this.segments,
    this.destinationContext,
    this.onOptimizeTap,
  });

  final List<ItineraryTransitSegment> segments;
  final String? destinationContext;
  final VoidCallback? onOptimizeTap;

  String _modeBadgeLabel(String mode) {
    return switch (mode) {
      'walk' => 'Recommended: Walk',
      'public_transit' => 'Recommended: Public Transit',
      'taxi_rideshare' => 'Recommended: Taxi / Ride',
      _ => 'Coordinates Needed',
    };
  }

  IconData _modeIcon(String mode) {
    return switch (mode) {
      'walk' => Icons.directions_walk_rounded,
      'public_transit' => Icons.directions_transit_rounded,
      'taxi_rideshare' => Icons.local_taxi_rounded,
      _ => Icons.map_outlined,
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (segments.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Stop-to-Stop Transit Mode Comparisons',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (onOptimizeTap != null)
              TextButton.icon(
                onPressed: onOptimizeTap,
                icon: const Icon(Icons.alt_route_rounded, size: 18),
                label: const Text('Optimize Route'),
              ),
          ],
        ),
        const SizedBox(height: 8),
        for (final seg in segments)
          Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Icon(
                        _modeIcon(seg.recommendedMode),
                        color: colorScheme.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${seg.fromTitle} → ${seg.toTitle}',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (seg.distanceKm != null)
                        Text(
                          '${seg.distanceKm!.toStringAsFixed(1)} km',
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: colorScheme.primary,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _modeBadgeLabel(seg.recommendedMode),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (seg.modeComparisons.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        for (final mode in seg.modeComparisons)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: mode.suitability == 'recommended'
                                  ? colorScheme.primaryContainer
                                  : colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              mode.estimatedDurationMinutes != null
                                  ? '${mode.label}: ~${mode.estimatedDurationMinutes} min'
                                  : '${mode.label}: See Maps',
                              style: theme.textTheme.labelSmall?.copyWith(
                                fontWeight: mode.suitability == 'recommended'
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 6),
                  Text(
                    seg.limitationNotice,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 11,
                    ),
                  ),
                  RecommendationLinkActions(
                    query: [
                      seg.toPlaceName,
                      if (destinationContext != null &&
                          destinationContext!.isNotEmpty)
                        destinationContext!,
                    ].join(', '),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
