<?php

declare(strict_types=1);

namespace App\Services\Circles;

use App\Models\Trip;
use App\Models\TripLocationShare;
use App\Models\User;
use Carbon\CarbonImmutable;
use Illuminate\Auth\Access\AuthorizationException;
use Illuminate\Database\Eloquent\Collection;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;

final class TripLocationShareService
{
    /**
     * Retrieve the location share record for a given user & trip.
     *
     * @throws AuthorizationException
     */
    public function getForUser(Trip $trip, User $user): ?TripLocationShare
    {
        $this->ensureMembership($trip, $user);

        return TripLocationShare::query()
            ->where('trip_id', $trip->id)
            ->where('user_id', $user->id)
            ->first();
    }

    /**
     * List active location shares for the trip visible to the actor.
     *
     * @return Collection<int, TripLocationShare>
     *
     * @throws AuthorizationException
     */
    public function listActiveForTrip(Trip $trip, User $actor): Collection
    {
        $this->ensureMembership($trip, $actor);

        $isOwner = $trip->owner_id === $actor->id || $trip->memberRole($actor) === 'owner';

        /** @var Collection<int, TripLocationShare> $shares */
        $shares = TripLocationShare::query()
            ->where('trip_id', $trip->id)
            ->active()
            ->with(['user'])
            ->get();

        return $shares->filter(function (TripLocationShare $share) use ($actor, $isOwner): bool {
            if ($share->user_id === $actor->id) {
                return true;
            }

            if ($share->audience === 'organizer_only' && ! $isOwner) {
                return false;
            }

            return true;
        })->values();
    }

    /**
     * Enable location sharing with explicit duration, audience, and coordinates.
     *
     * @throws AuthorizationException
     */
    public function enable(
        Trip $trip,
        User $user,
        int $durationMinutes = 60,
        string $audience = 'circle',
        ?float $latitude = null,
        ?float $longitude = null,
    ): TripLocationShare {
        $this->ensureMembership($trip, $user);

        if ($latitude === null || $longitude === null) {
            throw ValidationException::withMessages([
                'location' => ['Coordinates are required when starting location sharing.'],
            ]);
        }

        $now = CarbonImmutable::now('UTC');
        $expiresAt = $now->addMinutes($durationMinutes);

        return DB::transaction(function () use ($trip, $user, $durationMinutes, $expiresAt, $audience, $latitude, $longitude, $now): TripLocationShare {
            /** @var TripLocationShare $share */
            $share = TripLocationShare::query()->firstOrCreate(
                ['trip_id' => $trip->id, 'user_id' => $user->id],
                [
                    'enabled' => true,
                    'duration_minutes' => $durationMinutes,
                    'expires_at' => $expiresAt,
                    'audience' => $audience,
                    'latitude' => $latitude,
                    'longitude' => $longitude,
                    'last_shared_at' => $now,
                ]
            );

            $share->enabled = true;
            $share->duration_minutes = $durationMinutes;
            $share->expires_at = $expiresAt;
            $share->audience = $audience;
            $share->latitude = $latitude;
            $share->longitude = $longitude;
            $share->last_shared_at = $now;
            $share->save();

            return $share->fresh(['user']);
        });
    }

    /**
     * Disable location sharing for the user on the trip.
     *
     * @throws AuthorizationException
     */
    public function disable(Trip $trip, User $user): TripLocationShare
    {
        $this->ensureMembership($trip, $user);

        /** @var TripLocationShare $share */
        $share = TripLocationShare::query()
            ->firstOrCreate(
                ['trip_id' => $trip->id, 'user_id' => $user->id],
                ['enabled' => false]
            );

        $share->enabled = false;
        $share->expires_at = CarbonImmutable::now('UTC');
        $share->latitude = null;
        $share->longitude = null;
        $share->last_shared_at = null;
        $share->save();

        return $share->fresh(['user']);
    }

    /**
     * Update current coordinates for an active location share.
     *
     * @throws AuthorizationException
     * @throws ValidationException
     */
    public function updateCoordinates(Trip $trip, User $user, float $latitude, float $longitude): TripLocationShare
    {
        $this->ensureMembership($trip, $user);

        /** @var TripLocationShare|null $share */
        $share = TripLocationShare::query()
            ->where('trip_id', $trip->id)
            ->where('user_id', $user->id)
            ->first();

        if ($share === null || ! $share->isActive()) {
            throw ValidationException::withMessages([
                'location' => ['Location sharing is not currently active for this trip.'],
            ]);
        }

        $share->latitude = $latitude;
        $share->longitude = $longitude;
        $share->last_shared_at = CarbonImmutable::now('UTC');
        $share->save();

        return $share->fresh(['user']);
    }

    /**
     * Ensure the given user is an accepted member or owner of the trip.
     *
     * @throws AuthorizationException
     */
    private function ensureMembership(Trip $trip, User $user): void
    {
        if (! $trip->hasMember($user) && $trip->owner_id !== $user->id) {
            throw new AuthorizationException('You are not an authorized member of this trip.');
        }
    }
}
