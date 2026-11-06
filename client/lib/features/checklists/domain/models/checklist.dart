import 'checklist_item.dart';

class Checklist {
  Checklist({
    required this.id,
    required this.tripId,
    required this.title,
    this.type = 'packing',
    this.description,
    this.sortOrder = 0,
    int? totalItemsCount,
    int? packedItemsCount,
    int? progressPercentage,
    this.items = const [],
    this.createdAt,
    this.updatedAt,
  }) : totalItemsCount = totalItemsCount ?? items.length,
       packedItemsCount =
           packedItemsCount ?? items.where((i) => i.isPacked).length,
       progressPercentage =
           progressPercentage ??
           ((totalItemsCount ?? items.length) > 0
               ? (((packedItemsCount ?? items.where((i) => i.isPacked).length) /
                             (totalItemsCount ?? items.length)) *
                         100)
                     .round()
               : 0);

  final String id;
  final String tripId;
  final String title;
  final String type;
  final String? description;
  final int sortOrder;
  final int totalItemsCount;
  final int packedItemsCount;
  final int progressPercentage;
  final List<ChecklistItem> items;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Checklist copyWith({
    String? id,
    String? tripId,
    String? title,
    String? type,
    String? description,
    int? sortOrder,
    int? totalItemsCount,
    int? packedItemsCount,
    int? progressPercentage,
    List<ChecklistItem>? items,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    final newItems = items ?? this.items;
    return Checklist(
      id: id ?? this.id,
      tripId: tripId ?? this.tripId,
      title: title ?? this.title,
      type: type ?? this.type,
      description: description ?? this.description,
      sortOrder: sortOrder ?? this.sortOrder,
      totalItemsCount:
          totalItemsCount ??
          (items != null ? newItems.length : this.totalItemsCount),
      packedItemsCount:
          packedItemsCount ??
          (items != null
              ? newItems.where((i) => i.isPacked).length
              : this.packedItemsCount),
      progressPercentage: progressPercentage,
      items: newItems,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory Checklist.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List<dynamic>? ?? [];
    final itemsList = rawItems
        .map((item) => ChecklistItem.fromJson(item as Map<String, dynamic>))
        .toList();

    final totalCount = json['total_items_count'] as int? ?? itemsList.length;
    final packedCount =
        json['packed_items_count'] as int? ??
        itemsList.where((i) => i.isPacked).length;
    final progress =
        json['progress_percentage'] as int? ??
        (totalCount > 0 ? ((packedCount / totalCount) * 100).round() : 0);

    return Checklist(
      id: json['id'] as String,
      tripId: json['trip_id'] as String,
      title: json['title'] as String,
      type: json['type'] as String? ?? 'packing',
      description: json['description'] as String?,
      sortOrder: json['sort_order'] as int? ?? 0,
      totalItemsCount: totalCount,
      packedItemsCount: packedCount,
      progressPercentage: progress,
      items: itemsList,
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
      'title': title,
      'type': type,
      'description': description,
      'sort_order': sortOrder,
      'total_items_count': totalItemsCount,
      'packed_items_count': packedItemsCount,
      'progress_percentage': progressPercentage,
      'items': items.map((i) => i.toJson()).toList(),
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}
