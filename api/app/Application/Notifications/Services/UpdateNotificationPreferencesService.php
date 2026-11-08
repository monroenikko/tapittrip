<?php

declare(strict_types=1);

namespace App\Application\Notifications\Services;

use App\Application\Notifications\Data\UpdateNotificationPreferencesData;
use App\Domain\Notifications\Models\NotificationPreference;
use App\Models\User;

final class UpdateNotificationPreferencesService
{
    /**
     * Update notification preferences for the user.
     */
    public function execute(User $user, UpdateNotificationPreferencesData $data): NotificationPreference
    {
        $preferences = NotificationPreference::firstOrCreate(
            ['user_id' => $user->id],
            [
                'morning_summary_enabled' => true,
                'morning_summary_time' => '08:00',
                'activity_reminders_enabled' => true,
                'activity_reminder_lead_minutes' => 30,
                'checklist_reminders_enabled' => true,
                'stay_reminders_enabled' => true,
                'quiet_hours_enabled' => false,
                'quiet_hours_start' => '22:00',
                'quiet_hours_end' => '07:00',
                'geofence_arrival_enabled' => true,
                'timezone_behavior' => 'destination',
            ]
        );

        $updates = $data->toArray();
        if (! empty($updates)) {
            $preferences->update($updates);
        }

        return $preferences->refresh();
    }
}

