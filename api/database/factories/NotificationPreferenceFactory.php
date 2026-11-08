<?php

declare(strict_types=1);

namespace Database\Factories;

use App\Domain\Notifications\Models\NotificationPreference;
use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<NotificationPreference>
 */
final class NotificationPreferenceFactory extends Factory
{
    protected $model = NotificationPreference::class;

    /**
     * Define the model's default state.
     *
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        return [
            'user_id' => User::factory(),
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
        ];
    }
}

