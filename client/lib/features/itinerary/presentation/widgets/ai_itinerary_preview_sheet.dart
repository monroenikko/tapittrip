import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tapittrip/features/itinerary/domain/models/ai_itinerary_plan.dart';

import '../providers/itinerary_provider.dart';

class AiItineraryPreviewSheet extends ConsumerStatefulWidget {
  const AiItineraryPreviewSheet({
    super.key,
    required this.tripId,
    required this.plan,
  });

  final String tripId;
  final AiItineraryPlan plan;

  @override
  ConsumerState<AiItineraryPreviewSheet> createState() =>
      _AiItineraryPreviewSheetState();
}

class _AiItineraryPreviewSheetState
    extends ConsumerState<AiItineraryPreviewSheet> {
  late List<AiDaySuggestion> _days;
  bool _isApplying = false;

  @override
  void initState() {
    super.initState();
    _days = widget.plan.days
        .map(
          (d) => AiDaySuggestion(
            dayNumber: d.dayNumber,
            title: d.title,
            theme: d.theme,
            primaryNeighborhood: d.primaryNeighborhood,
            activities: List<AiActivitySuggestion>.from(d.activities),
            budgetEstimate: d.budgetEstimate,
            familyTip: d.familyTip,
          ),
        )
        .toList();
  }

  int get _totalActivities =>
      _days.fold<int>(0, (sum, d) => sum + d.activities.length);

  void _removeActivity(int dayIndex, int activityIndex) {
    if (dayIndex < 0 || dayIndex >= _days.length) return;
    final day = _days[dayIndex];
    if (activityIndex < 0 || activityIndex >= day.activities.length) return;

    final removed = day.activities[activityIndex];

    setState(() {
      final updatedActivities = List<AiActivitySuggestion>.from(day.activities)
        ..removeAt(activityIndex);

      if (updatedActivities.isEmpty) {
        _days.removeAt(dayIndex);
      } else {
        _days[dayIndex] = AiDaySuggestion(
          dayNumber: day.dayNumber,
          title: day.title,
          theme: day.theme,
          primaryNeighborhood: day.primaryNeighborhood,
          activities: updatedActivities,
          budgetEstimate: day.budgetEstimate,
          familyTip: day.familyTip,
        );
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Removed "${removed.title}"'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            setState(() {
              if (dayIndex >= _days.length) {
                _days.insert(
                  dayIndex,
                  AiDaySuggestion(
                    dayNumber: day.dayNumber,
                    title: day.title,
                    theme: day.theme,
                    primaryNeighborhood: day.primaryNeighborhood,
                    activities: [removed],
                    budgetEstimate: day.budgetEstimate,
                    familyTip: day.familyTip,
                  ),
                );
              } else {
                final currentDay = _days[dayIndex];
                final restored = List<AiActivitySuggestion>.from(
                  currentDay.activities,
                );
                final insertAt = activityIndex.clamp(0, restored.length);
                restored.insert(insertAt, removed);
                _days[dayIndex] = AiDaySuggestion(
                  dayNumber: currentDay.dayNumber,
                  title: currentDay.title,
                  theme: currentDay.theme,
                  primaryNeighborhood: currentDay.primaryNeighborhood,
                  activities: restored,
                  budgetEstimate: currentDay.budgetEstimate,
                  familyTip: currentDay.familyTip,
                );
              }
            });
          },
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _removeDay(int dayIndex) {
    if (dayIndex < 0 || dayIndex >= _days.length) return;
    final removedDay = _days[dayIndex];

    setState(() {
      _days.removeAt(dayIndex);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Removed Day ${removedDay.dayNumber}'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            setState(() {
              _days.insert(dayIndex.clamp(0, _days.length), removedDay);
            });
          },
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _resetPlan() {
    setState(() {
      _days = widget.plan.days
          .map(
            (d) => AiDaySuggestion(
              dayNumber: d.dayNumber,
              title: d.title,
              theme: d.theme,
              primaryNeighborhood: d.primaryNeighborhood,
              activities: List<AiActivitySuggestion>.from(d.activities),
              budgetEstimate: d.budgetEstimate,
              familyTip: d.familyTip,
            ),
          )
          .toList();
    });
  }

  Future<void> _applyPlan() async {
    final validDays = _days.where((d) => d.activities.isNotEmpty).toList();
    if (validDays.isEmpty) return;

    setState(() => _isApplying = true);
    try {
      final repo = ref.read(aiItineraryRepositoryProvider);
      final savedItems = await repo.applyPlan(widget.tripId, validDays);
      await ref.read(itineraryListProvider(widget.tripId).notifier).refresh();
      ref.invalidate(tripDaysProvider(widget.tripId));

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${savedItems.length} activities saved to your itinerary!',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isApplying = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save itinerary: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final plan = widget.plan;

    return DraggableScrollableSheet(
      initialChildSize: 0.88,
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
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(24),
                  children: [
                    // Header
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: colorScheme.primaryContainer,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.auto_awesome_rounded,
                            color: colorScheme.onPrimaryContainer,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Overview Suggested Itinerary',
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                plan.destination,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  color: colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (_totalActivities <
                            widget.plan.days.fold<int>(
                              0,
                              (s, d) => s + d.activities.length,
                            ))
                          TextButton.icon(
                            onPressed: _resetPlan,
                            icon: const Icon(Icons.restore_rounded, size: 16),
                            label: const Text('Reset'),
                            style: TextButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    Text(
                      plan.summary,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Helpful instructions Banner
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer.withValues(
                          alpha: 0.3,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: colorScheme.primary.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.tune_rounded,
                            size: 20,
                            color: colorScheme.primary,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Customize your plan: Remove any stops you do not want before saving to your trip.',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: colorScheme.onSurface,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Empty state if all days/stops were removed
                    if (_days.isEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 36),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.playlist_remove_rounded,
                                size: 48,
                                color: colorScheme.outline,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'All suggested stops removed',
                                style: theme.textTheme.titleMedium,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'You can reset to restore all stops or discard and plan again.',
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 16),
                              FilledButton.tonalIcon(
                                onPressed: _resetPlan,
                                icon: const Icon(
                                  Icons.restore_rounded,
                                  size: 18,
                                ),
                                label: const Text('Restore All Stops'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],

                    // Days & Activities Staging
                    ..._days.asMap().entries.map((dayEntry) {
                      final dayIdx = dayEntry.key;
                      final day = dayEntry.value;

                      return Card(
                        elevation: 0,
                        margin: const EdgeInsets.only(bottom: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(
                            color: colorScheme.outlineVariant.withValues(
                              alpha: 0.6,
                            ),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Day Header with Day number, Theme, and Remove Day button
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: colorScheme.primary,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      'Day ${day.dayNumber}',
                                      style: theme.textTheme.labelSmall
                                          ?.copyWith(
                                            color: colorScheme.onPrimary,
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      day.theme,
                                      style: theme.textTheme.titleSmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete_outline_rounded,
                                      size: 18,
                                    ),
                                    color: colorScheme.error.withValues(
                                      alpha: 0.8,
                                    ),
                                    tooltip: 'Remove Day ${day.dayNumber}',
                                    onPressed: () => _removeDay(dayIdx),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    Icons.location_on_outlined,
                                    size: 14,
                                    color: colorScheme.secondary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    day.primaryNeighborhood,
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: colorScheme.secondary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(height: 20),

                              // Activities list with individual remove buttons
                              ...day.activities.asMap().entries.map((actEntry) {
                                final actIdx = actEntry.key;
                                final act = actEntry.value;

                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: colorScheme
                                              .surfaceContainerHighest,
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Icon(
                                          _getKindIcon(act.kind),
                                          size: 16,
                                          color: colorScheme.primary,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              act.title,
                                              style: theme.textTheme.bodyMedium
                                                  ?.copyWith(
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                            ),
                                            if (act.plannedStartTime !=
                                                null) ...[
                                              const SizedBox(height: 2),
                                              Text(
                                                '${act.plannedStartTime} – ${act.plannedEndTime ?? ''}',
                                                style: theme
                                                    .textTheme
                                                    .labelSmall
                                                    ?.copyWith(
                                                      color: colorScheme
                                                          .onSurfaceVariant,
                                                    ),
                                              ),
                                            ],
                                            if (act.description != null) ...[
                                              const SizedBox(height: 2),
                                              Text(
                                                act.description!,
                                                style:
                                                    theme.textTheme.bodySmall,
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.remove_circle_outline_rounded,
                                          size: 20,
                                        ),
                                        color: colorScheme.error.withValues(
                                          alpha: 0.8,
                                        ),
                                        tooltip: 'Remove stop',
                                        onPressed: () =>
                                            _removeActivity(dayIdx, actIdx),
                                      ),
                                    ],
                                  ),
                                );
                              }),

                              if (day.familyTip != null) ...[
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.amber.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.child_care_rounded,
                                        size: 16,
                                        color: Colors.amber.shade900,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          day.familyTip!,
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                                color: Colors.amber.shade900,
                                                fontWeight: FontWeight.w500,
                                              ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    }),

                    // Weather Alternative Note
                    if (plan.weatherAlternativeNote != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest.withValues(
                            alpha: 0.4,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.umbrella_outlined,
                              color: colorScheme.primary,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                plan.weatherAlternativeNote!,
                                style: theme.textTheme.bodySmall,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ],
                ),
              ),

              // Pinned Bottom Action Buttons
              Container(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
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
                      child: OutlinedButton(
                        onPressed: _isApplying
                            ? null
                            : () => Navigator.of(context).pop(false),
                        child: const Text('Discard'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: FilledButton.icon(
                        icon: _isApplying
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.check_rounded, size: 18),
                        label: Text(
                          _isApplying
                              ? 'Saving Itinerary...'
                              : 'Save Itinerary ($_totalActivities ${_totalActivities == 1 ? 'stop' : 'stops'})',
                        ),
                        onPressed: (_isApplying || _totalActivities == 0)
                            ? null
                            : _applyPlan,
                      ),
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

  static IconData _getKindIcon(String kind) {
    switch (kind.toLowerCase()) {
      case 'dining':
        return Icons.restaurant_rounded;
      case 'nature':
        return Icons.park_rounded;
      case 'activity':
        return Icons.local_activity_rounded;
      case 'sightseeing':
      default:
        return Icons.attractions_rounded;
    }
  }
}
