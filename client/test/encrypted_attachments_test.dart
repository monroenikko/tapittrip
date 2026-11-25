import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapittrip/features/documents/domain/models/travel_document.dart';
import 'package:tapittrip/features/documents/presentation/pages/trip_documents_vault_page.dart';
import 'package:tapittrip/features/documents/presentation/providers/travel_document_provider.dart';
import 'package:tapittrip/features/imports/domain/models/booking_import.dart';

void main() {
  test('TravelDocument and BookingImport parse encrypted binary attachment metadata and signed download URLs', () {
    final doc = TravelDocument.fromJson({
      'id': 'doc-1',
      'trip_id': 'trip-1',
      'owner_id': 'user-1',
      'is_owner': true,
      'document_type': 'passport_note',
      'display_name': 'Passport Bio Scan',
      'has_attachment': true,
      'original_filename': 'passport.pdf',
      'mime_type': 'application/pdf',
      'file_size_bytes': 20480,
      'download_url':
          'https://api.example/v1/documents/doc-1/download?signature=abc',
    });

    expect(doc.hasAttachment, isTrue);
    expect(doc.originalFilename, 'passport.pdf');
    expect(doc.mimeType, 'application/pdf');
    expect(doc.fileSizeBytes, 20480);
    expect(doc.downloadUrl, contains('signature=abc'));

    final bookingImport = BookingImport.fromJson({
      'id': 'imp-1',
      'trip_id': 'trip-1',
      'user_id': 'user-1',
      'source': 'upload_file',
      'booking_type': 'flight',
      'extraction_status': 'extracted',
      'has_attachment': true,
      'original_filename': 'ticket.pdf',
      'mime_type': 'application/pdf',
      'file_size_bytes': 12345,
      'download_url':
          'https://api.example/v1/imports/imp-1/download?signature=xyz',
    });

    expect(bookingImport.hasAttachment, isTrue);
    expect(bookingImport.originalFilename, 'ticket.pdf');
    expect(bookingImport.downloadUrl, contains('signature=xyz'));
  });

  testWidgets(
    'TripDocumentsVaultPage shows encrypted attachment badge with View File for owner and hides download link for companions',
    (tester) async {
      const ownerDoc = TravelDocument(
        id: 'doc-1',
        tripId: 'trip-1',
        ownerId: 'user-1',
        isOwner: true,
        documentType: 'passport_note',
        displayName: 'Owner Passport Scan',
        hasAttachment: true,
        originalFilename: 'passport_bio.pdf',
        mimeType: 'application/pdf',
        fileSizeBytes: 51200,
        downloadUrl: 'https://api.example/v1/documents/doc-1/download?sig=1',
      );
      const companionDoc = TravelDocument(
        id: 'doc-2',
        tripId: 'trip-1',
        ownerId: 'user-2',
        isOwner: false,
        documentType: 'travel_insurance',
        displayName: 'Companion Shared Policy',
        accessPolicy: 'circle_members',
        hasAttachment: true,
        originalFilename: null,
        downloadUrl: null,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            tripDocumentsProvider('trip-1')
                .overrideWith((ref) async => [ownerDoc, companionDoc]),
          ],
          child: const MaterialApp(
            home: TripDocumentsVaultPage(tripId: 'trip-1'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('passport_bio.pdf'), findsOneWidget);
      expect(find.text('View File'), findsOneWidget);
      expect(find.text('Encrypted file attached (Owner only)'), findsOneWidget);
    },
  );
}
