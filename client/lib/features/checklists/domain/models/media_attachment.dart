class MediaAttachment {
  const MediaAttachment({
    required this.id,
    required this.tripId,
    this.attachableType,
    this.attachableId,
    required this.uploadedById,
    this.uploadedByName,
    required this.originalFilename,
    required this.mimeType,
    required this.fileSizeBytes,
    required this.formattedSize,
    this.title,
    this.notes,
    required this.url,
    required this.isImage,
    required this.isPdf,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String tripId;
  final String? attachableType;
  final String? attachableId;
  final String uploadedById;
  final String? uploadedByName;
  final String originalFilename;
  final String mimeType;
  final int fileSizeBytes;
  final String formattedSize;
  final String? title;
  final String? notes;
  final String url;
  final bool isImage;
  final bool isPdf;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory MediaAttachment.fromJson(Map<String, dynamic> json) {
    return MediaAttachment(
      id: json['id'] as String,
      tripId: json['trip_id'] as String,
      attachableType: json['attachable_type'] as String?,
      attachableId: json['attachable_id'] as String?,
      uploadedById: json['uploaded_by_id'] as String,
      uploadedByName: json['uploaded_by_name'] as String?,
      originalFilename: json['original_filename'] as String,
      mimeType: json['mime_type'] as String,
      fileSizeBytes: json['file_size_bytes'] as int? ?? 0,
      formattedSize: json['formatted_size'] as String? ?? '0 B',
      title: json['title'] as String?,
      notes: json['notes'] as String?,
      url: json['url'] as String,
      isImage: json['is_image'] as bool? ?? false,
      isPdf: json['is_pdf'] as bool? ?? false,
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
      'attachable_type': attachableType,
      'attachable_id': attachableId,
      'uploaded_by_id': uploadedById,
      'uploaded_by_name': uploadedByName,
      'original_filename': originalFilename,
      'mime_type': mimeType,
      'file_size_bytes': fileSizeBytes,
      'formatted_size': formattedSize,
      'title': title,
      'notes': notes,
      'url': url,
      'is_image': isImage,
      'is_pdf': isPdf,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}
