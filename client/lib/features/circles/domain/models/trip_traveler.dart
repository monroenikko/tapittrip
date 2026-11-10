class TripTraveler {
  const TripTraveler({
    required this.id,
    required this.tripId,
    required this.managingUserId,
    required this.managingUserName,
    required this.displayName,
    this.travelerCategory = 'child',
    this.linkedMemberId,
    this.restrictedNotes,
    this.canEdit = false,
    this.canDelete = false,
    this.version = 1,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String tripId;
  final String? linkedMemberId;
  final String managingUserId;
  final String managingUserName;
  final String displayName;
  final String travelerCategory;
  final String? restrictedNotes;
  final bool canEdit;
  final bool canDelete;
  final int version;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  String get categoryLabel {
    switch (travelerCategory) {
      case 'infant':
        return 'Infant';
      case 'adult':
        return 'Adult';
      case 'companion':
        return 'Companion';
      default:
        return 'Child';
    }
  }

  factory TripTraveler.fromJson(Map<String, dynamic> json) {
    return TripTraveler(
      id: json['id'] as String,
      tripId: json['trip_id'] as String,
      linkedMemberId: json['linked_member_id'] as String?,
      managingUserId: json['managing_user_id'] as String? ?? '',
      managingUserName: json['managing_user_name'] as String? ?? 'Organizer',
      displayName: json['display_name'] as String? ?? 'Traveler',
      travelerCategory: json['traveler_category'] as String? ?? 'child',
      restrictedNotes: json['restricted_notes'] as String?,
      canEdit: json['can_edit'] as bool? ?? false,
      canDelete: json['can_delete'] as bool? ?? false,
      version: (json['version'] as num?)?.toInt() ?? 1,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'trip_id': tripId,
      'linked_member_id': linkedMemberId,
      'managing_user_id': managingUserId,
      'managing_user_name': managingUserName,
      'display_name': displayName,
      'traveler_category': travelerCategory,
      'restricted_notes': restrictedNotes,
      'can_edit': canEdit,
      'can_delete': canDelete,
      'version': version,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }
}
