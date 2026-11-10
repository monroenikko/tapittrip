<?php

declare(strict_types=1);

namespace App\Http\Controllers\Api\V1;

use App\DTOs\Itinerary\RecordVisitEventData;
use App\Http\Controllers\Controller;
use App\Http\Requests\Api\V1\Itinerary\RecordVisitEventRequest;
use App\Http\Resources\Api\V1\VisitEventResource;
use App\Models\ItineraryItem;
use App\Services\Itinerary\ItineraryService;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Gate;

final class VisitEventController extends Controller
{
    public function __construct(
        private readonly ItineraryService $itineraryService,
    ) {}

    /**
     * Record a visit event (suggested, confirmed, revoked) for an itinerary item.
     */
    public function store(RecordVisitEventRequest $request, ItineraryItem $item): JsonResponse
    {
        Gate::authorize('update', $item->trip);

        $event = $this->itineraryService->recordVisitEvent(
            $item,
            $request->user(),
            RecordVisitEventData::from($request->validated()),
        );

        return (new VisitEventResource($event))
            ->response()
            ->setStatusCode(201);
    }
}
