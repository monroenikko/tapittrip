import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapittrip/core/network/api_client.dart';
import 'package:tapittrip/core/network/api_exceptions.dart';
import 'package:tapittrip/core/storage/token_storage.dart';
import 'package:tapittrip/core/theme/app_theme.dart';
import 'package:tapittrip/features/checklists/data/checklist_repository.dart';
import 'package:tapittrip/features/checklists/domain/models/checklist_item.dart';
import 'package:tapittrip/features/checklists/domain/models/media_attachment.dart';
import 'package:tapittrip/features/checklists/presentation/widgets/checklist_item_tile.dart';
import 'package:tapittrip/features/checklists/presentation/widgets/checklist_template_dialog.dart';
import 'package:tapittrip/features/checklists/presentation/widgets/photo_viewer_dialog.dart';

class FakeApiClient extends ApiClient {
  FakeApiClient() : super(tokenStorage: InMemoryTokenStorage());

  dynamic getResponse;
  dynamic postResponse;
  bool shouldThrow = false;

  @override
  Future<dynamic> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    if (shouldThrow) throw const NetworkException();
    return getResponse;
  }

  @override
  Future<dynamic> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    if (shouldThrow) throw const NetworkException();
    return postResponse;
  }
}

class FakeSecureStorage extends FlutterSecureStorage {
  FakeSecureStorage([Map<String, String>? initial])
    : _data = initial != null ? Map.from(initial) : {};

  final Map<String, String> _data;

  @override
  Future<String?> read({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async => _data[key];

  @override
  Future<void> write({
    required String key,
    required String? value,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (value != null) {
      _data[key] = value;
    } else {
      _data.remove(key);
    }
  }
}

void main() {
  group('MediaAttachment Domain Model', () {
    test('parses from JSON correctly', () {
      final json = {
        'id': 'media-1',
        'trip_id': 'trip-1',
        'attachable_type': 'checklist_item',
        'attachable_id': 'item-1',
        'uploaded_by_id': 'user-1',
        'uploaded_by_name': 'Traveler John',
        'original_filename': 'passport_scan.jpg',
        'mime_type': 'image/jpeg',
        'file_size_bytes': 1048576,
        'formatted_size': '1.0 MB',
        'title': 'Passport Scan',
        'notes': 'Official passport copy',
        'url': 'http://localhost/api/v1/trips/trip-1/media/media-1',
        'is_image': true,
        'is_pdf': false,
        'created_at': '2026-11-06T12:00:00Z',
      };

      final media = MediaAttachment.fromJson(json);

      expect(media.id, 'media-1');
      expect(media.title, 'Passport Scan');
      expect(media.originalFilename, 'passport_scan.jpg');
      expect(media.isImage, isTrue);
      expect(media.isPdf, isFalse);
      expect(media.fileSizeBytes, 1048576);
      expect(media.formattedSize, '1.0 MB');
      expect(media.uploadedByName, 'Traveler John');
    });
  });

  group('ChecklistRepository Media Upload', () {
    test('uploads item photo via multipart endpoint', () async {
      final fakeApi = FakeApiClient();
      final repo = ChecklistRepository(
        apiClient: fakeApi,
        storage: FakeSecureStorage(),
      );

      fakeApi.postResponse = {
        'id': 'item-42',
        'checklist_id': 'cl-1',
        'trip_id': 'trip-1',
        'title': 'Japan Rail Pass Voucher',
        'category': 'documents',
        'is_packed': false,
        'quantity': 1,
        'photo_url': 'http://localhost/api/v1/trips/trip-1/media/media-42',
        'version': 2,
      };

      final updated = await repo.uploadItemPhoto(
        'item-42',
        fileName: 'jr_voucher.jpg',
        bytes: [0, 1, 2, 3],
        title: 'JR Voucher',
      );

      expect(updated.id, 'item-42');
      expect(updated.photoUrl, contains('media-42'));
    });
  });

  group('ChecklistTemplateDialog Trip-Stage Templates', () {
    testWidgets('displays Departure Day and Return Trip templates', (
      tester,
    ) async {
      String? selectedKey;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: ChecklistTemplateDialog(
              onSelectTemplate: (key) async => selectedKey = key,
            ),
          ),
        ),
      );

      expect(find.text('Departure Day Checklist'), findsOneWidget);
      expect(find.text('Return Trip Checklist'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text('Departure Day Checklist'),
        100,
        scrollable: find.byType(Scrollable),
      );
      await tester.tap(find.text('Departure Day Checklist'));
      await tester.pumpAndSettle();

      expect(selectedKey, 'departure_day');
    });
  });

  group('PhotoViewerDialog and Item Thumbnail', () {
    testWidgets(
      'ChecklistItemTile displays photo thumbnail when photoUrl exists',
      (tester) async {
        const itemWithPhoto = ChecklistItem(
          id: 'item-10',
          checklistId: 'cl-1',
          tripId: 'trip-1',
          title: 'Universal Power Adapter',
          category: 'electronics',
          photoUrl: 'https://images.unsplash.com/photo-1544716278-ca5e3f4abd8c',
        );

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light(),
            home: Scaffold(
              body: ChecklistItemTile(item: itemWithPhoto, onToggle: () {}),
            ),
          ),
        );

        expect(find.text('Universal Power Adapter'), findsOneWidget);
        // Photo container should be rendered
        expect(find.byType(Image), findsOneWidget);
      },
    );

    testWidgets('PhotoViewerDialog displays title and can be dismissed', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: const Scaffold(
            body: PhotoViewerDialog(
              photoUrl: 'https://example.com/photo.jpg',
              title: 'Flight Boarding Pass',
            ),
          ),
        ),
      );

      expect(find.text('Flight Boarding Pass'), findsOneWidget);
      expect(find.byIcon(Icons.close_rounded), findsOneWidget);

      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();
    });
  });
}
