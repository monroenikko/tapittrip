<?php

declare(strict_types=1);

namespace App\Http\Controllers\Api\V1;

use App\Application\Stays\Data\CompareStayTransportData;
use App\Application\Stays\Services\CompareStayTransportService;
use App\Domain\Stays\Models\Stay;
use App\Http\Controllers\Controller;
use App\Http\Requests\Api\V1\Stays\CompareStayTransportRequest;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Gate;

final class StayTransportController extends Controller
{
    /**
     * Compare luggage-aware airport/origin to stay transportation options.
     */
    public function compare(
        CompareStayTransportRequest $request,
        Stay $stay,
        CompareStayTransportService $service,
    ): JsonResponse {
        Gate::authorize('view', $stay->trip);

        $result = $service->handle(
            $stay,
            CompareStayTransportData::from($request->validated()),
        );

        return response()->json([
            'data' => $result,
        ]);
    }
}
