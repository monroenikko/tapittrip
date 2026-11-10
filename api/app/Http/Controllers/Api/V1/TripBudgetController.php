<?php

declare(strict_types=1);

namespace App\Http\Controllers\Api\V1;

use App\DTOs\Expenses\SetTripBudgetData;
use App\Http\Controllers\Controller;
use App\Http\Requests\Api\V1\Expenses\SetTripBudgetRequest;
use App\Http\Resources\Api\V1\TripBudgetResource;
use App\Models\Trip;
use App\Services\Expenses\ExpenseService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Gate;

final class TripBudgetController extends Controller
{
    public function __construct(
        private readonly ExpenseService $expenseService,
    ) {}

    /**
     * Get the target budget for a trip.
     */
    public function show(Request $request, Trip $trip): JsonResponse
    {
        Gate::authorize('view', $trip);

        $budget = $this->expenseService->getTripBudget($trip);
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
    ): JsonResponse {
        Gate::authorize('update', $trip);

        $data = SetTripBudgetData::fromArray($request->validated());
        $budget = $this->expenseService->setBudget($trip, $data);

        return (new TripBudgetResource($budget))
            ->response()
            ->setStatusCode(200);
    }
}
