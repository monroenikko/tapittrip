<?php

declare(strict_types=1);

namespace App\Application\Identity\Services;

use App\Application\Expenses\Services\CountryCurrencyResolver;
use App\Application\Identity\Data\AccessTokenResult;
use App\Application\Identity\Data\RegisterUserData;
use App\Models\User;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;

final class RegisterUserService
{
    public function handle(RegisterUserData $data): AccessTokenResult
    {
        return DB::transaction(function () use ($data): AccessTokenResult {
            $homeCountry = $data->homeCountry ? strtoupper(trim($data->homeCountry)) : null;
            $homeCurrency = $data->homeCurrency ? strtoupper(trim($data->homeCurrency)) : null;

            if ($homeCurrency === null && ($homeCountry !== null || $data->permanentAddress !== null)) {
                $homeCurrency = CountryCurrencyResolver::resolve($homeCountry ?? $data->permanentAddress);
            }

            /** @var User $user */
            $user = User::query()->create([
                'name' => $data->name,
                'display_name' => $data->displayName ?? $data->name,
                'email' => $data->email,
                'password' => Hash::make($data->password),
                'locale' => $data->locale ?? 'en',
                'home_timezone' => $data->homeTimezone ?? 'UTC',
                'permanent_address' => $data->permanentAddress ? trim($data->permanentAddress) : null,
                'home_country' => $homeCountry,
                'home_currency' => $homeCurrency,
            ]);

            $plainTextToken = $user->createToken($data->deviceName ?? 'mobile')->plainTextToken;

            return new AccessTokenResult(
                user: $user,
                plainTextToken: $plainTextToken,
            );
        });
    }
}
