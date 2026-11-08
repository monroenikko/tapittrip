<?php

declare(strict_types=1);

namespace App\Application\Identity\Services;

use App\Application\Expenses\Services\CountryCurrencyResolver;
use App\Models\User;

final class UpdateProfileService
{
    /**
     * @param  array<string, mixed>  $data
     */
    public function execute(User $user, array $data): User
    {
        $attributes = [];

        if (array_key_exists('display_name', $data) && $data['display_name'] !== null) {
            $attributes['display_name'] = trim((string) $data['display_name']);
        }

        if (array_key_exists('home_country', $data) && $data['home_country'] !== null) {
            $homeCountry = strtoupper(trim((string) $data['home_country']));
            $attributes['home_country'] = $homeCountry;

            // Automatically set default home currency if not explicitly provided
            if (empty($data['home_currency'])) {
                $attributes['home_currency'] = CountryCurrencyResolver::resolve($homeCountry);
            }
        }

        if (array_key_exists('home_currency', $data) && ! empty($data['home_currency'])) {
            $attributes['home_currency'] = strtoupper(trim((string) $data['home_currency']));
        }

        if (array_key_exists('home_timezone', $data) && $data['home_timezone'] !== null) {
            $attributes['home_timezone'] = trim((string) $data['home_timezone']);
        }

        if (array_key_exists('locale', $data) && $data['locale'] !== null) {
            $attributes['locale'] = trim((string) $data['locale']);
        }

        if (! empty($attributes)) {
            $user->update($attributes);
        }

        return $user->fresh();
    }
}
