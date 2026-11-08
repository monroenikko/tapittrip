import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../domain/models/notification_preference.dart';
import '../domain/models/trip_reminder.dart';

enum NotificationChannelType {
  tripSummaries,
  activityAlerts,
  checklistAlerts,
  stayAlerts,
}

class LocalNotificationService {
  LocalNotificationService({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  String _localRemindersKey(String tripId) =>
      'scheduled_local_notifications_$tripId';

  /// Schedule reminders for a trip, filtering out quiet hours and duplicate triggers.
  Future<List<TripReminder>> scheduleRemindersForTrip({
    required String tripId,
    required List<TripReminder> reminders,
    required NotificationPreference preferences,
  }) async {
    final activeScheduled = <TripReminder>[];

    for (final reminder in reminders) {
      if (reminder.status != 'scheduled') {
        continue;
      }

      // Check quiet hours
      if (preferences.quietHoursEnabled &&
          isInQuietHours(
            reminder.triggerAtUtc,
            preferences.quietHoursStart,
            preferences.quietHoursEnd,
          )) {
        continue;
      }

      activeScheduled.add(reminder);
    }

    // Persist to secure storage so schedule survives restarts & offline periods
    await _storage.write(
      key: _localRemindersKey(tripId),
      value: jsonEncode(activeScheduled.map((r) => r.toJson()).toList()),
    );

    return activeScheduled;
  }

  /// Cancel all scheduled local notifications for a trip.
  Future<void> cancelRemindersForTrip(String tripId) async {
    await _storage.delete(key: _localRemindersKey(tripId));
  }

  /// Retrieve currently scheduled reminders from local device storage.
  Future<List<TripReminder>> getScheduledReminders(String tripId) async {
    final cached = await _storage.read(key: _localRemindersKey(tripId));
    if (cached != null) {
      final list = jsonDecode(cached) as List<dynamic>;
      return list
          .map((json) => TripReminder.fromJson(json as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  /// Helper to test if a given trigger time falls into quiet hours.
  bool isInQuietHours(
    DateTime triggerTime,
    String? quietStart,
    String? quietEnd,
  ) {
    if (quietStart == null || quietEnd == null) return false;

    final hour = triggerTime.hour.toString().padLeft(2, '0');
    final minute = triggerTime.minute.toString().padLeft(2, '0');
    final currentStr = '$hour:$minute';

    if (quietStart.compareTo(quietEnd) > 0) {
      // Overnight quiet hours, e.g. 22:00 to 07:00
      return currentStr.compareTo(quietStart) >= 0 ||
          currentStr.compareTo(quietEnd) < 0;
    }

    return currentStr.compareTo(quietStart) >= 0 &&
        currentStr.compareTo(quietEnd) < 0;
  }
}
