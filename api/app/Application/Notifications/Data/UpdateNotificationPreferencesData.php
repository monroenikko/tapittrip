<?php

declare(strict_types=1);

namespace App\Application\Notifications\Data;

final readonly class UpdateNotificationPreferencesData
{
    public function __construct(
        public ?bool $morningSummaryEnabled = null,
        public ?string $morningSummaryTime = null,
        public ?bool $activityRemindersEnabled = null,
        public ?int $activityReminderLeadMinutes = null,
        public ?bool $checklistRemindersEnabled = null,
        public ?bool $stayRemindersEnabled = null,
        public ?bool $quietHoursEnabled = null,
        public ?string $quietHoursStart = null,
        public ?string $quietHoursEnd = null,
        public ?bool $geofenceArrivalEnabled = null,
        public ?string $timezoneBehavior = null,
    ) {}

    /**
     * @param  array<string, mixed>  $data
     */
    public static function from(array $data): self
    {
        return new self(
            morningSummaryEnabled: isset($data['morning_summary_enabled']) ? (bool) $data['morning_summary_enabled'] : null,
            morningSummaryTime: isset($data['morning_summary_time']) ? (string) $data['morning_summary_time'] : null,
            activityRemindersEnabled: isset($data['activity_reminders_enabled']) ? (bool) $data['activity_reminders_enabled'] : null,
            activityReminderLeadMinutes: isset($data['activity_reminder_lead_minutes']) ? (int) $data['activity_reminder_lead_minutes'] : null,
            checklistRemindersEnabled: isset($data['checklist_reminders_enabled']) ? (bool) $data['checklist_reminders_enabled'] : null,
            stayRemindersEnabled: isset($data['stay_reminders_enabled']) ? (bool) $data['stay_reminders_enabled'] : null,
            quietHoursEnabled: isset($data['quiet_hours_enabled']) ? (bool) $data['quiet_hours_enabled'] : null,
            quietHoursStart: isset($data['quiet_hours_start']) ? (string) $data['quiet_hours_start'] : null,
            quietHoursEnd: isset($data['quiet_hours_end']) ? (string) $data['quiet_hours_end'] : null,
            geofenceArrivalEnabled: isset($data['geofence_arrival_enabled']) ? (bool) $data['geofence_arrival_enabled'] : null,
            timezoneBehavior: isset($data['timezone_behavior']) ? (string) $data['timezone_behavior'] : null,
        );
    }

    /**
     * @return array<string, mixed>
     */
    public function toArray(): array
    {
        return array_filter([
            'morning_summary_enabled' => $this->morningSummaryEnabled,
            'morning_summary_time' => $this->morningSummaryTime,
            'activity_reminders_enabled' => $this->activityRemindersEnabled,
            'activity_reminder_lead_minutes' => $this->activityReminderLeadMinutes,
            'checklist_reminders_enabled' => $this->checklistRemindersEnabled,
            'stay_reminders_enabled' => $this->stayRemindersEnabled,
            'quiet_hours_enabled' => $this->quietHoursEnabled,
            'quiet_hours_start' => $this->quietHoursStart,
            'quiet_hours_end' => $this->quietHoursEnd,
            'geofence_arrival_enabled' => $this->geofenceArrivalEnabled,
            'timezone_behavior' => $this->timezoneBehavior,
        ], fn ($val): bool => $val !== null);
    }
}
