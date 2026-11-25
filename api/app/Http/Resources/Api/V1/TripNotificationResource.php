<?php

declare(strict_types=1);

namespace App\Http\Resources\Api\V1;

use App\Models\TripNotification;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * @mixin TripNotification
 */
final class TripNotificationResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => (string) $this->id,
            'trip_id' => (string) $this->trip_id,
            'trip_title' => (string) ($this->trip?->title ?? 'Shared Trip'),
            'announcement_id' => $this->announcement_id !== null ? (string) $this->announcement_id : null,
            'category' => (string) $this->category,
            'title' => (string) $this->title,
            'body' => (string) $this->body,
            'scheduled_for_utc' => $this->scheduled_for_utc?->toIso8601String(),
            'timezone' => (string) $this->timezone,
            'trip_local_time_label' => $this->trip_local_time_label,
            'status' => (string) $this->status,
            'is_read' => $this->read_at !== null,
            'read_at' => $this->read_at?->toIso8601String(),
            'created_at' => $this->created_at?->toIso8601String(),
        ];
    }
}
