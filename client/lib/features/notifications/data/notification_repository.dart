// ignore_for_file: use_null_aware_elements

import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exceptions.dart';
import '../domain/models/notification_preference.dart';
import '../domain/models/trip_reminder.dart';

class NotificationRepository {
  NotificationRepository({
    required this.apiClient,
    FlutterSecureStorage? storage,
  }) : _storage = storage ?? const FlutterSecureStorage();

  final ApiClient apiClient;
  final FlutterSecureStorage _storage;

  static const String _prefCacheKey = 'cached_notification_preferences';
  String _remindersCacheKey(String tripId) => 'cached_reminders_$tripId';

  /// Fetch user notification preferences with offline cache fallback.
  Future<NotificationPreference> fetchPreferences() async {
    try {
      final response = await apiClient.get('/me/notification-preferences');
      if (response is Map<String, dynamic>) {
        await _storage.write(key: _prefCacheKey, value: jsonEncode(response));
        return NotificationPreference.fromJson(response);
      }
      return const NotificationPreference(id: 'default', userId: 'default');
    } on ApiException {
      return _loadCachedPreferences();
    } catch (_) {
      return _loadCachedPreferences();
    }
  }

  Future<NotificationPreference> _loadCachedPreferences() async {
    final cached = await _storage.read(key: _prefCacheKey);
    if (cached != null) {
      final data = jsonDecode(cached) as Map<String, dynamic>;
      return NotificationPreference.fromJson(data);
    }
    return const NotificationPreference(id: 'default', userId: 'default');
  }

  /// Update user notification preferences.
  Future<NotificationPreference> updatePreferences(
    Map<String, dynamic> updates,
  ) async {
    final response = await apiClient.put(
      '/me/notification-preferences',
      data: updates,
    );

    if (response is Map<String, dynamic>) {
      await _storage.write(key: _prefCacheKey, value: jsonEncode(response));
      return NotificationPreference.fromJson(response);
    }

    return fetchPreferences();
  }

  /// Register or update device push token.
  Future<void> registerDevice({
    required String platform,
    required String deviceKey,
    String? pushToken,
  }) async {
    await apiClient.post(
      '/devices/register',
      data: {
        'platform': platform,
        'device_key': deviceKey,
        if (pushToken != null) 'push_token': pushToken,
      },
    );
  }

  /// Fetch scheduled reminders for a trip with offline caching.
  Future<List<TripReminder>> fetchTripReminders(
    String tripId, {
    String? status,
  }) async {
    try {
      final queryParams = status != null ? {'status': status} : null;
      final response = await apiClient.get(
        '/trips/$tripId/reminders',
        queryParameters: queryParams,
      );

      if (response is List) {
        await _storage.write(
          key: _remindersCacheKey(tripId),
          value: jsonEncode(response),
        );

        return response
            .map((json) => TripReminder.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      return [];
    } on ApiException {
      return _loadCachedReminders(tripId);
    } catch (_) {
      return _loadCachedReminders(tripId);
    }
  }

  Future<List<TripReminder>> _loadCachedReminders(String tripId) async {
    final cached = await _storage.read(key: _remindersCacheKey(tripId));
    if (cached != null) {
      final data = jsonDecode(cached) as List<dynamic>;
      return data
          .map((json) => TripReminder.fromJson(json as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  /// Trigger recalculation of reminders on server.
  Future<List<TripReminder>> generateTripReminders(String tripId) async {
    final response = await apiClient.post(
      '/trips/$tripId/reminders/generate',
      data: {},
    );

    if (response is List) {
      await _storage.write(
        key: _remindersCacheKey(tripId),
        value: jsonEncode(response),
      );

      return response
          .map((json) => TripReminder.fromJson(json as Map<String, dynamic>))
          .toList();
    }
    return [];
  }
}
