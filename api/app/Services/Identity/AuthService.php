<?php

declare(strict_types=1);

namespace App\Services\Identity;

use App\Contracts\OAuthTokenVerifierInterface;
use App\DTOs\Identity\AuthTokenResult;
use App\DTOs\Identity\LoginUserData;
use App\DTOs\Identity\RegisterUserData;
use App\Exceptions\InvalidCredentials;
use App\Models\User;
use App\Models\UserOAuthIdentity;
use App\Services\Expenses\CountryCurrencyResolver;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Str;
use Illuminate\Validation\ValidationException;
use Laravel\Sanctum\PersonalAccessToken;

final class AuthService
{
    public const SUPPORTED_OAUTH_PROVIDERS = ['google', 'apple'];

    public function __construct(
        private readonly ?OAuthTokenVerifierInterface $oauthVerifier = null,
    ) {}

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
     * Exchange a verified Google or Apple OAuth ID token for a Sanctum personal access token.
     *
     * @param  array<string, mixed>  $data
     * @return array{result: AuthTokenResult, is_new_user: bool}
     *
     * @throws InvalidCredentials
     */
    public function exchangeOAuth(string $provider, array $data): array
    {
        $normalizedProvider = strtolower(trim($provider));
        if (! in_array($normalizedProvider, self::SUPPORTED_OAUTH_PROVIDERS, true)) {
            throw ValidationException::withMessages([
                'provider' => ['Unsupported OAuth provider. Supported providers: google, apple.'],
            ]);
        }

        $verifier = $this->oauthVerifier ?? app(OAuthTokenVerifierInterface::class);
        $verified = $verifier->verify($normalizedProvider, (string) ($data['id_token'] ?? ''));

        if ($verified === null) {
            throw new InvalidCredentials;
        }

        return DB::transaction(function () use ($normalizedProvider, $verified, $data): array {
            /** @var UserOAuthIdentity|null $existingIdentity */
            $existingIdentity = UserOAuthIdentity::query()
                ->where('provider', $normalizedProvider)
                ->where('provider_subject', $verified->providerSubject)
                ->with('user')
                ->first();

            $isNewUser = false;

            if ($existingIdentity !== null && $existingIdentity->user !== null) {
                $user = $existingIdentity->user;
            } else {
                $user = null;
                if ($verified->email !== null) {
                    /** @var User|null $existingByEmail */
                    $existingByEmail = User::query()->where('email', $verified->email)->first();

                    if ($existingByEmail !== null) {
                        // Account-takeover guard: never link an unverified OAuth email to an existing account
                        if (! $verified->emailVerified) {
                            throw new InvalidCredentials;
                        }
                        $user = $existingByEmail;
                    }
                }

                if ($user === null) {
                    $fallbackEmail = $verified->email ?? "{$normalizedProvider}_".Str::lower(Str::random(12)).'@oauth.tapittrip.invalid';
                    $displayName = isset($data['display_name']) && is_string($data['display_name']) && trim($data['display_name']) !== ''
                        ? trim($data['display_name'])
                        : ($verified->displayName ?? 'Traveler');

                    /** @var User $user */
                    $user = User::query()->create([
                        'name' => $displayName,
                        'display_name' => $displayName,
                        'email' => $fallbackEmail,
                        'avatar_url' => $verified->avatarUrl,
                        'password' => Hash::make(Str::random(40)),
                        'locale' => isset($data['locale']) && is_string($data['locale']) ? $data['locale'] : 'en',
                        'home_timezone' => isset($data['home_timezone']) && is_string($data['home_timezone']) ? $data['home_timezone'] : 'UTC',
                    ]);
                    $isNewUser = true;
                }

                UserOAuthIdentity::query()->create([
                    'user_id' => $user->id,
                    'provider' => $normalizedProvider,
                    'provider_subject' => $verified->providerSubject,
                    'email' => $verified->email,
                    'email_verified' => $verified->emailVerified,
                ]);
            }

            $deviceName = isset($data['device_name']) && is_string($data['device_name']) && trim($data['device_name']) !== ''
                ? trim($data['device_name'])
                : 'mobile';

            return [
                'result' => new AuthTokenResult(
                    user: $user,
                    plainTextToken: $user->createToken($deviceName)->plainTextToken,
                ),
                'is_new_user' => $isNewUser,
            ];
        });
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
