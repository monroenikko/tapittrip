<?php

declare(strict_types=1);

namespace App\Http\Controllers\Api\V1;

use App\DTOs\Circles\CreateTripInvitationData;
use App\Http\Controllers\Controller;
use App\Http\Requests\Api\V1\Circles\CreateTripInvitationRequest;
use App\Http\Requests\Api\V1\Circles\UpdateTripMemberRoleRequest;
use App\Http\Resources\Api\V1\TripCircleMemberResource;
use App\Http\Resources\Api\V1\TripInvitationResource;
use App\Models\Trip;
use App\Models\TripInvitation;
use App\Models\TripMember;
use App\Services\Circles\TripCircleService;
use App\Support\Http\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Response;

final class TripCircleController extends Controller
{
    public function __construct(
        private readonly TripCircleService $circleService,
        private readonly ApiResponse $response,
    ) {}

    public function members(Trip $trip, Request $request): JsonResponse
    {
        $members = $this->circleService->listMembers($trip, $request->user());

        return $this->response->success(TripCircleMemberResource::collection($members));
    }

    public function updateMemberRole(
        Trip $trip,
        TripMember $member,
        UpdateTripMemberRoleRequest $request,
    ): JsonResponse {
        $updated = $this->circleService->updateMemberRole(
            $trip,
            $member,
            (string) $request->validated('role'),
            $request->user(),
        );

        return $this->response->success(new TripCircleMemberResource($updated));
    }

    public function removeMember(Trip $trip, TripMember $member, Request $request): Response
    {
        $this->circleService->removeMember($trip, $member, $request->user());

        return $this->response->noContent();
    }

    public function invitations(Trip $trip, Request $request): JsonResponse
    {
        $invitations = $this->circleService->listInvitations($trip, $request->user());

        return $this->response->success(TripInvitationResource::collection($invitations));
    }

    public function storeInvitation(
        Trip $trip,
        CreateTripInvitationRequest $request,
    ): JsonResponse {
        $validated = $request->validated();

        $result = $this->circleService->createInvitation(
            $trip,
            $request->user(),
            new CreateTripInvitationData(
                proposedRole: (string) ($validated['proposed_role'] ?? 'viewer'),
                maxUses: (int) ($validated['max_uses'] ?? 1),
                expiresInDays: (int) ($validated['expires_in_days'] ?? 7),
            ),
        );

        return $this->response->success([
            ...(new TripInvitationResource($result->invitation))->resolve($request),
            'invite_token' => $result->rawToken,
            'share_url' => $result->shareUrl,
        ], 201);
    }

    public function revokeInvitation(
        Trip $trip,
        TripInvitation $invitation,
        Request $request,
    ): JsonResponse {
        $revoked = $this->circleService->revokeInvitation($trip, $invitation, $request->user());

        return $this->response->success(new TripInvitationResource($revoked));
    }
}

