import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/notification_provider.dart';
import '../widgets/notification_permission_banner.dart';

class NotificationPreferencesPage extends ConsumerStatefulWidget {
  const NotificationPreferencesPage({super.key});

  @override
  ConsumerState<NotificationPreferencesPage> createState() =>
      _NotificationPreferencesPageState();
}

class _NotificationPreferencesPageState
    extends ConsumerState<NotificationPreferencesPage> {
  bool _mockPermissionGranted = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final prefsAsync = ref.watch(notificationPreferencesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Notification Preferences')),
      body: prefsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Failed to load preferences: $error'),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: () => ref.refresh(notificationPreferencesProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (prefs) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              NotificationPermissionBanner(
                isGranted: _mockPermissionGranted,
                onRequestPermission: () {
                  setState(() {
                    _mockPermissionGranted = true;
                  });
                },
              ),

              // Section 1: Morning Summary
              _buildSectionHeader(context, 'Daily Itinerary Overview'),
              Card(
                child: Column(
                  children: [
                    SwitchListTile(
                      title: const Text('Morning Summary'),
                      subtitle: const Text(
                        'Receive an overview of the day’s activities in destination time',
                      ),
                      value: prefs.morningSummaryEnabled,
                      onChanged: (val) {
                        ref
                            .read(notificationPreferencesProvider.notifier)
                            .updatePreferences({
                              'morning_summary_enabled': val,
                            });
                      },
                    ),
                    if (prefs.morningSummaryEnabled) ...[
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.alarm_outlined),
                        title: const Text('Summary Time'),
                        trailing: OutlinedButton(
                          onPressed: () async {
                            final parts = prefs.morningSummaryTime.split(':');
                            final initialTime = TimeOfDay(
                              hour: int.tryParse(parts.first) ?? 8,
                              minute: int.tryParse(parts.last) ?? 0,
                            );

                            final picked = await showTimePicker(
                              context: context,
                              initialTime: initialTime,
                            );

                            if (picked != null) {
                              final formatted =
                                  '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
                              ref
                                  .read(
                                    notificationPreferencesProvider.notifier,
                                  )
                                  .updatePreferences({
                                    'morning_summary_time': formatted,
                                  });
                            }
                          },
                          child: Text(prefs.morningSummaryTime),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Section 2: Activity Alerts
              _buildSectionHeader(context, 'Activity Departure Alerts'),
              Card(
                child: Column(
                  children: [
                    SwitchListTile(
                      title: const Text('Upcoming Activity Reminders'),
                      subtitle: const Text(
                        'Alert me before scheduled activities begin',
                      ),
                      value: prefs.activityRemindersEnabled,
                      onChanged: (val) {
                        ref
                            .read(notificationPreferencesProvider.notifier)
                            .updatePreferences({
                              'activity_reminders_enabled': val,
                            });
                      },
                    ),
                    if (prefs.activityRemindersEnabled) ...[
                      const Divider(height: 1),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Reminder Lead Time',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              children: [15, 30, 60].map((mins) {
                                final isSelected =
                                    prefs.activityReminderLeadMinutes == mins;
                                return ChoiceChip(
                                  label: Text(
                                    mins == 60 ? '1 hour' : '$mins mins',
                                  ),
                                  selected: isSelected,
                                  onSelected: (selected) {
                                    if (selected) {
                                      ref
                                          .read(
                                            notificationPreferencesProvider
                                                .notifier,
                                          )
                                          .updatePreferences({
                                            'activity_reminder_lead_minutes':
                                                mins,
                                          });
                                    }
                                  },
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Section 3: Stays & Checklists
              _buildSectionHeader(context, 'Stays & Packing Reminders'),
              Card(
                child: Column(
                  children: [
                    SwitchListTile(
                      title: const Text('Hotel Check-in & Check-out'),
                      subtitle: const Text(
                        'Reminders before scheduled check-in and room check-out',
                      ),
                      value: prefs.stayRemindersEnabled,
                      onChanged: (val) {
                        ref
                            .read(notificationPreferencesProvider.notifier)
                            .updatePreferences({'stay_reminders_enabled': val});
                      },
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      title: const Text('Departure & Packing Checklists'),
                      subtitle: const Text(
                        'Reminders to check off essential items before departure day',
                      ),
                      value: prefs.checklistRemindersEnabled,
                      onChanged: (val) {
                        ref
                            .read(notificationPreferencesProvider.notifier)
                            .updatePreferences({
                              'checklist_reminders_enabled': val,
                            });
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Section 4: Quiet Hours
              _buildSectionHeader(context, 'Quiet Hours (Do Not Disturb)'),
              Card(
                child: Column(
                  children: [
                    SwitchListTile(
                      title: const Text('Enable Quiet Hours'),
                      subtitle: const Text(
                        'Mute non-urgent notifications during your rest hours',
                      ),
                      value: prefs.quietHoursEnabled,
                      onChanged: (val) {
                        ref
                            .read(notificationPreferencesProvider.notifier)
                            .updatePreferences({'quiet_hours_enabled': val});
                      },
                    ),
                    if (prefs.quietHoursEnabled) ...[
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.bedtime_outlined),
                        title: const Text('Start Time'),
                        trailing: OutlinedButton(
                          onPressed: () async {
                            final parts = (prefs.quietHoursStart ?? '22:00')
                                .split(':');
                            final initial = TimeOfDay(
                              hour: int.tryParse(parts.first) ?? 22,
                              minute: int.tryParse(parts.last) ?? 0,
                            );
                            final picked = await showTimePicker(
                              context: context,
                              initialTime: initial,
                            );
                            if (picked != null) {
                              final formatted =
                                  '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
                              ref
                                  .read(
                                    notificationPreferencesProvider.notifier,
                                  )
                                  .updatePreferences({
                                    'quiet_hours_start': formatted,
                                  });
                            }
                          },
                          child: Text(prefs.quietHoursStart ?? '22:00'),
                        ),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.wb_sunny_outlined),
                        title: const Text('End Time'),
                        trailing: OutlinedButton(
                          onPressed: () async {
                            final parts = (prefs.quietHoursEnd ?? '07:00')
                                .split(':');
                            final initial = TimeOfDay(
                              hour: int.tryParse(parts.first) ?? 7,
                              minute: int.tryParse(parts.last) ?? 0,
                            );
                            final picked = await showTimePicker(
                              context: context,
                              initialTime: initial,
                            );
                            if (picked != null) {
                              final formatted =
                                  '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
                              ref
                                  .read(
                                    notificationPreferencesProvider.notifier,
                                  )
                                  .updatePreferences({
                                    'quiet_hours_end': formatted,
                                  });
                            }
                          },
                          child: Text(prefs.quietHoursEnd ?? '07:00'),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Section 5: Smart Geofence Arrival
              _buildSectionHeader(context, 'Smart Arrival Detection'),
              Card(
                child: SwitchListTile(
                  title: const Text('Geofence Arrival Suggestions'),
                  subtitle: const Text(
                    'Notify and suggest marking activities as visited when you arrive nearby (never marks visited without your approval)',
                  ),
                  value: prefs.geofenceArrivalEnabled,
                  onChanged: (val) {
                    ref
                        .read(notificationPreferencesProvider.notifier)
                        .updatePreferences({'geofence_arrival_enabled': val});
                  },
                ),
              ),
              const SizedBox(height: 32),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
