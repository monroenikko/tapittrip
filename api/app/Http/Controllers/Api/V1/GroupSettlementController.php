<?php

declare(strict_types=1);

namespace App\Http\Controllers\Api\V1;

use App\DTOs\Expenses\RecordSettlementData;
use App\Http\Controllers\Controller;
use App\Http\Requests\Api\V1\Expenses\RecordSettlementRequest;
use App\Http\Resources\Api\V1\ExpenseSettlementResource;
use App\Http\Resources\Api\V1\GroupSettlementResource;
use App\Models\Trip;
use App\Services\Expenses\ExpenseService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Gate;

final class GroupSettlementController extends Controller
{
    public function __construct(
        private readonly ExpenseService $expenseService,
    ) {}

    /**
     * Get member net balances and simplified debt settlement transfers.
     */
    public function index(
        Request $request,
        Trip $trip,
    ): JsonResponse {
        Gate::authorize('view', $trip);

        $result = $this->expenseService->calculateGroupSettlement($trip, $request->user());

        return (new GroupSettlementResource($result))->response();
    }

    /**
     * Record a debt settlement between two trip members.
     */
    public function store(
        RecordSettlementRequest $request,
        Trip $trip,
    ): JsonResponse {
        Gate::authorize('update', $trip);

        $settlement = $this->expenseService->recordSettlement(
            $trip,
            $request->user(),
            RecordSettlementData::fromArray($request->validated()),
        );

        return (new ExpenseSettlementResource($settlement))
            ->response()
            ->setStatusCode(201);
    }
}
