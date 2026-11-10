<?php

declare(strict_types=1);

namespace App\Services\Identity;

use App\DTOs\Identity\UpdateProfileData;
use App\Models\Trip;
use App\Models\TripInvitation;
use App\Models\TripMember;
use App\Models\TripOwnershipTransfer;
use App\Models\User;
use App\Services\Expenses\CountryCurrencyResolver;
use Carbon\CarbonImmutable;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;

final class ProfileService
{
    /**
     * Update the traveler's personal profile and preferences.
     */
    public function update(User $user, UpdateProfileData $data): User
    {
        $attributes = [];

        if ($data->hasDisplayName && $data->displayName !== null) {
            $attributes['display_name'] = trim($data->displayName);
        }

        if ($data->hasPermanentAddress) {
            $attributes['permanent_address'] = $data->permanentAddress !== null
                ? trim($data->permanentAddress)
                : null;
        }

        if ($data->hasHomeCountry && $data->homeCountry !== null) {
            $homeCountry = strtoupper(trim($data->homeCountry));
            $attributes['home_country'] = $homeCountry;

            // Automatically set default home currency if not explicitly provided
            if (empty($data->homeCurrency)) {
                $attributes['home_currency'] = CountryCurrencyResolver::resolve($homeCountry);
            }
        } elseif (! empty($attributes['permanent_address']) && empty($data->homeCurrency)) {
            $attributes['home_currency'] = CountryCurrencyResolver::resolve($attributes['permanent_address']);
        }

        if ($data->hasHomeCurrency && ! empty($data->homeCurrency)) {
            $attributes['home_currency'] = strtoupper(trim($data->homeCurrency));
        }

        if ($data->hasHomeTimezone && $data->homeTimezone !== null) {
            $attributes['home_timezone'] = trim($data->homeTimezone);
        }

        if ($data->hasLocale && $data->locale !== null) {
            $attributes['locale'] = trim($data->locale);
        }

        if ($data->hasAcceptsDirectInvites && $data->acceptsDirectInvites !== null) {
            $attributes['accepts_direct_invites'] = $data->acceptsDirectInvites;
        }

        if (! empty($attributes)) {
            $user->update($attributes);
        }

        return $user->fresh();
    }

    /**
     * Rotate the authenticated traveler's friend code immediately.
     */
    public function regenerateFriendCode(User $user): User
    {
        return DB::transaction(function () use ($user): User {
            $user->update([
                'friend_code' => User::generateUniqueFriendCode(),
            ]);

            return $user->fresh();
        });
    }

    /**
     * Delete the authenticated user account and revoke all tokens.
     * Blocks deletion if the user is organizer of shared trips with other accepted members (TC-3.4).
     *
     * @throws ValidationException
     */
    public function deleteAccount(User $user): void
    {
        DB::transaction(function () use ($user): void {
            $now = CarbonImmutable::now('UTC');

            $ownedTrips = Trip::query()
                ->where('owner_id', $user->id)
                ->lockForUpdate()
                ->get();

            foreach ($ownedTrips as $trip) {
                $hasSharedCompanions = TripMember::query()
                    ->where('trip_id', $trip->id)
                    ->where('user_id', '!=', $user->id)
                    ->where('invitation_status', 'accepted')
                    ->exists();

                if ($hasSharedCompanions) {
                    throw ValidationException::withMessages([
                        'account' => ['Transfer organizer ownership or delete shared trips before deleting your account.'],
                    ]);
                }
            }

            // Soft-delete any solo owned trips cleanly so none are orphaned
            foreach ($ownedTrips as $soloTrip) {
                TripInvitation::query()
                    ->where('trip_id', $soloTrip->id)
                    ->whereIn('status', ['active', 'pending'])
                    ->update(['status' => 'revoked', 'revoked_at' => $now]);

                TripOwnershipTransfer::query()
                    ->where('trip_id', $soloTrip->id)
                    ->where('status', 'pending')
                    ->update(['status' => 'cancelled', 'responded_at' => $now]);

                $soloTrip->delete();
            }

            // Revoke/cancel any incoming/outgoing direct invitations & handovers and companion memberships
            TripInvitation::query()
                ->where('target_user_id', $user->id)
                ->where('status', 'pending')
                ->update(['status' => 'declined', 'responded_at' => $now]);

            TripOwnershipTransfer::query()
                ->where('to_user_id', $user->id)
                ->where('status', 'pending')
                ->update(['status' => 'declined', 'responded_at' => $now]);

            TripMember::query()
                ->where('user_id', $user->id)
                ->delete();

            $user->tokens()->delete();
            $user->delete();
        });
    }
}
