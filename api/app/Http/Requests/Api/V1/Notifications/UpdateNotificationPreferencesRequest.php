<?php

declare(strict_types=1);

namespace App\Http\Requests\Api\V1\Notifications;

use Illuminate\Foundation\Http\FormRequest;

final class UpdateNotificationPreferencesRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    /**
     * @return array<string, array<int, string>>
     */
    public function rules(): array
    {
        return [
            'morning_summary_enabled' => ['sometimes', 'boolean'],
            'morning_summary_time' => ['sometimes', 'string', 'regex:/^\d{2}:\d{2}$/'],
            'activity_reminders_enabled' => ['sometimes', 'boolean'],
            'activity_reminder_lead_minutes' => ['sometimes', 'integer', 'min:0', 'max:1440'],
            'checklist_reminders_enabled' => ['sometimes', 'boolean'],
            'stay_reminders_enabled' => ['sometimes', 'boolean'],
            'quiet_hours_enabled' => ['sometimes', 'boolean'],
            'quiet_hours_start' => ['sometimes', 'nullable', 'string', 'regex:/^\d{2}:\d{2}$/'],
            'quiet_hours_end' => ['sometimes', 'nullable', 'string', 'regex:/^\d{2}:\d{2}$/'],
            'geofence_arrival_enabled' => ['sometimes', 'boolean'],
            'timezone_behavior' => ['sometimes', 'string', 'in:destination,home,device'],
        ];
    }
}

