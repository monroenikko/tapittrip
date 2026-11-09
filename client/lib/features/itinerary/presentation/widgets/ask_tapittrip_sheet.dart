import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tapittrip/core/network/api_exceptions.dart';
import 'package:tapittrip/features/itinerary/domain/models/trip_assistant_response.dart';
import 'package:tapittrip/features/itinerary/presentation/providers/itinerary_provider.dart';

class AskTapItTripSheet extends ConsumerStatefulWidget {
  const AskTapItTripSheet({super.key, required this.tripId, this.initialQuery});

  final String tripId;
  final String? initialQuery;

  static Future<void> show(
    BuildContext context, {
    required String tripId,
    String? initialQuery,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) =>
          AskTapItTripSheet(tripId: tripId, initialQuery: initialQuery),
    );
  }

  @override
  ConsumerState<AskTapItTripSheet> createState() => _AskTapItTripSheetState();
}

class _AskTapItTripSheetState extends ConsumerState<AskTapItTripSheet> {
  late final TextEditingController _queryController;
  bool _isLoading = false;
  String? _errorMessage;
  TripAssistantResponse? _response;

  final List<String> _quickPrompts = const [
    'Where should we eat near our hotel?',
    'Which lounge can I use in Terminal 3?',
    'Can you make Day 2 easier for our toddler?',
    'What should we do if it rains today?',
  ];

  @override
  void initState() {
    super.initState();
    _queryController = TextEditingController(text: widget.initialQuery ?? '');
    if (widget.initialQuery != null && widget.initialQuery!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _sendQuery(widget.initialQuery!);
      });
    }
  }

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  Future<void> _sendQuery(String queryText) async {
    final query = queryText.trim();
    if (query.isEmpty) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final repo = ref.read(aiItineraryRepositoryProvider);
      final result = await repo.askAssistant(widget.tripId, query: query);

      if (mounted) {
        setState(() {
          _isLoading = false;
          _response = result;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Could not get response: $e';
        });
      }
    }
  }

  Future<void> _handleAction(AssistantSuggestedAction action) async {
    if (action.kind == 'navigate_lounge_finder') {
      Navigator.of(context).pop();
      context.push('/lounges');
      return;
    }

    if (action.kind == 'add_activity') {
      final payload = action.payload;
      try {
        final rawKind = payload['kind'] as String?;
        final normalizedKind = _normalizeActivityKind(rawKind);

        await ref
            .read(itineraryListProvider(widget.tripId).notifier)
            .addItem(
              title: (payload['title'] as String?) ?? 'Suggested Stop',
              kind: normalizedKind,
              notes: payload['notes'] as String?,
              inlinePlace: payload['place_name'] != null
                  ? {
                      'name': payload['place_name'],
                      'address': payload['place_address'],
                    }
                  : null,
            );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Added "${payload['title']}" to your itinerary!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          String displayError = e.toString();
          if (e is ValidationException) {
            displayError = e.fieldErrors.join(', ');
          } else if (e is ApiException) {
            displayError = e.message;
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to add stop: $displayError'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    }
  }

  String _normalizeActivityKind(String? raw) {
    switch (raw?.toLowerCase().trim()) {
      case 'sightseeing':
      case 'activity':
      case 'nature':
      case 'culture':
      case 'shopping':
        return 'attraction';
      case 'dining':
      case 'food':
      case 'restaurant':
      case 'cafe':
      case 'bar':
        return 'meal';
      case 'transit':
      case 'train':
      case 'bus':
      case 'rideshare':
        return 'transport';
      case 'stay':
      case 'accommodation':
        return 'hotel';
      default:
        return (raw != null && raw.isNotEmpty) ? raw : 'attraction';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (ctx, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 12, 8),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.chat_bubble_outline_rounded,
                        color: colorScheme.onPrimaryContainer,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Ask TapItTrip',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Your contextual in-trip assistant',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),

              // Scrollable Body
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  children: [
                    // Quick Prompts Section
                    Text(
                      'Suggested Questions',
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _quickPrompts.map((prompt) {
                        return ActionChip(
                          avatar: const Icon(Icons.auto_awesome, size: 14),
                          label: Text(
                            prompt,
                            style: theme.textTheme.labelSmall,
                          ),
                          onPressed: _isLoading
                              ? null
                              : () {
                                  _queryController.text = prompt;
                                  _sendQuery(prompt);
                                },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),

                    // Loading State
                    if (_isLoading) ...[
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 32),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(height: 12),
                              Text('Consulting your trip details...'),
                            ],
                          ),
                        ),
                      ),
                    ],

                    // Error State
                    if (_errorMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: colorScheme.errorContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.error_outline,
                              color: colorScheme.onErrorContainer,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onErrorContainer,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Response Card
                    if (_response != null) ...[
                      Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(
                            color: colorScheme.outlineVariant.withValues(
                              alpha: 0.6,
                            ),
                          ),
                        ),
                        color: colorScheme.surfaceContainerLow,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _categoryColor(
                                        _response!.category,
                                        colorScheme,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      _categoryLabel(_response!.category),
                                      style: theme.textTheme.labelSmall
                                          ?.copyWith(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                  ),
                                  const Spacer(),
                                  Icon(
                                    Icons.shield_outlined,
                                    size: 16,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Advisory only',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _response!.reply,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  height: 1.4,
                                ),
                              ),
                              if (_response!.suggestedActions.isNotEmpty) ...[
                                const Divider(height: 24),
                                Text(
                                  'Suggested Actions',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.primary,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                ..._response!.suggestedActions.map((action) {
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 6),
                                    child: FilledButton.tonalIcon(
                                      icon: const Icon(
                                        Icons.add_task_rounded,
                                        size: 16,
                                      ),
                                      label: Text(action.label),
                                      onPressed: () => _handleAction(action),
                                    ),
                                  );
                                }),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ],
                ),
              ),

              // Pinned Bottom Query Input
              Container(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  border: Border(
                    top: BorderSide(
                      color: colorScheme.outlineVariant.withValues(alpha: 0.4),
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _queryController,
                        textInputAction: TextInputAction.send,
                        onSubmitted: _isLoading ? null : _sendQuery,
                        decoration: InputDecoration(
                          hintText: 'Ask about food, lounges, pacing...',
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      icon: _isLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.arrow_upward_rounded),
                      onPressed: _isLoading
                          ? null
                          : () => _sendQuery(_queryController.text),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Color _categoryColor(String category, ColorScheme colorScheme) {
    switch (category.toLowerCase()) {
      case 'dining':
        return Colors.deepOrange;
      case 'lounge':
        return Colors.indigo;
      case 'toddler_friendly':
        return Colors.teal;
      case 'weather':
        return Colors.blueGrey;
      default:
        return colorScheme.primary;
    }
  }

  String _categoryLabel(String category) {
    switch (category.toLowerCase()) {
      case 'dining':
        return 'Dining & Hotel';
      case 'lounge':
        return 'Airport Lounge';
      case 'toddler_friendly':
        return 'Toddler & Family';
      case 'weather':
        return 'Weather Alternative';
      default:
        return 'Assistant Tip';
    }
  }
}
