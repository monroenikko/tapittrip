<?php

declare(strict_types=1);

namespace App\Services\Circles;

use App\DTOs\Circles\CreateTripTravelerData;
use App\DTOs\Circles\UpdateTripTravelerData;
use App\Exceptions\VersionConflictException;
use App\Models\ChecklistItem;
use App\Models\Trip;
use App\Models\TripMember;
use App\Models\TripTraveler;
use App\Models\User;
use Illuminate\Auth\Access\AuthorizationException;
use Illuminate\Database\Eloquent\Collection;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;

final class TripTravelerService
{
    /**
     * List minimal traveler profiles visible to active accepted trip members.
     *
     * @return Collection<int, TripTraveler>
     *
     * @throws AuthorizationException
     */
    public function listForTrip(Trip $trip, User $actor): Collection
    {
        if (! $trip->hasMember($actor) && $trip->owner_id !== $actor->id) {
            throw new AuthorizationException('You are not a member of this trip circle.');
        }

        return $trip->travelers()
            ->with(['managingUser', 'trip'])
            ->get();
    }

    /**
     * Create a minimal managed traveler profile without creating a child/companion user account (TC-6.3).
     *
     * @throws AuthorizationException
     * @throws ValidationException
     */
    public function create(Trip $trip, User $actor, CreateTripTravelerData $data): TripTraveler
    {
        $role = $trip->memberRole($actor);
        if (! in_array($role, ['owner', 'editor'], true) && $trip->owner_id !== $actor->id) {
            throw new AuthorizationException('Only authorized adult editors or organizers can create managed traveler profiles.');
        }

        if ($data->linkedMemberId !== null && $data->linkedMemberId !== '') {
            $memberValid = TripMember::query()
                ->where('id', $data->linkedMemberId)
                ->where('trip_id', $trip->id)
                ->where('invitation_status', 'accepted')
                ->exists();

            if (! $memberValid) {
                throw ValidationException::withMessages([
                    'linked_member_id' => ['The linked member must be an accepted member of this trip.'],
                ]);
            }
        }

        /** @var TripTraveler $traveler */
        $traveler = TripTraveler::create([
            'trip_id' => $trip->id,
            'linked_member_id' => $data->linkedMemberId,
            'managing_user_id' => $actor->id,
            'display_name' => trim($data->displayName),
            'traveler_category' => $data->travelerCategory,
            'restricted_notes' => $data->restrictedNotes !== null && trim($data->restrictedNotes) !== ''
                ? trim($data->restrictedNotes)
                : null,
            'version' => 1,
        ]);

        return $traveler->fresh(['managingUser', 'trip']) ?? $traveler;
    }

    /**
     * Update a managed traveler profile. Strictly restricted to the managing adult (TC-6.3).
     *
     * @throws AuthorizationException
     * @throws VersionConflictException
     */
    public function update(
        TripTraveler $traveler,
        User $actor,
        UpdateTripTravelerData $data,
    ): TripTraveler {
        $trip = $traveler->trip;
        if (
            $trip === null
            || ! $trip->hasMember($actor)
            || $traveler->managing_user_id !== $actor->id
        ) {
            throw new AuthorizationException('Only the managing adult can edit this managed traveler profile.');
        }

        return DB::transaction(function () use ($traveler, $actor, $data): TripTraveler {
            /** @var TripTraveler $locked */
            $locked = TripTraveler::query()
                ->with(['managingUser', 'trip'])
                ->whereKey($traveler->id)
                ->lockForUpdate()
                ->firstOrFail();

            if ($data->baseVersion !== null && $data->baseVersion !== $locked->version) {
                throw new VersionConflictException(
                    serverVersion: (int) $locked->version,
                    serverPayload: [
                        'id' => $locked->id,
                        'trip_id' => $locked->trip_id,
                        'display_name' => $locked->display_name,
                        'traveler_category' => $locked->traveler_category,
                        'restricted_notes' => $locked->managing_user_id === $actor->id
                            ? $locked->restricted_notes
                            : null,
                        'version' => (int) $locked->version,
                    ],
                );
            }

            $updates = ['version' => $locked->version + 1];
            if ($data->displayName !== null) {
                $updates['display_name'] = trim($data->displayName);
            }
            if ($data->travelerCategory !== null) {
                $updates['traveler_category'] = $data->travelerCategory;
            }
            if ($data->clearRestrictedNotes) {
                $updates['restricted_notes'] = null;
            } elseif ($data->restrictedNotes !== null) {
                $updates['restricted_notes'] = trim($data->restrictedNotes) !== ''
                    ? trim($data->restrictedNotes)
                    : null;
            }

            $locked->update($updates);

            return $locked->fresh(['managingUser', 'trip']) ?? $locked;
        });
    }

    /**
     * Delete a managed traveler profile and clear any assigned checklist tasks atomically (TC-6.1, TC-6.3).
     *
     * @throws AuthorizationException
     */
    public function delete(TripTraveler $traveler, User $actor): void
    {
        $trip = $traveler->trip;
        if (
            $trip === null
            || ! $trip->hasMember($actor)
            || ($traveler->managing_user_id !== $actor->id && $trip->owner_id !== $actor->id)
        ) {
            throw new AuthorizationException('Only the managing adult or trip organizer can remove this managed traveler.');
        }

        DB::transaction(function () use ($traveler): void {
            ChecklistItem::query()
                ->where('trip_id', $traveler->trip_id)
                ->where('assigned_traveler_id', $traveler->id)
                ->update([
                    'assigned_traveler_id' => null,
                    'version' => DB::raw('version + 1'),
                ]);

            $traveler->delete();
        });
    }
}
