import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../flights/domain/models/flight.dart';
import '../../../flights/presentation/widgets/add_flight_sheet.dart';
import '../../domain/models/today_dashboard_summary.dart';

class TodayFlightCard extends StatelessWidget {
  const TodayFlightCard({
    super.key,
    required this.summary,
    this.onFlightChanged,
  });

  final TodayDashboardSummary summary;
  final VoidCallback? onFlightChanged;

  String _formatUtcShort(DateTime dt) {
    final u = dt.toUtc();
    final month = u.month.toString().padLeft(2, '0');
    final day = u.day.toString().padLeft(2, '0');
    final hour = u.hour.toString().padLeft(2, '0');
    final minute = u.minute.toString().padLeft(2, '0');
    return '${u.year}-$month-$day $hour:$minute UTC';
  }

  Future<void> _openFlightSheet(
    BuildContext context, {
    Flight? existing,
  }) async {
    await AddFlightSheet.show(
      context,
      summary.trip.id,
      existingFlight: existing,
    );
    onFlightChanged?.call();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final flight = summary.upcomingFlight;

    if (flight == null || flight.segments.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colorScheme.outlineVariant, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    Icons.flight_takeoff_rounded,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'No flight booking linked',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Add a flight or paste confirmation text for terminal prep & reminders',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => _openFlightSheet(context),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Add Flight'),
              ),
            ),
          ],
        ),
      );
    }

    final nowUtc = DateTime.now().toUtc();
    final activeSegment = flight.segments.firstWhere(
      (s) => s.scheduledArrivalUtc.isAfter(nowUtc),
      orElse: () => flight.segments.first,
    );
    final hasTerminal =
        activeSegment.terminal != null &&
        activeSegment.terminal!.trim().isNotEmpty;
    final terminalText = hasTerminal ? activeSegment.terminal!.trim() : null;
    final hasGate =
        activeSegment.gate != null && activeSegment.gate!.trim().isNotEmpty;
    final loungeRoute = terminalText != null
        ? '/lounges?iata=${activeSegment.originAirport}&terminal=${Uri.encodeComponent(terminalText)}'
        : '/lounges?iata=${activeSegment.originAirport}';
    final loungeButtonLabel = terminalText != null
        ? 'Explore ${activeSegment.originAirport} T$terminalText Lounges'
        : 'Explore ${activeSegment.originAirport} Lounges';

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 8),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    Icons.flight_takeoff_rounded,
                    color: colorScheme.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            'UPCOMING FLIGHT',
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.secondary,
                              letterSpacing: 0.5,
                            ),
                          ),
                          if (flight.airline != null &&
                              flight.airline!.trim().isNotEmpty)
                            Text(
                              '• ${flight.airline}',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: colorScheme.outline,
                              ),
                            ),
                          if (flight.segments.length > 1)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: colorScheme.secondaryContainer,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${flight.segments.length} segments',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: colorScheme.onSecondaryContainer,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${activeSegment.flightNumber} • ${activeSegment.originAirport} → ${activeSegment.destinationAirport}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Departs ${_formatUtcShort(activeSegment.scheduledDepartureUtc)} (${activeSegment.originTimezone})',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Edit flight',
                  onPressed: () => _openFlightSheet(context, existing: flight),
                  icon: const Icon(Icons.edit_outlined, size: 20),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                if (terminalText != null)
                  _InfoChip(
                    icon: Icons.meeting_room_outlined,
                    label: 'Terminal $terminalText',
                  ),
                if (hasGate)
                  _InfoChip(
                    icon: Icons.sensor_door_outlined,
                    label: 'Gate ${activeSegment.gate!.trim()}',
                  ),
                if (flight.bookingReference != null &&
                    flight.bookingReference!.trim().isNotEmpty)
                  _InfoChip(
                    icon: Icons.lock_outline_rounded,
                    label: 'Ref: ${flight.bookingReference!.trim()}',
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Text(
              'Scheduled booking details • Not live airline status',
              style: theme.textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: OverflowBar(
              spacing: 8,
              overflowSpacing: 8,
              alignment: MainAxisAlignment.end,
              children: [
                FilledButton.tonalIcon(
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => context.push(loungeRoute),
                  icon: const Icon(
                    Icons.airline_seat_recline_extra_rounded,
                    size: 16,
                  ),
                  label: Text(
                    loungeButtonLabel,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: colorScheme.primary),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
