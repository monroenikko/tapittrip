import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapittrip/core/network/api_client.dart';
import 'package:tapittrip/core/network/api_exceptions.dart';
import 'package:tapittrip/core/storage/token_storage.dart';
import 'package:tapittrip/core/theme/app_theme.dart';
import 'package:tapittrip/features/notifications/data/notification_repository.dart';
import 'package:tapittrip/features/notifications/domain/models/notification_preference.dart';
import 'package:tapittrip/features/notifications/domain/models/trip_reminder.dart';
import 'package:tapittrip/features/notifications/presentation/pages/notification_preferences_page.dart';
import 'package:tapittrip/features/notifications/presentation/providers/notification_provider.dart';
import 'package:tapittrip/features/notifications/services/local_notification_service.dart';

class FakeApiClient extends ApiClient {
  FakeApiClient() : super(tokenStorage: InMemoryTokenStorage());

  dynamic getResponse;
  dynamic putResponse;
  dynamic postResponse;
  bool shouldThrow = false;

  @override
  Future<dynamic> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    if (shouldThrow) {
      throw const NetworkException();
    }
    return getResponse;
  }

  @override
  Future<dynamic> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    if (shouldThrow) {
      throw const NetworkException();
    }
    return putResponse;
  }

  @override
  Future<dynamic> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    if (shouldThrow) {
      throw const NetworkException();
    }
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
  }) async {
    return _data[key];
  }

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

  @override
  Future<void> delete({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    _data.remove(key);
  }
}

void main() {
  group('NotificationPreference Model', () {
    test('parses from JSON and serializes correctly', () {
      final json = {
        'id': 'pref-123',
        'user_id': 'user-456',
        'morning_summary_enabled': true,
        'morning_summary_time': '07:30',
        'activity_reminders_enabled': true,
        'activity_reminder_lead_minutes': 45,
        'checklist_reminders_enabled': true,
        'stay_reminders_enabled': true,
        'quiet_hours_enabled': true,
        'quiet_hours_start': '23:00',
        'quiet_hours_end': '06:00',
        'geofence_arrival_enabled': true,
        'timezone_behavior': 'destination',
      };

      final pref = NotificationPreference.fromJson(json);

      expect(pref.id, 'pref-123');
      expect(pref.userId, 'user-456');
      expect(pref.morningSummaryTime, '07:30');
      expect(pref.activityReminderLeadMinutes, 45);
      expect(pref.quietHoursEnabled, isTrue);
      expect(pref.quietHoursStart, '23:00');

      final serialized = pref.toJson();
      expect(serialized['morning_summary_time'], '07:30');
      expect(serialized['activity_reminder_lead_minutes'], 45);
    });

    test('copyWith modifies attributes properly', () {
      const initial = NotificationPreference(
        id: 'pref-1',
        userId: 'user-1',
        morningSummaryTime: '08:00',
      );

      final updated = initial.copyWith(
        morningSummaryTime: '09:00',
        quietHoursEnabled: true,
      );

      expect(updated.id, 'pref-1');
      expect(updated.morningSummaryTime, '09:00');
      expect(updated.quietHoursEnabled, isTrue);
    });
  });

  group('TripReminder Model', () {
    test('parses from JSON with status flags', () {
      final json = {
        'id': 'rem-1',
        'trip_id': 'trip-1',
        'type': 'activity_reminder',
        'title': 'Depart for Fushimi Inari',
        'body': 'Starts in 30 mins.',
        'trigger_at_utc': '2026-12-01T08:30:00Z',
        'timezone': 'Asia/Tokyo',
        'delivery_channel': 'local',
        'status': 'scheduled',
        'dedupe_key': 'trip-1:activity:123',
        'source_version': 2,
      };

      final reminder = TripReminder.fromJson(json);

      expect(reminder.id, 'rem-1');
      expect(reminder.isScheduled, isTrue);
      expect(reminder.isCancelled, isFalse);
      expect(reminder.triggerAtUtc.year, 2026);
    });
  });

  group('LocalNotificationService', () {
    test('detects quiet hours correctly spanning midnight and same day', () {
      final service = LocalNotificationService();

      // Overnight 22:00 to 07:00
      final atNight = DateTime(2026, 12, 1, 23, 30);
      final earlyMorning = DateTime(2026, 12, 1, 6, 15);
      final midDay = DateTime(2026, 12, 1, 14, 0);

      expect(service.isInQuietHours(atNight, '22:00', '07:00'), isTrue);
      expect(service.isInQuietHours(earlyMorning, '22:00', '07:00'), isTrue);
      expect(service.isInQuietHours(midDay, '22:00', '07:00'), isFalse);
    });

    test(
      'scheduleRemindersForTrip filters quiet hours and persists offline',
      () async {
        final storage = FakeSecureStorage();
        final service = LocalNotificationService(storage: storage);

        const prefs = NotificationPreference(
          id: 'pref-1',
          userId: 'user-1',
          quietHoursEnabled: true,
          quietHoursStart: '22:00',
          quietHoursEnd: '07:00',
        );

        final daytimeReminder = TripReminder(
          id: 'rem-day',
          tripId: 'trip-1',
          type: 'activity_reminder',
          title: 'Lunch at Nishiki Market',
          body: 'Starts soon',
          triggerAtUtc: DateTime(2026, 12, 1, 11, 30),
          timezone: 'Asia/Tokyo',
          dedupeKey: 'key-1',
        );

        final nightReminder = TripReminder(
          id: 'rem-night',
          tripId: 'trip-1',
          type: 'activity_reminder',
          title: 'Late Midnight Snack',
          body: 'Starts soon',
          triggerAtUtc: DateTime(2026, 12, 1, 23, 45),
          timezone: 'Asia/Tokyo',
          dedupeKey: 'key-2',
        );

        final scheduled = await service.scheduleRemindersForTrip(
          tripId: 'trip-1',
          reminders: [daytimeReminder, nightReminder],
          preferences: prefs,
        );

        expect(scheduled.length, 1);
        expect(scheduled.first.id, 'rem-day');

        // Verify offline persistence
        final cached = await service.getScheduledReminders('trip-1');
        expect(cached.length, 1);
        expect(cached.first.id, 'rem-day');

        // Verify cancellation
        await service.cancelRemindersForTrip('trip-1');
        final cleared = await service.getScheduledReminders('trip-1');
        expect(cleared.isEmpty, isTrue);
      },
    );
  });

  group('NotificationRepository', () {
    test('fetches preferences with offline fallback', () async {
      final apiClient = FakeApiClient();
      final storage = FakeSecureStorage({
        'cached_notification_preferences': jsonEncode({
          'id': 'cached-pref',
          'user_id': 'user-1',
          'morning_summary_time': '06:45',
        }),
      });

      final repository = NotificationRepository(
        apiClient: apiClient,
        storage: storage,
      );

      // Successful API call
      apiClient.getResponse = {
        'id': 'live-pref',
        'user_id': 'user-1',
        'morning_summary_time': '07:00',
      };
      final live = await repository.fetchPreferences();
      expect(live.morningSummaryTime, '07:00');

      // Network failure -> offline cached fallback
      apiClient.shouldThrow = true;
      final cached = await repository.fetchPreferences();
      expect(cached.morningSummaryTime, '07:00'); // updated in storage
    });
  });

  group('NotificationPreferencesPage Widget', () {
    testWidgets('renders switches and lead time chips', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final fakeApi = FakeApiClient();
      fakeApi.getResponse = {
        'id': 'pref-1',
        'user_id': 'user-1',
        'morning_summary_enabled': true,
        'morning_summary_time': '08:00',
        'activity_reminders_enabled': true,
        'activity_reminder_lead_minutes': 30,
        'checklist_reminders_enabled': true,
        'stay_reminders_enabled': true,
        'quiet_hours_enabled': true,
        'quiet_hours_start': '22:00',
        'quiet_hours_end': '07:00',
        'geofence_arrival_enabled': true,
        'timezone_behavior': 'destination',
      };

      final fakeStorage = FakeSecureStorage();
      final repo = NotificationRepository(
        apiClient: fakeApi,
        storage: fakeStorage,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [notificationRepositoryProvider.overrideWithValue(repo)],
          child: MaterialApp(
            theme: AppTheme.light(),
            home: const NotificationPreferencesPage(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Notification Preferences'), findsOneWidget);
      expect(find.text('Daily Itinerary Overview'), findsOneWidget);
      expect(find.text('Morning Summary'), findsOneWidget);
      expect(find.text('08:00'), findsOneWidget);
      expect(find.text('Upcoming Activity Reminders'), findsOneWidget);
      expect(find.text('30 mins'), findsOneWidget);
      expect(find.text('Enable Quiet Hours'), findsOneWidget);
      expect(find.text('Geofence Arrival Suggestions'), findsOneWidget);
    });
  });
}
