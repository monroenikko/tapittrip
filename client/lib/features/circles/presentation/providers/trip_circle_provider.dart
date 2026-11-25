import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exceptions.dart';
import '../../data/trip_circle_repository.dart';
import '../../domain/models/activity_event.dart';
import '../../domain/models/circle_member.dart';
import '../../domain/models/trip_announcement.dart';
import '../../domain/models/trip_invitation.dart';
import '../../domain/models/trip_location_share.dart';
import '../../domain/models/trip_traveler.dart';

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

  Future<({TripInvitation invitation, bool alreadyPending})>
  sendDirectInvitation({
    required String friendCode,
    String proposedRole = 'viewer',
    int expiresInDays = 7,
  }) async {
    final repo = ref.read(tripCircleRepositoryProvider);
    final result = await repo.sendDirectInvitation(
      tripId,
      friendCode: friendCode,
      proposedRole: proposedRole,
      expiresInDays: expiresInDays,
    );
    final current = state.asData?.value ?? [];
    final withoutDup = current
        .where((inv) => inv.id != result.invitation.id)
        .toList();
    state = AsyncData([result.invitation, ...withoutDup]);
    return result;
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

class TripAnnouncementsState {
  const TripAnnouncementsState({required this.items, this.isOffline = false});

  final List<TripAnnouncement> items;
  final bool isOffline;
}

class TripAnnouncementsNotifier extends AsyncNotifier<TripAnnouncementsState> {
  TripAnnouncementsNotifier(this.tripId);
  final String tripId;

  @override
  Future<TripAnnouncementsState> build() async {
    final repo = ref.watch(tripCircleRepositoryProvider);
    final res = await repo.getAnnouncements(tripId);
    return TripAnnouncementsState(items: res.items, isOffline: res.fromCache);
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(tripCircleRepositoryProvider);
      final res = await repo.getAnnouncements(tripId);
      return TripAnnouncementsState(items: res.items, isOffline: res.fromCache);
    });
  }

  Future<TripAnnouncement> createAnnouncement({
    required String title,
    required String body,
    bool isPinned = false,
    String? clientOperationId,
  }) async {
    final repo = ref.read(tripCircleRepositoryProvider);
    final created = await repo.createAnnouncement(
      tripId,
      title: title,
      body: body,
      isPinned: isPinned,
      clientOperationId: clientOperationId,
    );
    await refresh();
    ref.invalidate(tripActivityFeedProvider(tripId));
    return created;
  }

  Future<TripAnnouncement> updateAnnouncement(
    String announcementId, {
    String? title,
    String? body,
    bool? isPinned,
    int? baseVersion,
  }) async {
    final repo = ref.read(tripCircleRepositoryProvider);
    final updated = await repo.updateAnnouncement(
      announcementId,
      title: title,
      body: body,
      isPinned: isPinned,
      baseVersion: baseVersion,
    );
    await refresh();
    ref.invalidate(tripActivityFeedProvider(tripId));
    return updated;
  }

  Future<void> deleteAnnouncement(String announcementId) async {
    final repo = ref.read(tripCircleRepositoryProvider);
    await repo.deleteAnnouncement(announcementId);
    final current = state.asData?.value;
    if (current != null) {
      state = AsyncData(
        TripAnnouncementsState(
          items: current.items.where((a) => a.id != announcementId).toList(),
          isOffline: current.isOffline,
        ),
      );
    }
  }
}

final tripAnnouncementsProvider =
    AsyncNotifierProvider.family<
      TripAnnouncementsNotifier,
      TripAnnouncementsState,
      String
    >((tripId) => TripAnnouncementsNotifier(tripId));

class PendingOwnershipTransferNotifier
    extends AsyncNotifier<TripOwnershipTransfer?> {
  PendingOwnershipTransferNotifier(this.tripId);
  final String tripId;

  @override
  Future<TripOwnershipTransfer?> build() async {
    final repo = ref.watch(tripCircleRepositoryProvider);
    try {
      return await repo.getPendingOwnershipTransfer(tripId);
    } on ApiException catch (e) {
      if (e.statusCode == 403 || e.code == 'forbidden') {
        return null;
      }
      rethrow;
    }
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(tripCircleRepositoryProvider);
      try {
        return await repo.getPendingOwnershipTransfer(tripId);
      } on ApiException catch (e) {
        if (e.statusCode == 403 || e.code == 'forbidden') {
          return null;
        }
        rethrow;
      }
    });
  }

  Future<({TripOwnershipTransfer transfer, bool alreadyPending})>
  initiateTransfer({
    required String targetMemberId,
    String formerOwnerRole = 'editor',
  }) async {
    final repo = ref.read(tripCircleRepositoryProvider);
    final result = await repo.initiateOwnershipTransfer(
      tripId,
      targetMemberId: targetMemberId,
      formerOwnerRole: formerOwnerRole,
    );
    state = AsyncData(result.transfer);
    return result;
  }

  Future<void> cancelTransfer(String transferId) async {
    final repo = ref.read(tripCircleRepositoryProvider);
    await repo.cancelOwnershipTransfer(tripId, transferId);
    state = const AsyncData(null);
  }
}

final pendingOwnershipTransferProvider =
    AsyncNotifierProvider.family<
      PendingOwnershipTransferNotifier,
      TripOwnershipTransfer?,
      String
    >((tripId) => PendingOwnershipTransferNotifier(tripId));

class CircleInboxData {
  const CircleInboxData({
    required this.invitations,
    required this.transfers,
    this.isOffline = false,
  });

  final List<IncomingInvitation> invitations;
  final List<TripOwnershipTransfer> transfers;
  final bool isOffline;

  int get totalPendingCount =>
      invitations.where((i) => i.isPending).length +
      transfers.where((t) => t.isPending).length;

  bool get isEmpty => invitations.isEmpty && transfers.isEmpty;
}

class CircleInboxNotifier extends AsyncNotifier<CircleInboxData> {
  @override
  Future<CircleInboxData> build() async {
    return _fetch();
  }

  Future<CircleInboxData> _fetch() async {
    final repo = ref.read(tripCircleRepositoryProvider);
    final invResult = await repo.getIncomingInvitations();
    final transferResult = await repo.getIncomingOwnershipTransfers();
    return CircleInboxData(
      invitations: invResult.items,
      transfers: transferResult.items,
      isOffline: invResult.fromCache || transferResult.fromCache,
    );
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_fetch);
  }

  Future<String> acceptInvitation(String invitationId) async {
    final repo = ref.read(tripCircleRepositoryProvider);
    final res = await repo.acceptDirectInvitation(invitationId);
    final current = state.asData?.value;
    if (current != null) {
      state = AsyncData(
        CircleInboxData(
          invitations: current.invitations
              .where((i) => i.id != invitationId)
              .toList(),
          transfers: current.transfers,
          isOffline: false,
        ),
      );
    }
    return res.trip.id;
  }

  Future<void> declineInvitation(
    String invitationId, {
    bool blockSender = false,
  }) async {
    final repo = ref.read(tripCircleRepositoryProvider);
    await repo.declineDirectInvitation(invitationId, blockSender: blockSender);
    final current = state.asData?.value;
    if (current != null) {
      state = AsyncData(
        CircleInboxData(
          invitations: current.invitations
              .where((i) => i.id != invitationId)
              .toList(),
          transfers: current.transfers,
          isOffline: false,
        ),
      );
    }
  }

  Future<String> acceptOwnershipTransfer(String transferId) async {
    final repo = ref.read(tripCircleRepositoryProvider);
    final res = await repo.acceptOwnershipTransfer(transferId);
    final current = state.asData?.value;
    if (current != null) {
      state = AsyncData(
        CircleInboxData(
          invitations: current.invitations,
          transfers: current.transfers
              .where((t) => t.id != transferId)
              .toList(),
          isOffline: false,
        ),
      );
    }
    return res.trip.id;
  }

  Future<void> declineOwnershipTransfer(String transferId) async {
    final repo = ref.read(tripCircleRepositoryProvider);
    await repo.declineOwnershipTransfer(transferId);
    final current = state.asData?.value;
    if (current != null) {
      state = AsyncData(
        CircleInboxData(
          invitations: current.invitations,
          transfers: current.transfers
              .where((t) => t.id != transferId)
              .toList(),
          isOffline: false,
        ),
      );
    }
  }
}

final circleInboxProvider =
    AsyncNotifierProvider<CircleInboxNotifier, CircleInboxData>(
      CircleInboxNotifier.new,
    );

final pendingInboxCountProvider = Provider<int>((ref) {
  final inbox = ref.watch(circleInboxProvider).asData?.value;
  return inbox?.totalPendingCount ?? 0;
});

class TripTravelersNotifier extends AsyncNotifier<List<TripTraveler>> {
  TripTravelersNotifier(this.tripId);
  final String tripId;

  @override
  Future<List<TripTraveler>> build() async {
    final repo = ref.watch(tripCircleRepositoryProvider);
    return repo.getTravelers(tripId);
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() {
      final repo = ref.read(tripCircleRepositoryProvider);
      return repo.getTravelers(tripId);
    });
  }

  Future<TripTraveler> createTraveler({
    required String displayName,
    String travelerCategory = 'child',
    String? restrictedNotes,
  }) async {
    final repo = ref.read(tripCircleRepositoryProvider);
    final created = await repo.createTraveler(
      tripId,
      displayName: displayName,
      travelerCategory: travelerCategory,
      restrictedNotes: restrictedNotes,
    );
    final current = state.asData?.value ?? [];
    state = AsyncData([...current, created]);
    return created;
  }

  Future<TripTraveler> updateTraveler(
    String travelerId, {
    String? displayName,
    String? travelerCategory,
    String? restrictedNotes,
    int? baseVersion,
  }) async {
    final repo = ref.read(tripCircleRepositoryProvider);
    final updated = await repo.updateTraveler(
      travelerId,
      displayName: displayName,
      travelerCategory: travelerCategory,
      restrictedNotes: restrictedNotes,
      baseVersion: baseVersion,
    );
    final current = state.asData?.value ?? [];
    state = AsyncData(
      current.map((t) => t.id == travelerId ? updated : t).toList(),
    );
    return updated;
  }

  Future<void> deleteTraveler(String travelerId) async {
    final repo = ref.read(tripCircleRepositoryProvider);
    await repo.deleteTraveler(travelerId);
    final current = state.asData?.value ?? [];
    state = AsyncData(current.where((t) => t.id != travelerId).toList());
  }
}

final tripTravelersProvider =
    AsyncNotifierProvider.family<
      TripTravelersNotifier,
      List<TripTraveler>,
      String
    >((tripId) => TripTravelersNotifier(tripId));

class TripLocationShareNotifier extends AsyncNotifier<TripLocationShare> {
  TripLocationShareNotifier(this.tripId);
  final String tripId;

  @override
  Future<TripLocationShare> build() async {
    final repo = ref.watch(tripCircleRepositoryProvider);
    return repo.getLocationShare(tripId);
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() {
      final repo = ref.read(tripCircleRepositoryProvider);
      return repo.getLocationShare(tripId);
    });
  }

  Future<TripLocationShare> enable({
    int durationMinutes = 60,
    String audience = 'circle',
    required double latitude,
    required double longitude,
  }) async {
    final repo = ref.read(tripCircleRepositoryProvider);
    final updated = await repo.enableLocationShare(
      tripId,
      durationMinutes: durationMinutes,
      audience: audience,
      latitude: latitude,
      longitude: longitude,
    );
    state = AsyncData(updated);
    ref.invalidate(activeLocationSharesProvider(tripId));
    return updated;
  }

  Future<TripLocationShare> disable() async {
    final repo = ref.read(tripCircleRepositoryProvider);
    final updated = await repo.disableLocationShare(tripId);
    state = AsyncData(updated);
    ref.invalidate(activeLocationSharesProvider(tripId));
    return updated;
  }

  Future<TripLocationShare> updateCoordinates({
    required double latitude,
    required double longitude,
  }) async {
    final repo = ref.read(tripCircleRepositoryProvider);
    final updated = await repo.updateLocationCoordinates(
      tripId,
      latitude: latitude,
      longitude: longitude,
    );
    state = AsyncData(updated);
    ref.invalidate(activeLocationSharesProvider(tripId));
    return updated;
  }
}

final tripLocationShareProvider =
    AsyncNotifierProvider.family<
      TripLocationShareNotifier,
      TripLocationShare,
      String
    >((tripId) => TripLocationShareNotifier(tripId));

final activeLocationSharesProvider =
    FutureProvider.family<List<TripLocationShare>, String>((ref, tripId) async {
      final repo = ref.watch(tripCircleRepositoryProvider);
      return repo.getActiveLocationShares(tripId);
    });
