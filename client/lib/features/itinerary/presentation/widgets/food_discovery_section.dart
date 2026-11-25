import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/food_suggestion.dart';
import '../providers/itinerary_provider.dart';
import 'recommendation_link_actions.dart';

class FoodDiscoverySection extends ConsumerStatefulWidget {
  const FoodDiscoverySection({
    super.key,
    required this.tripId,
    this.destination,
  });

  final String tripId;
  final String? destination;

  @override
  ConsumerState<FoodDiscoverySection> createState() =>
      _FoodDiscoverySectionState();
}

class _FoodDiscoverySectionState extends ConsumerState<FoodDiscoverySection> {
  String _selectedMealType = 'all';
  bool _loading = true;
  String? _error;
  FoodSuggestionsResult? _result;
  final Set<String> _addingIds = <String>{};

  static const List<(String, String)> _mealTypes = [
    ('all', 'All Meals'),
    ('breakfast', 'Breakfast'),
    ('lunch', 'Lunch'),
    ('dinner', 'Dinner'),
    ('cafe', 'Cafe'),
  ];

  @override
  void initState() {
    super.initState();
    _loadSuggestions();
  }

  Future<void> _loadSuggestions() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final repo = ref.read(itineraryRepositoryProvider);
      final res = await repo.fetchFoodSuggestions(
        widget.tripId,
        mealType: _selectedMealType,
      );
      if (!mounted) return;
      setState(() {
        _result = res;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not load restaurant discovery suggestions.';
        _loading = false;
      });
    }
  }

  Future<void> _addMealToItinerary(FoodSuggestionItem item) async {
    if (_addingIds.contains(item.id)) return;
    setState(() => _addingIds.add(item.id));
    try {
      await ref
          .read(itineraryListProvider(widget.tripId).notifier)
          .addItem(
            title: item.suggestedTitle,
            kind: 'meal',
            notes: item.suggestedNotes,
            inlinePlace: {
              'name': item.suggestedPlaceName,
              'provider': 'manual',
            },
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Added "${item.suggestedTitle}" to itinerary')),
      );
      await _loadSuggestions();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not add meal to itinerary.')),
      );
    } finally {
      if (mounted) {
        setState(() => _addingIds.remove(item.id));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(Icons.restaurant_menu_rounded, color: colorScheme.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Restaurant & Food Discovery',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        if (_result?.anchorStayName != null &&
            _result!.anchorStayName!.trim().isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            'Curated dining near ${_result!.anchorStayName}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final (value, label) in _mealTypes)
              ChoiceChip(
                label: Text(label),
                selected: _selectedMealType == value,
                onSelected: (selected) {
                  if (!selected || _selectedMealType == value) return;
                  setState(() => _selectedMealType = value);
                  _loadSuggestions();
                },
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (_loading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: LinearProgressIndicator(),
          )
        else if (_error != null)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_error!),
              TextButton(
                onPressed: _loadSuggestions,
                child: const Text('Retry food suggestions'),
              ),
            ],
          )
        else if (_result == null || _result!.suggestions.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text(
              'No additional restaurant suggestions for this filter.',
            ),
          )
        else ...[
          for (final item in _result!.suggestions)
            Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.restaurant_outlined,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.name,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${item.cuisine} • ${item.neighborhood}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                item.proximityLabel,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(item.notes, style: theme.textTheme.bodySmall),
                    if (item.dietaryTags.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          for (final tag in item.dietaryTags)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: colorScheme.secondaryContainer,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                tag.replaceAll('_', ' '),
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: colorScheme.onSecondaryContainer,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        FilledButton.tonalIcon(
                          onPressed: _addingIds.contains(item.id)
                              ? null
                              : () => _addMealToItinerary(item),
                          icon: const Icon(Icons.add_rounded, size: 18),
                          label: const Text('Add to Itinerary'),
                        ),
                      ],
                    ),
                    RecommendationLinkActions(
                      query: [
                        item.name,
                        item.neighborhood,
                        if (widget.destination != null) widget.destination!,
                      ].join(', '),
                    ),
                  ],
                ),
              ),
            ),
          if (_result!.advisoryNotice.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                _result!.advisoryNotice,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 11,
                ),
              ),
            ),
        ],
      ],
    );
  }
}
