class BookingImport {
  const BookingImport({
    required this.id,
    required this.tripId,
    required this.userId,
    required this.source,
    this.hasAttachment = false,
    this.originalFilename,
    this.mimeType,
    this.fileSizeBytes,
    this.downloadUrl,
    required this.bookingType,
    this.rawText,
    required this.extractionStatus,
    this.extractedData,
    this.confidenceScore,
    this.confirmedEntityType,
    this.confirmedEntityId,
    this.reviewedAt,
    this.errorMessage,
    this.version = 1,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String tripId;
  final String userId;
  final String source;
  final bool hasAttachment;
  final String? originalFilename;
  final String? mimeType;
  final int? fileSizeBytes;
  final String? downloadUrl;
  final String bookingType;
  final String? rawText;
  final String extractionStatus;
  final Map<String, dynamic>? extractedData;
  final double? confidenceScore;
  final String? confirmedEntityType;
  final String? confirmedEntityId;
  final DateTime? reviewedAt;
  final String? errorMessage;
  final int version;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isPending => extractionStatus == 'pending';
  bool get isExtracted => extractionStatus == 'extracted';
  bool get isConfirmed => extractionStatus == 'confirmed';
  bool get isFailed => extractionStatus == 'failed';
  bool get isDismissed => extractionStatus == 'dismissed';

  String get summary {
    final s = extractedData?['summary'];
    if (s is String && s.isNotEmpty) {
      return s;
    }
    return 'Booking Confirmation';
  }

  String get confidencePercentText {
    if (confidenceScore == null) return 'N/A';
    return '${(confidenceScore! * 100).round()}%';
  }

  String get typeLabel {
    switch (bookingType.toLowerCase()) {
      case 'flight':
        return 'Flight';
      case 'stay':
        return 'Hotel / Stay';
      case 'activity':
        return 'Activity / Tour';
      default:
        return 'Booking';
    }
  }

  Map<String, dynamic>? get extractedFlight {
    final f = extractedData?['flight'];
    if (f is Map<String, dynamic>) return f;
    if (f is Map) return Map<String, dynamic>.from(f);
    return null;
  }

  Map<String, dynamic>? get extractedStay {
    final s = extractedData?['stay'];
    if (s is Map<String, dynamic>) return s;
    if (s is Map) return Map<String, dynamic>.from(s);
    return null;
  }

  Map<String, dynamic>? get extractedActivity {
    final a = extractedData?['activity'];
    if (a is Map<String, dynamic>) return a;
    if (a is Map) return Map<String, dynamic>.from(a);
    return null;
  }

  factory BookingImport.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic value) {
      if (value is String && value.isNotEmpty) {
        return DateTime.tryParse(value);
      }
      return null;
    }

    Map<String, dynamic>? data;
    if (json['extracted_data'] is Map) {
      data = Map<String, dynamic>.from(json['extracted_data'] as Map);
    }

    return BookingImport(
      id: json['id'] as String? ?? '',
      tripId: json['trip_id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      source: json['source'] as String? ?? 'paste_text',
      hasAttachment: json['has_attachment'] as bool? ?? false,
      originalFilename: json['original_filename'] as String?,
      mimeType: json['mime_type'] as String?,
      fileSizeBytes: (json['file_size_bytes'] as num?)?.toInt(),
      downloadUrl: json['download_url'] as String?,
      bookingType: json['booking_type'] as String? ?? 'auto',
      rawText: json['raw_text'] as String?,
      extractionStatus: json['extraction_status'] as String? ?? 'pending',
      extractedData: data,
      confidenceScore: (json['confidence_score'] as num?)?.toDouble(),
      confirmedEntityType: json['confirmed_entity_type'] as String?,
      confirmedEntityId: json['confirmed_entity_id'] as String?,
      reviewedAt: parseDate(json['reviewed_at']),
      errorMessage: json['error_message'] as String?,
      version: (json['version'] as num?)?.toInt() ?? 1,
      createdAt: parseDate(json['created_at']),
      updatedAt: parseDate(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'trip_id': tripId,
      'user_id': userId,
      'source': source,
      'has_attachment': hasAttachment,
      'original_filename': originalFilename,
      'mime_type': mimeType,
      'file_size_bytes': fileSizeBytes,
      'download_url': downloadUrl,
      'booking_type': bookingType,
      'raw_text': rawText,
      'extraction_status': extractionStatus,
      'extracted_data': extractedData,
      'confidence_score': confidenceScore,
      'confirmed_entity_type': confirmedEntityType,
      'confirmed_entity_id': confirmedEntityId,
      'reviewed_at': reviewedAt?.toIso8601String(),
      'error_message': errorMessage,
      'version': version,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}
