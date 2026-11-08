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
              if (syncState.conflicts.isNotEmpty) {
                showDialog<void>(
                  context: context,
                  builder: (ctx) => ConflictResolutionDialog(
                    conflict: syncState.conflicts.first,
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
