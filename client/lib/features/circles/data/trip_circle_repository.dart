import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exceptions.dart';
import '../../notifications/services/local_notification_service.dart';
import '../../trips/domain/models/trip.dart';
import '../domain/models/activity_event.dart';
import '../domain/models/circle_member.dart';
import '../domain/models/trip_announcement.dart';
import '../domain/models/trip_invitation.dart';
import '../domain/models/trip_traveler.dart';

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

  /// Clear all per-trip local caches and device reminders when access is revoked (TC-1.7, TC-4.4, TC-5.3).
  Future<void> purgeTripCircleCaches(String tripId) =>
      purgeAllTripCachesForStorage(storage: _storage, tripId: tripId);

  /// Purge all cached trip collections and local reminders for a revoked trip.
  static Future<void> purgeAllTripCachesForStorage({
    required FlutterSecureStorage storage,
    required String tripId,
  }) async {
    const prefixes = [
      'cached_circle_members_',
      'cached_activity_feed_',
      'cached_announcements_',
      'cached_travelers_',
      'cached_journal_',
      'cached_recap_',
      'cached_today_',
      'cached_budget_',
      'cached_expenses_',
      'cached_summary_',
      'cached_settlements_',
      'cached_checklists_',
      'cached_stays_',
      'cached_weather_',
      'cached_itinerary_',
      'cached_days_',
      'cached_reminders_',
    ];
    for (final prefix in prefixes) {
      try {
        await storage.delete(key: '$prefix$tripId');
      } catch (_) {}
    }
    try {
      await LocalNotificationService(storage: storage)
          .cancelRemindersForTrip(tripId);
    } catch (_) {}
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

  String _announcementsCacheKey(String tripId) =>
      'cached_announcements_$tripId';

  /// Fetch organizer announcements (works in-app without push permission, cached offline).
  Future<({List<TripAnnouncement> items, bool fromCache})> getAnnouncements(
    String tripId,
  ) async {
    try {
      final response = await apiClient.get('/trips/$tripId/announcements');
      final list = _extractList(response);

      await _storage.write(
        key: _announcementsCacheKey(tripId),
        value: jsonEncode(list),
      );

      final items = list
          .whereType<Map>()
          .map((e) => TripAnnouncement.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      return (items: items, fromCache: false);
    } catch (e) {
      if (_isRevokedOrForbidden(e)) {
        await purgeTripCircleCaches(tripId);
        rethrow;
      }
      final cached = await getCachedAnnouncements(tripId);
      if (cached.isNotEmpty) {
        return (items: cached, fromCache: true);
      }
      if (e is NetworkException) {
        return (items: const <TripAnnouncement>[], fromCache: true);
      }
      rethrow;
    }
  }

  Future<List<TripAnnouncement>> getCachedAnnouncements(String tripId) async {
    try {
      final raw = await _storage.read(key: _announcementsCacheKey(tripId));
      if (raw == null || raw.isEmpty) return [];
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .whereType<Map>()
          .map((e) => TripAnnouncement.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<TripAnnouncement> createAnnouncement(
    String tripId, {
    required String title,
    required String body,
    bool isPinned = false,
    String? clientOperationId,
  }) async {
    final response = await apiClient.post(
      '/trips/$tripId/announcements',
      data: {
        'title': title,
        'body': body,
        'is_pinned': isPinned,
        if (clientOperationId != null && clientOperationId.isNotEmpty)
          'client_operation_id': clientOperationId,
      },
    );
    return TripAnnouncement.fromJson(_extractMap(response));
  }

  Future<TripAnnouncement> updateAnnouncement(
    String announcementId, {
    String? title,
    String? body,
    bool? isPinned,
    int? baseVersion,
  }) async {
    final response = await apiClient.patch(
      '/announcements/$announcementId',
      data: {
        'title': ?title,
        'body': ?body,
        'is_pinned': ?isPinned,
        'base_version': ?baseVersion,
      },
    );
    return TripAnnouncement.fromJson(_extractMap(response));
  }

  Future<void> deleteAnnouncement(String announcementId) async {
    await apiClient.delete('/announcements/$announcementId');
  }

  String _travelersCacheKey(String tripId) => 'cached_travelers_$tripId';

  /// Fetch minimal managed traveler profiles for a trip circle (TC-6.3).
  Future<List<TripTraveler>> getTravelers(String tripId) async {
    try {
      final response = await apiClient.get('/trips/$tripId/travelers');
      final list = _extractList(response);

      await _storage.write(
        key: _travelersCacheKey(tripId),
        value: jsonEncode(list),
      );

      return list
          .whereType<Map>()
          .map((e) => TripTraveler.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (e) {
      if (_isRevokedOrForbidden(e)) {
        await purgeTripCircleCaches(tripId);
        rethrow;
      }
      final cached = await _storage.read(key: _travelersCacheKey(tripId));
      if (cached != null && cached.isNotEmpty) {
        final raw = jsonDecode(cached) as List<dynamic>;
        return raw
            .whereType<Map>()
            .map((e) => TripTraveler.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }
      if (e is NetworkException) return [];
      rethrow;
    }
  }

  Future<TripTraveler> createTraveler(
    String tripId, {
    required String displayName,
    String travelerCategory = 'child',
    String? restrictedNotes,
  }) async {
    final response = await apiClient.post(
      '/trips/$tripId/travelers',
      data: {
        'display_name': displayName,
        'traveler_category': travelerCategory,
        if (restrictedNotes != null && restrictedNotes.isNotEmpty)
          'restricted_notes': restrictedNotes,
      },
    );
    return TripTraveler.fromJson(_extractMap(response));
  }

  Future<TripTraveler> updateTraveler(
    String travelerId, {
    String? displayName,
    String? travelerCategory,
    String? restrictedNotes,
    int? baseVersion,
  }) async {
    final response = await apiClient.patch(
      '/travelers/$travelerId',
      data: {
        'display_name': ?displayName,
        'traveler_category': ?travelerCategory,
        if (restrictedNotes != null)
          'restricted_notes': restrictedNotes.isEmpty ? null : restrictedNotes,
        'base_version': ?baseVersion,
      },
    );
    return TripTraveler.fromJson(_extractMap(response));
  }

  Future<void> deleteTraveler(String travelerId) async {
    await apiClient.delete('/travelers/$travelerId');
  }
}

final tripCircleRepositoryProvider = Provider<TripCircleRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return TripCircleRepository(apiClient: apiClient);
});
