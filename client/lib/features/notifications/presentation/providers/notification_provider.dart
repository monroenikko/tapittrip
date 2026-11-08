import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../data/notification_repository.dart';
import '../../domain/models/notification_preference.dart';
import '../../domain/models/trip_reminder.dart';
import '../../services/local_notification_service.dart';

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return NotificationRepository(apiClient: apiClient);
});

final localNotificationServiceProvider = Provider<LocalNotificationService>((
  ref,
) {
  return LocalNotificationService();
});

class NotificationPreferencesNotifier
    extends AsyncNotifier<NotificationPreference> {
  late final NotificationRepository _repository;

  @override
  Future<NotificationPreference> build() async {
    _repository = ref.watch(notificationRepositoryProvider);
    return _repository.fetchPreferences();
  }

  Future<void> updatePreferences(Map<String, dynamic> updates) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => _repository.updatePreferences(updates),
    );
  }
}

final notificationPreferencesProvider =
    AsyncNotifierProvider<
      NotificationPreferencesNotifier,
      NotificationPreference
    >(NotificationPreferencesNotifier.new);

class TripRemindersNotifier extends AsyncNotifier<List<TripReminder>> {
  TripRemindersNotifier(this.tripId);

  final String tripId;
  late final NotificationRepository _repository;
  late final LocalNotificationService _localNotificationService;

  @override
  Future<List<TripReminder>> build() async {
    _repository = ref.watch(notificationRepositoryProvider);
    _localNotificationService = ref.watch(localNotificationServiceProvider);
    return _repository.fetchTripReminders(tripId);
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => _repository.fetchTripReminders(tripId),
    );
  }

  Future<List<TripReminder>> generateReminders(
    NotificationPreference preferences,
  ) async {
    state = const AsyncValue.loading();
    final result = await _repository.generateTripReminders(tripId);

    // Sync to local notification scheduling
    await _localNotificationService.scheduleRemindersForTrip(
      tripId: tripId,
      reminders: result,
      preferences: preferences,
    );

    state = AsyncValue.data(result);
    return result;
  }
}

final tripRemindersProvider =
    AsyncNotifierProvider.family<
      TripRemindersNotifier,
      List<TripReminder>,
      String
    >(TripRemindersNotifier.new);
