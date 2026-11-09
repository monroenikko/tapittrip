import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tapittrip/core/network/api_exceptions.dart';
import 'package:tapittrip/features/itinerary/domain/models/trip_assistant_response.dart';
import 'package:tapittrip/features/itinerary/presentation/providers/itinerary_provider.dart';

class _AssistantChatMessage {
  const _AssistantChatMessage({
    required this.isUser,
    required this.text,
    this.response,
  });

  final bool isUser;
  final String text;
  final TripAssistantResponse? response;
}

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
  final ScrollController _scrollController = ScrollController();
  final List<_AssistantChatMessage> _messages = [];

  final Set<String> _pendingActionKeys = {};
  final Set<String> _completedActionKeys = {};
  String? _actionSuccessMessage;
  String? _actionErrorMessage;
  Timer? _bannerTimer;

  bool _isLoading = false;
  String? _errorMessage;

  final List<String> _quickPrompts = const [
    'Where should we eat near our hotel?',
    'Which lounge can I use in Terminal 3?',
    'What should I pack for this trip?',
    'Local tipping & payment etiquette',
    'Top hidden gems and spots to visit',
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
    _bannerTimer?.cancel();
    _queryController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendQuery(String queryText) async {
    final query = queryText.trim();
    if (query.isEmpty) return;

    _queryController.clear();

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _messages.add(_AssistantChatMessage(isUser: true, text: query));
    });

    _scrollToBottom();

    try {
      final repo = ref.read(aiItineraryRepositoryProvider);
      final result = await repo.askAssistant(widget.tripId, query: query);

      if (mounted) {
        setState(() {
          _isLoading = false;
          _messages.add(
            _AssistantChatMessage(
              isUser: false,
              text: result.reply,
              response: result,
            ),
          );
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Could not get response: $e';
        });
        _scrollToBottom();
      }
    }
  }

  String _getActionKey(AssistantSuggestedAction action) {
    final title = action.payload['title'] ?? action.label;
    return '${action.kind}_$title';
  }

  Future<void> _handleAction(AssistantSuggestedAction action) async {
    if (action.kind == 'navigate_lounge_finder') {
      Navigator.of(context).pop();
      context.push('/lounges');
      return;
    }

    if (action.kind == 'add_activity') {
      final actionKey = _getActionKey(action);
      if (_pendingActionKeys.contains(actionKey) ||
          _completedActionKeys.contains(actionKey)) {
        return;
      }

      final payload = action.payload;
      final rawTitle = (payload['title'] as String?)?.trim();
      final rawPlaceName = (payload['place_name'] as String?)?.trim();
      final stopTitle = (rawTitle != null && rawTitle.isNotEmpty)
          ? rawTitle
          : (rawPlaceName != null && rawPlaceName.isNotEmpty
                ? rawPlaceName
                : (action.label.isNotEmpty
                      ? action.label
                      : 'Suggested Activity'));

      final rawAddress =
          (payload['place_address'] ??
                  payload['address'] ??
                  payload['formatted_address'])
              as String?;
      final address = rawAddress?.trim();

      setState(() {
        _pendingActionKeys.add(actionKey);
        _actionSuccessMessage = null;
        _actionErrorMessage = null;
      });

      try {
        final rawKind = payload['kind'] as String?;
        final normalizedKind = _normalizeActivityKind(rawKind);

        final Map<String, dynamic>? inlinePlace =
            (rawPlaceName != null && rawPlaceName.isNotEmpty)
            ? {
                'name': rawPlaceName,
                if (address != null && address.isNotEmpty) ...{
                  'formatted_address': address,
                  'address': address,
                },
                'provider': 'manual',
                'attribution': 'TapItTrip Assistant',
              }
            : null;

        await ref
            .read(itineraryListProvider(widget.tripId).notifier)
            .addItem(
              title: stopTitle,
              kind: normalizedKind,
              notes: payload['notes'] as String?,
              inlinePlace: inlinePlace,
            );

        if (mounted) {
          setState(() {
            _pendingActionKeys.remove(actionKey);
            _completedActionKeys.add(actionKey);
            _actionSuccessMessage = 'Added "$stopTitle" to your itinerary!';
          });

          // Also trigger a snackbar in case the sheet is dismissed
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Added "$stopTitle" to your itinerary!'),
              backgroundColor: Colors.green,
            ),
          );

          // Auto-hide in-sheet banner after 4.5 seconds
          _bannerTimer?.cancel();
          _bannerTimer = Timer(const Duration(milliseconds: 4500), () {
            if (mounted) {
              setState(() {
                if (_actionSuccessMessage ==
                    'Added "$stopTitle" to your itinerary!') {
                  _actionSuccessMessage = null;
                }
              });
            }
          });
        }
      } catch (e) {
        if (mounted) {
          String displayError;
          if (e is ValidationException) {
            displayError = e.fieldErrors.isNotEmpty
                ? e.fieldErrors.join(', ')
                : e.message;
          } else if (e is ApiException) {
            displayError = e.message;
          } else {
            displayError = e
                .toString()
                .replaceAll(RegExp(r'^ApiException\([^)]+\):\s*'), '')
                .replaceAll(RegExp(r'^Exception:\s*'), '');
          }
          setState(() {
            _pendingActionKeys.remove(actionKey);
            _actionErrorMessage = 'Failed to add stop: $displayError';
          });
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
    if (raw == null || raw.trim().isEmpty) return 'attraction';
    final lower = raw.toLowerCase().trim();
    if (lower.contains('food') ||
        lower.contains('dine') ||
        lower.contains('dining') ||
        lower.contains('restaurant') ||
        lower.contains('cafe') ||
        lower.contains('bar') ||
        lower.contains('meal') ||
        lower.contains('eat') ||
        lower.contains('lunch') ||
        lower.contains('dinner') ||
        lower.contains('breakfast') ||
        lower.contains('bakery') ||
        lower.contains('coffee') ||
        lower.contains('snack') ||
        lower.contains('drink')) {
      return 'meal';
    }
    if (lower.contains('flight') || lower.contains('airline')) {
      return 'flight';
    }
    if (lower.contains('transit') ||
        lower.contains('train') ||
        lower.contains('bus') ||
        lower.contains('taxi') ||
        lower.contains('rideshare') ||
        lower.contains('subway') ||
        lower.contains('metro') ||
        lower.contains('ferry') ||
        lower.contains('transfer') ||
        lower.contains('transport')) {
      return 'transport';
    }
    if (lower.contains('stay') ||
        lower.contains('hotel') ||
        lower.contains('resort') ||
        lower.contains('accommodation') ||
        lower.contains('hostel') ||
        lower.contains('lodging')) {
      return 'hotel';
    }
    if (lower == 'custom') return 'custom';
    return 'attraction';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return DraggableScrollableSheet(
      initialChildSize: 0.88,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (ctx, parentScrollController) {
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
                        Icons.auto_awesome_rounded,
                        color: colorScheme.onPrimaryContainer,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Ask TapItTrip',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: colorScheme.primary.withValues(
                                    alpha: 0.12,
                                  ),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'AI',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.primary,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                            ],
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

              // Scrollable Conversation Area
              Expanded(
                child: ListView(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Welcome & Scoping Banner if no messages yet
                    if (_messages.isEmpty) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: colorScheme.outlineVariant.withValues(
                              alpha: 0.5,
                            ),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.travel_explore_rounded,
                                  size: 18,
                                  color: colorScheme.primary,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Travel & Suggestions Assistant',
                                  style: theme.textTheme.labelLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Ask anything about local dining, packing tips, etiquette, transit, or hidden gems. Tap any suggestion below to get started!',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

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
                    const SizedBox(height: 16),

                    // Render Messages History
                    ..._messages.map((msg) {
                      if (msg.isUser) {
                        return Align(
                          alignment: Alignment.centerRight,
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12, left: 48),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: colorScheme.primary,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(16),
                                topRight: Radius.circular(16),
                                bottomLeft: Radius.circular(16),
                                bottomRight: Radius.circular(4),
                              ),
                            ),
                            child: Text(
                              msg.text,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onPrimary,
                              ),
                            ),
                          ),
                        );
                      }

                      final response = msg.response;
                      if (response == null) {
                        return const SizedBox.shrink();
                      }

                      final isOutOfScope =
                          response.category.toLowerCase() == 'out_of_scope';

                      return Card(
                        elevation: 0,
                        margin: const EdgeInsets.only(bottom: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(
                            color: isOutOfScope
                                ? colorScheme.error.withValues(alpha: 0.4)
                                : colorScheme.outlineVariant.withValues(
                                    alpha: 0.6,
                                  ),
                          ),
                        ),
                        color: isOutOfScope
                            ? colorScheme.errorContainer.withValues(alpha: 0.2)
                            : colorScheme.surfaceContainerLow,
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
                                        response.category,
                                        colorScheme,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      _categoryLabel(response.category),
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
                                response.reply,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  height: 1.45,
                                ),
                              ),
                              if (response.suggestedActions.isNotEmpty) ...[
                                const Divider(height: 24),
                                Text(
                                  'Suggested Actions',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.primary,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                ...response.suggestedActions.map((action) {
                                  final actionKey = _getActionKey(action);
                                  final isPending = _pendingActionKeys.contains(
                                    actionKey,
                                  );
                                  final isCompleted = _completedActionKeys
                                      .contains(actionKey);

                                  if (isCompleted) {
                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 8),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 10,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.green.withValues(
                                          alpha: 0.12,
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: Colors.green.withValues(
                                            alpha: 0.35,
                                          ),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.check_circle_rounded,
                                            color: Colors.green,
                                            size: 18,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Added to Itinerary',
                                            style: theme.textTheme.labelMedium
                                                ?.copyWith(
                                                  color: Colors.green.shade800,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }

                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: FilledButton.tonalIcon(
                                      icon: isPending
                                          ? const SizedBox(
                                              width: 14,
                                              height: 14,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                              ),
                                            )
                                          : const Icon(
                                              Icons.add_task_rounded,
                                              size: 16,
                                            ),
                                      label: Text(
                                        isPending
                                            ? 'Adding to itinerary...'
                                            : action.label,
                                      ),
                                      onPressed: (isPending || _isLoading)
                                          ? null
                                          : () => _handleAction(action),
                                    ),
                                  );
                                }),
                              ],
                            ],
                          ),
                        ),
                      );
                    }),

                    // Loading State
                    if (_isLoading) ...[
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
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
                  ],
                ),
              ),

              // In-Sheet Live Action Success Banner
              if (_actionSuccessMessage != null) ...[
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.shade700,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.check_circle_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _actionSuccessMessage!,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      TextButton(
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          visualDensity: VisualDensity.compact,
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text(
                          'View',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.close_rounded,
                          color: Colors.white70,
                          size: 18,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () {
                          setState(() => _actionSuccessMessage = null);
                        },
                      ),
                    ],
                  ),
                ),
              ],

              // In-Sheet Live Action Error Banner
              if (_actionErrorMessage != null) ...[
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline_rounded,
                        color: colorScheme.onErrorContainer,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _actionErrorMessage!,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onErrorContainer,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.close_rounded,
                          color: colorScheme.onErrorContainer,
                          size: 18,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () {
                          setState(() => _actionErrorMessage = null);
                        },
                      ),
                    ],
                  ),
                ),
              ],

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
                          hintText: 'Ask about food, packing, etiquette...',
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
      case 'packing':
        return Colors.purple;
      case 'culture':
      case 'etiquette':
        return Colors.amber.shade800;
      case 'transit':
      case 'transport':
        return Colors.blue;
      case 'itinerary':
        return Colors.green.shade700;
      case 'safety':
        return Colors.red.shade700;
      case 'out_of_scope':
        return Colors.blueGrey.shade700;
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
        return 'Weather Advice';
      case 'packing':
        return 'Packing & Gear';
      case 'culture':
      case 'etiquette':
        return 'Culture & Etiquette';
      case 'transit':
      case 'transport':
        return 'Transit & Navigation';
      case 'itinerary':
        return 'Itinerary Suggestion';
      case 'safety':
        return 'Safety & Emergency';
      case 'out_of_scope':
        return 'Travel Guardrail';
      default:
        return 'Travel Assistant';
    }
  }
}
