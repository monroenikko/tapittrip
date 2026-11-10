import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/models/trip_notification.dart';
import '../providers/notification_provider.dart';

class CircleNoticesSection extends ConsumerWidget {
  const CircleNoticesSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final asyncNotices = ref.watch(userNotificationsProvider);

    return asyncNotices.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (notices) {
        if (notices.isEmpty) {
          return const SizedBox.shrink();
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                'Circle Notices',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ...notices.map(
              (n) => _NoticeCard(
                notice: n,
                colorScheme: colorScheme,
                theme: theme,
                onMarkRead: n.isRead
                    ? null
                    : () => ref
                          .read(userNotificationsProvider.notifier)
                          .markRead(n.id),
                onOpenTrip: () async {
                  if (!n.isRead) {
                    await ref
                        .read(userNotificationsProvider.notifier)
                        .markRead(n.id);
                  }
                  if (context.mounted) {
                    context.push('/trips/${n.tripId}/circle');
                  }
                },
              ),
            ),
            const SizedBox(height: 12),
          ],
        );
      },
    );
  }
}

class _NoticeCard extends StatelessWidget {
  const _NoticeCard({
    required this.notice,
    required this.colorScheme,
    required this.theme,
    required this.onMarkRead,
    required this.onOpenTrip,
  });

  final UserNotification notice;
  final ColorScheme colorScheme;
  final ThemeData theme;
  final VoidCallback? onMarkRead;
  final VoidCallback onOpenTrip;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      color: notice.isRead ? null : colorScheme.secondaryContainer,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onOpenTrip,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.notifications_active_outlined,
                    size: 18,
                    color: notice.isRead
                        ? colorScheme.onSurfaceVariant
                        : colorScheme.onSecondaryContainer,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      notice.title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (!notice.isRead)
                    TextButton(
                      onPressed: onMarkRead,
                      child: const Text('Mark read'),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(notice.body, style: theme.textTheme.bodyMedium),
              const SizedBox(height: 6),
              Text(
                '${notice.tripTitle}${notice.tripLocalTimeLabel != null ? ' • ${notice.tripLocalTimeLabel}' : ''}${notice.isSuppressedQuietHours ? ' • Queued after quiet hours' : ''}',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

