class ChecklistItem {
  const ChecklistItem({
    required this.id,
    required this.checklistId,
    required this.tripId,
    required this.title,
    this.category = 'other',
    this.isPacked = false,
    this.quantity = 1,
    this.notes,
    this.photoUrl,
    this.sortOrder = 0,
    this.packedAt,
    this.version = 1,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String checklistId;
  final String tripId;
  final String title;
  final String category;
  final bool isPacked;
  final int quantity;
  final String? notes;
  final String? photoUrl;
  final int sortOrder;
  final DateTime? packedAt;
  final int version;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  ChecklistItem copyWith({
    String? id,
    String? checklistId,
    String? tripId,
    String? title,
    String? category,
    bool? isPacked,
    int? quantity,
    String? notes,
    String? photoUrl,
    int? sortOrder,
    DateTime? packedAt,
    int? version,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ChecklistItem(
      id: id ?? this.id,
      checklistId: checklistId ?? this.checklistId,
      tripId: tripId ?? this.tripId,
      title: title ?? this.title,
      category: category ?? this.category,
      isPacked: isPacked ?? this.isPacked,
      quantity: quantity ?? this.quantity,
      notes: notes ?? this.notes,
      photoUrl: photoUrl ?? this.photoUrl,
      sortOrder: sortOrder ?? this.sortOrder,
      packedAt: packedAt ?? this.packedAt,
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
      'title': title,
      'category': category,
      'is_packed': isPacked,
      'quantity': quantity,
      'notes': notes,
      'photo_url': photoUrl,
      'sort_order': sortOrder,
      'packed_at': packedAt?.toIso8601String(),
      'version': version,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}
