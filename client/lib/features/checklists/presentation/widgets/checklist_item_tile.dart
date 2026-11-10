import 'package:flutter/material.dart';

import '../../domain/models/checklist_item.dart';
import 'photo_viewer_dialog.dart';

class ChecklistItemTile extends StatelessWidget {
  const ChecklistItemTile({
    super.key,
    required this.item,
    required this.onToggle,
    this.canToggle = true,
    this.canEdit = true,
    this.onEdit,
    this.onDelete,
    this.onAttachPhoto,
  });

  final ChecklistItem item;
  final VoidCallback onToggle;
  final bool canToggle;
  final bool canEdit;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onAttachPhoto;

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
        onTap: canToggle ? onToggle : null,
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
                onPressed: canToggle ? onToggle : null,
                icon: Icon(
                  isPacked
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked_rounded,
                  color: isPacked
                      ? colorScheme.primary
                      : canToggle
                      ? colorScheme.onSurfaceVariant.withValues(alpha: 0.7)
                      : colorScheme.outlineVariant,
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
                    if (item.assigneeLabel != null ||
                        (item.isPacked && item.completedByName != null)) ...[
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          if (item.assigneeLabel != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: colorScheme.tertiaryContainer,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                item.assignedTravelerId != null
                                    ? 'For ${item.assigneeLabel} (Managed)'
                                    : 'Assigned: ${item.assigneeLabel}',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: colorScheme.onTertiaryContainer,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          if (item.isPacked && item.completedByName != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Packed by ${item.completedByName}',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              if (item.photoUrl != null && item.photoUrl!.isNotEmpty) ...[
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => PhotoViewerDialog.show(
                    context,
                    photoUrl: item.photoUrl!,
                    title: item.title,
                  ),
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: colorScheme.surfaceContainerHighest,
                      border: Border.all(
                        color: colorScheme.primary.withValues(alpha: 0.3),
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Image.network(
                      item.photoUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.photo_rounded,
                        size: 18,
                        color: Colors.blueGrey,
                      ),
                    ),
                  ),
                ),
              ],

              // Context Menu (only for editors/organizers)
              if (canEdit)
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
                    if (value == 'photo') onAttachPhoto?.call();
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
                      value: 'photo',
                      child: Row(
                        children: [
                          Icon(Icons.add_a_photo_outlined, size: 18),
                          SizedBox(width: 8),
                          Text('Attach Photo'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(
                            Icons.delete_outline_rounded,
                            size: 18,
                            color: colorScheme.error,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Delete',
                            style: TextStyle(color: colorScheme.error),
                          ),
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
