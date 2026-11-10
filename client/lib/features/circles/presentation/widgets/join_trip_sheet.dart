import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/countries.dart';
import '../../../../core/network/api_exceptions.dart';
import '../../../trips/presentation/providers/trip_list_provider.dart';
import '../../data/trip_circle_repository.dart';
import '../../domain/models/trip_invitation.dart';

class JoinTripSheet extends ConsumerStatefulWidget {
  const JoinTripSheet({super.key, this.onJoined});

  final void Function(String tripId)? onJoined;

  static Future<void> show(
    BuildContext context, {
    void Function(String tripId)? onJoined,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => JoinTripSheet(onJoined: onJoined),
    );
  }

  @override
  ConsumerState<JoinTripSheet> createState() => _JoinTripSheetState();
}

class _JoinTripSheetState extends ConsumerState<JoinTripSheet> {
  final _tokenController = TextEditingController();
  InvitationPreview? _preview;
  String? _errorMessage;
  bool _isChecking = false;
  bool _isJoining = false;

  @override
  void dispose() {
    _tokenController.dispose();
    super.dispose();
  }

  Future<void> _lookupInvite() async {
    final input = _tokenController.text.trim();
    if (input.isEmpty) {
      setState(() {
        _errorMessage = 'Enter an invite link or code first.';
        _preview = null;
      });
      return;
    }

    setState(() {
      _isChecking = true;
      _errorMessage = null;
      _preview = null;
    });

    try {
      final repo = ref.read(tripCircleRepositoryProvider);
      final preview = await repo.previewInvitation(input);
      if (mounted) {
        setState(() {
          _preview = preview;
          _isChecking = false;
        });
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.message;
          _isChecking = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Could not verify invite code. Check your internet connection and code.';
          _isChecking = false;
        });
      }
    }
  }

  Future<void> _acceptInvite() async {
    final input = _tokenController.text.trim();
    if (input.isEmpty) return;

    setState(() {
      _isJoining = true;
      _errorMessage = null;
    });

    try {
      final repo = ref.read(tripCircleRepositoryProvider);
      final result = await repo.acceptInvitation(input);

      await ref.read(tripListProvider.notifier).refresh();

      if (!mounted) return;
      final navigator = Navigator.of(context);
      final messenger = ScaffoldMessenger.of(context);
      final router = widget.onJoined == null ? GoRouter.maybeOf(context) : null;

      navigator.pop();
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            result.alreadyMember
                ? 'You are already part of "${result.trip.title}".'
                : 'Joined "${result.trip.title}" as ${result.member.roleLabel}!',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );

      if (widget.onJoined != null) {
        widget.onJoined!(result.trip.id);
      } else {
        router?.push('/trips/${result.trip.id}/itinerary', extra: result.trip);
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.message;
          _isJoining = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Unable to join trip. Please check your connection.';
          _isJoining = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 24 + bottomInset),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.group_add_rounded, color: colorScheme.primary),
                const SizedBox(width: 10),
                Text(
                  'Join a Trip Circle',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Paste a private invite link or code shared by the trip organizer.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _tokenController,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => _lookupInvite(),
                    decoration: const InputDecoration(
                      labelText: 'Invite Link or Code',
                      hintText: 'Paste invite code here...',
                      prefixIcon: Icon(Icons.link_rounded),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton.tonal(
                  onPressed: _isChecking ? null : _lookupInvite,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 16,
                    ),
                  ),
                  child: _isChecking
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Check'),
                ),
              ],
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.errorContainer.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline_rounded,
                      size: 18,
                      color: colorScheme.error,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(
                          color: colorScheme.onErrorContainer,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (_preview != null) ...[
              const SizedBox(height: 16),
              _buildPreviewCard(context, _preview!),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: (!_preview!.isRedeemable || _isJoining)
                    ? null
                    : _acceptInvite,
                icon: _isJoining
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.check_circle_outline_rounded),
                label: Text(
                  _preview!.isRedeemable
                      ? 'Accept & Join Trip'
                      : 'Invite ${_preview!.status.toUpperCase()}',
                ),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewCard(BuildContext context, InvitationPreview preview) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final flag =
        CountryCurrencyHelper.resolveFlag(preview.destinationCountry) ??
        CountryCurrencyHelper.resolveFlag(preview.tripTitle);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: preview.isRedeemable
              ? colorScheme.primary.withValues(alpha: 0.35)
              : colorScheme.error.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (flag != null) ...[
                Text(flag, style: const TextStyle(fontSize: 22)),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  preview.tripTitle,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: preview.isRedeemable
                      ? Colors.teal.withValues(alpha: 0.15)
                      : colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  preview.status.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: preview.isRedeemable
                        ? Colors.teal.shade800
                        : colorScheme.onErrorContainer,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Invited by ${preview.inviterName}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Access level: ${preview.proposedRoleLabel}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Preview only reveals basic trip details. Accepting grants access online.',
            style: theme.textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
