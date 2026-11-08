import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../domain/models/airport_lounge.dart';

class LoungeDetailSheet extends StatelessWidget {
  const LoungeDetailSheet({super.key, required this.lounge});

  final AirportLounge lounge;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (ctx, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
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
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(24),
                  children: [
                    // Header & Badges
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                lounge.name,
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (lounge.operatorName.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  lounge.operatorName,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            lounge.terminal?.code ?? 'Terminal',
                            style: theme.textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Zone & Hours Pills
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        Chip(
                          avatar: Icon(
                            lounge.isAirside
                                ? Icons.flight_takeoff
                                : Icons.meeting_room_outlined,
                            size: 16,
                            color: colorScheme.primary,
                          ),
                          label: Text(
                            lounge.isAirside
                                ? 'Airside (Post-Security)'
                                : 'Landside (Pre-Security)',
                            style: theme.textTheme.labelSmall,
                          ),
                          visualDensity: VisualDensity.compact,
                        ),
                        if (lounge.openingHours != null)
                          Chip(
                            avatar: const Icon(
                              Icons.schedule_rounded,
                              size: 16,
                            ),
                            label: Text(
                              _formatHours(lounge.openingHours!),
                              style: theme.textTheme.labelSmall,
                            ),
                            visualDensity: VisualDensity.compact,
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Location Directions
                    Card(
                      elevation: 0,
                      color: colorScheme.surfaceContainerHighest.withValues(
                        alpha: 0.4,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.directions_walk_rounded,
                              color: colorScheme.primary,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Location & Directions',
                                    style: theme.textTheme.labelMedium
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    lounge.locationDescription,
                                    style: theme.textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Transit Warning if any
                    if (lounge.transitWarning != null &&
                        lounge.transitWarning!.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: colorScheme.errorContainer.withValues(
                            alpha: 0.3,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: colorScheme.error.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.warning_amber_rounded,
                              color: colorScheme.error,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                lounge.transitWarning!,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onErrorContainer,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Amenities Section
                    Text(
                      'Lounge Amenities',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: lounge.amenities.map((amenity) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _getAmenityIcon(amenity),
                                size: 16,
                                color: colorScheme.primary,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _humanize(amenity),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),

                    // Access Methods & Pricing
                    Text(
                      'Access Programs & Eligibility',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: lounge.accessMethods.map((method) {
                        return Chip(
                          backgroundColor: colorScheme.secondaryContainer
                              .withValues(alpha: 0.5),
                          label: Text(
                            _humanize(method),
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSecondaryContainer,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    if (lounge.estimatedPrice != null) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(
                            Icons.payments_outlined,
                            size: 18,
                            color: colorScheme.secondary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Estimated walk-in rate: ${lounge.estimatedPrice!['currency']} ${(lounge.estimatedPrice!['amount_cents'] as num) / (lounge.estimatedPrice!['currency'] == 'JPY' ? 1 : 100)}',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 20),

                    // Gate Departure Alert Notice
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Colors.amber.shade700.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.timer_outlined,
                            color: Colors.amber.shade900,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Boarding Reminder: Allow 15–20 minutes to leave the lounge and reach your departure gate.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.amber.shade900,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Booking Link Button if available
                    if (lounge.bookingUrl != null &&
                        lounge.bookingUrl!.isNotEmpty) ...[
                      FilledButton.icon(
                        icon: const Icon(Icons.open_in_new_rounded, size: 18),
                        label: const Text('View Official Booking Page'),
                        onPressed: () {
                          final uri = Uri.tryParse(lounge.bookingUrl!);
                          if (uri != null) {
                            launchUrl(
                              uri,
                              mode: LaunchMode.externalApplication,
                            );
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Disclaimer
                    Text(
                      lounge.disclaimer ?? 'Actual lounge access depends on airline status, card eligibility, capacity, and terminal security regulations. Check with the lounge desk for real-time entry.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 11,
                        color: colorScheme.onSurfaceVariant.withValues(
                          alpha: 0.8,
                        ),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  static String _formatHours(Map<String, dynamic> hours) {
    if (hours['is_24h'] == true) return 'Open 24 hours';
    final open = hours['open'] ?? '06:00';
    final close = hours['close'] ?? '23:00';
    return '$open – $close';
  }

  static IconData _getAmenityIcon(String amenity) {
    switch (amenity.toLowerCase()) {
      case 'buffet':
      case 'dining':
        return Icons.restaurant_rounded;
      case 'bar':
      case 'drinks':
        return Icons.local_bar_rounded;
      case 'showers':
        return Icons.shower_rounded;
      case 'wifi':
        return Icons.wifi_rounded;
      case 'power_outlets':
        return Icons.power_rounded;
      case 'quiet_area':
        return Icons.bed_outlined;
      case 'family_room':
        return Icons.family_restroom_rounded;
      default:
        return Icons.check_circle_outline_rounded;
    }
  }

  static String _humanize(String str) {
    return str
        .replaceAll('_', ' ')
        .split(' ')
        .map(
          (w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '',
        )
        .join(' ');
  }
}
