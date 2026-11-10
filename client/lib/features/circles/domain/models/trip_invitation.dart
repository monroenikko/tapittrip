class TripInvitation {
  const TripInvitation({
    required this.id,
    required this.tripId,
    required this.proposedRole,
    required this.status,
    required this.maxUses,
    required this.useCount,
    required this.expiresAt,
    this.revokedAt,
    required this.inviterName,
    this.createdAt,
    this.inviteToken,
    this.shareUrl,
  });

  final String id;
  final String tripId;
  final String proposedRole;
  final String status;
  final int maxUses;
  final int useCount;
  final DateTime expiresAt;
  final DateTime? revokedAt;
  final String inviterName;
  final DateTime? createdAt;
  final String? inviteToken;
  final String? shareUrl;

  bool get isActive => status == 'active';
  int get remainingUses => (maxUses - useCount).clamp(0, maxUses);

  String get proposedRoleLabel =>
      proposedRole == 'editor' ? 'Editor' : 'Viewer';

  factory TripInvitation.fromJson(Map<String, dynamic> json) {
    return TripInvitation(
      id: (json['id'] ?? '').toString(),
      tripId: (json['trip_id'] ?? '').toString(),
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
      inviterName: (json['inviter_name'] ?? 'Organizer').toString(),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      inviteToken: json['invite_token'] as String?,
      shareUrl: json['share_url'] as String?,
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
