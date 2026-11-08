<?php

declare(strict_types=1);

namespace App\Application\Itinerary\Services;

use App\Application\Itinerary\Data\RecordVisitEventData;
use App\Domain\Itinerary\Models\ItineraryItem;
use App\Domain\Itinerary\Models\VisitEvent;
use App\Models\User;
use Carbon\Carbon;

final class RecordVisitEventService
{
    /**
     * Record a visit event (suggested, confirmed, revoked) for an itinerary item.
     */
    public function execute(ItineraryItem $item, User $user, RecordVisitEventData $data): VisitEvent
    {
        $detectedAt = $data->detectedAt ? Carbon::parse($data->detectedAt) : now();

        $event = VisitEvent::create([
            'itinerary_item_id' => $item->id,
            'user_id' => $user->id,
            'event_type' => $data->eventType,
            'method' => $data->method,
            'detected_at' => $detectedAt,
            'accuracy_m' => $data->accuracyM,
        ]);

        if ($data->eventType === 'confirmed') {
            $item->update(['status' => 'visited']);
        } elseif ($data->eventType === 'revoked') {
            $item->update(['status' => 'planned']);
        }

        return $event;
    }
}

