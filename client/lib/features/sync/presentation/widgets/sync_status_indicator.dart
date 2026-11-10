import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/sync_provider.dart';
import 'conflict_resolution_dialog.dart';

class SyncStatusIndicator extends ConsumerWidget {
  const SyncStatusIndicator({super.key, this.tripId});

  final String? tripId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncState = ref.watch(syncProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    switch (syncState.status) {
      case SyncStatus.synced:
        return Tooltip(
          message: 'All changes synced with server',
          child: IconButton(
            icon: const Icon(
              Icons.cloud_done_outlined,
              size: 20,
              color: Colors.green,
            ),
            onPressed: () =>
                ref.read(syncProvider.notifier).sync(tripId: tripId),
          ),
        );

      case SyncStatus.pending:
        return Tooltip(
          message:
              '${syncState.pendingCount} offline changes pending sync. Tap to sync.',
          child: InkWell(
            onTap: () => ref.read(syncProvider.notifier).sync(tripId: tripId),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.amber),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.cloud_upload_outlined,
                    size: 16,
                    color: Colors.amber,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${syncState.pendingCount}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.amber.shade900,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );

      case SyncStatus.syncing:
        return const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        );

      case SyncStatus.conflict:
        return Tooltip(
          message:
              '${syncState.conflictCount} version conflict(s) detected. Tap to resolve.',
          child: InkWell(
            onTap: () {
              if (syncState.conflicts.length == 1) {
                showDialog<void>(
                  context: context,
                  builder: (ctx) => ConflictResolutionDialog(
                    conflict: syncState.conflicts.first,
                  ),
                );
              } else if (syncState.conflicts.length > 1) {
                showModalBottomSheet<void>(
                  context: context,
                  showDragHandle: true,
                  builder: (sheetCtx) => ListView(
                    shrinkWrap: true,
                    padding: const EdgeInsets.all(16),
                    children: [
                      Text(
                        '${syncState.conflicts.length} Sync Conflicts',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...syncState.conflicts.map(
                        (conflict) => ListTile(
                          leading: Icon(
                            Icons.warning_amber_rounded,
                            color: colorScheme.error,
                          ),
                          title: Text(
                            conflict.payload?['title']?.toString() ??
                                conflict.payload?['name']?.toString() ??
                                conflict.entityType.replaceAll('_', ' '),
                          ),
                          subtitle: Text(
                            'Local v${conflict.baseVersion} vs Server v${conflict.conflictDetails?['server_version'] ?? '?'}',
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            Navigator.of(sheetCtx).pop();
                            showDialog<void>(
                              context: context,
                              builder: (ctx) =>
                                  ConflictResolutionDialog(conflict: conflict),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                );
              }
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              decoration: BoxDecoration(
                color: colorScheme.error.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: colorScheme.error),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    size: 16,
                    color: colorScheme.error,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Conflict (${syncState.conflictCount})',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.error,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );

      case SyncStatus.rejected:
        return Tooltip(
          message:
              '${syncState.rejectedCount} offline edit(s) rejected by server permissions. Tap for details.',
          child: InkWell(
            onTap: () {
              final rejected = syncState.rejectedOperations.firstOrNull;
              if (rejected != null) {
                final reason =
                    rejected.conflictDetails?['reason']?.toString() ??
                    'You no longer have edit permissions for this trip.';
                showDialog<void>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Offline Edit Rejected'),
                    content: Text(
                      'Your offline update to ${rejected.entityType.replaceAll('_', ' ')} was not applied:\n\n$reason',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () {
                          ref
                              .read(syncProvider.notifier)
                              .dismissRejected(rejected.operationId);
                          Navigator.of(ctx).pop();
                        },
                        child: const Text('Dismiss'),
                      ),
                    ],
                  ),
                );
              }
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              decoration: BoxDecoration(
                color: colorScheme.error.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: colorScheme.error),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.block_rounded, size: 16, color: colorScheme.error),
                  const SizedBox(width: 4),
                  Text(
                    'Rejected (${syncState.rejectedCount})',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.error,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );

      case SyncStatus.offline:
        return Tooltip(
          message: 'Offline mode — edits will sync when reconnected',
          child: IconButton(
            icon: Icon(
              Icons.cloud_off_outlined,
              size: 20,
              color: colorScheme.onSurfaceVariant,
            ),
            onPressed: () =>
                ref.read(syncProvider.notifier).sync(tripId: tripId),
          ),
        );
    }
  }
}
