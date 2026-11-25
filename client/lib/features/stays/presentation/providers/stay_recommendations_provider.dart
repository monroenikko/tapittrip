import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../itinerary/domain/models/trip_assistant_response.dart';
import '../../../itinerary/presentation/providers/itinerary_provider.dart';
import '../../data/stay_recommendation_repository.dart';
import 'stay_provider.dart';

final _stayRecommendationContextProvider = Provider.autoDispose
    .family<String?, String>((ref, tripId) {
      final stays = ref.watch(stayListProvider(tripId)).asData?.value;
      if (stays == null || stays.isNotEmpty) return null;
      final items = ref.watch(itineraryListProvider(tripId)).asData?.value;
      if (items == null) return null;
      return jsonEncode([
        for (final item in items)
          [item.id, item.version, item.title, item.tripDayId, item.place?.name],
      ]);
    });

final stayRecommendationsProvider = FutureProvider.autoDispose
    .family<TripAssistantResponse?, String>((ref, tripId) async {
      final context = ref.watch(_stayRecommendationContextProvider(tripId));
      if (context == null) return null;
      final repository = ref.watch(stayRecommendationRepositoryProvider);
      await Future<void>.delayed(const Duration(milliseconds: 600));
      if (!ref.mounted) return null;
      return repository.fetch(tripId);
    }, retry: (_, _) => null);
