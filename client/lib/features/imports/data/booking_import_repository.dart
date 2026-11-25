import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exceptions.dart';
import '../domain/models/booking_import.dart';

class BookingImportRepository {
  BookingImportRepository({
    required this.apiClient,
    FlutterSecureStorage? storage,
  }) : _storage = storage ?? const FlutterSecureStorage();

  final ApiClient apiClient;
  final FlutterSecureStorage _storage;

  String _cacheKey(String tripId) => 'cached_booking_imports_$tripId';

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

  Future<List<BookingImport>> listImports(String tripId) async {
    try {
      final response = await apiClient.get('/trips/$tripId/imports');
      final list = _extractList(response);
      final imports = list
          .whereType<Map>()
          .map(
            (item) => BookingImport.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList();
      await _saveCache(tripId, imports);
      return imports;
    } on ApiException catch (e) {
      if (e.statusCode == 403) {
        await _storage.delete(key: _cacheKey(tripId));
        rethrow;
      }
    } catch (_) {
      // Fall through to cached data
    }

    return _readCache(tripId);
  }

  Future<BookingImport> createImport(
    String tripId, {
    required String rawText,
    String? bookingType,
    String? source,
    String? clientOperationId,
  }) async {
    final payload = <String, dynamic>{
      'raw_text': rawText,
      'booking_type': ?bookingType,
      'source': source ?? 'paste_text',
      'client_operation_id': ?clientOperationId,
    };

    final response = await apiClient.post(
      '/trips/$tripId/imports',
      data: payload,
    );
    final map = _extractMap(response);
    if (map == null) {
      throw const ApiException(
        code: 'parse_error',
        message: 'Invalid response from booking import creation',
      );
    }

    return BookingImport.fromJson(map);
  }

  Future<BookingImport> createImportFromFile(
    String tripId, {
    required List<int> bytes,
    required String filename,
    String? rawText,
    String? bookingType,
    String? clientOperationId,
  }) async {
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(bytes, filename: filename),
      'source': 'upload_file',
      if (rawText != null && rawText.trim().isNotEmpty)
        'raw_text': rawText.trim(),
      'booking_type': ?bookingType,
      'client_operation_id': ?clientOperationId,
    });

    final response = await apiClient.post(
      '/trips/$tripId/imports',
      data: formData,
    );
    final map = _extractMap(response);
    if (map == null) {
      throw const ApiException(
        code: 'parse_error',
        message: 'Invalid response from booking file import',
      );
    }

    return BookingImport.fromJson(map);
  }

  Future<BookingImport> confirmImport(
    String importId, {
    required int baseVersion,
    required String bookingType,
    Map<String, dynamic>? flight,
    Map<String, dynamic>? stay,
    Map<String, dynamic>? activity,
  }) async {
    final payload = <String, dynamic>{
      'base_version': baseVersion,
      'booking_type': bookingType,
      'flight': ?flight,
      'stay': ?stay,
      'activity': ?activity,
    };

    final response = await apiClient.post(
      '/imports/$importId/confirm',
      data: payload,
    );
    final map = _extractMap(response);
    if (map == null) {
      throw const ApiException(
        code: 'confirmation_error',
        message: 'Invalid response from booking confirmation',
      );
    }

    return BookingImport.fromJson(map);
  }

  Future<void> deleteImport(String importId) async {
    await apiClient.delete('/imports/$importId');
  }

  Future<void> _saveCache(String tripId, List<BookingImport> imports) async {
    try {
      final jsonList = imports.map((i) => i.toJson()).toList();
      await _storage.write(key: _cacheKey(tripId), value: jsonEncode(jsonList));
    } catch (_) {}
  }

  Future<List<BookingImport>> _readCache(String tripId) async {
    try {
      final raw = await _storage.read(key: _cacheKey(tripId));
      if (raw == null || raw.isEmpty) return const [];
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded
            .whereType<Map>()
            .map(
              (item) => BookingImport.fromJson(Map<String, dynamic>.from(item)),
            )
            .toList();
      }
    } catch (_) {}
    return const [];
  }
}
