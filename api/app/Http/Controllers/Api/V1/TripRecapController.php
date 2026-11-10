<?php

declare(strict_types=1);

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Resources\Api\V1\TripRecapResource;
use App\Models\Trip;
use App\Services\Recap\TripRecapService;
use App\Support\Http\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

final class TripRecapController extends Controller
{
    public function __construct(
        private readonly TripRecapService $recapService,
        private readonly ApiResponse $response,
    ) {}

    public function show(Trip $trip, Request $request): JsonResponse
    {
        $recap = $this->recapService->getRecap($trip, $request->user());

        return $this->response->success(new TripRecapResource($recap));
    }
}
