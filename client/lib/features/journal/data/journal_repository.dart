import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../core/network/api_client.dart';
import '../domain/models/journal_entry.dart';

class JournalRepository {
  JournalRepository({required this.apiClient, FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  final ApiClient apiClient;
  final FlutterSecureStorage _storage;

  Future<List<JournalEntry>> getJournalEntries(
    String tripId, {
    String? date,
  }) async {
    final queryParams = <String, dynamic>{};
    if (date != null && date.isNotEmpty) {
      queryParams['date'] = date;
    }

    try {
      final response = await apiClient.get(
        '/trips/$tripId/journal',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );
      final rawList = (response['data'] as List<dynamic>?) ?? [];
      final entries = rawList
          .map((item) => JournalEntry.fromJson(item as Map<String, dynamic>))
          .toList();

      if (date == null) {
        await _storage.write(
          key: 'cached_journal_$tripId',
          value: jsonEncode(rawList),
        );
      }

      return entries;
    } catch (_) {
      final cached = await _storage.read(key: 'cached_journal_$tripId');
      if (cached != null) {
        final rawList = jsonDecode(cached) as List<dynamic>;
        var entries = rawList
            .map((item) => JournalEntry.fromJson(item as Map<String, dynamic>))
            .toList();
        if (date != null && date.isNotEmpty) {
          entries = entries.where((e) => e.entryDate == date).toList();
        }
        return entries;
      }
      rethrow;
    }
  }

  Future<JournalEntry> createJournalEntry(
    String tripId, {
    required String title,
    required String content,
    required String entryDate,
    String? locationName,
    String? weather,
    String? mood,
    bool isShared = false,
    String? itineraryItemId,
    List<String>? photos,
  }) async {
    final payload = <String, dynamic>{
      'title': title,
      'content': content,
      'entry_date': entryDate,
      'is_shared': isShared,
    };
    if (locationName != null) payload['location_name'] = locationName;
    if (weather != null) payload['weather'] = weather;
    if (mood != null) payload['mood'] = mood;
    if (itineraryItemId != null) payload['itinerary_item_id'] = itineraryItemId;
    if (photos != null && photos.isNotEmpty) payload['photos'] = photos;

    final response = await apiClient.post(
      '/trips/$tripId/journal',
      data: payload,
    );
    final data = response['data'] as Map<String, dynamic>;
    return JournalEntry.fromJson(data);
  }

  Future<JournalEntry> updateJournalEntry(
    String entryId, {
    String? title,
    String? content,
    String? entryDate,
    String? locationName,
    String? weather,
    String? mood,
    bool? isShared,
    String? itineraryItemId,
    List<String>? photos,
  }) async {
    final payload = <String, dynamic>{};
    if (title != null) payload['title'] = title;
    if (content != null) payload['content'] = content;
    if (entryDate != null) payload['entry_date'] = entryDate;
    if (locationName != null) payload['location_name'] = locationName;
    if (weather != null) payload['weather'] = weather;
    if (mood != null) payload['mood'] = mood;
    if (isShared != null) payload['is_shared'] = isShared;
    if (itineraryItemId != null) payload['itinerary_item_id'] = itineraryItemId;
    if (photos != null) payload['photos'] = photos;

    final response = await apiClient.patch(
      '/journal-entries/$entryId',
      data: payload,
    );
    final data = response['data'] as Map<String, dynamic>;
    return JournalEntry.fromJson(data);
  }

  Future<void> deleteJournalEntry(String entryId) async {
    await apiClient.delete('/journal-entries/$entryId');
  }

  Future<JournalEntry> uploadPhoto(
    String entryId, {
    required String fileName,
    required List<int> bytes,
  }) async {
    final formData = FormData.fromMap({
      'photo': MultipartFile.fromBytes(bytes, filename: fileName),
    });

    final response = await apiClient.post(
      '/journal-entries/$entryId/photos',
      data: formData,
    );
    final data = response['data'] as Map<String, dynamic>;
    return JournalEntry.fromJson(data);
  }
}

final journalRepositoryProvider = Provider<JournalRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return JournalRepository(apiClient: apiClient);
});
