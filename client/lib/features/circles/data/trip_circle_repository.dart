import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exceptions.dart';
import '../../trips/domain/models/trip.dart';
import '../domain/models/activity_event.dart';
import '../domain/models/circle_member.dart';
import '../domain/models/trip_invitation.dart';

class TripCircleRepository {
  TripCircleRepository({required this.apiClient, FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  final ApiClient apiClient;
  final FlutterSecureStorage _storage;

  String _membersCacheKey(String tripId) => 'cached_circle_members_$tripId';
  String _feedCacheKey(String tripId) => 'cached_activity_feed_$tripId';
  static const _incomingInvitesCacheKey = 'cached_incoming_invitations';
  static const _incomingTransfersCacheKey = 'cached_incoming_transfers';

  static String normalizeRawToken(String input) {
    var trimmed = input.trim();
    if (trimmed.contains('/')) {
      final uri = Uri.tryParse(trimmed);
      final segments = (uri?.pathSegments ?? trimmed.split('/'))
          .where((s) => s.trim().isNotEmpty)
          .toList();
      if (segments.isNotEmpty) {
        trimmed = segments.last.trim();
      }
    }
    return trimmed;
  }

  List<dynamic> _extractList(dynamic response) {
    if (response is List) {
      return response;
    }
    if (response is Map && response['data'] is List) {
      return response['data'] as List<dynamic>;
    }
    return const [];
  }

  Map<String, dynamic> _extractMap(dynamic response) {
    if (response is Map &&
        response.containsKey('data') &&
        response['data'] is Map) {
      return Map<String, dynamic>.from(response['data'] as Map);
    }
    if (response is Map) {
      return Map<String, dynamic>.from(response);
    }
    return const {};
  }

  bool _isRevokedOrForbidden(Object error) {
    if (error is ApiException) {
      return error.statusCode == 403 ||
          error.statusCode == 401 ||
          error.code == 'forbidden' ||
          error.code == 'unauthorized';
    }
    return false;
  }

  /// Clear cached circle, feed, journal, and recap artifacts when access is revoked (TC-1.7).
  Future<void> purgeTripCircleCaches(String tripId) async {
    await _storage.delete(key: _membersCacheKey(tripId));
    await _storage.delete(key: _feedCacheKey(tripId));
    await _storage.delete(key: 'cached_journal_$tripId');
    await _storage.delete(key: 'cached_recap_$tripId');
    await _storage.delete(key: 'cached_itinerary_$tripId');
    await _storage.delete(key: 'cached_days_$tripId');
  }

  /// Clear user-scoped incoming inbox caches on logout or account deletion (TC-1.8, TC-2.4).
  Future<void> purgeInboxCaches() async {
    try {
      await _storage.delete(key: _incomingInvitesCacheKey);
      await _storage.delete(key: _incomingTransfersCacheKey);
    } catch (_) {
      // Ignore uninitialized platform binding during pure Dart tests.
    }
  }

  Future<List<CircleMember>> getMembers(String tripId) async {
    try {
      final response = await apiClient.get('/trips/$tripId/members');
      final list = _extractList(response);

      await _storage.write(
        key: _membersCacheKey(tripId),
        value: jsonEncode(list),
      );

      return list
          .whereType<Map>()
          .map((e) => CircleMember.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (e) {
      if (_isRevokedOrForbidden(e)) {
        await purgeTripCircleCaches(tripId);
        rethrow;
      }
      final cached = await _storage.read(key: _membersCacheKey(tripId));
      if (cached != null) {
        final raw = jsonDecode(cached) as List<dynamic>;
        return raw
            .whereType<Map>()
            .map((e) => CircleMember.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }
      rethrow;
    }
  }

  Future<CircleMember> updateMemberRole(
    String tripId,
    String memberId,
    String role,
  ) async {
    final response = await apiClient.patch(
      '/trips/$tripId/members/$memberId',
      data: {'role': role},
    );
    return CircleMember.fromJson(_extractMap(response));
  }

  Future<void> removeOrLeaveMember(String tripId, String memberId) async {
    await apiClient.delete('/trips/$tripId/members/$memberId');
  }

  Future<List<TripInvitation>> getInvitations(String tripId) async {
    final response = await apiClient.get('/trips/$tripId/invitations');
    final list = _extractList(response);

    return list
        .whereType<Map>()
        .map((e) => TripInvitation.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<TripInvitation> createInvitation(
    String tripId, {
    String proposedRole = 'viewer',
    int maxUses = 1,
    int expiresInDays = 7,
  }) async {
    final response = await apiClient.post(
      '/trips/$tripId/invitations',
      data: {
        'proposed_role': proposedRole,
        'max_uses': maxUses,
        'expires_in_days': expiresInDays,
      },
    );
    return TripInvitation.fromJson(_extractMap(response));
  }

  Future<TripInvitation> revokeInvitation(
    String tripId,
    String invitationId,
  ) async {
    final response = await apiClient.delete(
      '/trips/$tripId/invitations/$invitationId',
    );
    return TripInvitation.fromJson(_extractMap(response));
  }

  Future<({TripInvitation invitation, bool alreadyPending})>
  sendDirectInvitation(
    String tripId, {
    required String friendCode,
    String proposedRole = 'viewer',
    int expiresInDays = 7,
  }) async {
    final response = await apiClient.post(
      '/trips/$tripId/invitations/direct',
      data: {
        'friend_code': friendCode.trim(),
        'proposed_role': proposedRole,
        'expires_in_days': expiresInDays,
      },
    );
    final map = _extractMap(response);
    return (
      invitation: TripInvitation.fromJson(map),
      alreadyPending: map['already_pending'] == true,
    );
  }

  Future<({List<IncomingInvitation> items, bool fromCache})>
  getIncomingInvitations() async {
    try {
      final response = await apiClient.get('/me/invitations');
      final list = _extractList(response);

      await _storage.write(
        key: _incomingInvitesCacheKey,
        value: jsonEncode(list),
      );

      return (
        items: list
            .whereType<Map>()
            .map(
              (e) => IncomingInvitation.fromJson(Map<String, dynamic>.from(e)),
            )
            .toList(),
        fromCache: false,
      );
    } catch (e) {
      if (_isRevokedOrForbidden(e)) rethrow;
      final cached = await _storage.read(key: _incomingInvitesCacheKey);
      if (cached != null) {
        final raw = jsonDecode(cached) as List<dynamic>;
        return (
          items: raw
              .whereType<Map>()
              .map(
                (e) =>
                    IncomingInvitation.fromJson(Map<String, dynamic>.from(e)),
              )
              .toList(),
          fromCache: true,
        );
      }
      rethrow;
    }
  }

  Future<({Trip trip, CircleMember member, bool alreadyMember})>
  acceptDirectInvitation(String invitationId) async {
    final response = await apiClient.post(
      '/me/invitations/$invitationId/accept',
    );
    final map = _extractMap(response);

    return (
      trip: Trip.fromJson(Map<String, dynamic>.from(map['trip'] as Map)),
      member: CircleMember.fromJson(
        Map<String, dynamic>.from(map['member'] as Map),
      ),
      alreadyMember: map['already_member'] == true,
    );
  }

  Future<IncomingInvitation> declineDirectInvitation(
    String invitationId, {
    bool blockSender = false,
  }) async {
    final response = await apiClient.post(
      '/me/invitations/$invitationId/decline',
      data: {'block_sender': blockSender},
    );
    return IncomingInvitation.fromJson(_extractMap(response));
  }

  Future<TripOwnershipTransfer?> getPendingOwnershipTransfer(
    String tripId,
  ) async {
    final response = await apiClient.get('/trips/$tripId/ownership-transfer');
    if (response is Map && response.containsKey('data')) {
      final data = response['data'];
      if (data == null) return null;
      if (data is Map) {
        return TripOwnershipTransfer.fromJson(Map<String, dynamic>.from(data));
      }
    }
    if (response == null) return null;
    if (response is Map) {
      if (response.isEmpty || response['id'] == null) return null;
      return TripOwnershipTransfer.fromJson(
        Map<String, dynamic>.from(response),
      );
    }
    return null;
  }

  Future<({TripOwnershipTransfer transfer, bool alreadyPending})>
  initiateOwnershipTransfer(
    String tripId, {
    required String targetMemberId,
    String formerOwnerRole = 'editor',
  }) async {
    final response = await apiClient.post(
      '/trips/$tripId/ownership-transfer',
      data: {
        'target_member_id': targetMemberId,
        'former_owner_role': formerOwnerRole,
      },
    );
    final map = _extractMap(response);
    return (
      transfer: TripOwnershipTransfer.fromJson(map),
      alreadyPending: map['already_pending'] == true,
    );
  }

  Future<TripOwnershipTransfer> cancelOwnershipTransfer(
    String tripId,
    String transferId,
  ) async {
    final response = await apiClient.delete(
      '/trips/$tripId/ownership-transfer/$transferId',
    );
    return TripOwnershipTransfer.fromJson(_extractMap(response));
  }

  Future<({List<TripOwnershipTransfer> items, bool fromCache})>
  getIncomingOwnershipTransfers() async {
    try {
      final response = await apiClient.get('/me/ownership-transfers');
      final list = _extractList(response);

      await _storage.write(
        key: _incomingTransfersCacheKey,
        value: jsonEncode(list),
      );

      return (
        items: list
            .whereType<Map>()
            .map(
              (e) =>
                  TripOwnershipTransfer.fromJson(Map<String, dynamic>.from(e)),
            )
            .toList(),
        fromCache: false,
      );
    } catch (e) {
      if (_isRevokedOrForbidden(e)) rethrow;
      final cached = await _storage.read(key: _incomingTransfersCacheKey);
      if (cached != null) {
        final raw = jsonDecode(cached) as List<dynamic>;
        return (
          items: raw
              .whereType<Map>()
              .map(
                (e) => TripOwnershipTransfer.fromJson(
                  Map<String, dynamic>.from(e),
                ),
              )
              .toList(),
          fromCache: true,
        );
      }
      rethrow;
    }
  }

  Future<({Trip trip, TripOwnershipTransfer transfer})> acceptOwnershipTransfer(
    String transferId,
  ) async {
    final response = await apiClient.post(
      '/me/ownership-transfers/$transferId/accept',
    );
    final map = _extractMap(response);
    return (
      trip: Trip.fromJson(Map<String, dynamic>.from(map['trip'] as Map)),
      transfer: TripOwnershipTransfer.fromJson(
        Map<String, dynamic>.from(map['transfer'] as Map),
      ),
    );
  }

  Future<TripOwnershipTransfer> declineOwnershipTransfer(
    String transferId,
  ) async {
    final response = await apiClient.post(
      '/me/ownership-transfers/$transferId/decline',
    );
    return TripOwnershipTransfer.fromJson(_extractMap(response));
  }

  Future<InvitationPreview> previewInvitation(String tokenOrUrl) async {
    final token = normalizeRawToken(tokenOrUrl);
    if (token.isEmpty) {
      throw const ApiException(
        code: 'validation_failed',
        message: 'Please enter a valid invitation link or code.',
        statusCode: 422,
      );
    }

    final response = await apiClient.get('/invitations/$token');
    return InvitationPreview.fromJson(_extractMap(response));
  }

  Future<({Trip trip, CircleMember member, bool alreadyMember})>
  acceptInvitation(String tokenOrUrl) async {
    final token = normalizeRawToken(tokenOrUrl);
    if (token.isEmpty) {
      throw const ApiException(
        code: 'validation_failed',
        message: 'Please enter a valid invitation link or code.',
        statusCode: 422,
      );
    }

    final response = await apiClient.post('/invitations/$token/accept');
    final map = _extractMap(response);

    return (
      trip: Trip.fromJson(Map<String, dynamic>.from(map['trip'] as Map)),
      member: CircleMember.fromJson(
        Map<String, dynamic>.from(map['member'] as Map),
      ),
      alreadyMember: map['already_member'] == true,
    );
  }

  Future<List<ActivityEvent>> getActivityFeed(
    String tripId, {
    int limit = 30,
    String? beforeId,
  }) async {
    try {
      final response = await apiClient.get(
        '/trips/$tripId/feed',
        queryParameters: {
          'limit': limit,
          if (beforeId != null && beforeId.isNotEmpty) 'before': beforeId,
        },
      );
      final list = _extractList(response);

      if (beforeId == null) {
        await _storage.write(
          key: _feedCacheKey(tripId),
          value: jsonEncode(list),
        );
      }

      return list
          .whereType<Map>()
          .map((e) => ActivityEvent.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (e) {
      if (_isRevokedOrForbidden(e)) {
        await purgeTripCircleCaches(tripId);
        rethrow;
      }
      if (beforeId == null) {
        final cached = await _storage.read(key: _feedCacheKey(tripId));
        if (cached != null) {
          final raw = jsonDecode(cached) as List<dynamic>;
          return raw
              .whereType<Map>()
              .map((e) => ActivityEvent.fromJson(Map<String, dynamic>.from(e)))
              .toList();
        }
      }
      rethrow;
    }
  }
}

final tripCircleRepositoryProvider = Provider<TripCircleRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return TripCircleRepository(apiClient: apiClient);
});
