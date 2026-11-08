<?php

declare(strict_types=1);

namespace App\Http\Controllers\Api\V1;

use App\Application\Itinerary\Data\RecordVisitEventData;
use App\Application\Itinerary\Services\RecordVisitEventService;
use App\Domain\Itinerary\Models\ItineraryItem;
use App\Http\Controllers\Controller;
use App\Http\Requests\Api\V1\Itinerary\RecordVisitEventRequest;
use App\Http\Resources\Api\V1\VisitEventResource;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Gate;

final class VisitEventController extends Controller
{
    /**
     * Record a visit event (suggested, confirmed, revoked) for an itinerary item.
     */
    public function store(
        RecordVisitEventRequest $request,
        ItineraryItem $item,
        RecordVisitEventService $service,
    ): JsonResponse {
        Gate::authorize('update', $item->trip);

        $event = $service->execute(
            $item,
            $request->user(),
            RecordVisitEventData::from($request->validated()),
        );

        return (new VisitEventResource($event))
            ->response()
            ->setStatusCode(201);
    }
}
