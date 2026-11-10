<?php

declare(strict_types=1);

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Resources\Api\V1\TripCircleMemberResource;
use App\Http\Resources\Api\V1\TripResource;
use App\Services\Circles\TripCircleService;
use App\Support\Http\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

final class InvitationRedemptionController extends Controller
{
    public function __construct(
        private readonly TripCircleService $circleService,
        private readonly ApiResponse $response,
    ) {}

    public function preview(string $token): JsonResponse
    {
        $summary = $this->circleService->previewInvitation($token);

        return $this->response->success($summary);
    }

    public function accept(string $token, Request $request): JsonResponse
    {
        $result = $this->circleService->acceptInvitation($token, $request->user());

        return $this->response->success([
            'trip' => (new TripResource($result->trip))->resolve($request),
            'member' => (new TripCircleMemberResource($result->member))->resolve($request),
            'already_member' => $result->alreadyMember,
        ]);
    }
}

