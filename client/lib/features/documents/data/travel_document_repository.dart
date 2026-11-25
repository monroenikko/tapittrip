import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exceptions.dart';
import '../domain/models/travel_document.dart';

class TravelDocumentRepository {
  TravelDocumentRepository({
    required this.apiClient,
    FlutterSecureStorage? storage,
  }) : _storage = storage ?? const FlutterSecureStorage();

  final ApiClient apiClient;
  final FlutterSecureStorage _storage;

  String _cacheKey(String tripId) => 'cached_documents_$tripId';

  List<dynamic> _extractList(dynamic response) {
    if (response is List) {
      return response;
    }
    if (response is Map && response['data'] is List) {
      return response['data'] as List<dynamic>;
    }
    return const [];
  }

  Map<String, dynamic>? _extractMap(dynamic response) {
    if (response is Map && response['data'] is Map) {
      return Map<String, dynamic>.from(response['data'] as Map);
    }
    if (response is Map) {
      return Map<String, dynamic>.from(response);
    }
    return null;
  }

  Future<List<TravelDocument>> listDocuments(String tripId) async {
    try {
      final response = await apiClient.get('/trips/$tripId/documents');
      final list = _extractList(response);
      final docs = list
          .whereType<Map>()
          .map(
            (item) => TravelDocument.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList();
      await _saveCache(tripId, docs);
      return docs;
    } on ApiException catch (e) {
      if (e.statusCode == 403) {
        await _storage.delete(key: _cacheKey(tripId));
        rethrow;
      }
    } catch (_) {
      // Fall through to cached documents
    }

    return _readCache(tripId);
  }

  Future<TravelDocument> createDocument(
    String tripId, {
    required String documentType,
    required String displayName,
    String? issuer,
    String? referenceNumber,
    String? notesPrivate,
    String? expiresOn,
    String accessPolicy = 'owner_only',
    String? clientOperationId,
  }) async {
    final response = await apiClient.post(
      '/trips/$tripId/documents',
      data: {
        'document_type': documentType,
        'display_name': displayName,
        if (issuer != null && issuer.trim().isNotEmpty) 'issuer': issuer.trim(),
        if (referenceNumber != null && referenceNumber.trim().isNotEmpty)
          'reference_number': referenceNumber.trim(),
        if (notesPrivate != null && notesPrivate.trim().isNotEmpty)
          'notes_private': notesPrivate.trim(),
        if (expiresOn != null && expiresOn.trim().isNotEmpty)
          'expires_on': expiresOn.trim(),
        'access_policy': accessPolicy,
        'client_operation_id': ?clientOperationId,
      },
    );

    final map = _extractMap(response);
    if (map != null) {
      final created = TravelDocument.fromJson(map);
      final current = await _readCache(tripId);
      final updated = [created, ...current.where((d) => d.id != created.id)];
      await _saveCache(tripId, updated);
      return created;
    }

    throw const ApiException(
      code: 'invalid_response',
      message: 'Failed to save travel document.',
    );
  }

  Future<TravelDocument> uploadAttachment(
    String tripId,
    String documentId, {
    required List<int> bytes,
    required String filename,
  }) async {
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(bytes, filename: filename),
    });

    final response = await apiClient.post(
      '/documents/$documentId/attachment',
      data: formData,
    );

    final map = _extractMap(response);
    if (map != null) {
      final updatedDoc = TravelDocument.fromJson(map);
      final current = await _readCache(tripId);
      final next = [
        for (final doc in current) doc.id == updatedDoc.id ? updatedDoc : doc,
      ];
      await _saveCache(tripId, next);
      return updatedDoc;
    }

    throw const ApiException(
      code: 'invalid_response',
      message: 'Failed to upload encrypted document attachment.',
    );
  }

  Future<TravelDocument> updateDocument(
    String tripId,
    String documentId, {
    required int baseVersion,
    String? documentType,
    String? displayName,
    String? issuer,
    String? referenceNumber,
    String? notesPrivate,
    String? expiresOn,
    String? accessPolicy,
  }) async {
    final response = await apiClient.patch(
      '/documents/$documentId',
      data: {
        'base_version': baseVersion,
        'document_type': ?documentType,
        if (displayName != null) 'display_name': displayName.trim(),
        'issuer': issuer?.trim(),
        'reference_number': referenceNumber?.trim(),
        'notes_private': notesPrivate?.trim(),
        'expires_on': expiresOn != null && expiresOn.trim().isNotEmpty
            ? expiresOn.trim()
            : null,
        'access_policy': ?accessPolicy,
      },
    );

    final map = _extractMap(response);
    if (map != null) {
      final updatedDoc = TravelDocument.fromJson(map);
      final current = await _readCache(tripId);
      final updated = current
          .map((d) => d.id == updatedDoc.id ? updatedDoc : d)
          .toList();
      await _saveCache(tripId, updated);
      return updatedDoc;
    }

    throw const ApiException(
      code: 'invalid_response',
      message: 'Failed to update travel document.',
    );
  }

  Future<void> deleteDocument(String tripId, String documentId) async {
    await apiClient.delete('/documents/$documentId');
    final current = await _readCache(tripId);
    await _saveCache(tripId, current.where((d) => d.id != documentId).toList());
  }

  Future<List<TravelDocument>> _readCache(String tripId) async {
    final raw = await _storage.read(key: _cacheKey(tripId));
    if (raw == null || raw.isEmpty) return const [];
    final decoded = jsonDecode(raw);
    if (decoded is List) {
      return decoded
          .whereType<Map>()
          .map((e) => TravelDocument.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }
    return const [];
  }

  Future<void> _saveCache(String tripId, List<TravelDocument> docs) async {
    await _storage.write(
      key: _cacheKey(tripId),
      value: jsonEncode(docs.map((e) => e.toJson()).toList()),
    );
  }
}
