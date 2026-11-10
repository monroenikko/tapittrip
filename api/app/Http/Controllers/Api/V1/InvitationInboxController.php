<?php

declare(strict_types=1);

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Requests\Api\V1\Circles\DeclineDirectInvitationRequest;
use App\Http\Resources\Api\V1\IncomingTripInvitationResource;
use App\Http\Resources\Api\V1\TripCircleMemberResource;
use App\Http\Resources\Api\V1\TripOwnershipTransferResource;
use App\Http\Resources\Api\V1\TripResource;
use App\Models\TripInvitation;
use App\Models\TripOwnershipTransfer;
use App\Services\Circles\TripCircleService;
use App\Services\Circles\TripOwnershipService;
use App\Support\Http\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

final class InvitationInboxController extends Controller
{
    public function __construct(
        private readonly TripCircleService $circleService,
        private readonly TripOwnershipService $ownershipService,
        private readonly ApiResponse $response,
    ) {}

    public function invitations(Request $request): JsonResponse
    {
        $invitations = $this->circleService->listIncomingInvitations($request->user());

        return $this->response->success(IncomingTripInvitationResource::collection($invitations));
    }

    public function acceptInvitation(TripInvitation $invitation, Request $request): JsonResponse
    {
        $result = $this->circleService->acceptDirectInvitation($invitation, $request->user());

        return $this->response->success([
            'trip' => (new TripResource($result->trip))->resolve($request),
            'member' => (new TripCircleMemberResource($result->member))->resolve($request),
            'already_member' => $result->alreadyMember,
        ]);
    }

    public function declineInvitation(
        TripInvitation $invitation,
        DeclineDirectInvitationRequest $request,
    ): JsonResponse {
        $declined = $this->circleService->declineDirectInvitation(
            $invitation,
            $request->user(),
            blockSender: (bool) $request->validated('block_sender', false),
        );

        return $this->response->success(new IncomingTripInvitationResource($declined));
    }

    public function ownershipTransfers(Request $request): JsonResponse
    {
        $transfers = $this->ownershipService->listIncomingTransfers($request->user());

        return $this->response->success(TripOwnershipTransferResource::collection($transfers));
    }

    public function acceptOwnershipTransfer(
        TripOwnershipTransfer $transfer,
        Request $request,
    ): JsonResponse {
        $result = $this->ownershipService->acceptTransfer($transfer, $request->user());

        return $this->response->success([
            'trip' => (new TripResource($result->trip))->resolve($request),
            'transfer' => (new TripOwnershipTransferResource($result->transfer))->resolve($request),
        ]);
    }

    public function declineOwnershipTransfer(
        TripOwnershipTransfer $transfer,
        Request $request,
    ): JsonResponse {
        $declined = $this->ownershipService->declineTransfer($transfer, $request->user());

        return $this->response->success(new TripOwnershipTransferResource($declined));
    }
}
