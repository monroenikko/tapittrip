import 'package:flutter/material.dart';

import '../../domain/models/airport_lounge.dart';
import 'lounge_detail_sheet.dart';

class LoungeCard extends StatelessWidget {
  const LoungeCard({super.key, required this.lounge});

  final AirportLounge lounge;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          showModalBottomSheet<void>(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (ctx) => LoungeDetailSheet(lounge: lounge),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          lounge.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (lounge.operatorName.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            lounge.operatorName,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      lounge.terminal?.code ?? 'Terminal',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Location description
              Row(
                children: [
                  Icon(
                    lounge.isAirside
                        ? Icons.flight_takeoff_rounded
                        : Icons.meeting_room_outlined,
                    size: 14,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '${lounge.isAirside ? 'Airside' : 'Landside'} • ${lounge.locationDescription}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Amenities Icons & Access Programs Preview
              Row(
                children: [
                  Expanded(
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: lounge.accessMethods.take(3).map((method) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            _formatTag(method),
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontSize: 10,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _formatTag(String tag) {
    switch (tag.toLowerCase()) {
      case 'priority_pass':
        return 'Priority Pass';
      case 'dragon_pass':
        return 'DragonPass';
      case 'lounge_key':
        return 'LoungeKey';
      case 'business_class':
        return 'Business Class';
      case 'paid_walkin':
        return 'Walk-In';
      default:
        return tag.replaceAll('_', ' ');
    }
  }
}
