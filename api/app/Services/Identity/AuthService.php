<?php

declare(strict_types=1);

namespace App\Services\Identity;

use App\DTOs\Identity\AuthTokenResult;
use App\DTOs\Identity\LoginUserData;
use App\DTOs\Identity\RegisterUserData;
use App\Exceptions\InvalidCredentials;
use App\Models\User;
use App\Services\Expenses\CountryCurrencyResolver;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Laravel\Sanctum\PersonalAccessToken;

final class AuthService
{
    /**
     * Register a new traveler user account and issue an initial API bearer token.
     */
    public function register(RegisterUserData $data): AuthTokenResult
    {
        return DB::transaction(function () use ($data): AuthTokenResult {
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

            return new AuthTokenResult(
                user: $user,
                plainTextToken: $plainTextToken,
            );
        });
    }

    /**
     * Authenticate an existing user with email and password, issuing a bearer token.
     *
     * @throws InvalidCredentials
     */
    public function login(LoginUserData $data): AuthTokenResult
    {
        /** @var User|null $user */
        $user = User::query()->where('email', $data->email)->first();

        if (! $user || ! $user->password || ! Hash::check($data->password, $user->password)) {
            throw new InvalidCredentials;
        }

        return new AuthTokenResult(
            user: $user,
            plainTextToken: $user->createToken($data->deviceName ?? 'mobile')->plainTextToken,
        );
    }

    /**
     * Revoke the current access token for the authenticated user session.
     */
    public function logout(User $user): void
    {
        $accessToken = $user->currentAccessToken();

        if ($accessToken instanceof PersonalAccessToken) {
            $accessToken->delete();
        }
    }
}
