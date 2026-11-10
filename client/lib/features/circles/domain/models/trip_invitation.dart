class TripInvitation {
  const TripInvitation({
    required this.id,
    required this.tripId,
    this.inviteType = 'link',
    this.targetDisplayName,
    required this.proposedRole,
    required this.status,
    required this.maxUses,
    required this.useCount,
    required this.expiresAt,
    this.revokedAt,
    this.respondedAt,
    required this.inviterName,
    this.createdAt,
    this.inviteToken,
    this.shareUrl,
  });

  final String id;
  final String tripId;
  final String inviteType;
  final String? targetDisplayName;
  final String proposedRole;
  final String status;
  final int maxUses;
  final int useCount;
  final DateTime expiresAt;
  final DateTime? revokedAt;
  final DateTime? respondedAt;
  final String inviterName;
  final DateTime? createdAt;
  final String? inviteToken;
  final String? shareUrl;

  bool get isDirect => inviteType == 'direct';
  bool get isActive => status == 'active' || status == 'pending';
  int get remainingUses => (maxUses - useCount).clamp(0, maxUses);

  String get proposedRoleLabel =>
      proposedRole == 'editor' ? 'Editor' : 'Viewer';

  factory TripInvitation.fromJson(Map<String, dynamic> json) {
    return TripInvitation(
      id: (json['id'] ?? '').toString(),
      tripId: (json['trip_id'] ?? '').toString(),
      inviteType: (json['invite_type'] ?? 'link').toString(),
      targetDisplayName: json['target_display_name'] as String?,
      proposedRole: (json['proposed_role'] ?? 'viewer').toString(),
      status: (json['status'] ?? 'active').toString(),
      maxUses: (json['max_uses'] as num?)?.toInt() ?? 1,
      useCount: (json['use_count'] as num?)?.toInt() ?? 0,
      expiresAt:
          DateTime.tryParse((json['expires_at'] ?? '').toString()) ??
          DateTime.now().add(const Duration(days: 7)),
      revokedAt: json['revoked_at'] != null
          ? DateTime.tryParse(json['revoked_at'].toString())
          : null,
      respondedAt: json['responded_at'] != null
          ? DateTime.tryParse(json['responded_at'].toString())
          : null,
      inviterName: (json['inviter_name'] ?? 'Organizer').toString(),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      inviteToken: json['invite_token'] as String?,
      shareUrl: json['share_url'] as String?,
    );
  }
}

class IncomingInvitation {
  const IncomingInvitation({
    required this.id,
    required this.tripId,
    required this.tripTitle,
    this.destinationCountry,
    required this.proposedRole,
    required this.status,
    required this.inviterName,
    required this.expiresAt,
    this.respondedAt,
    this.createdAt,
  });

  final String id;
  final String tripId;
  final String tripTitle;
  final String? destinationCountry;
  final String proposedRole;
  final String status;
  final String inviterName;
  final DateTime expiresAt;
  final DateTime? respondedAt;
  final DateTime? createdAt;

  bool get isPending => status == 'pending';

  String get proposedRoleLabel => proposedRole == 'editor'
      ? 'Editor (Can edit plan)'
      : 'Viewer (Read-only)';

  factory IncomingInvitation.fromJson(Map<String, dynamic> json) {
    return IncomingInvitation(
      id: (json['id'] ?? '').toString(),
      tripId: (json['trip_id'] ?? '').toString(),
      tripTitle: (json['trip_title'] ?? 'Shared Trip').toString(),
      destinationCountry: json['destination_country'] as String?,
      proposedRole: (json['proposed_role'] ?? 'viewer').toString(),
      status: (json['status'] ?? 'pending').toString(),
      inviterName: (json['inviter_name'] ?? 'Organizer').toString(),
      expiresAt:
          DateTime.tryParse((json['expires_at'] ?? '').toString()) ??
          DateTime.now().add(const Duration(days: 7)),
      respondedAt: json['responded_at'] != null
          ? DateTime.tryParse(json['responded_at'].toString())
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }
}

class TripOwnershipTransfer {
  const TripOwnershipTransfer({
    required this.id,
    required this.tripId,
    required this.tripTitle,
    required this.fromUserId,
    required this.fromUserName,
    required this.toUserId,
    required this.toUserName,
    this.formerOwnerRole = 'editor',
    required this.status,
    required this.expiresAt,
    this.respondedAt,
    this.createdAt,
  });

  final String id;
  final String tripId;
  final String tripTitle;
  final String fromUserId;
  final String fromUserName;
  final String toUserId;
  final String toUserName;
  final String formerOwnerRole;
  final String status;
  final DateTime expiresAt;
  final DateTime? respondedAt;
  final DateTime? createdAt;

  bool get isPending => status == 'pending';

  String get formerOwnerRoleLabel =>
      formerOwnerRole == 'viewer' ? 'Viewer' : 'Editor';

  factory TripOwnershipTransfer.fromJson(Map<String, dynamic> json) {
    return TripOwnershipTransfer(
      id: (json['id'] ?? '').toString(),
      tripId: (json['trip_id'] ?? '').toString(),
      tripTitle: (json['trip_title'] ?? 'Shared Trip').toString(),
      fromUserId: (json['from_user_id'] ?? '').toString(),
      fromUserName: (json['from_user_name'] ?? 'Organizer').toString(),
      toUserId: (json['to_user_id'] ?? '').toString(),
      toUserName: (json['to_user_name'] ?? 'Companion').toString(),
      formerOwnerRole: (json['former_owner_role'] ?? 'editor').toString(),
      status: (json['status'] ?? 'pending').toString(),
      expiresAt:
          DateTime.tryParse((json['expires_at'] ?? '').toString()) ??
          DateTime.now().add(const Duration(days: 7)),
      respondedAt: json['responded_at'] != null
          ? DateTime.tryParse(json['responded_at'].toString())
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }
}

class InvitationPreview {
  const InvitationPreview({
    required this.tripTitle,
    this.destinationCountry,
    required this.proposedRole,
    required this.inviterName,
    required this.expiresAt,
    required this.status,
  });

  final String tripTitle;
  final String? destinationCountry;
  final String proposedRole;
  final String inviterName;
  final DateTime expiresAt;
  final String status;

  bool get isRedeemable => status == 'active';

  String get proposedRoleLabel => proposedRole == 'editor'
      ? 'Editor (Can edit plan)'
      : 'Viewer (Read-only)';

  factory InvitationPreview.fromJson(Map<String, dynamic> json) {
    return InvitationPreview(
      tripTitle: (json['trip_title'] ?? '').toString(),
      destinationCountry: json['destination_country'] as String?,
      proposedRole: (json['proposed_role'] ?? 'viewer').toString(),
      inviterName: (json['inviter_name'] ?? 'Organizer').toString(),
      expiresAt:
          DateTime.tryParse((json['expires_at'] ?? '').toString()) ??
          DateTime.now(),
      status: (json['status'] ?? 'active').toString(),
    );
  }
}
