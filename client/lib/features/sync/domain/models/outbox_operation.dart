class OutboxOperation {
  const OutboxOperation({
    required this.operationId,
    this.tripId,
    required this.entityType,
    required this.entityId,
    required this.operationType,
    this.payload,
    this.baseVersion = 1,
    this.status = 'pending',
    this.conflictDetails,
    required this.createdAt,
  });

  final String operationId;
  final String? tripId;
  final String entityType;
  final String entityId;
  final String operationType;
  final Map<String, dynamic>? payload;
  final int baseVersion;
  final String status;
  final Map<String, dynamic>? conflictDetails;
  final DateTime createdAt;

  OutboxOperation copyWith({
    String? operationId,
    String? tripId,
    String? entityType,
    String? entityId,
    String? operationType,
    Map<String, dynamic>? payload,
    int? baseVersion,
    String? status,
    Map<String, dynamic>? conflictDetails,
    DateTime? createdAt,
  }) {
    return OutboxOperation(
      operationId: operationId ?? this.operationId,
      tripId: tripId ?? this.tripId,
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      operationType: operationType ?? this.operationType,
      payload: payload ?? this.payload,
      baseVersion: baseVersion ?? this.baseVersion,
      status: status ?? this.status,
      conflictDetails: conflictDetails ?? this.conflictDetails,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'operation_id': operationId,
      if (tripId != null) 'trip_id': tripId,
      'entity_type': entityType,
      'entity_id': entityId,
      'operation_type': operationType,
      if (payload != null) 'payload': payload,
      'base_version': baseVersion,
      'status': status,
      if (conflictDetails != null) 'conflict_details': conflictDetails,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory OutboxOperation.fromJson(Map<String, dynamic> json) {
    return OutboxOperation(
      operationId: json['operation_id'] as String,
      tripId: json['trip_id'] as String?,
      entityType: json['entity_type'] as String,
      entityId: json['entity_id'] as String,
      operationType: json['operation_type'] as String,
      payload: json['payload'] != null
          ? Map<String, dynamic>.from(json['payload'] as Map)
          : null,
      baseVersion: (json['base_version'] as num?)?.toInt() ?? 1,
      status: (json['status'] as String?) ?? 'pending',
      conflictDetails: json['conflict_details'] != null
          ? Map<String, dynamic>.from(json['conflict_details'] as Map)
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }
}
