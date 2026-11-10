<?php

declare(strict_types=1);

namespace App\Services\Identity;

use App\DTOs\Identity\UpdateProfileData;
use App\Models\User;
use App\Services\Expenses\CountryCurrencyResolver;
use Illuminate\Support\Facades\DB;

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

        if (! empty($attributes)) {
            $user->update($attributes);
        }

        return $user->fresh();
    }

    /**
     * Delete the authenticated user account and revoke all tokens.
     */
    public function deleteAccount(User $user): void
    {
        DB::transaction(function () use ($user): void {
            $user->tokens()->delete();
            $user->delete();
        });
    }
}
