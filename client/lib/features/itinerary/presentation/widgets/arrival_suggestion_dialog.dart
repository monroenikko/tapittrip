import 'package:flutter/material.dart';

import '../../domain/models/itinerary_item.dart';

class ArrivalSuggestionDialog extends StatelessWidget {
  const ArrivalSuggestionDialog({
    super.key,
    required this.item,
    this.distanceMeters,
    required this.onConfirm,
    this.onDismiss,
  });

  final ItineraryItem item;
  final double? distanceMeters;
  final VoidCallback onConfirm;
  final VoidCallback? onDismiss;

  static Future<bool?> show(
    BuildContext context, {
    required ItineraryItem item,
    double? distanceMeters,
    required VoidCallback onConfirm,
    VoidCallback? onDismiss,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (context) => ArrivalSuggestionDialog(
        item: item,
        distanceMeters: distanceMeters,
        onConfirm: onConfirm,
        onDismiss: onDismiss,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.location_on,
              color: colorScheme.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Arrival Detected',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          if (item.place?.formattedAddress != null) ...[
            const SizedBox(height: 4),
            Text(
              item.place!.formattedAddress!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Text(
            'We noticed you’ve arrived nearby. Would you like to mark this activity as visited to update your trip progress?',
            style: theme.textTheme.bodyMedium,
          ),
          if (distanceMeters != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '📍 ~${distanceMeters!.round()} meters away',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(false);
            onDismiss?.call();
          },
          child: const Text('Not Yet'),
        ),
        FilledButton.icon(
          onPressed: () {
            Navigator.of(context).pop(true);
            onConfirm();
          },
          icon: const Icon(Icons.check, size: 18),
          label: const Text('Mark Visited'),
        ),
      ],
    );
  }
}

