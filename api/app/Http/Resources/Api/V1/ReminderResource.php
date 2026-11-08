<?php

declare(strict_types=1);

namespace App\Http\Resources\Api\V1;

use App\Domain\Notifications\Models\Reminder;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * @mixin Reminder
 */
final class ReminderResource extends JsonResource
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
            'trip_id' => $this->trip_id,
            'itinerary_item_id' => $this->itinerary_item_id,
            'checklist_id' => $this->checklist_id,
            'type' => $this->type,
            'title' => $this->title,
            'body' => $this->body,
            'trigger_at_utc' => $this->trigger_at_utc?->toIso8601String(),
            'timezone' => $this->timezone,
            'delivery_channel' => $this->delivery_channel,
            'status' => $this->status,
            'dedupe_key' => $this->dedupe_key,
            'source_version' => $this->source_version,
            'created_at' => $this->created_at?->toIso8601String(),
            'updated_at' => $this->updated_at?->toIso8601String(),
        ];
    }
}
