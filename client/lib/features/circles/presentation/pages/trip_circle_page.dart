import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_exceptions.dart';
import '../../../auth/domain/models/auth_state.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../trips/presentation/providers/trip_list_provider.dart';
import '../../domain/models/activity_event.dart';
import '../../domain/models/circle_member.dart';
import '../../domain/models/trip_invitation.dart';
import '../providers/trip_circle_provider.dart';

class TripCirclePage extends ConsumerStatefulWidget {
  const TripCirclePage({super.key, required this.tripId});

  final String tripId;

  @override
  ConsumerState<TripCirclePage> createState() => _TripCirclePageState();
}

class _TripCirclePageState extends ConsumerState<TripCirclePage> {
  final _friendCodeController = TextEditingController();
  bool _directInviteMode = false;
  String _inviteRole = 'viewer';
  int _inviteMaxUses = 1;
  bool _isCreatingInvite = false;
  TripInvitation? _latestCreatedInvite;

  @override
  void dispose() {
    _friendCodeController.dispose();
    super.dispose();
  }

  Future<void> _sendDirectInvite() async {
    final code = _friendCodeController.text.trim().toUpperCase();
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter a traveler Friend Code first.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isCreatingInvite = true);
    try {
      final result = await ref
          .read(tripInvitationsProvider(widget.tripId).notifier)
          .sendDirectInvitation(friendCode: code, proposedRole: _inviteRole);
      if (mounted) {
        setState(() => _isCreatingInvite = false);
        _friendCodeController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result.alreadyPending
                  ? 'An invite is already pending for that traveler.'
                  : 'Invitation sent to ${result.invitation.targetDisplayName ?? 'traveler'}!',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } on ValidationException catch (e) {
      if (mounted) {
        setState(() => _isCreatingInvite = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.fieldErrors.isNotEmpty ? e.fieldErrors.first : e.message,
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() => _isCreatingInvite = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isCreatingInvite = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to send direct invite right now.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _confirmTransferOwnership(CircleMember member) async {
    var formerOwnerRole = 'editor';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Transfer Organizer Ownership?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Offer organizer ownership of this trip to ${member.displayName}. Ownership changes only after they explicitly accept.',
              ),
              const SizedBox(height: 14),
              const Text(
                'Your role after handover:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('Editor'),
                    selected: formerOwnerRole == 'editor',
                    onSelected: (_) =>
                        setDialogState(() => formerOwnerRole = 'editor'),
                  ),
                  ChoiceChip(
                    label: const Text('Viewer'),
                    selected: formerOwnerRole == 'viewer',
                    onSelected: (_) =>
                        setDialogState(() => formerOwnerRole = 'viewer'),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Send Handover Request'),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      final result = await ref
          .read(pendingOwnershipTransferProvider(widget.tripId).notifier)
          .initiateTransfer(
            targetMemberId: member.id,
            formerOwnerRole: formerOwnerRole,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result.alreadyPending
                  ? 'Handover request is already pending for ${member.displayName}.'
                  : 'Ownership handover offer sent to ${member.displayName}.',
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
    }
  }

  Future<void> _createInvite() async {
    setState(() => _isCreatingInvite = true);
    try {
      final created = await ref
          .read(tripInvitationsProvider(widget.tripId).notifier)
          .createInvitation(proposedRole: _inviteRole, maxUses: _inviteMaxUses);
      if (mounted) {
        setState(() {
          _latestCreatedInvite = created;
          _isCreatingInvite = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isCreatingInvite = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to generate invite link right now.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _copyToClipboard(String text, String label) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$label copied to clipboard.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _confirmRemoveOrLeave(
    CircleMember member, {
    required bool isSelf,
  }) async {
    final colorScheme = Theme.of(context).colorScheme;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isSelf ? 'Leave Trip Circle?' : 'Remove Member?'),
        content: Text(
          isSelf
              ? 'You will lose access to this shared trip unless invited again.'
              : 'Remove ${member.displayName} from this trip circle?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: colorScheme.error),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(isSelf ? 'Leave Trip' : 'Remove'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    await ref
        .read(circleMembersProvider(widget.tripId).notifier)
        .removeMember(member.id);

    if (isSelf) {
      await ref.read(tripListProvider.notifier).refresh();
      if (mounted) {
        context.go('/trips');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final trips = ref.watch(tripListProvider).asData?.value;
    final trip = trips?.where((t) => t.id == widget.tripId).firstOrNull;
    final tripTitle = trip?.title ?? 'Trip Circle';

    final authState = ref.watch(authProvider);
    final currentUserId = authState is Authenticated ? authState.user.id : null;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Trip Circle & Feed',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(
                tripTitle,
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Refresh Circle',
              onPressed: () {
                ref.invalidate(tripActivityFeedProvider(widget.tripId));
                ref
                    .read(circleMembersProvider(widget.tripId).notifier)
                    .refresh();
                ref
                    .read(tripInvitationsProvider(widget.tripId).notifier)
                    .refresh();
                ref
                    .read(
                      pendingOwnershipTransferProvider(widget.tripId).notifier,
                    )
                    .refresh();
              },
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(
                icon: Icon(Icons.dynamic_feed_outlined, size: 18),
                text: 'Activity Feed',
              ),
              Tab(
                icon: Icon(Icons.group_outlined, size: 18),
                text: 'Members & Invites',
              ),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildFeedTab(context),
            _buildMembersTab(context, currentUserId, trip?.ownerId),
          ],
        ),
      ),
    );
  }

  Widget _buildFeedTab(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final feedAsync = ref.watch(tripActivityFeedProvider(widget.tripId));

    return feedAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: colorScheme.error,
              ),
              const SizedBox(height: 12),
              Text(
                'Unable to load activity feed',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () =>
                    ref.invalidate(tripActivityFeedProvider(widget.tripId)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      data: (events) {
        if (events.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('✨', style: TextStyle(fontSize: 40)),
                  const SizedBox(height: 12),
                  Text(
                    'No circle activity yet',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'When companions join or share travel moments from their journal, updates appear here.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(tripActivityFeedProvider(widget.tripId));
          },
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: events.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, idx) =>
                _buildEventCard(context, events[idx]),
          ),
        );
      },
    );
  }

  Widget _buildEventCard(BuildContext context, ActivityEvent event) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: colorScheme.primaryContainer,
                child: Text(
                  event.actorName.isNotEmpty
                      ? event.actorName[0].toUpperCase()
                      : 'T',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onPrimaryContainer,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.actorName,
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (event.occurredAt != null)
                      Text(
                        event.occurredAt!.toLocal().toString().substring(0, 16),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
              Text(event.eventEmoji, style: const TextStyle(fontSize: 20)),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            event.title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          if (event.summary != null && event.summary!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              event.summary!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          if (event.photos.isNotEmpty) ...[
            const SizedBox(height: 10),
            SizedBox(
              height: 84,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: event.photos.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (_, idx) => ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    event.photos[idx],
                    width: 84,
                    height: 84,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(
                      width: 84,
                      height: 84,
                      color: colorScheme.surfaceContainerHighest,
                      child: const Icon(Icons.photo_outlined, size: 28),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMembersTab(
    BuildContext context,
    String? currentUserId,
    String? tripOwnerId,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final membersAsync = ref.watch(circleMembersProvider(widget.tripId));
    final invitationsAsync = ref.watch(tripInvitationsProvider(widget.tripId));
    final pendingTransferAsync = ref.watch(
      pendingOwnershipTransferProvider(widget.tripId),
    );

    return membersAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: colorScheme.error,
              ),
              const SizedBox(height: 12),
              Text(
                'Unable to load circle members',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => ref
                    .read(circleMembersProvider(widget.tripId).notifier)
                    .refresh(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      data: (members) {
        final selfMember = members
            .where((m) => currentUserId != null && m.userId == currentUserId)
            .firstOrNull;
        final isOrganizer =
            selfMember?.isOwner == true ||
            (currentUserId != null && currentUserId == tripOwnerId);

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (isOrganizer) ...[
              if (pendingTransferAsync.asData?.value != null) ...[
                _buildPendingTransferBanner(
                  context,
                  pendingTransferAsync.asData!.value!,
                ),
                const SizedBox(height: 12),
              ],
              _buildInviteGeneratorCard(context, theme, colorScheme),
              const SizedBox(height: 16),
            ],

            Text(
              'Travel Circle Members (${members.length})',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            ...members.map((member) {
              final isSelf =
                  currentUserId != null && member.userId == currentUserId;
              return _buildMemberCard(
                context,
                member: member,
                isOrganizerView: isOrganizer,
                isSelf: isSelf,
              );
            }),

            if (!isOrganizer && selfMember != null) ...[
              const SizedBox(height: 16),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: colorScheme.error,
                  side: BorderSide(
                    color: colorScheme.error.withValues(alpha: 0.5),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                icon: const Icon(Icons.logout_rounded),
                label: const Text('Leave Trip Circle'),
                onPressed: () =>
                    _confirmRemoveOrLeave(selfMember, isSelf: true),
              ),
            ],

            if (isOrganizer) ...[
              const SizedBox(height: 24),
              Text(
                'Active & Past Invites',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              invitationsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, _) => const Text('Unable to load invitations.'),
                data: (invites) {
                  if (invites.isEmpty) {
                    return Text(
                      'No invitations generated yet. Create an invite link above to share this trip.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    );
                  }
                  return Column(
                    children: invites
                        .map((inv) => _buildInvitationRow(context, inv))
                        .toList(),
                  );
                },
              ),
            ],
            const SizedBox(height: 32),
          ],
        );
      },
    );
  }

  Widget _buildPendingTransferBanner(
    BuildContext context,
    TripOwnershipTransfer transfer,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colorScheme.secondary.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(Icons.swap_horiz_rounded, color: colorScheme.secondary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ownership Handover Pending',
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Offered to ${transfer.toUserName} (you remain ${transfer.formerOwnerRoleLabel}).',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: colorScheme.error),
            onPressed: () => ref
                .read(pendingOwnershipTransferProvider(widget.tripId).notifier)
                .cancelTransfer(transfer.id),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Widget _buildInviteGeneratorCard(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.person_add_alt_1_rounded, color: colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'Invite Travelers',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ChoiceChip(
                label: const Text('Share Link'),
                selected: !_directInviteMode,
                onSelected: (_) => setState(() => _directInviteMode = false),
              ),
              ChoiceChip(
                label: const Text('Friend Code'),
                selected: _directInviteMode,
                onSelected: (_) => setState(() => _directInviteMode = true),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _directInviteMode
                ? 'Send an in-app invitation directly using your companion’s Friend Code.'
                : 'Generate a private expiring invite link to share via Messenger, WhatsApp, or text.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          if (_directInviteMode) ...[
            const SizedBox(height: 12),
            TextField(
              controller: _friendCodeController,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                labelText: 'Traveler Friend Code',
                hintText: 'e.g. TRP-4K9M2P',
                prefixIcon: Icon(Icons.qr_code_rounded),
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ChoiceChip(
                label: const Text('Viewer (Read-only)'),
                selected: _inviteRole == 'viewer',
                onSelected: (_) => setState(() => _inviteRole = 'viewer'),
              ),
              ChoiceChip(
                label: const Text('Editor (Can edit plan)'),
                selected: _inviteRole == 'editor',
                onSelected: (_) => setState(() => _inviteRole = 'editor'),
              ),
            ],
          ),
          if (!_directInviteMode) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                const Text('Max uses: ', style: TextStyle(fontSize: 13)),
                const SizedBox(width: 6),
                ChoiceChip(
                  label: const Text('1 person'),
                  selected: _inviteMaxUses == 1,
                  onSelected: (_) => setState(() => _inviteMaxUses = 1),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Up to 5'),
                  selected: _inviteMaxUses == 5,
                  onSelected: (_) => setState(() => _inviteMaxUses = 5),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _isCreatingInvite
                ? null
                : (_directInviteMode ? _sendDirectInvite : _createInvite),
            icon: _isCreatingInvite
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Icon(
                    _directInviteMode ? Icons.send_rounded : Icons.link_rounded,
                  ),
            label: Text(
              _isCreatingInvite
                  ? (_directInviteMode ? 'Sending...' : 'Generating...')
                  : (_directInviteMode
                        ? 'Send Direct Invite'
                        : 'Generate Invite Link'),
            ),
          ),
          if (!_directInviteMode &&
              _latestCreatedInvite != null &&
              _latestCreatedInvite!.inviteToken != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: colorScheme.primary.withValues(alpha: 0.4),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ready to share (${_latestCreatedInvite!.proposedRoleLabel}):',
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  SelectableText(
                    _latestCreatedInvite!.shareUrl ??
                        _latestCreatedInvite!.inviteToken!,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      FilledButton.tonalIcon(
                        onPressed: () => _copyToClipboard(
                          _latestCreatedInvite!.shareUrl ??
                              _latestCreatedInvite!.inviteToken!,
                          'Invite link',
                        ),
                        icon: const Icon(Icons.copy_rounded, size: 16),
                        label: const Text('Copy Invite'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMemberCard(
    BuildContext context, {
    required CircleMember member,
    required bool isOrganizerView,
    required bool isSelf,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: member.isOwner
                ? colorScheme.primary
                : colorScheme.secondaryContainer,
            child: Text(
              member.displayName.isNotEmpty
                  ? member.displayName[0].toUpperCase()
                  : 'T',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: member.isOwner
                    ? Colors.white
                    : colorScheme.onSecondaryContainer,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isSelf ? '${member.displayName} (You)' : member.displayName,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: member.isOwner
                        ? colorScheme.primaryContainer
                        : colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    member.roleLabel.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: member.isOwner
                          ? colorScheme.onPrimaryContainer
                          : colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (isOrganizerView && !member.isOwner && !isSelf)
            PopupMenuButton<String>(
              onSelected: (value) async {
                if (value == 'editor' || value == 'viewer') {
                  await ref
                      .read(circleMembersProvider(widget.tripId).notifier)
                      .updateRole(member.id, value);
                } else if (value == 'transfer') {
                  await _confirmTransferOwnership(member);
                } else if (value == 'remove') {
                  await _confirmRemoveOrLeave(member, isSelf: false);
                }
              },
              itemBuilder: (_) => [
                if (member.isViewer)
                  const PopupMenuItem(
                    value: 'editor',
                    child: Text('Promote to Editor'),
                  ),
                if (member.isEditor)
                  const PopupMenuItem(
                    value: 'viewer',
                    child: Text('Change to Viewer'),
                  ),
                const PopupMenuItem(
                  value: 'transfer',
                  child: Text('Transfer Ownership'),
                ),
                PopupMenuItem(
                  value: 'remove',
                  child: Text(
                    'Remove Member',
                    style: TextStyle(color: colorScheme.error),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildInvitationRow(BuildContext context, TripInvitation inv) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  inv.isDirect
                      ? '${inv.proposedRoleLabel} Direct • ${inv.targetDisplayName ?? 'Companion'}'
                      : '${inv.proposedRoleLabel} Invite • ${inv.useCount}/${inv.maxUses} used',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Status: ${inv.status.toUpperCase()}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: inv.isActive
                        ? colorScheme.primary
                        : colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (inv.isActive)
            TextButton(
              style: TextButton.styleFrom(foregroundColor: colorScheme.error),
              onPressed: () => ref
                  .read(tripInvitationsProvider(widget.tripId).notifier)
                  .revokeInvitation(inv.id),
              child: const Text('Revoke'),
            ),
        ],
      ),
    );
  }
}
