import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/map_launcher.dart';
import '../../domain/models/trip_location_share.dart';
import '../providers/trip_circle_provider.dart';

class LocationSharingSection extends ConsumerStatefulWidget {
  const LocationSharingSection({super.key, required this.tripId});

  final String tripId;

  @override
  ConsumerState<LocationSharingSection> createState() =>
      _LocationSharingSectionState();
}

class _LocationSharingSectionState
    extends ConsumerState<LocationSharingSection> {
  int _selectedDuration = 60;
  String _selectedAudience = 'circle';
  bool _isUpdating = false;

  final _durations = const [
    (label: '1 hr', minutes: 60),
    (label: '4 hrs', minutes: 240),
    (label: '8 hrs', minutes: 480),
    (label: '24 hrs', minutes: 1440),
  ];

  Future<void> _toggleShare(bool enable) async {
    if (!enable) {
      await _saveShareChange(disable: true);
      return;
    }

    final pin = await _requestMapPin();
    if (pin == null || !mounted) return;

    await _saveShareChange(latitude: pin.latitude, longitude: pin.longitude);
  }

  Future<void> _saveShareChange({
    bool disable = false,
    double? latitude,
    double? longitude,
  }) async {
    setState(() => _isUpdating = true);
    try {
      final notifier = ref.read(
        tripLocationShareProvider(widget.tripId).notifier,
      );
      if (disable) {
        await notifier.disable();
      } else {
        if (latitude == null || longitude == null) {
          throw StateError('A map pin is required to start location sharing.');
        }
        await notifier.enable(
          durationMinutes: _selectedDuration,
          audience: _selectedAudience,
          latitude: latitude,
          longitude: longitude,
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Location sharing could not be updated. Please try again.',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  Future<({double latitude, double longitude})?> _requestMapPin() async {
    final formKey = GlobalKey<FormState>();
    double? latitude;
    double? longitude;

    final result = await showDialog<({double latitude, double longitude})>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Share a map pin'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Enter the location you want to share. TapItTrip does not send a placeholder or synthetic location.',
              ),
              const SizedBox(height: 12),
              TextFormField(
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                  signed: true,
                ),
                decoration: const InputDecoration(labelText: 'Latitude'),
                validator: (value) {
                  final parsed = double.tryParse(value?.trim() ?? '');
                  return parsed == null || parsed < -90 || parsed > 90
                      ? 'Enter a latitude from -90 to 90.'
                      : null;
                },
                onSaved: (value) => latitude = double.parse(value!.trim()),
              ),
              TextFormField(
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                  signed: true,
                ),
                decoration: const InputDecoration(labelText: 'Longitude'),
                validator: (value) {
                  final parsed = double.tryParse(value?.trim() ?? '');
                  return parsed == null || parsed < -180 || parsed > 180
                      ? 'Enter a longitude from -180 to 180.'
                      : null;
                },
                onSaved: (value) => longitude = double.parse(value!.trim()),
              ),
              const SizedBox(height: 12),
              const Text(
                'This build does not collect background device GPS. Sharing stops automatically at the selected time or when you turn it off.',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (!formKey.currentState!.validate()) return;
              formKey.currentState!.save();
              Navigator.pop(dialogContext, (
                latitude: latitude!,
                longitude: longitude!,
              ));
            },
            child: const Text('Start sharing'),
          ),
        ],
      ),
    );

    return result;
  }

  Future<void> _updateDuration(int minutes) async {
    setState(() => _selectedDuration = minutes);
    final current = ref
        .read(tripLocationShareProvider(widget.tripId))
        .asData
        ?.value;
    if (current != null && current.isActive) {
      await _saveShareChange(
        latitude: current.latitude,
        longitude: current.longitude,
      );
    }
  }

  Future<void> _updateAudience(String audience) async {
    setState(() => _selectedAudience = audience);
    final current = ref
        .read(tripLocationShareProvider(widget.tripId))
        .asData
        ?.value;
    if (current != null && current.isActive) {
      await _saveShareChange(
        latitude: current.latitude,
        longitude: current.longitude,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final shareAsync = ref.watch(tripLocationShareProvider(widget.tripId));
    final activeSharesAsync = ref.watch(
      activeLocationSharesProvider(widget.tripId),
    );

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.near_me_outlined,
                  color: theme.colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Meeting Assistance',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (_isUpdating)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Temporary map-pin sharing for companions. It is off by default, expires automatically, and never claims live GPS when it is stale.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            shareAsync.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
              error: (e, _) => Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.errorContainer.withValues(
                    alpha: 0.5,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: theme.colorScheme.error,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Location sharing unavailable offline or not permitted.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onErrorContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              data: (share) {
                final isSharing = share.isActive;
                final selectedDuration = isSharing
                    ? share.durationMinutes
                    : _selectedDuration;
                final selectedAudience = isSharing
                    ? share.audience
                    : _selectedAudience;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        'Share My Location',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        isSharing
                            ? 'Sharing active (${share.audience == 'organizer_only' ? 'Organizer only' : 'Entire circle'})'
                            : 'Sharing is currently off',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isSharing
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      value: isSharing,
                      onChanged: _isUpdating ? null : (v) => _toggleShare(v),
                    ),
                    if (isSharing) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer.withValues(
                            alpha: 0.4,
                          ),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: theme.colorScheme.primary.withValues(
                              alpha: 0.3,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.fmd_good,
                              color: theme.colorScheme.primary,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                share.expiresAt != null
                                    ? 'Expires: ${share.expiresAt!.hour.toString().padLeft(2, '0')}:${share.expiresAt!.minute.toString().padLeft(2, '0')}'
                                    : 'Active',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onPrimaryContainer,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: share.isStale
                                    ? theme.colorScheme.errorContainer
                                    : theme.colorScheme.primary,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                share.isStale ? 'Stale' : 'Recent',
                                style: TextStyle(
                                  color: share.isStale
                                      ? theme.colorScheme.onErrorContainer
                                      : theme.colorScheme.onPrimary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Duration',
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        children: _durations.map((d) {
                          final isSelected = selectedDuration == d.minutes;
                          return ChoiceChip(
                            label: Text(d.label),
                            selected: isSelected,
                            onSelected: _isUpdating
                                ? null
                                : (_) => _updateDuration(d.minutes),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Audience',
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(
                            value: 'circle',
                            label: Text('Entire Circle'),
                            icon: Icon(Icons.group_outlined, size: 16),
                          ),
                          ButtonSegment(
                            value: 'organizer_only',
                            label: Text('Organizer Only'),
                            icon: Icon(Icons.shield_outlined, size: 16),
                          ),
                        ],
                        selected: {selectedAudience},
                        onSelectionChanged: _isUpdating
                            ? null
                            : (val) {
                                if (val.isNotEmpty) _updateAudience(val.first);
                              },
                      ),
                    ],
                  ],
                );
              },
            ),
            const Divider(height: 28),
            Text(
              'Circle Members Sharing a Location',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            activeSharesAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: LinearProgressIndicator(),
              ),
              error: (_, _) => Text(
                'Unable to retrieve member locations.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
              data: (activeShares) {
                if (activeShares.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'No circle members are currently sharing a location.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: activeShares.length,
                  separatorBuilder: (_, _) => const Divider(height: 12),
                  itemBuilder: (context, index) {
                    final item = activeShares[index];
                    return _MemberLocationTile(share: item);
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _MemberLocationTile extends StatelessWidget {
  const _MemberLocationTile({required this.share});

  final TripLocationShare share;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasCoords = share.latitude != null && share.longitude != null;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
            child: Text(
              share.userName.isNotEmpty ? share.userName[0].toUpperCase() : 'T',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  share.userName,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  share.isStale
                      ? 'Stale location (update >15m ago)'
                      : (share.lastSharedAt != null
                            ? 'Updated ${share.lastSharedAt!.hour.toString().padLeft(2, '0')}:${share.lastSharedAt!.minute.toString().padLeft(2, '0')}'
                            : 'Location shared; update time unavailable'),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: share.isStale
                        ? theme.colorScheme.error
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (hasCoords)
            IconButton(
              icon: const Icon(Icons.directions_outlined),
              tooltip: 'Directions in Maps',
              onPressed: () {
                MapLauncher.launchDirections(
                  query: '${share.latitude},${share.longitude}',
                );
              },
            ),
        ],
      ),
    );
  }
}
