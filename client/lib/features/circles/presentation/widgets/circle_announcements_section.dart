import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exceptions.dart';
import '../../../sync/services/sync_service.dart';
import '../../domain/models/trip_announcement.dart';
import '../providers/trip_circle_provider.dart';

class CircleAnnouncementsSection extends ConsumerWidget {
  const CircleAnnouncementsSection({
    required this.tripId,
    required this.isOwner,
    super.key,
  });

  final String tripId;
  final bool isOwner;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final asyncAnnouncements = ref.watch(tripAnnouncementsProvider(tripId));

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.campaign_outlined, color: colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Circle Announcements',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (isOwner)
                  FilledButton.tonalIcon(
                    onPressed: () => _openComposeSheet(context, ref),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Post'),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            asyncAnnouncements.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (err, _) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Unable to load organizer announcements.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.error,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextButton(
                    onPressed: () => ref
                        .read(tripAnnouncementsProvider(tripId).notifier)
                        .refresh(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
              data: (state) {
                if (state.items.isEmpty) {
                  return Text(
                    isOwner
                        ? 'Post updates for everyone in this circle. Members always see announcements here even if push alerts are off.'
                        : 'No organizer announcements yet.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (state.isOffline)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          'Showing cached announcements while offline.',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ...state.items.map(
                      (a) => _AnnouncementTile(
                        announcement: a,
                        isOwner: isOwner,
                        onEdit: () =>
                            _openComposeSheet(context, ref, existing: a),
                        onDelete: () => _confirmDelete(context, ref, a),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openComposeSheet(
    BuildContext context,
    WidgetRef ref, {
    TripAnnouncement? existing,
  }) async {
    final titleController = TextEditingController(text: existing?.title ?? '');
    final bodyController = TextEditingController(text: existing?.body ?? '');
    var isPinned = existing?.isPinned ?? false;
    final operationId = existing == null ? SyncService.generateUuid() : null;
    var saving = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            8,
            20,
            MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                existing == null ? 'Post Announcement' : 'Edit Announcement',
                style: Theme.of(ctx).textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: titleController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  hintText: 'e.g. Meet at Terminal 2',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: bodyController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Message',
                  hintText: 'Share schedule notes (never include passcodes).',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Pin announcement to top'),
                value: isPinned,
                onChanged: saving
                    ? null
                    : (val) => setSheetState(() => isPinned = val),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                  onPressed: saving
                      ? null
                      : () async {
                          final title = titleController.text.trim();
                          final body = bodyController.text.trim();
                          if (title.isEmpty || body.isEmpty) return;

                          setSheetState(() => saving = true);
                          try {
                            final notifier = ref.read(
                              tripAnnouncementsProvider(tripId).notifier,
                            );
                            if (existing == null) {
                              await notifier.createAnnouncement(
                                title: title,
                                body: body,
                                isPinned: isPinned,
                                clientOperationId: operationId,
                              );
                            } else {
                              await notifier.updateAnnouncement(
                                existing.id,
                                title: title,
                                body: body,
                                isPinned: isPinned,
                                baseVersion: existing.version,
                              );
                            }
                            if (ctx.mounted) Navigator.of(ctx).pop();
                          } on ApiException catch (e) {
                            setSheetState(() => saving = false);
                            if (ctx.mounted) {
                              ScaffoldMessenger.of(ctx).showSnackBar(
                                SnackBar(content: Text(e.message)),
                              );
                            }
                          }
                        },
                  child: saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(existing == null ? 'Publish' : 'Save Changes'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    TripAnnouncement announcement,
  ) async {
    final colorScheme = Theme.of(context).colorScheme;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Announcement?'),
        content: Text(
          'Remove "${announcement.title}" and cancel any pending notifications?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: colorScheme.error),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref
          .read(tripAnnouncementsProvider(tripId).notifier)
          .deleteAnnouncement(announcement.id);
    } on ApiException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }
}

class _AnnouncementTile extends StatelessWidget {
  const _AnnouncementTile({
    required this.announcement,
    required this.isOwner,
    required this.onEdit,
    required this.onDelete,
  });

  final TripAnnouncement announcement;
  final bool isOwner;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: announcement.isPinned
            ? colorScheme.primaryContainer.withValues(alpha: 0.35)
            : colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: announcement.isPinned
              ? colorScheme.primary.withValues(alpha: 0.4)
              : colorScheme.outlineVariant,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (announcement.isPinned) ...[
                Icon(Icons.push_pin, size: 16, color: colorScheme.primary),
                const SizedBox(width: 6),
              ],
              Expanded(
                child: Text(
                  announcement.title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (isOwner)
                PopupMenuButton<String>(
                  tooltip: 'Announcement actions',
                  onSelected: (value) {
                    if (value == 'edit') {
                      onEdit();
                    } else if (value == 'delete') {
                      onDelete();
                    }
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'edit', child: Text('Edit')),
                    PopupMenuItem(value: 'delete', child: Text('Delete')),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(announcement.body, style: theme.textTheme.bodyMedium),
          const SizedBox(height: 6),
          Text(
            'Posted by ${announcement.authorName}',
            style: theme.textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
