import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../domain/models/itinerary_item.dart';

class ActivityTimelineCard extends StatelessWidget {
  const ActivityTimelineCard({
    super.key,
    required this.item,
    this.onTap,
    this.onToggleVisited,
    this.onDelete,
  });

  final ItineraryItem item;
  final VoidCallback? onTap;
  final VoidCallback? onToggleVisited;
  final VoidCallback? onDelete;

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
    final destination = (place?.latitude != null && place?.longitude != null)
        ? '${place!.latitude},${place.longitude}'
        : (place?.formattedAddress ?? place?.name ?? item.title);

    final url =
        'https://www.google.com/maps/dir/?api=1&destination=${Uri.encodeComponent(destination)}';
    final uri = Uri.parse(url);

    try {
      // 1. Try launching in external application (e.g. Google Maps app or native map handler)
      bool launched = false;
      try {
        launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (_) {
        launched = false;
      }

      // 2. Fallback to platform default (browser or in-app Safari/Chrome) if external app failed or is unavailable (e.g. Simulator)
      if (!launched) {
        launched = await launchUrl(uri, mode: LaunchMode.platformDefault);
      }

      if (!launched && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open maps navigation.')),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to launch maps navigation.')),
        );
      }
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
              const SizedBox(height: 12),
              // Bottom Action Bar: Google Maps Directions, Visited Check, More
              Row(
                children: [
                  // Google Maps Deep Link CTA
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
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
}
