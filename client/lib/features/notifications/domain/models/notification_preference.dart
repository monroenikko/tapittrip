class NotificationPreference {
  const NotificationPreference({
    required this.id,
    required this.userId,
    this.morningSummaryEnabled = true,
    this.morningSummaryTime = '08:00',
    this.activityRemindersEnabled = true,
    this.activityReminderLeadMinutes = 30,
    this.checklistRemindersEnabled = true,
    this.stayRemindersEnabled = true,
    this.quietHoursEnabled = false,
    this.quietHoursStart = '22:00',
    this.quietHoursEnd = '07:00',
    this.geofenceArrivalEnabled = true,
    this.timezoneBehavior = 'destination',
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String userId;
  final bool morningSummaryEnabled;
  final String morningSummaryTime;
  final bool activityRemindersEnabled;
  final int activityReminderLeadMinutes;
  final bool checklistRemindersEnabled;
  final bool stayRemindersEnabled;
  final bool quietHoursEnabled;
  final String? quietHoursStart;
  final String? quietHoursEnd;
  final bool geofenceArrivalEnabled;
  final String timezoneBehavior;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  NotificationPreference copyWith({
    String? id,
    String? userId,
    bool? morningSummaryEnabled,
    String? morningSummaryTime,
    bool? activityRemindersEnabled,
    int? activityReminderLeadMinutes,
    bool? checklistRemindersEnabled,
    bool? stayRemindersEnabled,
    bool? quietHoursEnabled,
    String? quietHoursStart,
    String? quietHoursEnd,
    bool? geofenceArrivalEnabled,
    String? timezoneBehavior,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return NotificationPreference(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      morningSummaryEnabled:
          morningSummaryEnabled ?? this.morningSummaryEnabled,
      morningSummaryTime: morningSummaryTime ?? this.morningSummaryTime,
      activityRemindersEnabled:
          activityRemindersEnabled ?? this.activityRemindersEnabled,
      activityReminderLeadMinutes:
          activityReminderLeadMinutes ?? this.activityReminderLeadMinutes,
      checklistRemindersEnabled:
          checklistRemindersEnabled ?? this.checklistRemindersEnabled,
      stayRemindersEnabled: stayRemindersEnabled ?? this.stayRemindersEnabled,
      quietHoursEnabled: quietHoursEnabled ?? this.quietHoursEnabled,
      quietHoursStart: quietHoursStart ?? this.quietHoursStart,
      quietHoursEnd: quietHoursEnd ?? this.quietHoursEnd,
      geofenceArrivalEnabled:
          geofenceArrivalEnabled ?? this.geofenceArrivalEnabled,
      timezoneBehavior: timezoneBehavior ?? this.timezoneBehavior,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory NotificationPreference.fromJson(Map<String, dynamic> json) {
    return NotificationPreference(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      morningSummaryEnabled: json['morning_summary_enabled'] as bool? ?? true,
      morningSummaryTime: json['morning_summary_time'] as String? ?? '08:00',
      activityRemindersEnabled:
          json['activity_reminders_enabled'] as bool? ?? true,
      activityReminderLeadMinutes:
          json['activity_reminder_lead_minutes'] as int? ?? 30,
      checklistRemindersEnabled:
          json['checklist_reminders_enabled'] as bool? ?? true,
      stayRemindersEnabled: json['stay_reminders_enabled'] as bool? ?? true,
      quietHoursEnabled: json['quiet_hours_enabled'] as bool? ?? false,
      quietHoursStart: json['quiet_hours_start'] as String? ?? '22:00',
      quietHoursEnd: json['quiet_hours_end'] as String? ?? '07:00',
      geofenceArrivalEnabled: json['geofence_arrival_enabled'] as bool? ?? true,
      timezoneBehavior: json['timezone_behavior'] as String? ?? 'destination',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'morning_summary_enabled': morningSummaryEnabled,
      'morning_summary_time': morningSummaryTime,
      'activity_reminders_enabled': activityRemindersEnabled,
      'activity_reminder_lead_minutes': activityReminderLeadMinutes,
      'checklist_reminders_enabled': checklistRemindersEnabled,
      'stay_reminders_enabled': stayRemindersEnabled,
      'quiet_hours_enabled': quietHoursEnabled,
      'quiet_hours_start': quietHoursStart,
      'quiet_hours_end': quietHoursEnd,
      'geofence_arrival_enabled': geofenceArrivalEnabled,
      'timezone_behavior': timezoneBehavior,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }
}
