<?php

declare(strict_types=1);

namespace App\Http\Controllers\Api\V1;

use App\Application\Expenses\Data\RecordSettlementData;
use App\Application\Expenses\Services\CalculateGroupSettlementService;
use App\Application\Expenses\Services\RecordSettlementService;
use App\Domain\Trips\Models\Trip;
use App\Http\Controllers\Controller;
use App\Http\Requests\Api\V1\Expenses\RecordSettlementRequest;
use App\Http\Resources\Api\V1\ExpenseSettlementResource;
use App\Http\Resources\Api\V1\GroupSettlementResource;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Gate;

final class GroupSettlementController extends Controller
{
    /**
     * Get member net balances and simplified debt settlement transfers.
     */
    public function index(
        Request $request,
        Trip $trip,
        CalculateGroupSettlementService $service,
    ): JsonResponse {
        Gate::authorize('view', $trip);

        $result = $service->execute($trip, $request->user());

        return (new GroupSettlementResource($result))->response();
    }

    /**
     * Record a debt settlement between two trip members.
     */
    public function store(
        RecordSettlementRequest $request,
        Trip $trip,
        RecordSettlementService $service,
    ): JsonResponse {
        Gate::authorize('update', $trip);

        $settlement = $service->execute(
            $trip,
            $request->user(),
            RecordSettlementData::fromArray($request->validated()),
        );

        return (new ExpenseSettlementResource($settlement))
            ->response()
            ->setStatusCode(201);
    }
}
