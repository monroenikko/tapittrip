import 'package:flutter/material.dart';

import '../../domain/models/checklist_item.dart';

class ChecklistItemTile extends StatelessWidget {
  const ChecklistItemTile({
    super.key,
    required this.item,
    required this.onToggle,
    this.onEdit,
    this.onDelete,
  });

  final ChecklistItem item;
  final VoidCallback onToggle;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  IconData _categoryIcon(String category) {
    switch (category) {
      case 'documents':
        return Icons.description_outlined;
      case 'clothing':
        return Icons.checkroom_outlined;
      case 'electronics':
        return Icons.devices_other_outlined;
      case 'toiletries':
        return Icons.sanitizer_outlined;
      case 'health':
        return Icons.medical_services_outlined;
      case 'gear':
        return Icons.hiking_outlined;
      default:
        return Icons.category_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isPacked = item.isPacked;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onToggle,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: isPacked
                ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.35)
                : colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isPacked
                  ? Colors.transparent
                  : colorScheme.outlineVariant.withValues(alpha: 0.4),
            ),
          ),
          child: Row(
            children: [
              // Checkbox button
              IconButton(
                iconSize: 26,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: onToggle,
                icon: Icon(
                  isPacked
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked_rounded,
                  color: isPacked
                      ? Colors.teal
                      : colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(width: 12),

              // Category Icon
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.6,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _categoryIcon(item.category),
                  size: 16,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 12),

              // Title, quantity & notes
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.title,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              decoration: isPacked
                                  ? TextDecoration.lineThrough
                                  : null,
                              color: isPacked
                                  ? colorScheme.onSurfaceVariant.withValues(
                                      alpha: 0.6,
                                    )
                                  : colorScheme.onSurface,
                            ),
                          ),
                        ),
                        if (item.quantity > 1) ...[
                          const SizedBox(width: 8),
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
                              '×${item.quantity}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onSecondaryContainer,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (item.notes != null && item.notes!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        item.notes!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 12,
                          color: colorScheme.onSurfaceVariant.withValues(
                            alpha: 0.8,
                          ),
                          fontStyle: FontStyle.italic,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),

              // Context Menu
              PopupMenuButton<String>(
                icon: Icon(
                  Icons.more_vert_rounded,
                  size: 20,
                  color: colorScheme.onSurfaceVariant,
                ),
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                onSelected: (value) {
                  if (value == 'edit') onEdit?.call();
                  if (value == 'delete') onDelete?.call();
                },
                itemBuilder: (ctx) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit_outlined, size: 18),
                        SizedBox(width: 8),
                        Text('Edit'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(
                          Icons.delete_outline_rounded,
                          size: 18,
                          color: Colors.red,
                        ),
                        SizedBox(width: 8),
                        Text('Delete', style: TextStyle(color: Colors.red)),
                      ],
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
