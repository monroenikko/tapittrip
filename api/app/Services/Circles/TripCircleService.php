<?php

declare(strict_types=1);

namespace App\Services\Circles;

use App\DTOs\Activity\RecordActivityEventData;
use App\DTOs\Circles\AcceptTripInvitationResult;
use App\DTOs\Circles\CreatedDirectInvitationResult;
use App\DTOs\Circles\CreateDirectInvitationData;
use App\DTOs\Circles\CreatedTripInvitationResult;
use App\DTOs\Circles\CreateTripInvitationData;
use App\Models\ChecklistItem;
use App\Models\Trip;
use App\Models\TripInvitation;
use App\Models\TripMember;
use App\Models\TripOwnershipTransfer;
use App\Models\TripTraveler;
use App\Models\User;
use App\Models\UserBlock;
use App\Services\Activity\ActivityService;
use App\Services\Notifications\NotificationService;
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

        DB::transaction(function () use ($trip, $member): void {
            TripOwnershipTransfer::query()
                ->where('trip_id', $trip->id)
                ->where('to_user_id', $member->user_id)
                ->where('status', 'pending')
                ->update([
                    'status' => 'cancelled',
                    'responded_at' => CarbonImmutable::now('UTC'),
                ]);

            app(NotificationService::class)
                ->cancelMemberTripNotifications($trip, $member->user_id);

            ChecklistItem::query()
                ->where('trip_id', $trip->id)
                ->where('assigned_user_id', $member->user_id)
                ->update([
                    'assigned_user_id' => null,
                    'version' => DB::raw('version + 1'),
                ]);

            $managedTravelerIds = TripTraveler::query()
                ->where('trip_id', $trip->id)
                ->where('managing_user_id', $member->user_id)
                ->pluck('id')
                ->all();

            if ($managedTravelerIds !== []) {
                ChecklistItem::query()
                    ->where('trip_id', $trip->id)
                    ->whereIn('assigned_traveler_id', $managedTravelerIds)
                    ->update([
                        'assigned_traveler_id' => null,
                        'version' => DB::raw('version + 1'),
                    ]);

                TripTraveler::query()
                    ->whereIn('id', $managedTravelerIds)
                    ->delete();
            }

            TripTraveler::query()
                ->where('trip_id', $trip->id)
                ->where('linked_member_id', $member->id)
                ->where('managing_user_id', '!=', $member->user_id)
                ->update(['linked_member_id' => null]);

            $member->delete();
        });
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
            ->with(['inviter', 'targetUser'])
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
            'invite_type' => 'link',
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
     * Send a targeted direct invitation by privacy-safe friend code (TC-2.1, TC-2.3).
     *
     * @throws AuthorizationException
     * @throws ValidationException
     */
    public function createDirectInvitation(
        Trip $trip,
        User $actor,
        CreateDirectInvitationData $data,
    ): CreatedDirectInvitationResult {
        if ($trip->memberRole($actor) !== 'owner') {
            throw new AuthorizationException('Only the trip organizer can create invitations.');
        }

        $normalizedCode = strtoupper(trim($data->friendCode));

        return DB::transaction(function () use ($trip, $actor, $data, $normalizedCode): CreatedDirectInvitationResult {
            /** @var User|null $targetUser */
            $targetUser = User::query()
                ->where('friend_code', $normalizedCode)
                ->first();

            $isBlocked = $targetUser !== null && UserBlock::query()
                ->where('blocker_id', $targetUser->id)
                ->where('blocked_id', $actor->id)
                ->exists();

            // Nonexistent code, self-invite, direct-invite opt-out, and blocked sender
            // produce the identical safe error without leaking account existence or block status.
            if ($targetUser === null
                || $targetUser->id === $actor->id
                || ! $targetUser->accepts_direct_invites
                || $isBlocked) {
                throw ValidationException::withMessages([
                    'friend_code' => ['Unable to deliver invitation to that identifier. Please check the friend code and try again.'],
                ]);
            }

            if ($trip->hasMember($targetUser)) {
                throw ValidationException::withMessages([
                    'friend_code' => ['This traveler is already an accepted member of the trip circle.'],
                ]);
            }

            $now = CarbonImmutable::now('UTC');

            /** @var TripInvitation|null $existingPending */
            $existingPending = TripInvitation::query()
                ->where('trip_id', $trip->id)
                ->where('invite_type', 'direct')
                ->where('target_user_id', $targetUser->id)
                ->where('status', 'pending')
                ->lockForUpdate()
                ->first();

            if ($existingPending !== null) {
                if (! $existingPending->expires_at->isPast()) {
                    return new CreatedDirectInvitationResult(
                        invitation: $existingPending->load(['inviter', 'targetUser']),
                        alreadyPending: true,
                    );
                }

                $existingPending->update(['status' => 'expired']);
            }

            /** @var TripInvitation $invitation */
            $invitation = TripInvitation::query()->create([
                'trip_id' => $trip->id,
                'inviter_id' => $actor->id,
                'invite_type' => 'direct',
                'token_hash' => null,
                'target_user_id' => $targetUser->id,
                'proposed_role' => $data->proposedRole,
                'status' => 'pending',
                'max_uses' => 1,
                'use_count' => 0,
                'expires_at' => $now->addDays($data->expiresInDays),
            ]);

            return new CreatedDirectInvitationResult(
                invitation: $invitation->load(['inviter', 'targetUser']),
                alreadyPending: false,
            );
        });
    }

    /**
     * List pending direct invitations in the authenticated traveler's inbox (TC-2.2).
     *
     * @return Collection<int, TripInvitation>
     */
    public function listIncomingInvitations(User $user): Collection
    {
        return TripInvitation::query()
            ->where('invite_type', 'direct')
            ->where('target_user_id', $user->id)
            ->where('status', 'pending')
            ->whereHas('trip')
            ->with(['trip', 'inviter'])
            ->orderByDesc('created_at')
            ->get();
    }

    /**
     * Accept a targeted direct invitation cleanly inside an atomic transaction (TC-2.2).
     *
     * @throws AuthorizationException
     * @throws ValidationException
     */
    public function acceptDirectInvitation(TripInvitation $invitation, User $user): AcceptTripInvitationResult
    {
        if (($invitation->invite_type ?? 'link') !== 'direct') {
            throw new ModelNotFoundException('Direct invitation not found.');
        }

        if ($invitation->target_user_id !== $user->id) {
            throw new AuthorizationException('You are not authorized to respond to this invitation.');
        }

        return DB::transaction(function () use ($invitation, $user): AcceptTripInvitationResult {
            /** @var TripInvitation $locked */
            $locked = TripInvitation::query()
                ->where('id', $invitation->id)
                ->lockForUpdate()
                ->firstOrFail();

            if ($locked->target_user_id !== $user->id) {
                throw new AuthorizationException('You are not authorized to respond to this invitation.');
            }

            /** @var Trip|null $trip */
            $trip = Trip::query()->find($locked->trip_id);
            if ($trip === null) {
                throw new ModelNotFoundException('Trip not found.');
            }

            $status = $locked->effectiveStatus();

            if ($status === 'accepted') {
                /** @var TripMember|null $existingMember */
                $existingMember = TripMember::query()
                    ->where('trip_id', $trip->id)
                    ->where('user_id', $user->id)
                    ->where('invitation_status', 'accepted')
                    ->first();

                if ($existingMember !== null) {
                    return new AcceptTripInvitationResult(
                        trip: $trip,
                        member: $existingMember->load(['user']),
                        alreadyMember: true,
                    );
                }
            }

            if ($status === 'revoked') {
                throw ValidationException::withMessages([
                    'invitation' => ['This invitation has been revoked by the organizer.'],
                ]);
            }

            if ($status === 'declined') {
                throw ValidationException::withMessages([
                    'invitation' => ['Declined invitations cannot be accepted later. Ask the organizer for a new invite.'],
                ]);
            }

            if ($status === 'expired') {
                throw ValidationException::withMessages([
                    'invitation' => ['This invitation has expired.'],
                ]);
            }

            /** @var TripMember|null $existingActive */
            $existingActive = TripMember::query()
                ->where('trip_id', $trip->id)
                ->where('user_id', $user->id)
                ->where('invitation_status', 'accepted')
                ->first();

            $locked->update([
                'status' => 'accepted',
                'use_count' => 1,
                'responded_at' => CarbonImmutable::now('UTC'),
            ]);

            if ($existingActive !== null) {
                return new AcceptTripInvitationResult(
                    trip: $trip,
                    member: $existingActive->load(['user']),
                    alreadyMember: true,
                );
            }

            $member = $this->admitOrRestoreMember($trip, $user, (string) $locked->proposed_role);

            return new AcceptTripInvitationResult(
                trip: $trip,
                member: $member->load(['user']),
                alreadyMember: false,
            );
        });
    }

    /**
     * Decline a targeted direct invitation, optionally blocking future targeted invites from its sender (TC-2.2, TC-2.3).
     *
     * @throws AuthorizationException
     * @throws ValidationException
     */
    public function declineDirectInvitation(
        TripInvitation $invitation,
        User $user,
        bool $blockSender = false,
    ): TripInvitation {
        if (($invitation->invite_type ?? 'link') !== 'direct') {
            throw new ModelNotFoundException('Direct invitation not found.');
        }

        if ($invitation->target_user_id !== $user->id) {
            throw new AuthorizationException('You are not authorized to respond to this invitation.');
        }

        return DB::transaction(function () use ($invitation, $user, $blockSender): TripInvitation {
            /** @var TripInvitation $locked */
            $locked = TripInvitation::query()
                ->where('id', $invitation->id)
                ->lockForUpdate()
                ->firstOrFail();

            $status = $locked->effectiveStatus();

            if ($status === 'accepted') {
                throw ValidationException::withMessages([
                    'invitation' => ['This invitation has already been accepted.'],
                ]);
            }

            if ($status === 'revoked') {
                throw ValidationException::withMessages([
                    'invitation' => ['This invitation was revoked by the organizer.'],
                ]);
            }

            if ($status !== 'declined') {
                $locked->update([
                    'status' => 'declined',
                    'responded_at' => CarbonImmutable::now('UTC'),
                ]);
            }

            if ($blockSender && $locked->inviter_id !== $user->id) {
                UserBlock::query()->firstOrCreate([
                    'blocker_id' => $user->id,
                    'blocked_id' => $locked->inviter_id,
                ]);
            }

            return $locked->fresh(['trip', 'inviter']);
        });
    }

    /**
     * Revoke an active invitation (organizer only).
     *
     * @throws AuthorizationException
     * @throws ValidationException
     */
    public function revokeInvitation(Trip $trip, TripInvitation $invitation, User $actor): TripInvitation
    {
        if ($invitation->trip_id !== $trip->id) {
            throw new ModelNotFoundException('Invitation not found for this trip.');
        }

        if ($trip->memberRole($actor) !== 'owner') {
            throw new AuthorizationException('Only the trip organizer can revoke invitations.');
        }

        $effective = $invitation->effectiveStatus();
        if (in_array($effective, ['accepted', 'declined'], true)) {
            throw ValidationException::withMessages([
                'invitation' => ["Cannot revoke an invitation that has already been {$effective}."],
            ]);
        }

        if ($invitation->status !== 'revoked') {
            $invitation->update([
                'status' => 'revoked',
                'revoked_at' => CarbonImmutable::now('UTC'),
            ]);
        }

        return $invitation->fresh(['inviter', 'targetUser']);
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

            $member = $this->admitOrRestoreMember($trip, $user, (string) $invitation->proposed_role);

            return new AcceptTripInvitationResult(
                trip: $trip,
                member: $member->load(['user']),
                alreadyMember: false,
            );
        });
    }

    /**
     * Create or restore a traveler's TripMember row cleanly and log join activity.
     */
    private function admitOrRestoreMember(Trip $trip, User $user, string $role): TripMember
    {
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
                'role' => $role,
                'invitation_status' => 'accepted',
            ]);
            $member = $existingAny;
        } else {
            /** @var TripMember $member */
            $member = TripMember::query()->create([
                'trip_id' => $trip->id,
                'user_id' => $user->id,
                'role' => $role,
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
                summary: "Joined as {$role}.",
                entityType: 'trip_member',
                entityId: (string) $member->id,
                metadata: [
                    'role' => $role,
                ],
            )
        );

        return $member;
    }
}
