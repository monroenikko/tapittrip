<?php

declare(strict_types=1);

namespace App\Domain\Trips\Policies;

use App\Domain\Trips\Models\Trip;
use App\Models\User;

final class TripPolicy
{
    /**
     * Determine whether the user can view any trips.
     */
    public function viewAny(User $user): bool
    {
        return true;
    }

    /**
     * Determine whether the user can view the trip.
     */
    public function view(User $user, Trip $trip): bool
    {
        return $trip->hasMember($user);
    }

    /**
     * Determine whether the user can create trips.
     */
    public function create(User $user): bool
    {
        return true;
    }

    /**
     * Determine whether the user can update the trip.
     */
    public function update(User $user, Trip $trip): bool
    {
        $role = $trip->memberRole($user);

        return in_array($role, ['owner', 'editor'], true);
    }

    /**
     * Determine whether the user can delete the trip.
     */
    public function delete(User $user, Trip $trip): bool
    {
        return $trip->owner_id === $user->id;
    }
}
