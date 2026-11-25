import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../itinerary/presentation/providers/itinerary_provider.dart';
import '../../../itinerary/presentation/widgets/recommendation_link_actions.dart';
import '../providers/stay_provider.dart';
import '../providers/stay_recommendations_provider.dart';

class StayRecommendationsView extends ConsumerWidget {
  const StayRecommendationsView({super.key, required this.tripId});

  final String tripId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stays = ref.watch(stayListProvider(tripId)).asData?.value;
    if (stays == null || stays.isNotEmpty) return const SizedBox.shrink();
    final items = ref.watch(itineraryListProvider(tripId)).asData?.value;
    final response = ref.watch(stayRecommendationsProvider(tripId));
    final fil = [
      'fil',
      'tl',
    ].contains(Localizations.localeOf(context).languageCode);
    String copy(String en, String tl) => fil ? tl : en;

    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            copy('Ideas for where to stay', 'Mga ideya kung saan tutuloy'),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            items?.isNotEmpty == true
                ? copy(
                    'Based on your planned stops. These are ideas to research, not bookings.',
                    'Batay sa iyong mga nakaplanong lugar. Mga ideya lamang ito, hindi mga booking.',
                  )
                : copy(
                    'Without itinerary stops, ideas use your trip destination.',
                    'Kung wala pang itinerary, gagamitin ang destinasyon ng iyong biyahe.',
                  ),
          ),
          const SizedBox(height: 12),
          if (items == null)
            Text(
              copy(
                'Load your itinerary to get stay ideas.',
                'I-load ang itinerary para makakuha ng mga ideya.',
              ),
            )
          else
            response.when(
              skipLoadingOnRefresh: false,
              loading: () => const LinearProgressIndicator(),
              error: (_, _) => Column(
                children: [
                  Text(
                    copy(
                      'Stay ideas are unavailable. You can still add your own accommodation.',
                      'Hindi makuha ang mga ideya. Maaari ka pa ring magdagdag ng sariling tutuluyan.',
                    ),
                  ),
                  TextButton(
                    onPressed: () =>
                        ref.invalidate(stayRecommendationsProvider(tripId)),
                    child: Text(copy('Retry stay ideas', 'Subukang muli')),
                  ),
                ],
              ),
              data: (result) {
                if (result?.contextSummary['status'] == 'stay_exists') {
                  return const SizedBox.shrink();
                }
                if (result?.contextSummary['source'] != 'gemini') {
                  return Text(
                    copy(
                      'AI stay ideas are unavailable right now. Consider an area near several of your stops and confirm transport options before booking.',
                      'Walang AI na mungkahi sa ngayon. Isaalang-alang ang lugar na malapit sa ilan sa iyong mga pupuntahan at suriin ang transportasyon bago mag-book.',
                    ),
                  );
                }
                final seen = <String>{};
                final ideas = result!.suggestedActions.where((action) {
                  final title = action.payload['title'];
                  return action.kind == 'add_activity' &&
                      action.payload['kind'] == 'hotel' &&
                      title is String &&
                      title.trim().isNotEmpty &&
                      seen.add(title.trim().toLowerCase());
                });
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      copy(
                        'AI-generated • Verify availability, prices and location before booking.',
                        'Mula sa AI • Suriin ang availability, presyo at lokasyon bago mag-book.',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(result.reply),
                    for (final idea in ideas)
                      Card(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            ListTile(
                              leading: const Icon(Icons.hotel_outlined),
                              title: Text(idea.payload['title'] as String),
                              subtitle: idea.payload['notes'] is String
                                  ? Text(idea.payload['notes'] as String)
                                  : null,
                            ),
                            RecommendationLinkActions(
                              query: [
                                if (idea.payload['place_name'] is String &&
                                    (idea.payload['place_name'] as String)
                                        .trim()
                                        .isNotEmpty)
                                  idea.payload['place_name'] as String
                                else
                                  idea.payload['title'] as String,
                                if (result.contextSummary['destination']
                                    is String)
                                  result.contextSummary['destination']
                                      as String,
                              ].join(', '),
                            ),
                          ],
                        ),
                      ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }
}
