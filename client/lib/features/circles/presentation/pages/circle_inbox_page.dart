import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_exceptions.dart';
import '../../../notifications/presentation/providers/notification_provider.dart';
import '../../../notifications/presentation/widgets/circle_notices_section.dart';
import '../../../trips/presentation/providers/trip_list_provider.dart';
import '../../domain/models/trip_invitation.dart';
import '../providers/trip_circle_provider.dart';
import '../widgets/join_trip_sheet.dart';

class CircleInboxPage extends ConsumerStatefulWidget {
  const CircleInboxPage({super.key});

  @override
  ConsumerState<CircleInboxPage> createState() => _CircleInboxPageState();
}

class _CircleInboxPageState extends ConsumerState<CircleInboxPage> {
  final Set<String> _busyIds = {};

  Future<void> _acceptInvitation(IncomingInvitation invite) async {
    setState(() => _busyIds.add(invite.id));
    try {
      await ref.read(circleInboxProvider.notifier).acceptInvitation(invite.id);
      await ref.read(tripListProvider.notifier).refresh();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Joined "${invite.tripTitle}"!'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Unable to accept invitation right now. Check your connection.',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _busyIds.remove(invite.id));
      }
    }
  }

  Future<void> _confirmDeclineInvitation(IncomingInvitation invite) async {
    var blockSender = false;
    final colorScheme = Theme.of(context).colorScheme;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Decline Invitation?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Decline joining "${invite.tripTitle}" from ${invite.inviterName}?',
              ),
              const SizedBox(height: 12),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: blockSender,
                onChanged: (v) =>
                    setDialogState(() => blockSender = v ?? false),
                title: const Text(
                  'Block future direct invites from this organizer',
                  style: TextStyle(fontSize: 13),
                ),
                controlAffinity: ListTileControlAffinity.leading,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: colorScheme.error),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Decline'),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _busyIds.add(invite.id));
    try {
      await ref
          .read(circleInboxProvider.notifier)
          .declineInvitation(invite.id, blockSender: blockSender);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              blockSender
                  ? 'Invitation declined and future direct invites blocked.'
                  : 'Invitation declined.',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _busyIds.remove(invite.id));
      }
    }
  }

  Future<void> _acceptTransfer(TripOwnershipTransfer transfer) async {
    setState(() => _busyIds.add(transfer.id));
    try {
      await ref
          .read(circleInboxProvider.notifier)
          .acceptOwnershipTransfer(transfer.id);
      await ref.read(tripListProvider.notifier).refresh();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'You are now the organizer of "${transfer.tripTitle}".',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Unable to accept ownership handover. Check your connection.',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _busyIds.remove(transfer.id));
      }
    }
  }

  Future<void> _declineTransfer(TripOwnershipTransfer transfer) async {
    setState(() => _busyIds.add(transfer.id));
    try {
      await ref
          .read(circleInboxProvider.notifier)
          .declineOwnershipTransfer(transfer.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ownership handover declined.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _busyIds.remove(transfer.id));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final inboxAsync = ref.watch(circleInboxProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Circle Inbox'),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_2_rounded),
            tooltip: 'Enter Invite Link or Code',
            onPressed: () => JoinTripSheet.show(
              context,
              onJoined: (tripId) => context.push('/trips/$tripId/circle'),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Inbox',
            onPressed: () => ref.read(circleInboxProvider.notifier).refresh(),
          ),
        ],
      ),
      body: inboxAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.cloud_off_rounded,
                  size: 48,
                  color: colorScheme.error,
                ),
                const SizedBox(height: 12),
                Text(
                  'Unable to load Circle Inbox',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 6),
                Text(
                  'Connect to the internet to check for direct trip invites and organizer handovers.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () =>
                      ref.read(circleInboxProvider.notifier).refresh(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (inbox) {
          final notices =
              ref.watch(userNotificationsProvider).asData?.value ?? const [];
          if (inbox.isEmpty && notices.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.mark_email_read_outlined,
                      size: 56,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No pending circle invitations',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Share your Friend Code from your Profile, or paste an organizer’s invite link below.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 16),
                    FilledButton.tonalIcon(
                      onPressed: () => JoinTripSheet.show(
                        context,
                        onJoined: (tripId) =>
                            context.push('/trips/$tripId/circle'),
                      ),
                      icon: const Icon(Icons.group_add_outlined),
                      label: const Text('Join with Invite Link'),
                    ),
                  ],
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              await Future.wait([
                ref.read(circleInboxProvider.notifier).refresh(),
                ref.read(userNotificationsProvider.notifier).refresh(),
              ]);
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const CircleNoticesSection(),
                if (inbox.isOffline) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.wifi_off_rounded,
                          size: 18,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Offline cache shown. Connect online to accept or decline.',
                            style: theme.textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                if (inbox.transfers.isNotEmpty) ...[
                  Text(
                    'Organizer Handovers',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...inbox.transfers.map(
                    (transfer) => _buildTransferCard(
                      context,
                      transfer,
                      disabled:
                          inbox.isOffline || _busyIds.contains(transfer.id),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                if (inbox.invitations.isNotEmpty) ...[
                  Text(
                    'Direct Trip Invitations',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...inbox.invitations.map(
                    (invite) => _buildInviteCard(
                      context,
                      invite,
                      disabled: inbox.isOffline || _busyIds.contains(invite.id),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTransferCard(
    BuildContext context,
    TripOwnershipTransfer transfer, {
    required bool disabled,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.secondary.withValues(alpha: 0.45)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.swap_horiz_rounded, color: colorScheme.secondary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    transfer.tripTitle,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '${transfer.fromUserName} offered to transfer trip organizer ownership to you. They will remain as ${transfer.formerOwnerRoleLabel}.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: disabled
                        ? null
                        : () => _declineTransfer(transfer),
                    child: const Text('Decline'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed: disabled
                        ? null
                        : () => _acceptTransfer(transfer),
                    child: const Text('Become Organizer'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInviteCard(
    BuildContext context,
    IncomingInvitation invite, {
    required bool disabled,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isExpired = invite.status == 'expired';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    invite.tripTitle,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    invite.proposedRole == 'editor' ? 'EDITOR' : 'VIEWER',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Invited by ${invite.inviterName}${invite.destinationCountry != null ? ' • ${invite.destinationCountry}' : ''}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            if (isExpired) ...[
              const SizedBox(height: 8),
              Text(
                'This invitation has expired.',
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: disabled
                        ? null
                        : () => _confirmDeclineInvitation(invite),
                    child: const Text('Decline'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed: disabled || isExpired
                        ? null
                        : () => _acceptInvitation(invite),
                    child: const Text('Accept & Join'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
