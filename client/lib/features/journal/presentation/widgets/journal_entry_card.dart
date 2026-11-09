import 'package:flutter/material.dart';

import '../../domain/models/journal_entry.dart';

class JournalEntryCard extends StatelessWidget {
  const JournalEntryCard({
    super.key,
    required this.entry,
    this.onTap,
    this.onToggleShare,
    this.onEdit,
    this.onDelete,
    this.onAddPhoto,
  });

  final JournalEntry entry;
  final VoidCallback? onTap;
  final VoidCallback? onToggleShare;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onAddPhoto;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: entry.isShared
              ? Colors.teal.withValues(alpha: 0.3)
              : colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row: Author + Date + Privacy Badge + Options
              Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: colorScheme.primaryContainer,
                    child: Text(
                      entry.authorName.isNotEmpty
                          ? entry.authorName[0].toUpperCase()
                          : 'T',
                      style: TextStyle(
                        color: colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.authorName,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          entry.entryDate,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Privacy chip
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: entry.isShared
                          ? Colors.teal.withValues(alpha: 0.12)
                          : Colors.amber.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: entry.isShared
                            ? Colors.teal.withValues(alpha: 0.4)
                            : Colors.amber.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          entry.privacyIcon,
                          size: 13,
                          color: entry.privacyColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          entry.privacyLabel,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: entry.privacyColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (entry.isAuthor) ...[
                    PopupMenuButton<String>(
                      icon: Icon(
                        Icons.more_vert,
                        size: 20,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      onSelected: (value) {
                        switch (value) {
                          case 'toggle_share':
                            onToggleShare?.call();
                            break;
                          case 'edit':
                            onEdit?.call();
                            break;
                          case 'add_photo':
                            onAddPhoto?.call();
                            break;
                          case 'delete':
                            onDelete?.call();
                            break;
                        }
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'toggle_share',
                          child: Row(
                            children: [
                              Icon(
                                entry.isShared
                                    ? Icons.lock_outline_rounded
                                    : Icons.group_rounded,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                entry.isShared
                                    ? 'Make Private (Only You)'
                                    : 'Share with Circle',
                              ),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'edit',
                          child: const Row(
                            children: [
                              Icon(Icons.edit_outlined, size: 18),
                              SizedBox(width: 8),
                              Text('Edit Entry'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'add_photo',
                          child: const Row(
                            children: [
                              Icon(
                                Icons.add_photo_alternate_outlined,
                                size: 18,
                              ),
                              SizedBox(width: 8),
                              Text('Add Photo'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: const Row(
                            children: [
                              Icon(
                                Icons.delete_outline,
                                size: 18,
                                color: Colors.red,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Delete',
                                style: TextStyle(color: Colors.red),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12),

              // Title
              Text(
                entry.title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),

              // Metadata chips (Mood, Weather, Location)
              if (entry.mood != null ||
                  entry.weather != null ||
                  entry.locationName != null) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    if (entry.mood != null && entry.mood!.isNotEmpty)
                      Chip(
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        padding: EdgeInsets.zero,
                        labelPadding: const EdgeInsets.symmetric(horizontal: 8),
                        avatar: Text(entry.moodEmoji),
                        label: Text(
                          entry.moodLabel,
                          style: const TextStyle(fontSize: 12),
                        ),
                        backgroundColor: colorScheme.surfaceContainerHighest,
                      ),
                    if (entry.weather != null && entry.weather!.isNotEmpty)
                      Chip(
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        padding: EdgeInsets.zero,
                        labelPadding: const EdgeInsets.symmetric(horizontal: 8),
                        avatar: Icon(
                          entry.weatherIcon,
                          size: 14,
                          color: Colors.orange,
                        ),
                        label: Text(
                          entry.weather!,
                          style: const TextStyle(fontSize: 12),
                        ),
                        backgroundColor: colorScheme.surfaceContainerHighest,
                      ),
                    if (entry.locationName != null &&
                        entry.locationName!.isNotEmpty)
                      Chip(
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        padding: EdgeInsets.zero,
                        labelPadding: const EdgeInsets.symmetric(horizontal: 8),
                        avatar: const Icon(
                          Icons.location_on_outlined,
                          size: 14,
                          color: Colors.redAccent,
                        ),
                        label: Text(
                          entry.locationName!,
                          style: const TextStyle(fontSize: 12),
                        ),
                        backgroundColor: colorScheme.surfaceContainerHighest,
                      ),
                  ],
                ),
              ],

              const SizedBox(height: 10),

              // Reflection content
              Text(
                entry.content,
                style: theme.textTheme.bodyMedium?.copyWith(
                  height: 1.45,
                  color: colorScheme.onSurface,
                ),
              ),

              // Photo Gallery Carousel / Row
              if (entry.photos.isNotEmpty) ...[
                const SizedBox(height: 14),
                SizedBox(
                  height: 100,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: entry.photos.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final photoUrl = entry.photos[index];
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          width: 100,
                          height: 100,
                          color: colorScheme.surfaceContainerHighest,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.network(
                                photoUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) => Center(
                                  child: Icon(
                                    Icons.image_outlined,
                                    size: 32,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: 4,
                                right: 4,
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: BoxDecoration(
                                    color: Colors.black54,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Icon(
                                    Icons.fullscreen,
                                    size: 14,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
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
