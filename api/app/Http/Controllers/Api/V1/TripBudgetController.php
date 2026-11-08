<?php

declare(strict_types=1);

namespace App\Http\Controllers\Api\V1;

use App\Application\Expenses\Data\SetTripBudgetData;
use App\Application\Expenses\Services\SetTripBudgetService;
use App\Domain\Trips\Models\Trip;
use App\Http\Controllers\Controller;
use App\Http\Requests\Api\V1\Expenses\SetTripBudgetRequest;
use App\Http\Resources\Api\V1\TripBudgetResource;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Gate;

final class TripBudgetController extends Controller
{
    /**
     * Get the target budget for a trip.
     */
    public function show(Request $request, Trip $trip): JsonResponse
    {
        Gate::authorize('view', $trip);

        $budget = $trip->budget;
        if (! $budget) {
            return response()->json(['data' => null]);
        }

        return (new TripBudgetResource($budget))->response();
    }

    /**
     * Set or update the target budget and base currency for a trip.
     */
    public function store(
        SetTripBudgetRequest $request,
        Trip $trip,
        SetTripBudgetService $service,
    ): JsonResponse {
        Gate::authorize('update', $trip);

        $data = SetTripBudgetData::fromArray($request->validated());
        $budget = $service->execute($trip, $data);

        return (new TripBudgetResource($budget))
            ->response()
            ->setStatusCode(200);
    }
}
