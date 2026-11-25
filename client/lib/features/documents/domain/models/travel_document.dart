class TravelDocument {
  const TravelDocument({
    required this.id,
    required this.tripId,
    required this.ownerId,
    required this.isOwner,
    required this.documentType,
    required this.displayName,
    this.issuer,
    this.referenceNumber,
    this.notesPrivate,
    this.expiresOn,
    this.isExpired = false,
    this.daysUntilExpiry,
    this.accessPolicy = 'owner_only',
    this.hasAttachment = false,
    this.originalFilename,
    this.mimeType,
    this.fileSizeBytes,
    this.downloadUrl,
    this.version = 1,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String tripId;
  final String ownerId;
  final bool isOwner;
  final String documentType;
  final String displayName;
  final String? issuer;
  final String? referenceNumber;
  final String? notesPrivate;
  final String? expiresOn;
  final bool isExpired;
  final int? daysUntilExpiry;
  final String accessPolicy;
  final bool hasAttachment;
  final String? originalFilename;
  final String? mimeType;
  final int? fileSizeBytes;
  final String? downloadUrl;
  final int version;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isSharedWithCircle => accessPolicy == 'circle_members';

  String get typeLabel {
    switch (documentType) {
      case 'passport_note':
        return 'Passport Note';
      case 'visa_reference':
        return 'Visa Reference';
      case 'travel_insurance':
        return 'Travel Insurance';
      case 'ticket_voucher':
        return 'Ticket / Voucher';
      case 'health_certificate':
        return 'Health Certificate';
      default:
        return 'Document';
    }
  }

  factory TravelDocument.fromJson(Map<String, dynamic> json) {
    return TravelDocument(
      id: json['id'] as String? ?? '',
      tripId: json['trip_id'] as String? ?? '',
      ownerId: json['owner_id'] as String? ?? '',
      isOwner: json['is_owner'] as bool? ?? true,
      documentType: json['document_type'] as String? ?? 'other',
      displayName: json['display_name'] as String? ?? '',
      issuer: json['issuer'] as String?,
      referenceNumber: json['reference_number'] as String?,
      notesPrivate: json['notes_private'] as String?,
      expiresOn: json['expires_on'] as String?,
      isExpired: json['is_expired'] as bool? ?? false,
      daysUntilExpiry: (json['days_until_expiry'] as num?)?.toInt(),
      accessPolicy: json['access_policy'] as String? ?? 'owner_only',
      hasAttachment: json['has_attachment'] as bool? ?? false,
      originalFilename: json['original_filename'] as String?,
      mimeType: json['mime_type'] as String?,
      fileSizeBytes: (json['file_size_bytes'] as num?)?.toInt(),
      downloadUrl: json['download_url'] as String?,
      version: (json['version'] as num?)?.toInt() ?? 1,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'trip_id': tripId,
    'owner_id': ownerId,
    'is_owner': isOwner,
    'document_type': documentType,
    'display_name': displayName,
    'issuer': issuer,
    'reference_number': referenceNumber,
    'notes_private': notesPrivate,
    'expires_on': expiresOn,
    'is_expired': isExpired,
    'days_until_expiry': daysUntilExpiry,
    'access_policy': accessPolicy,
    'has_attachment': hasAttachment,
    'original_filename': originalFilename,
    'mime_type': mimeType,
    'file_size_bytes': fileSizeBytes,
    'download_url': downloadUrl,
    'version': version,
    'created_at': createdAt?.toIso8601String(),
    'updated_at': updatedAt?.toIso8601String(),
  };
}
