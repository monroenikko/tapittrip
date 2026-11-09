import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/map_launcher.dart';
import '../../../weather/domain/models/daily_forecast.dart';
import '../../../weather/domain/models/trip_weather.dart';
import '../../../weather/presentation/providers/weather_provider.dart';
import '../../domain/models/itinerary_item.dart';

class ActivityTimelineCard extends StatelessWidget {
  const ActivityTimelineCard({
    super.key,
    required this.item,
    this.weather,
    this.onTap,
    this.onToggleVisited,
    this.onEdit,
    this.onDelete,
    this.onWeatherTap,
  });

  final ItineraryItem item;
  final TripWeather? weather;
  final VoidCallback? onTap;
  final VoidCallback? onToggleVisited;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onWeatherTap;

  IconData _iconForKind(String kind) {
    switch (kind.toLowerCase()) {
      case 'flight':
        return Icons.flight_takeoff_rounded;
      case 'hotel':
        return Icons.hotel_rounded;
      case 'meal':
        return Icons.restaurant_rounded;
      case 'transport':
        return Icons.directions_bus_rounded;
      case 'attraction':
      default:
        return Icons.explore_rounded;
    }
  }

  Future<void> _openGoogleMaps(BuildContext context) async {
    final place = item.place;
    final success = await MapLauncher.launchDirections(
      latitude: place?.latitude,
      longitude: place?.longitude,
      query: place?.formattedAddress ?? place?.name ?? item.title,
    );

    if (!success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to launch maps navigation.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isVisited = item.status == 'visited';

    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isVisited
              ? colorScheme.outlineVariant.withValues(alpha: 0.3)
              : colorScheme.outlineVariant.withValues(alpha: 0.7),
        ),
      ),
      color: isVisited
          ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.3)
          : colorScheme.surface,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon Squircle
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: isVisited
                          ? colorScheme.surfaceContainerHighest
                          : colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _iconForKind(item.kind),
                      color: isVisited
                          ? colorScheme.onSurfaceVariant
                          : colorScheme.primary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Title & Status
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                item.title,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  decoration: isVisited
                                      ? TextDecoration.lineThrough
                                      : null,
                                  color: isVisited
                                      ? colorScheme.onSurfaceVariant
                                      : colorScheme.onSurface,
                                ),
                              ),
                            ),
                            if (isVisited)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: colorScheme.secondaryContainer,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'Visited',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.onSecondaryContainer,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        if (item.place?.name != null) ...[
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              Icon(
                                Icons.place_rounded,
                                size: 14,
                                color: colorScheme.secondary,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  item.place!.name,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              if (item.notes != null && item.notes!.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  item.notes!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              if (weather != null)
                _buildWeatherBadge(context, colorScheme, weather!),
              const SizedBox(height: 12),
              // Bottom Action Bar: Google Maps Directions, Visited Check, More
              Row(
                children: [
                  // Google Maps Deep Link CTA
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      minimumSize: const Size(0, 32),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      side: BorderSide(
                        color: colorScheme.primary.withValues(alpha: 0.5),
                      ),
                    ),
                    onPressed: () => _openGoogleMaps(context),
                    icon: Icon(
                      Icons.navigation_rounded,
                      size: 14,
                      color: colorScheme.primary,
                    ),
                    label: Text(
                      'Directions',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.primary,
                      ),
                    ),
                  ),
                  const Spacer(),
                  // Visited Toggle Button
                  IconButton(
                    iconSize: 20,
                    tooltip: isVisited ? 'Mark as planned' : 'Mark as visited',
                    onPressed: onToggleVisited,
                    icon: Icon(
                      isVisited
                          ? Icons.check_circle_rounded
                          : Icons.radio_button_unchecked_rounded,
                      color: isVisited
                          ? colorScheme.secondary
                          : colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (onEdit != null)
                    IconButton(
                      iconSize: 18,
                      tooltip: 'Edit activity',
                      onPressed: onEdit,
                      icon: Icon(
                        Icons.edit_outlined,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  if (onDelete != null)
                    IconButton(
                      iconSize: 18,
                      tooltip: 'Delete stop',
                      onPressed: onDelete,
                      icon: Icon(
                        Icons.delete_outline_rounded,
                        color: colorScheme.error.withValues(alpha: 0.8),
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

  Widget _buildWeatherBadge(
    BuildContext context,
    ColorScheme colorScheme,
    TripWeather weather,
  ) {
    final theme = Theme.of(context);
    String? scheduledDate = item.day?.localDate;
    if (scheduledDate == null &&
        item.startsAtUtc != null &&
        item.startsAtUtc!.length >= 10) {
      scheduledDate = item.startsAtUtc!.substring(0, 10);
    }

    DailyForecast? matchedForecast;
    if (scheduledDate != null && weather.forecast.isNotEmpty) {
      for (final f in weather.forecast) {
        if (f.date == scheduledDate) {
          matchedForecast = f;
          break;
        }
      }
    }

    final IconData icon =
        matchedForecast?.weatherIcon ?? weather.current.weatherIcon;
    final Color color =
        matchedForecast?.weatherColor ?? weather.current.weatherColor;
    final String temp = matchedForecast != null
        ? '${matchedForecast.tempMaxC.round()}°C'
        : weather.current.tempString;
    final String condition =
        matchedForecast?.condition ?? weather.current.condition;
    final int rainChance =
        matchedForecast?.precipitationProbability ??
        weather.current.precipitationProbability;

    final String dayPrefix = matchedForecast != null
        ? '${matchedForecast.dayName}: '
        : '';

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: InkWell(
        onTap: onWeatherTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.25)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  '$dayPrefix$temp • $condition',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (rainChance > 15) ...[
                const SizedBox(width: 6),
                Icon(
                  Icons.water_drop_outlined,
                  size: 11,
                  color: Colors.blue.shade700,
                ),
                const SizedBox(width: 2),
                Text(
                  '$rainChance%',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: Colors.blue.shade700,
                    fontWeight: FontWeight.w600,
                    fontSize: 10,
                  ),
                ),
              ],
              if (onWeatherTap != null) ...[
                const SizedBox(width: 4),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 12,
                  color: color.withValues(alpha: 0.7),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// A wrapper around [ActivityTimelineCard] that automatically resolves and watches
/// location-specific or destination weather for the given itinerary stop.
class LiveWeatherActivityTimelineCard extends ConsumerWidget {
  const LiveWeatherActivityTimelineCard({
    super.key,
    required this.tripId,
    required this.item,
    this.onTap,
    this.onToggleVisited,
    this.onEdit,
    this.onDelete,
    this.onWeatherTap,
  });

  final String tripId;
  final ItineraryItem item;
  final VoidCallback? onTap;
  final VoidCallback? onToggleVisited;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onWeatherTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final place = item.place;
    final lat = place?.latitude;
    final lng = place?.longitude;
    final locName = place?.name ?? item.title;

    final weatherAsync = ref.watch(
      itemLocationWeatherProvider((
        tripId: tripId,
        latitude: lat,
        longitude: lng,
        location: locName,
      )),
    );

    final weather =
        weatherAsync.asData?.value ??
        ref.watch(tripWeatherProvider(tripId)).asData?.value;

    return ActivityTimelineCard(
      item: item,
      weather: weather,
      onTap: onTap,
      onToggleVisited: onToggleVisited,
      onEdit: onEdit,
      onDelete: onDelete,
      onWeatherTap: onWeatherTap,
    );
  }
}
