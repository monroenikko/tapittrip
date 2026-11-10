<?php

declare(strict_types=1);

namespace App\Services\Circles;

use App\DTOs\Activity\RecordActivityEventData;
use App\DTOs\Circles\AcceptTripInvitationResult;
use App\DTOs\Circles\CreatedTripInvitationResult;
use App\DTOs\Circles\CreateTripInvitationData;
use App\Models\Trip;
use App\Models\TripInvitation;
use App\Models\TripMember;
use App\Models\User;
use App\Services\Activity\ActivityService;
use Carbon\CarbonImmutable;
use Illuminate\Auth\Access\AuthorizationException;
use Illuminate\Database\Eloquent\Collection;
use Illuminate\Database\Eloquent\ModelNotFoundException;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;

final class TripCircleService
{
    public function __construct(
        private readonly ActivityService $activityService,
    ) {}

    /**
     * Normalize a raw invitation token or extract it from a shared URL path.
     */
    public static function normalizeRawToken(string $tokenOrUrl): string
    {
        $trimmed = trim($tokenOrUrl);

        if (str_contains($trimmed, '/')) {
            $parsedPath = parse_url($trimmed, PHP_URL_PATH);
            $path = is_string($parsedPath) ? $parsedPath : $trimmed;
            $segments = array_values(array_filter(explode('/', $path), static fn (string $s): bool => $s !== ''));
            if ($segments !== []) {
                $trimmed = end($segments);
            }
        }

        return trim($trimmed);
    }

    /**
     * List all accepted members in a trip circle.
     *
     * @return Collection<int, TripMember>
     *
     * @throws AuthorizationException
     */
    public function listMembers(Trip $trip, User $actor): Collection
    {
        if (! $trip->hasMember($actor)) {
            throw new AuthorizationException('You are not a member of this trip circle.');
        }

        return $trip->members()
            ->where('invitation_status', 'accepted')
            ->with(['user'])
            ->orderByRaw("CASE WHEN role = 'owner' THEN 0 WHEN role = 'editor' THEN 1 ELSE 2 END")
            ->orderBy('created_at')
            ->get();
    }

    /**
     * Update a companion member's role (organizer only).
     *
     * @throws AuthorizationException
     * @throws ValidationException
     */
    public function updateMemberRole(Trip $trip, TripMember $member, string $role, User $actor): TripMember
    {
        if ($member->trip_id !== $trip->id) {
            throw new ModelNotFoundException('Member not found in this trip.');
        }

        if ($trip->memberRole($actor) !== 'owner') {
            throw new AuthorizationException('Only the trip organizer can manage member roles.');
        }

        if ($member->user_id === $trip->owner_id || $member->role === 'owner') {
            throw ValidationException::withMessages([
                'role' => ['The trip organizer role cannot be changed directly.'],
            ]);
        }

        $member->update(['role' => $role]);

        return $member->fresh(['user']);
    }

    /**
     * Remove a companion member (organizer only) or allow a companion to leave the circle.
     *
     * @throws AuthorizationException
     * @throws ValidationException
     */
    public function removeMember(Trip $trip, TripMember $member, User $actor): void
    {
        if ($member->trip_id !== $trip->id) {
            throw new ModelNotFoundException('Member not found in this trip.');
        }

        $isOwner = $trip->memberRole($actor) === 'owner';
        $isSelf = $member->user_id === $actor->id;

        if (! $isOwner && ! $isSelf) {
            throw new AuthorizationException('Only the trip organizer can remove other members.');
        }

        if ($member->user_id === $trip->owner_id || $member->role === 'owner') {
            throw ValidationException::withMessages([
                'member' => ['The sole organizer cannot leave the trip without deleting it.'],
            ]);
        }

        $member->delete();
    }

    /**
     * List invitations issued for a trip (organizer only).
     *
     * @return Collection<int, TripInvitation>
     *
     * @throws AuthorizationException
     */
    public function listInvitations(Trip $trip, User $actor): Collection
    {
        if ($trip->memberRole($actor) !== 'owner') {
            throw new AuthorizationException('Only the trip organizer can manage invitations.');
        }

        return $trip->invitations()
            ->with(['inviter'])
            ->get();
    }

    /**
     * Generate a shareable invitation link with a hashed single/bounded-use token.
     *
     * @throws AuthorizationException
     */
    public function createInvitation(
        Trip $trip,
        User $actor,
        CreateTripInvitationData $data,
    ): CreatedTripInvitationResult {
        if ($trip->memberRole($actor) !== 'owner') {
            throw new AuthorizationException('Only the trip organizer can create invitations.');
        }

        $rawToken = bin2hex(random_bytes(24));
        $tokenHash = hash('sha256', $rawToken);

        /** @var TripInvitation $invitation */
        $invitation = TripInvitation::query()->create([
            'trip_id' => $trip->id,
            'inviter_id' => $actor->id,
            'token_hash' => $tokenHash,
            'proposed_role' => $data->proposedRole,
            'status' => 'active',
            'max_uses' => $data->maxUses,
            'use_count' => 0,
            'expires_at' => CarbonImmutable::now('UTC')->addDays($data->expiresInDays),
        ]);

        $configuredBaseUrl = rtrim((string) config('app.invite_base_url', ''), '/');
        $shareUrl = $configuredBaseUrl !== ''
            ? $configuredBaseUrl.'/invite/'.$rawToken
            : $rawToken;

        return new CreatedTripInvitationResult(
            invitation: $invitation->load(['inviter']),
            rawToken: $rawToken,
            shareUrl: $shareUrl,
        );
    }

    /**
     * Revoke an active invitation (organizer only).
     *
     * @throws AuthorizationException
     */
    public function revokeInvitation(Trip $trip, TripInvitation $invitation, User $actor): TripInvitation
    {
        if ($invitation->trip_id !== $trip->id) {
            throw new ModelNotFoundException('Invitation not found for this trip.');
        }

        if ($trip->memberRole($actor) !== 'owner') {
            throw new AuthorizationException('Only the trip organizer can revoke invitations.');
        }

        if ($invitation->status !== 'revoked') {
            $invitation->update([
                'status' => 'revoked',
                'revoked_at' => CarbonImmutable::now('UTC'),
            ]);
        }

        return $invitation->fresh(['inviter']);
    }

    /**
     * Preview minimal safe summary fields for an invitation token (TC-1.4, TC-1.9).
     * Never exposes itinerary items, dates, stay addresses, expenses, or member identities.
     *
     * @return array{
     *     trip_title: string,
     *     destination_country: ?string,
     *     proposed_role: string,
     *     inviter_name: string,
     *     expires_at: string,
     *     status: string
     * }
     */
    public function previewInvitation(string $tokenOrUrl): array
    {
        $rawToken = self::normalizeRawToken($tokenOrUrl);
        if ($rawToken === '') {
            throw new ModelNotFoundException('Invitation not found.');
        }

        $tokenHash = hash('sha256', $rawToken);

        /** @var TripInvitation|null $invitation */
        $invitation = TripInvitation::query()
            ->where('token_hash', $tokenHash)
            ->with(['trip', 'inviter'])
            ->first();

        if ($invitation === null || $invitation->trip === null) {
            throw new ModelNotFoundException('Invitation not found.');
        }

        return [
            'trip_title' => (string) $invitation->trip->title,
            'destination_country' => $invitation->trip->destination_country,
            'proposed_role' => (string) $invitation->proposed_role,
            'inviter_name' => (string) ($invitation->inviter?->display_name ?? $invitation->inviter?->name ?? 'Organizer'),
            'expires_at' => $invitation->expires_at->toIso8601String(),
            'status' => $invitation->effectiveStatus(),
        ];
    }

    /**
     * Atomically accept an invitation token and admit the authenticated traveler.
     *
     * @throws ValidationException
     */
    public function acceptInvitation(string $tokenOrUrl, User $user): AcceptTripInvitationResult
    {
        $rawToken = self::normalizeRawToken($tokenOrUrl);
        if ($rawToken === '') {
            throw new ModelNotFoundException('Invitation not found.');
        }

        $tokenHash = hash('sha256', $rawToken);

        return DB::transaction(function () use ($tokenHash, $user): AcceptTripInvitationResult {
            /** @var TripInvitation|null $invitation */
            $invitation = TripInvitation::query()
                ->where('token_hash', $tokenHash)
                ->lockForUpdate()
                ->first();

            if ($invitation === null) {
                throw new ModelNotFoundException('Invitation not found.');
            }

            /** @var Trip|null $trip */
            $trip = Trip::query()->find($invitation->trip_id);
            if ($trip === null) {
                throw new ModelNotFoundException('Trip not found.');
            }

            $status = $invitation->effectiveStatus();

            if ($status === 'revoked') {
                throw ValidationException::withMessages([
                    'token' => ['This invitation has been revoked by the organizer.'],
                ]);
            }

            if ($status === 'expired') {
                throw ValidationException::withMessages([
                    'token' => ['This invitation link has expired.'],
                ]);
            }

            // Check if the traveler is already an active accepted member (idempotent retry protection, TC-1.5)
            /** @var TripMember|null $existingActive */
            $existingActive = TripMember::query()
                ->where('trip_id', $trip->id)
                ->where('user_id', $user->id)
                ->where('invitation_status', 'accepted')
                ->first();

            if ($existingActive !== null) {
                return new AcceptTripInvitationResult(
                    trip: $trip,
                    member: $existingActive->load(['user']),
                    alreadyMember: true,
                );
            }

            if ($status === 'exhausted') {
                throw ValidationException::withMessages([
                    'token' => ['This invitation link has already been used up.'],
                ]);
            }

            $newUseCount = $invitation->use_count + 1;
            $invitation->update([
                'use_count' => $newUseCount,
                'status' => $newUseCount >= $invitation->max_uses ? 'exhausted' : 'active',
            ]);

            /** @var TripMember|null $existingAny */
            $existingAny = TripMember::withTrashed()
                ->where('trip_id', $trip->id)
                ->where('user_id', $user->id)
                ->first();

            if ($existingAny !== null) {
                if ($existingAny->trashed()) {
                    $existingAny->restore();
                }
                $existingAny->update([
                    'role' => $invitation->proposed_role,
                    'invitation_status' => 'accepted',
                ]);
                $member = $existingAny;
            } else {
                /** @var TripMember $member */
                $member = TripMember::query()->create([
                    'trip_id' => $trip->id,
                    'user_id' => $user->id,
                    'role' => $invitation->proposed_role,
                    'invitation_status' => 'accepted',
                ]);
            }

            $displayName = $user->display_name ?? $user->name;
            $this->activityService->recordEvent(
                $trip,
                $user,
                new RecordActivityEventData(
                    eventType: 'member_joined',
                    title: "{$displayName} joined the trip circle",
                    summary: "Joined as {$invitation->proposed_role}.",
                    entityType: 'trip_member',
                    entityId: (string) $member->id,
                    metadata: [
                        'role' => $invitation->proposed_role,
                    ],
                )
            );

            return new AcceptTripInvitationResult(
                trip: $trip,
                member: $member->load(['user']),
                alreadyMember: false,
            );
        });
    }
}

