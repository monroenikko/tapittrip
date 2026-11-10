import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exceptions.dart';
import '../../data/trip_circle_repository.dart';
import '../../domain/models/activity_event.dart';
import '../../domain/models/circle_member.dart';
import '../../domain/models/trip_invitation.dart';

class CircleMembersNotifier extends AsyncNotifier<List<CircleMember>> {
  CircleMembersNotifier(this.tripId);
  final String tripId;

  @override
  Future<List<CircleMember>> build() async {
    final repo = ref.watch(tripCircleRepositoryProvider);
    return repo.getMembers(tripId);
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() {
      final repo = ref.read(tripCircleRepositoryProvider);
      return repo.getMembers(tripId);
    });
  }

  Future<void> updateRole(String memberId, String newRole) async {
    final repo = ref.read(tripCircleRepositoryProvider);
    final updated = await repo.updateMemberRole(tripId, memberId, newRole);
    final current = state.asData?.value ?? [];
    state = AsyncData(
      current.map((m) => m.id == memberId ? updated : m).toList(),
    );
  }

  Future<void> removeMember(String memberId) async {
    final repo = ref.read(tripCircleRepositoryProvider);
    await repo.removeOrLeaveMember(tripId, memberId);
    final current = state.asData?.value ?? [];
    state = AsyncData(current.where((m) => m.id != memberId).toList());
  }
}

final circleMembersProvider =
    AsyncNotifierProvider.family<
      CircleMembersNotifier,
      List<CircleMember>,
      String
    >((tripId) => CircleMembersNotifier(tripId));

class TripInvitationsNotifier extends AsyncNotifier<List<TripInvitation>> {
  TripInvitationsNotifier(this.tripId);
  final String tripId;

  @override
  Future<List<TripInvitation>> build() async {
    final repo = ref.watch(tripCircleRepositoryProvider);
    try {
      return await repo.getInvitations(tripId);
    } on ApiException catch (e) {
      // Companions (non-organizers) receive 403 for invite list; return empty cleanly
      if (e.statusCode == 403 || e.code == 'forbidden') {
        return const [];
      }
      rethrow;
    }
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(tripCircleRepositoryProvider);
      try {
        return await repo.getInvitations(tripId);
      } on ApiException catch (e) {
        if (e.statusCode == 403 || e.code == 'forbidden') {
          return const <TripInvitation>[];
        }
        rethrow;
      }
    });
  }

  Future<TripInvitation> createInvitation({
    String proposedRole = 'viewer',
    int maxUses = 1,
    int expiresInDays = 7,
  }) async {
    final repo = ref.read(tripCircleRepositoryProvider);
    final created = await repo.createInvitation(
      tripId,
      proposedRole: proposedRole,
      maxUses: maxUses,
      expiresInDays: expiresInDays,
    );
    final current = state.asData?.value ?? [];
    state = AsyncData([created, ...current]);
    return created;
  }

  Future<void> revokeInvitation(String invitationId) async {
    final repo = ref.read(tripCircleRepositoryProvider);
    final revoked = await repo.revokeInvitation(tripId, invitationId);
    final current = state.asData?.value ?? [];
    state = AsyncData(
      current.map((inv) => inv.id == invitationId ? revoked : inv).toList(),
    );
  }
}

final tripInvitationsProvider =
    AsyncNotifierProvider.family<
      TripInvitationsNotifier,
      List<TripInvitation>,
      String
    >((tripId) => TripInvitationsNotifier(tripId));

final tripActivityFeedProvider =
    FutureProvider.family<List<ActivityEvent>, String>((ref, tripId) async {
      final repo = ref.watch(tripCircleRepositoryProvider);
      return repo.getActivityFeed(tripId);
    });
