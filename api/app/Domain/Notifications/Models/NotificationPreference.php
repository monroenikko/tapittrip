<?php

declare(strict_types=1);

namespace App\Domain\Notifications\Models;

use App\Domain\Users\Models\User;
use Database\Factories\NotificationPreferenceFactory;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

#[Fillable([
    'user_id',
    'morning_summary_enabled',
    'morning_summary_time',
    'activity_reminders_enabled',
    'activity_reminder_lead_minutes',
    'checklist_reminders_enabled',
    'stay_reminders_enabled',
    'quiet_hours_enabled',
    'quiet_hours_start',
    'quiet_hours_end',
    'geofence_arrival_enabled',
    'timezone_behavior',
])]
final class NotificationPreference extends Model
{
    /** @use HasFactory<NotificationPreferenceFactory> */
    use HasFactory, HasUuids;

    /**
     * Create a new factory instance for the model.
     */
    protected static function newFactory(): NotificationPreferenceFactory
    {
        return NotificationPreferenceFactory::new();
    }

    /**
     * Get the attributes that should be cast.
     *
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'morning_summary_enabled' => 'boolean',
            'activity_reminders_enabled' => 'boolean',
            'activity_reminder_lead_minutes' => 'integer',
            'checklist_reminders_enabled' => 'boolean',
            'stay_reminders_enabled' => 'boolean',
            'quiet_hours_enabled' => 'boolean',
            'geofence_arrival_enabled' => 'boolean',
        ];
    }

    /**
     * The user these preferences belong to.
     *
     * @return BelongsTo<User, $this>
     */
    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}

