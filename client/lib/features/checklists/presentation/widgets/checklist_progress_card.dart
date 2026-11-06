import 'package:flutter/material.dart';

class ChecklistProgressCard extends StatelessWidget {
  const ChecklistProgressCard({
    super.key,
    required this.totalItems,
    required this.packedItems,
    required this.progressPercentage,
    this.checklistTitle,
  });

  final int totalItems;
  final int packedItems;
  final int progressPercentage;
  final String? checklistTitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isComplete = totalItems > 0 && packedItems == totalItems;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isComplete
              ? Colors.teal.withValues(alpha: 0.5)
              : colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isComplete
                      ? Colors.teal.withValues(alpha: 0.15)
                      : colorScheme.primary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isComplete
                      ? Icons.check_circle_rounded
                      : Icons.backpack_rounded,
                  color: isComplete ? Colors.teal : colorScheme.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      checklistTitle ?? 'Packing Progress',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$packedItems of $totalItems packed',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
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
                  color: isComplete
                      ? Colors.teal.withValues(alpha: 0.15)
                      : colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$progressPercentage%',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: isComplete
                        ? Colors.teal.shade800
                        : colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: totalItems > 0 ? (packedItems / totalItems) : 0,
              minHeight: 8,
              backgroundColor: colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(
                isComplete ? Colors.teal : colorScheme.primary,
              ),
            ),
          ),
          if (isComplete) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(
                  Icons.verified_rounded,
                  size: 16,
                  color: Colors.teal.shade700,
                ),
                const SizedBox(width: 6),
                Text(
                  'All packed and ready for departure! 🎉',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: Colors.teal.shade800,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
