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

  static const Map<String, double> _ianaUtcOffsetHours = {
    'UTC': 0,
    'Etc/UTC': 0,
    'Europe/London': 0,
    'Europe/Paris': 1,
    'Europe/Rome': 1,
    'Europe/Madrid': 1,
    'Europe/Berlin': 1,
    'Asia/Bangkok': 7,
    'Asia/Jakarta': 7,
    'Asia/Manila': 8,
    'Asia/Singapore': 8,
    'Asia/Makassar': 8,
    'Asia/Taipei': 8,
    'Asia/Hong_Kong': 8,
    'Asia/Kuala_Lumpur': 8,
    'Asia/Tokyo': 9,
    'Asia/Seoul': 9,
    'Australia/Sydney': 10,
    'America/New_York': -5,
    'America/Chicago': -6,
    'America/Denver': -7,
    'America/Los_Angeles': -8,
  };

  /// Schedule reminders for a trip, filtering out quiet hours and duplicate triggers.
  Future<List<TripReminder>> scheduleRemindersForTrip({
    required String tripId,
    required List<TripReminder> reminders,
    required NotificationPreference preferences,
    String? homeTimezone,
  }) async {
    final activeScheduled = <TripReminder>[];

    for (final reminder in reminders) {
      if (reminder.status != 'scheduled') {
        continue;
      }

      // Evaluate quiet hours against destination or home wall-clock time
      if (preferences.quietHoursEnabled) {
        final wallClock = _resolveWallClockForQuietHours(
          reminder,
          preferences,
          homeTimezone: homeTimezone,
        );
        if (isInQuietHours(
          wallClock,
          preferences.quietHoursStart,
          preferences.quietHoursEnd,
        )) {
          continue;
        }
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

  DateTime _resolveWallClockForQuietHours(
    TripReminder reminder,
    NotificationPreference preferences, {
    String? homeTimezone,
  }) {
    if (preferences.timezoneBehavior == 'home') {
      if (homeTimezone != null &&
          _ianaUtcOffsetHours.containsKey(homeTimezone)) {
        final offsetMins = (_ianaUtcOffsetHours[homeTimezone]! * 60).round();
        return reminder.triggerAtUtc.toUtc().add(Duration(minutes: offsetMins));
      }
      if (reminder.triggerAtUtc.isUtc) {
        return reminder.triggerAtUtc.toLocal();
      }
      return reminder.triggerAtUtc;
    }

    if (reminder.triggerLocalTime != null &&
        RegExp(r'^\d{2}:\d{2}$').hasMatch(reminder.triggerLocalTime!)) {
      final parts = reminder.triggerLocalTime!.split(':');
      return DateTime(
        reminder.triggerAtUtc.year,
        reminder.triggerAtUtc.month,
        reminder.triggerAtUtc.day,
        int.parse(parts[0]),
        int.parse(parts[1]),
      );
    }

    if (reminder.triggerAtUtc.isUtc &&
        _ianaUtcOffsetHours.containsKey(reminder.timezone)) {
      final offsetMins = (_ianaUtcOffsetHours[reminder.timezone]! * 60).round();
      return reminder.triggerAtUtc.toUtc().add(Duration(minutes: offsetMins));
    }

    return reminder.triggerAtUtc;
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
