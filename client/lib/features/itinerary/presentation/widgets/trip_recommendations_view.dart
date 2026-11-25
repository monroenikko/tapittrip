import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../localization/recommendations_strings.dart';
import '../providers/itinerary_provider.dart';
import '../providers/recommendations_provider.dart';
import 'recommendation_link_actions.dart';

class TripRecommendationsView extends ConsumerWidget {
  const TripRecommendationsView({
    super.key,
    required this.tripId,
    this.destination,
  });

  final String tripId;
  final String? destination;

  String _query(String title, Object? place, Object? context) => [
    if (place is String && place.trim().isNotEmpty) place.trim() else title,
    if (context is String && context.trim().isNotEmpty) context.trim(),
  ].join(', ');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final strings = RecommendationsStrings(Localizations.localeOf(context));
    final items = ref.watch(itineraryListProvider(tripId)).asData?.value ?? [];
    final suggestions = ref.watch(tripRecommendationsProvider(tripId));
    final existing = <String>{
      for (final item in items) item.title.trim().toLowerCase(),
      for (final item in items)
        if (item.place != null) item.place!.name.trim().toLowerCase(),
    };

    if (items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Text(strings.empty),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(strings.plannedHeading, style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        for (final item in items)
          Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ListTile(
                  leading: const Icon(Icons.event_available_outlined),
                  title: Text(item.title),
                  subtitle: Text(
                    [
                      strings.planned,
                      if (item.day != null) item.day!.displayHeader,
                      if (item.place != null) item.place!.name,
                    ].join(' • '),
                  ),
                ),
                RecommendationLinkActions(
                  query: _query(
                    item.title,
                    item.place?.name,
                    item.place?.formattedAddress ?? destination,
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 24),
        Text(strings.suggestedHeading, style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        suggestions.when(
          skipLoadingOnRefresh: false,
          loading: () => Column(
            children: [
              const LinearProgressIndicator(),
              const SizedBox(height: 8),
              Text(strings.loading),
            ],
          ),
          error: (_, _) => Column(
            children: [
              Text(strings.error),
              TextButton(
                onPressed: () =>
                    ref.invalidate(tripRecommendationsProvider(tripId)),
                child: Text(strings.retry),
              ),
            ],
          ),
          data: (response) {
            final isAi = response?.contextSummary['source'] == 'gemini';
            final seen = {...existing};
            final actions =
                response?.suggestedActions.where((action) {
                  final title = action.payload['title'];
                  final place = action.payload['place_name'];
                  if (action.kind != 'add_activity' ||
                      title is! String ||
                      title.trim().isEmpty) {
                    return false;
                  }
                  if (place is String &&
                      seen.contains(place.trim().toLowerCase())) {
                    return false;
                  }
                  if (!seen.add(title.trim().toLowerCase())) {
                    return false;
                  }
                  if (place is String) {
                    seen.add(place.trim().toLowerCase());
                  }
                  return true;
                }).toList() ??
                [];
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(isAi ? strings.aiSource : strings.fallbackSource),
                if (actions.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Text(strings.noSuggestions),
                  ),
                for (final action in actions)
                  Card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ListTile(
                          leading: Icon(
                            isAi
                                ? Icons.auto_awesome_outlined
                                : Icons.lightbulb_outline,
                          ),
                          title: Text(action.payload['title'] as String),
                          subtitle: action.payload['notes'] is String
                              ? Text(action.payload['notes'] as String)
                              : null,
                        ),
                        RecommendationLinkActions(
                          query: _query(
                            action.payload['title'] as String,
                            action.payload['place_name'],
                            response?.contextSummary['destination'] ??
                                destination,
                          ),
                        ),
                      ],
                    ),
                  ),
                Text(strings.advisory),
              ],
            );
          },
        ),
      ],
    );
  }
}
