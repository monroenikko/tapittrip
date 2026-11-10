// ignore_for_file: use_null_aware_elements

import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exceptions.dart';
import '../../circles/data/trip_circle_repository.dart';
import '../domain/models/checklist.dart';
import '../domain/models/checklist_item.dart';
import '../domain/models/media_attachment.dart';

class ChecklistRepository {
  ChecklistRepository({required this.apiClient, FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  final ApiClient apiClient;
  final FlutterSecureStorage _storage;

  String _cacheKey(String tripId) => 'cached_checklists_$tripId';

  /// Fetch all checklists for a trip with offline caching support.
  Future<List<Checklist>> fetchChecklists(String tripId) async {
    try {
      final response = await apiClient.get('/trips/$tripId/checklists');

      if (response is List) {
        await _storage.write(
          key: _cacheKey(tripId),
          value: jsonEncode(response),
        );

        return response
            .map((json) => Checklist.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      return [];
    } on ApiException catch (e) {
      if (e.statusCode == 403 || e.code == 'forbidden') {
        await TripCircleRepository.purgeAllTripCachesForStorage(
          storage: _storage,
          tripId: tripId,
        );
        rethrow;
      }
      return _loadFromCache(tripId);
    } catch (_) {
      return _loadFromCache(tripId);
    }
  }

  /// Persist updated checklist list to local offline storage cleanly.
  Future<void> cacheChecklists(
    String tripId,
    List<Checklist> checklists,
  ) async {
    try {
      await _storage.write(
        key: _cacheKey(tripId),
        value: jsonEncode(checklists.map((c) => c.toJson()).toList()),
      );
    } catch (_) {}
  }

  Future<List<Checklist>> _loadFromCache(String tripId) async {
    final cached = await _storage.read(key: _cacheKey(tripId));
    if (cached != null) {
      final data = jsonDecode(cached) as List<dynamic>;
      return data
          .map((json) => Checklist.fromJson(json as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  /// Create a new checklist for a trip.
  Future<Checklist> createChecklist(
    String tripId, {
    required String title,
    String type = 'packing',
    String? description,
    int sortOrder = 0,
  }) async {
    final payload = {
      'title': title,
      'type': type,
      if (description != null) 'description': description,
      'sort_order': sortOrder,
    };

    final response = await apiClient.post(
      '/trips/$tripId/checklists',
      data: payload,
    );

    return Checklist.fromJson(response as Map<String, dynamic>);
  }

  /// Apply a starter packing template to a trip.
  Future<Checklist> applyTemplate(
    String tripId, {
    required String template,
  }) async {
    final response = await apiClient.post(
      '/trips/$tripId/checklists/apply-template',
      data: {'template': template},
    );

    return Checklist.fromJson(response as Map<String, dynamic>);
  }

  /// Delete a checklist and its items.
  Future<void> deleteChecklist(String checklistId) async {
    await apiClient.delete('/checklists/$checklistId');
  }

  /// Add an item inside a checklist.
  Future<ChecklistItem> addItem(
    String checklistId, {
    required String title,
    String category = 'other',
    int quantity = 1,
    String? notes,
    String? photoUrl,
    int sortOrder = 0,
    String? assignedUserId,
    String? assignedTravelerId,
  }) async {
    final payload = {
      'title': title,
      'category': category,
      'quantity': quantity,
      if (notes != null) 'notes': notes,
      if (photoUrl != null) 'photo_url': photoUrl,
      'sort_order': sortOrder,
      if (assignedUserId != null) 'assigned_user_id': assignedUserId,
      if (assignedTravelerId != null)
        'assigned_traveler_id': assignedTravelerId,
    };

    final response = await apiClient.post(
      '/checklists/$checklistId/items',
      data: payload,
    );

    return ChecklistItem.fromJson(response as Map<String, dynamic>);
  }

  /// Toggle an item's packed status with optional optimistic concurrency version.
  Future<ChecklistItem> toggleItem(String itemId, {int? baseVersion}) async {
    final response = await apiClient.post(
      '/checklist-items/$itemId/toggle',
      data: {if (baseVersion != null) 'base_version': baseVersion},
    );

    return ChecklistItem.fromJson(response as Map<String, dynamic>);
  }

  /// Update item details.
  Future<ChecklistItem> updateItem(
    String itemId, {
    String? title,
    String? category,
    int? quantity,
    String? notes,
    String? photoUrl,
    bool? isPacked,
    String? assignedUserId,
    String? assignedTravelerId,
    bool clearAssignee = false,
    int? baseVersion,
  }) async {
    final payload = <String, dynamic>{
      if (title != null) 'title': title,
      if (category != null) 'category': category,
      if (quantity != null) 'quantity': quantity,
      if (notes != null) 'notes': notes,
      if (photoUrl != null) 'photo_url': photoUrl,
      if (isPacked != null) 'is_packed': isPacked,
      if (clearAssignee) ...{
        'assigned_user_id': null,
        'assigned_traveler_id': null,
      } else ...{
        if (assignedUserId != null) 'assigned_user_id': assignedUserId,
        if (assignedTravelerId != null)
          'assigned_traveler_id': assignedTravelerId,
      },
      if (baseVersion != null) 'base_version': baseVersion,
    };

    final response = await apiClient.patch(
      '/checklist-items/$itemId',
      data: payload,
    );

    return ChecklistItem.fromJson(response as Map<String, dynamic>);
  }

  /// Delete an item from a checklist.
  Future<void> deleteItem(String itemId) async {
    await apiClient.delete('/checklist-items/$itemId');
  }

  /// Upload and attach a photo to a checklist item.
  Future<ChecklistItem> uploadItemPhoto(
    String itemId, {
    required String fileName,
    required List<int> bytes,
    String? title,
    String? notes,
  }) async {
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(bytes, filename: fileName),
      if (title != null) 'title': title,
      if (notes != null) 'notes': notes,
    });

    final response = await apiClient.post(
      '/checklist-items/$itemId/photo',
      data: formData,
    );

    return ChecklistItem.fromJson(response as Map<String, dynamic>);
  }

  /// Fetch all media attachments for a trip.
  Future<List<MediaAttachment>> fetchTripMedia(
    String tripId, {
    String? attachableType,
  }) async {
    final response = await apiClient.get(
      '/trips/$tripId/media',
      queryParameters: {
        if (attachableType != null) 'attachable_type': attachableType,
      },
    );

    if (response is List) {
      return response
          .map((json) => MediaAttachment.fromJson(json as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  /// Delete a media attachment.
  Future<void> deleteMedia(String tripId, String mediaId) async {
    await apiClient.delete('/trips/$tripId/media/$mediaId');
  }
}
