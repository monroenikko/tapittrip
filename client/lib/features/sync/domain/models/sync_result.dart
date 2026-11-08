class SyncOperationResult {
  const SyncOperationResult({
    required this.operationId,
    required this.status,
    this.serverSequence,
    this.currentVersion,
    this.conflictDetails,
  });

  final String operationId;
  final String status; // 'accepted', 'conflict', 'rejected'
  final int? serverSequence;
  final int? currentVersion;
  final Map<String, dynamic>? conflictDetails;

  factory SyncOperationResult.fromJson(Map<String, dynamic> json) {
    return SyncOperationResult(
      operationId: json['operation_id'] as String,
      status: json['status'] as String,
      serverSequence: (json['server_sequence'] as num?)?.toInt(),
      currentVersion: (json['current_version'] as num?)?.toInt(),
      conflictDetails: json['conflict_details'] != null
          ? Map<String, dynamic>.from(json['conflict_details'] as Map)
          : null,
    );
  }
}

class PullResult {
  const PullResult({
    required this.cursor,
    required this.operations,
    required this.hasMore,
  });

  final int cursor;
  final List<Map<String, dynamic>> operations;
  final bool hasMore;

  factory PullResult.fromJson(Map<String, dynamic> json) {
    return PullResult(
      cursor: (json['cursor'] as num?)?.toInt() ?? 0,
      operations: (json['operations'] as List<dynamic>? ?? [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList(),
      hasMore: (json['has_more'] as bool?) ?? false,
    );
  }
}
