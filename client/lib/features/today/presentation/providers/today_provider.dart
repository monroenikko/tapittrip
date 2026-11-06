import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../data/today_repository.dart';
import '../../domain/models/today_dashboard_summary.dart';

final todayRepositoryProvider = Provider<TodayRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return TodayRepository(apiClient: apiClient);
});

/// Live Today summary provider parameterized by tripId.
final todaySummaryProvider =
    FutureProvider.family<TodayDashboardSummary, String>((ref, tripId) async {
      final repository = ref.watch(todayRepositoryProvider);
      return repository.fetchTodaySummary(tripId);
    });

class ActiveTripNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void selectTrip(String? tripId) => state = tripId;
}

/// Currently selected active trip id for the dashboard.
final activeDashboardTripIdProvider =
    NotifierProvider<ActiveTripNotifier, String?>(ActiveTripNotifier.new);
