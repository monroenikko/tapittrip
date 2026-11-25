import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/smart_replan_result.dart';
import '../providers/itinerary_provider.dart';

class SmartReplanSheet extends ConsumerStatefulWidget {
  const SmartReplanSheet({super.key, required this.tripId, this.tripDayId});

  final String tripId;
  final String? tripDayId;

  @override
  ConsumerState<SmartReplanSheet> createState() => _SmartReplanSheetState();
}

class _SmartReplanSheetState extends ConsumerState<SmartReplanSheet> {
  String _selectedTrigger = 'rain_weather';
  int _delayMinutes = 120;
  bool _loading = true;
  bool _applying = false;
  String? _error;
  SmartReplanResult? _preview;

  static const List<(String, String, IconData)> _triggers = [
    ('rain_weather', 'Rain / Weather', Icons.umbrella_rounded),
    ('flight_delay', 'Flight Delay', Icons.schedule_rounded),
    ('skipped_stop', 'Skipped Stop', Icons.fast_forward_rounded),
    ('tired_family_pacing', 'Family Pacing', Icons.child_care_rounded),
  ];

  @override
  void initState() {
    super.initState();
    _loadPreview();
  }

  Future<void> _loadPreview() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final repo = ref.read(aiItineraryRepositoryProvider);
      final res = await repo.replanItinerary(
        widget.tripId,
        triggerReason: _selectedTrigger,
        tripDayId: widget.tripDayId,
        apply: false,
        delayMinutes: _selectedTrigger == 'flight_delay' ? _delayMinutes : null,
      );
      if (!mounted) return;
      setState(() {
        _preview = res;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not generate smart replanning proposal right now.';
        _loading = false;
      });
    }
  }

  Future<void> _applyReplan() async {
    if (_applying || _preview == null) return;
    setState(() => _applying = true);
    try {
      final repo = ref.read(aiItineraryRepositoryProvider);
      await repo.replanItinerary(
        widget.tripId,
        triggerReason: _selectedTrigger,
        tripDayId: widget.tripDayId,
        apply: true,
        delayMinutes: _selectedTrigger == 'flight_delay' ? _delayMinutes : null,
      );
      await ref.read(itineraryListProvider(widget.tripId).notifier).refresh();
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _applying = false;
        _error = 'Could not apply replanning proposal. Please try again.';
      });
    }
  }

  IconData _actionIcon(String action) {
    return switch (action) {
      'keep_visited' => Icons.verified_rounded,
      'shift_time' => Icons.access_time_filled_rounded,
      _ => Icons.add_circle_outline_rounded,
    };
  }

  String _actionLabel(String action) {
    return switch (action) {
      'keep_visited' => 'Preserved Memory',
      'shift_time' => 'Time Shifted',
      _ => 'Suggested Backup Stop',
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(Icons.auto_fix_high_rounded, color: colorScheme.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Smart In-Trip Replanning',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              Text(
                'Adapts your upcoming schedule to weather, delays, or pacing without deleting visited stops.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final (value, label, icon) in _triggers)
                    ChoiceChip(
                      avatar: Icon(icon, size: 16),
                      label: Text(label),
                      selected: _selectedTrigger == value,
                      onSelected: (selected) {
                        if (!selected || _selectedTrigger == value) return;
                        setState(() => _selectedTrigger = value);
                        _loadPreview();
                      },
                    ),
                ],
              ),
              if (_selectedTrigger == 'flight_delay') ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Arrival / flight delay duration',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                    DropdownButton<int>(
                      value: _delayMinutes,
                      items: const [
                        DropdownMenuItem(value: 60, child: Text('1 hour')),
                        DropdownMenuItem(value: 120, child: Text('2 hours')),
                        DropdownMenuItem(value: 180, child: Text('3 hours')),
                      ],
                      onChanged: (val) {
                        if (val == null || val == _delayMinutes) return;
                        setState(() => _delayMinutes = val);
                        _loadPreview();
                      },
                    ),
                  ],
                ),
              ],
              const Divider(height: 20),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_error != null)
                Column(
                  children: [
                    Text(_error!, style: TextStyle(color: colorScheme.error)),
                    TextButton(
                      onPressed: _loadPreview,
                      child: const Text('Retry'),
                    ),
                  ],
                )
              else if (_preview != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Preserves ${_preview!.preservedVisitedCount} visited stop(s) & past memories',
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(_preview!.summary, style: theme.textTheme.bodySmall),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                for (final change in _preview!.proposedChanges)
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      _actionIcon(change.action),
                      color: change.action == 'keep_visited'
                          ? colorScheme.secondary
                          : colorScheme.primary,
                    ),
                    title: Text(change.title),
                    subtitle: Text(
                      '${_actionLabel(change.action)} • ${change.reason}',
                    ),
                  ),
                if (_preview!.advisoryNotice.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    _preview!.advisoryNotice,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 11,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _applying ? null : _applyReplan,
                  icon: const Icon(Icons.check_circle_outline_rounded),
                  label: Text(
                    _applying ? 'Applying...' : 'Approve & Apply Replan',
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
