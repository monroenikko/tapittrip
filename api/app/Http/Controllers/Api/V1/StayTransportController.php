<?php

declare(strict_types=1);

namespace App\Http\Controllers\Api\V1;

use App\DTOs\Stays\CompareStayTransportData;
use App\Http\Controllers\Controller;
use App\Http\Requests\Api\V1\Stays\CompareStayTransportRequest;
use App\Models\Stay;
use App\Services\Stays\StayService;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Gate;

final class StayTransportController extends Controller
{
    public function __construct(
        private readonly StayService $stayService,
    ) {}

    /**
     * Compare luggage-aware airport/origin to stay transportation options.
     */
    public function compare(CompareStayTransportRequest $request, Stay $stay): JsonResponse
    {
        Gate::authorize('view', $stay->trip);

        $result = $this->stayService->compareTransport(
            $stay,
            CompareStayTransportData::from($request->validated()),
        );

        return response()->json([
            'data' => $result,
        ]);
    }
}
