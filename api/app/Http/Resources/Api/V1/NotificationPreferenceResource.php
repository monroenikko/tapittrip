<?php

declare(strict_types=1);

namespace App\Http\Resources\Api\V1;

use App\Domain\Notifications\Models\NotificationPreference;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * @mixin NotificationPreference
 */
final class NotificationPreferenceResource extends JsonResource
{
    /**
     * Transform the resource into an array.
     *
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'user_id' => $this->user_id,
            'morning_summary_enabled' => $this->morning_summary_enabled,
            'morning_summary_time' => $this->morning_summary_time,
            'activity_reminders_enabled' => $this->activity_reminders_enabled,
            'activity_reminder_lead_minutes' => $this->activity_reminder_lead_minutes,
            'checklist_reminders_enabled' => $this->checklist_reminders_enabled,
            'stay_reminders_enabled' => $this->stay_reminders_enabled,
            'quiet_hours_enabled' => $this->quiet_hours_enabled,
            'quiet_hours_start' => $this->quiet_hours_start,
            'quiet_hours_end' => $this->quiet_hours_end,
            'geofence_arrival_enabled' => $this->geofence_arrival_enabled,
            'timezone_behavior' => $this->timezone_behavior,
            'created_at' => $this->created_at?->toIso8601String(),
            'updated_at' => $this->updated_at?->toIso8601String(),
        ];
    }
}

