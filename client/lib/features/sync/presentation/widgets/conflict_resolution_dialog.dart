import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/outbox_operation.dart';
import '../providers/sync_provider.dart';

class ConflictResolutionDialog extends ConsumerWidget {
  const ConflictResolutionDialog({super.key, required this.conflict});

  final OutboxOperation conflict;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final serverVersion =
        conflict.conflictDetails?['server_version'] ?? 'Latest';
    final serverPayload =
        conflict.conflictDetails?['server_payload'] as Map<String, dynamic>?;

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: colorScheme.error),
          const SizedBox(width: 8),
          const Expanded(child: Text('Version Conflict Detected')),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'A concurrent change was saved on the server while you were offline for ${conflict.entityType.replaceAll('_', ' ')}.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.errorContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: colorScheme.error.withValues(alpha: 0.4),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Server Version ($serverVersion)',
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.error,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    serverPayload != null
                        ? _formatPayloadSummary(serverPayload)
                        : 'Remote updates applied.',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: colorScheme.primary.withValues(alpha: 0.4),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your Offline Edit (Version ${conflict.baseVersion})',
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    conflict.payload != null
                        ? _formatPayloadSummary(conflict.payload!)
                        : 'Local offline modifications.',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        OutlinedButton(
          onPressed: () async {
            await ref
                .read(syncProvider.notifier)
                .resolveConflict(conflict.operationId, keepLocal: false);
            if (context.mounted) Navigator.of(context).pop();
          },
          child: const Text('Keep Server Version'),
        ),
        FilledButton(
          onPressed: () async {
            await ref
                .read(syncProvider.notifier)
                .resolveConflict(conflict.operationId, keepLocal: true);
            if (context.mounted) Navigator.of(context).pop();
          },
          child: const Text('Keep My Offline Edit'),
        ),
      ],
    );
  }

  static String _formatPayloadSummary(Map<String, dynamic> payload) {
    final keys = ['title', 'name', 'is_packed', 'notes', 'status'];
    final buffer = StringBuffer();
    for (final key in keys) {
      if (payload.containsKey(key)) {
        buffer.writeln('$key: ${payload[key]}');
      }
    }
    return buffer.isEmpty ? payload.toString() : buffer.toString().trim();
  }
}
