class ChecklistItem {
  const ChecklistItem({
    required this.id,
    required this.checklistId,
    required this.tripId,
    required this.title,
    this.assignedUserId,
    this.assignedUserName,
    this.assignedTravelerId,
    this.assignedTravelerName,
    this.assignedTravelerCategory,
    this.category = 'other',
    this.isPacked = false,
    this.quantity = 1,
    this.notes,
    this.photoUrl,
    this.sortOrder = 0,
    this.packedAt,
    this.completedByUserId,
    this.completedByName,
    this.version = 1,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String checklistId;
  final String tripId;
  final String? assignedUserId;
  final String? assignedUserName;
  final String? assignedTravelerId;
  final String? assignedTravelerName;
  final String? assignedTravelerCategory;
  final String title;
  final String category;
  final bool isPacked;
  final int quantity;
  final String? notes;
  final String? photoUrl;
  final int sortOrder;
  final DateTime? packedAt;
  final String? completedByUserId;
  final String? completedByName;
  final int version;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  String? get assigneeLabel => assignedUserName ?? assignedTravelerName;
  bool get isAssigned => assignedUserId != null || assignedTravelerId != null;

  ChecklistItem copyWith({
    String? id,
    String? checklistId,
    String? tripId,
    String? assignedUserId,
    String? assignedUserName,
    String? assignedTravelerId,
    String? assignedTravelerName,
    String? assignedTravelerCategory,
    bool clearAssignee = false,
    String? title,
    String? category,
    bool? isPacked,
    int? quantity,
    String? notes,
    String? photoUrl,
    int? sortOrder,
    DateTime? packedAt,
    String? completedByUserId,
    String? completedByName,
    bool clearCompletedBy = false,
    int? version,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ChecklistItem(
      id: id ?? this.id,
      checklistId: checklistId ?? this.checklistId,
      tripId: tripId ?? this.tripId,
      assignedUserId: clearAssignee
          ? null
          : (assignedUserId ?? this.assignedUserId),
      assignedUserName: clearAssignee
          ? null
          : (assignedUserName ?? this.assignedUserName),
      assignedTravelerId: clearAssignee
          ? null
          : (assignedTravelerId ?? this.assignedTravelerId),
      assignedTravelerName: clearAssignee
          ? null
          : (assignedTravelerName ?? this.assignedTravelerName),
      assignedTravelerCategory: clearAssignee
          ? null
          : (assignedTravelerCategory ?? this.assignedTravelerCategory),
      title: title ?? this.title,
      category: category ?? this.category,
      isPacked: isPacked ?? this.isPacked,
      quantity: quantity ?? this.quantity,
      notes: notes ?? this.notes,
      photoUrl: photoUrl ?? this.photoUrl,
      sortOrder: sortOrder ?? this.sortOrder,
      packedAt: packedAt ?? this.packedAt,
      completedByUserId: clearCompletedBy
          ? null
          : (completedByUserId ?? this.completedByUserId),
      completedByName: clearCompletedBy
          ? null
          : (completedByName ?? this.completedByName),
      version: version ?? this.version,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory ChecklistItem.fromJson(Map<String, dynamic> json) {
    return ChecklistItem(
      id: json['id'] as String,
      checklistId: json['checklist_id'] as String,
      tripId: json['trip_id'] as String,
      assignedUserId: json['assigned_user_id'] as String?,
      assignedUserName: json['assigned_user_name'] as String?,
      assignedTravelerId: json['assigned_traveler_id'] as String?,
      assignedTravelerName: json['assigned_traveler_name'] as String?,
      assignedTravelerCategory: json['assigned_traveler_category'] as String?,
      title: json['title'] as String,
      category: json['category'] as String? ?? 'other',
      isPacked: json['is_packed'] as bool? ?? false,
      quantity: json['quantity'] as int? ?? 1,
      notes: json['notes'] as String?,
      photoUrl: json['photo_url'] as String?,
      sortOrder: json['sort_order'] as int? ?? 0,
      packedAt: json['packed_at'] != null
          ? DateTime.tryParse(json['packed_at'] as String)
          : null,
      completedByUserId: json['completed_by_user_id'] as String?,
      completedByName: json['completed_by_name'] as String?,
      version: json['version'] as int? ?? 1,
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
      'checklist_id': checklistId,
      'trip_id': tripId,
      'assigned_user_id': assignedUserId,
      'assigned_user_name': assignedUserName,
      'assigned_traveler_id': assignedTravelerId,
      'assigned_traveler_name': assignedTravelerName,
      'assigned_traveler_category': assignedTravelerCategory,
      'title': title,
      'category': category,
      'is_packed': isPacked,
      'quantity': quantity,
      'notes': notes,
      'photo_url': photoUrl,
      'sort_order': sortOrder,
      'packed_at': packedAt?.toIso8601String(),
      'completed_by_user_id': completedByUserId,
      'completed_by_name': completedByName,
      'version': version,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}
