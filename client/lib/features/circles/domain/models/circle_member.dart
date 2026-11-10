class CircleMember {
  const CircleMember({
    required this.id,
    required this.tripId,
    required this.userId,
    required this.displayName,
    this.avatarUrl,
    required this.role,
    this.invitationStatus = 'accepted',
    this.joinedAt,
  });

  final String id;
  final String tripId;
  final String userId;
  final String displayName;
  final String? avatarUrl;
  final String role;
  final String invitationStatus;
  final DateTime? joinedAt;

  bool get isOwner => role == 'owner';
  bool get isEditor => role == 'editor';
  bool get isViewer => role == 'viewer';

  String get roleLabel => switch (role) {
    'owner' => 'Organizer',
    'editor' => 'Editor',
    _ => 'Viewer',
  };

  factory CircleMember.fromJson(Map<String, dynamic> json) {
    return CircleMember(
      id: (json['id'] ?? '').toString(),
      tripId: (json['trip_id'] ?? '').toString(),
      userId: (json['user_id'] ?? '').toString(),
      displayName: (json['display_name'] ?? 'Traveler').toString(),
      avatarUrl: json['avatar_url'] as String?,
      role: (json['role'] ?? 'viewer').toString(),
      invitationStatus: (json['invitation_status'] ?? 'accepted').toString(),
      joinedAt: json['joined_at'] != null
          ? DateTime.tryParse(json['joined_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'trip_id': tripId,
    'user_id': userId,
    'display_name': displayName,
    'avatar_url': avatarUrl,
    'role': role,
    'invitation_status': invitationStatus,
    'joined_at': joinedAt?.toIso8601String(),
  };
}
