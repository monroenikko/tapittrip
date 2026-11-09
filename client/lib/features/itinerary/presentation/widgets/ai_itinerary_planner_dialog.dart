import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exceptions.dart';
import '../providers/itinerary_provider.dart';
import 'ai_itinerary_preview_sheet.dart';

class AiItineraryPlannerDialog extends ConsumerStatefulWidget {
  const AiItineraryPlannerDialog({
    super.key,
    required this.tripId,
    this.initialDestination,
    this.initialDays = 3,
  });

  final String tripId;
  final String? initialDestination;
  final int initialDays;

  @override
  ConsumerState<AiItineraryPlannerDialog> createState() =>
      _AiItineraryPlannerDialogState();
}

class _AiItineraryPlannerDialogState
    extends ConsumerState<AiItineraryPlannerDialog> {
  late final TextEditingController _destinationController;
  late int _durationDays;
  String _budgetTier = 'moderate';
  String _travelParty = 'family_kids';
  String _travelPace = 'balanced';
  final Set<String> _selectedInterests = {'food', 'culture'};
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _destinationController = TextEditingController(
      text: widget.initialDestination ?? 'Tokyo, Japan',
    );
    _durationDays = widget.initialDays.clamp(1, 7);
  }

  @override
  void dispose() {
    _destinationController.dispose();
    super.dispose();
  }

  Future<void> _generateItinerary() async {
    final destination = _destinationController.text.trim();
    if (destination.isEmpty) {
      setState(() => _errorMessage = 'Please specify a destination.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final repo = ref.read(aiItineraryRepositoryProvider);
      final plan = await repo.generatePlan(
        widget.tripId,
        destination: destination,
        durationDays: _durationDays,
        budgetTier: _budgetTier,
        travelParty: _travelParty,
        pace: _travelPace,
        interests: _selectedInterests.toList(),
      );

      if (mounted) {
        Navigator.of(context).pop();
        showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (ctx) =>
              AiItineraryPreviewSheet(tripId: widget.tripId, plan: plan),
        );
      }
    } catch (e) {
      if (mounted) {
        final message = e is ApiException
            ? e.toString()
            : 'Failed to generate itinerary: $e';
        setState(() {
          _isLoading = false;
          _errorMessage = message;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 680),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.auto_awesome_rounded,
                      color: colorScheme.onPrimaryContainer,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Plan Trip with AI',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'AI suggests; you approve every stop',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: _isLoading
                        ? null
                        : () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              Expanded(
                child: ListView(
                  children: [
                    // Destination Input
                    Text(
                      'Where are you going?',
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _destinationController,
                      decoration: InputDecoration(
                        hintText: 'e.g. Tokyo, Japan or Paris, France',
                        prefixIcon: const Icon(Icons.flight_takeoff_rounded),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Duration Stepper
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Trip Duration',
                                style: theme.textTheme.labelMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '$_durationDays ${_durationDays == 1 ? 'day' : 'days'}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton.filledTonal(
                          icon: const Icon(Icons.remove, size: 18),
                          onPressed: _durationDays > 1 && !_isLoading
                              ? () => setState(() => _durationDays--)
                              : null,
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            '$_durationDays',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton.filledTonal(
                          icon: const Icon(Icons.add, size: 18),
                          onPressed: _durationDays < 7 && !_isLoading
                              ? () => setState(() => _durationDays++)
                              : null,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Budget Tier
                    Text(
                      'Budget',
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      children: [
                        _buildChoiceChip(
                          label: 'Budget',
                          value: 'low',
                          selected:
                              _budgetTier == 'low' || _budgetTier == 'budget',
                          onSelected: (val) =>
                              setState(() => _budgetTier = 'low'),
                        ),
                        _buildChoiceChip(
                          label: 'Moderate',
                          value: 'moderate',
                          selected: _budgetTier == 'moderate',
                          onSelected: (val) =>
                              setState(() => _budgetTier = 'moderate'),
                        ),
                        _buildChoiceChip(
                          label: 'Luxury',
                          value: 'luxury',
                          selected: _budgetTier == 'luxury',
                          onSelected: (val) =>
                              setState(() => _budgetTier = 'luxury'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Traveling With (Party)
                    Text(
                      'Traveling with',
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      children: [
                        _buildChoiceChip(
                          label: 'Solo',
                          value: 'solo',
                          selected: _travelParty == 'solo',
                          onSelected: (val) =>
                              setState(() => _travelParty = 'solo'),
                        ),
                        _buildChoiceChip(
                          label: 'Couple',
                          value: 'couple',
                          selected: _travelParty == 'couple',
                          onSelected: (val) =>
                              setState(() => _travelParty = 'couple'),
                        ),
                        _buildChoiceChip(
                          label: 'Family / Kids',
                          value: 'family_kids',
                          selected:
                              _travelParty == 'family_kids' ||
                              _travelParty == 'family',
                          onSelected: (val) =>
                              setState(() => _travelParty = 'family_kids'),
                        ),
                        _buildChoiceChip(
                          label: 'Friends',
                          value: 'friends',
                          selected: _travelParty == 'friends',
                          onSelected: (val) =>
                              setState(() => _travelParty = 'friends'),
                        ),
                        _buildChoiceChip(
                          label: 'Seniors',
                          value: 'seniors',
                          selected: _travelParty == 'seniors',
                          onSelected: (val) =>
                              setState(() => _travelParty = 'seniors'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Travel Pace
                    Text(
                      'Travel pace',
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      children: [
                        _buildChoiceChip(
                          label: 'Relaxed (1-2 stops)',
                          value: 'relaxed',
                          selected: _travelPace == 'relaxed',
                          onSelected: (val) =>
                              setState(() => _travelPace = 'relaxed'),
                        ),
                        _buildChoiceChip(
                          label: 'Balanced (3 stops)',
                          value: 'balanced',
                          selected: _travelPace == 'balanced',
                          onSelected: (val) =>
                              setState(() => _travelPace = 'balanced'),
                        ),
                        _buildChoiceChip(
                          label: 'High Energy (4+ stops)',
                          value: 'packed',
                          selected:
                              _travelPace == 'packed' || _travelPace == 'fast',
                          onSelected: (val) =>
                              setState(() => _travelPace = 'packed'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Interests
                    Text(
                      'Interests',
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        _buildFilterChip(
                          label: 'Food & Dining',
                          value: 'food',
                          icon: Icons.restaurant,
                        ),
                        _buildFilterChip(
                          label: 'Culture & Heritage',
                          value: 'culture',
                          icon: Icons.museum_outlined,
                        ),
                        _buildFilterChip(
                          label: 'Shopping',
                          value: 'shopping',
                          icon: Icons.shopping_bag_outlined,
                        ),
                        _buildFilterChip(
                          label: 'Nature',
                          value: 'nature',
                          icon: Icons.park_outlined,
                        ),
                        _buildFilterChip(
                          label: 'Theme parks',
                          value: 'theme_parks',
                          icon: Icons.attractions_outlined,
                        ),
                        _buildFilterChip(
                          label: 'Hidden gems',
                          value: 'hidden_gems',
                          icon: Icons.explore_outlined,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: colorScheme.error.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline_rounded,
                        size: 16,
                        color: colorScheme.error,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onErrorContainer,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isLoading
                          ? null
                          : () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: FilledButton.icon(
                      onPressed: _isLoading ? null : _generateItinerary,
                      icon: _isLoading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.auto_awesome_rounded, size: 18),
                      label: Text(_isLoading ? 'Planning...' : 'Preview Plan'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChoiceChip({
    required String label,
    required String value,
    required bool selected,
    required ValueChanged<bool> onSelected,
  }) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: _isLoading ? null : onSelected,
    );
  }

  Widget _buildFilterChip({
    required String label,
    required String value,
    required IconData icon,
  }) {
    final selected = _selectedInterests.contains(value);
    return FilterChip(
      avatar: Icon(icon, size: 16),
      label: Text(label),
      selected: selected,
      onSelected: _isLoading
          ? null
          : (val) {
              setState(() {
                if (val) {
                  _selectedInterests.add(value);
                } else {
                  _selectedInterests.remove(value);
                }
              });
            },
    );
  }
}
