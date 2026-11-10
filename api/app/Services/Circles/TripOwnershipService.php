<?php

declare(strict_types=1);

namespace App\Services\Circles;

use App\DTOs\Activity\RecordActivityEventData;
use App\DTOs\Circles\AcceptOwnershipTransferResult;
use App\DTOs\Circles\InitiateOwnershipTransferData;
use App\DTOs\Circles\InitiateOwnershipTransferResult;
use App\Models\Trip;
use App\Models\TripMember;
use App\Models\TripOwnershipTransfer;
use App\Models\User;
use App\Services\Activity\ActivityService;
use Carbon\CarbonImmutable;
use Illuminate\Auth\Access\AuthorizationException;
use Illuminate\Database\Eloquent\Collection;
use Illuminate\Database\Eloquent\ModelNotFoundException;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;

final class TripOwnershipService
{
    public function __construct(
        private readonly ActivityService $activityService,
    ) {}

    /**
     * Fetch the currently active pending handover request for a trip (organizer view).
     *
     * @throws AuthorizationException
     */
    public function getPendingTransfer(Trip $trip, User $actor): ?TripOwnershipTransfer
    {
        if ($trip->memberRole($actor) !== 'owner' || $trip->owner_id !== $actor->id) {
            throw new AuthorizationException('Only the trip organizer can inspect ownership transfer requests.');
        }

        return TripOwnershipTransfer::query()
            ->where('trip_id', $trip->id)
            ->where('status', 'pending')
            ->where('expires_at', '>', CarbonImmutable::now('UTC'))
            ->with(['trip', 'fromUser', 'toUser'])
            ->latest('created_at')
            ->first();
    }

    /**
     * Initiate or idempotently re-confirm an explicit two-party organizer handover request (TC-3.3).
     *
     * @throws AuthorizationException
     * @throws ValidationException
     */
    public function requestTransfer(
        Trip $trip,
        User $actor,
        InitiateOwnershipTransferData $data,
    ): InitiateOwnershipTransferResult {
        if ($trip->memberRole($actor) !== 'owner' || $trip->owner_id !== $actor->id) {
            throw new AuthorizationException('Only the trip organizer can transfer ownership.');
        }

        return DB::transaction(function () use ($trip, $actor, $data): InitiateOwnershipTransferResult {
            /** @var Trip $lockedTrip */
            $lockedTrip = Trip::query()
                ->where('id', $trip->id)
                ->lockForUpdate()
                ->firstOrFail();

            if ($lockedTrip->owner_id !== $actor->id) {
                throw new AuthorizationException('Only the active trip organizer can transfer ownership.');
            }

            /** @var TripMember|null $targetMember */
            $targetMember = TripMember::query()
                ->where('id', $data->targetMemberId)
                ->where('trip_id', $lockedTrip->id)
                ->where('invitation_status', 'accepted')
                ->first();

            if ($targetMember === null) {
                throw ValidationException::withMessages([
                    'target_member_id' => ['Recipient must be an active accepted member of this trip circle.'],
                ]);
            }

            if ($targetMember->user_id === $actor->id || $targetMember->role === 'owner') {
                throw ValidationException::withMessages([
                    'target_member_id' => ['Cannot transfer ownership to yourself.'],
                ]);
            }

            $now = CarbonImmutable::now('UTC');

            /** @var Collection<int, TripOwnershipTransfer> $activePending */
            $activePending = TripOwnershipTransfer::query()
                ->where('trip_id', $lockedTrip->id)
                ->where('status', 'pending')
                ->lockForUpdate()
                ->get();

            foreach ($activePending as $existing) {
                if ($existing->expires_at->isPast()) {
                    $existing->update(['status' => 'expired']);

                    continue;
                }

                if ($existing->to_user_id === $targetMember->user_id
                    && $existing->former_owner_role === $data->formerOwnerRole) {
                    return new InitiateOwnershipTransferResult(
                        transfer: $existing->load(['trip', 'fromUser', 'toUser']),
                        alreadyPending: true,
                    );
                }

                $existing->update([
                    'status' => 'cancelled',
                    'responded_at' => $now,
                ]);
            }

            /** @var TripOwnershipTransfer $transfer */
            $transfer = TripOwnershipTransfer::query()->create([
                'trip_id' => $lockedTrip->id,
                'from_user_id' => $actor->id,
                'to_user_id' => $targetMember->user_id,
                'former_owner_role' => $data->formerOwnerRole,
                'status' => 'pending',
                'expires_at' => $now->addDays(7),
            ]);

            return new InitiateOwnershipTransferResult(
                transfer: $transfer->load(['trip', 'fromUser', 'toUser']),
                alreadyPending: false,
            );
        });
    }

    /**
     * Cancel a pending ownership handover request (organizer only).
     *
     * @throws AuthorizationException
     */
    public function cancelTransfer(
        Trip $trip,
        TripOwnershipTransfer $transfer,
        User $actor,
    ): TripOwnershipTransfer {
        if ($transfer->trip_id !== $trip->id) {
            throw new ModelNotFoundException('Ownership transfer not found for this trip.');
        }

        if ($trip->memberRole($actor) !== 'owner' || $trip->owner_id !== $actor->id) {
            throw new AuthorizationException('Only the trip organizer can cancel an ownership transfer.');
        }

        if ($transfer->status === 'pending') {
            $transfer->update([
                'status' => 'cancelled',
                'responded_at' => CarbonImmutable::now('UTC'),
            ]);
        }

        return $transfer->fresh(['trip', 'fromUser', 'toUser']);
    }

    /**
     * List pending incoming ownership transfer offers for the authenticated traveler.
     *
     * @return Collection<int, TripOwnershipTransfer>
     */
    public function listIncomingTransfers(User $user): Collection
    {
        return TripOwnershipTransfer::query()
            ->where('to_user_id', $user->id)
            ->where('status', 'pending')
            ->whereHas('trip')
            ->with(['trip', 'fromUser', 'toUser'])
            ->orderByDesc('created_at')
            ->get();
    }

    /**
     * Atomically accept a two-party organizer handover request (TC-3.3, TC-3.4).
     *
     * @throws AuthorizationException
     * @throws ValidationException
     */
    public function acceptTransfer(
        TripOwnershipTransfer $transfer,
        User $actor,
    ): AcceptOwnershipTransferResult {
        if ($transfer->to_user_id !== $actor->id) {
            throw new AuthorizationException('You are not the designated recipient of this ownership transfer.');
        }

        return DB::transaction(function () use ($transfer, $actor): AcceptOwnershipTransferResult {
            /** @var TripOwnershipTransfer $lockedTransfer */
            $lockedTransfer = TripOwnershipTransfer::query()
                ->where('id', $transfer->id)
                ->lockForUpdate()
                ->firstOrFail();

            if ($lockedTransfer->to_user_id !== $actor->id) {
                throw new AuthorizationException('You are not the designated recipient of this ownership transfer.');
            }

            /** @var Trip|null $trip */
            $trip = Trip::query()
                ->where('id', $lockedTransfer->trip_id)
                ->lockForUpdate()
                ->first();

            if ($trip === null) {
                throw new ModelNotFoundException('Trip not found.');
            }

            $status = $lockedTransfer->effectiveStatus();

            // Retry-safe idempotency if already completed
            if ($status === 'accepted' && $trip->owner_id === $actor->id) {
                return new AcceptOwnershipTransferResult(
                    trip: $trip,
                    transfer: $lockedTransfer->load(['trip', 'fromUser', 'toUser']),
                );
            }

            if ($status !== 'pending') {
                throw ValidationException::withMessages([
                    'transfer' => ["This ownership transfer is {$status} and can no longer be accepted."],
                ]);
            }

            if ($trip->owner_id !== $lockedTransfer->from_user_id) {
                $lockedTransfer->update([
                    'status' => 'cancelled',
                    'responded_at' => CarbonImmutable::now('UTC'),
                ]);

                throw ValidationException::withMessages([
                    'transfer' => ['Trip organizer changed before handover completion.'],
                ]);
            }

            /** @var TripMember|null $recipientMember */
            $recipientMember = TripMember::query()
                ->where('trip_id', $trip->id)
                ->where('user_id', $actor->id)
                ->where('invitation_status', 'accepted')
                ->lockForUpdate()
                ->first();

            if ($recipientMember === null) {
                $lockedTransfer->update([
                    'status' => 'cancelled',
                    'responded_at' => CarbonImmutable::now('UTC'),
                ]);

                throw ValidationException::withMessages([
                    'transfer' => ['You must remain an accepted member of this trip circle to become organizer.'],
                ]);
            }

            /** @var TripMember|null $formerOwnerMember */
            $formerOwnerMember = TripMember::query()
                ->where('trip_id', $trip->id)
                ->where('user_id', $lockedTransfer->from_user_id)
                ->lockForUpdate()
                ->first();

            $recipientMember->update(['role' => 'owner']);

            if ($formerOwnerMember !== null) {
                $formerOwnerMember->update(['role' => $lockedTransfer->former_owner_role]);
            }

            $trip->update([
                'owner_id' => $actor->id,
                'version' => $trip->version + 1,
            ]);

            $now = CarbonImmutable::now('UTC');
            $lockedTransfer->update([
                'status' => 'accepted',
                'responded_at' => $now,
            ]);

            TripOwnershipTransfer::query()
                ->where('trip_id', $trip->id)
                ->where('id', '!=', $lockedTransfer->id)
                ->where('status', 'pending')
                ->update([
                    'status' => 'cancelled',
                    'responded_at' => $now,
                ]);

            $newOwnerName = $actor->display_name ?? $actor->name;
            $this->activityService->recordEvent(
                $trip,
                $actor,
                new RecordActivityEventData(
                    eventType: 'ownership_transferred',
                    title: "{$newOwnerName} is now the trip organizer",
                    summary: 'Organizer responsibilities have been handed over.',
                    entityType: 'trip_ownership_transfer',
                    entityId: (string) $lockedTransfer->id,
                    metadata: [
                        'former_owner_id' => $lockedTransfer->from_user_id,
                        'former_owner_role' => $lockedTransfer->former_owner_role,
                    ],
                )
            );

            return new AcceptOwnershipTransferResult(
                trip: $trip->fresh(),
                transfer: $lockedTransfer->fresh(['trip', 'fromUser', 'toUser']),
            );
        });
    }

    /**
     * Decline an incoming ownership transfer offer.
     *
     * @throws AuthorizationException
     * @throws ValidationException
     */
    public function declineTransfer(
        TripOwnershipTransfer $transfer,
        User $actor,
    ): TripOwnershipTransfer {
        if ($transfer->to_user_id !== $actor->id) {
            throw new AuthorizationException('You are not the designated recipient of this ownership transfer.');
        }

        return DB::transaction(function () use ($transfer): TripOwnershipTransfer {
            /** @var TripOwnershipTransfer $lockedTransfer */
            $lockedTransfer = TripOwnershipTransfer::query()
                ->where('id', $transfer->id)
                ->lockForUpdate()
                ->firstOrFail();

            $status = $lockedTransfer->effectiveStatus();
            if ($status === 'declined') {
                return $lockedTransfer->load(['trip', 'fromUser', 'toUser']);
            }

            if ($status !== 'pending') {
                throw ValidationException::withMessages([
                    'transfer' => ["This ownership transfer is {$status} and cannot be declined."],
                ]);
            }

            $lockedTransfer->update([
                'status' => 'declined',
                'responded_at' => CarbonImmutable::now('UTC'),
            ]);

            return $lockedTransfer->fresh(['trip', 'fromUser', 'toUser']);
        });
    }
}
