<?php

declare(strict_types=1);

namespace App\Services\Identity;

use App\Contracts\OAuthTokenVerifierInterface;
use App\DTOs\Identity\VerifiedOAuthIdentity;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

final class LiveOAuthTokenVerifier implements OAuthTokenVerifierInterface
{
    public function verify(string $provider, string $idToken): ?VerifiedOAuthIdentity
    {
        $normalized = strtolower(trim($provider));
        $token = trim($idToken);

        if ($token === '') {
            return null;
        }

        if ($normalized === 'google') {
            return $this->verifyGoogleToken($token);
        }

        if ($normalized === 'facebook') {
            return $this->verifyFacebookToken($token);
        }

        // Apple OAuth requires configured Apple client ID and JWKS signature verification.
        return null;
    }

    private function verifyFacebookToken(string $accessToken): ?VerifiedOAuthIdentity
    {
        $expectedAppId = trim((string) config('services.facebook.app_id', ''));
        $appSecret = trim((string) config('services.facebook.app_secret', ''));
        if ($expectedAppId === '' || $appSecret === '') {
            return null;
        }

        try {
            $debugResponse = Http::timeout(5)->get('https://graph.facebook.com/debug_token', [
                'input_token' => $accessToken,
                'access_token' => "{$expectedAppId}|{$appSecret}",
            ]);

            if (! $debugResponse->successful()) {
                Log::warning('LiveOAuthTokenVerifier Facebook debug_token rejected token', [
                    'status' => $debugResponse->status(),
                ]);

                return null;
            }

            $debugData = $debugResponse->json('data');
            if (! is_array($debugData)) {
                return null;
            }

            $isValid = ($debugData['is_valid'] ?? false) === true;
            $appId = (string) ($debugData['app_id'] ?? '');
            $userId = (string) ($debugData['user_id'] ?? '');
            if (! $isValid || $appId !== $expectedAppId || $userId === '') {
                return null;
            }

            $profileResponse = Http::timeout(5)->get('https://graph.facebook.com/me', [
                'fields' => 'id,name,email,picture.type(large)',
                'access_token' => $accessToken,
            ]);

            if (! $profileResponse->successful()) {
                Log::warning('LiveOAuthTokenVerifier Facebook profile fetch failed', [
                    'status' => $profileResponse->status(),
                ]);

                return null;
            }

            $profile = $profileResponse->json();
            if (! is_array($profile) || (string) ($profile['id'] ?? '') !== $userId) {
                return null;
            }

            $email = isset($profile['email']) && is_string($profile['email']) && trim($profile['email']) !== ''
                ? strtolower(trim($profile['email']))
                : null;
            $name = isset($profile['name']) && is_string($profile['name']) ? trim($profile['name']) : null;
            $picture = isset($profile['picture']['data']['url']) && is_string($profile['picture']['data']['url'])
                ? trim($profile['picture']['data']['url'])
                : null;

            return new VerifiedOAuthIdentity(
                provider: 'facebook',
                providerSubject: $userId,
                email: $email,
                emailVerified: $email !== null,
                displayName: $name,
                avatarUrl: $picture,
            );
        } catch (\Throwable) {
            Log::warning('LiveOAuthTokenVerifier Facebook verification request failed');

            return null;
        }
    }

    private function verifyGoogleToken(string $idToken): ?VerifiedOAuthIdentity
    {
        $expectedClientId = trim((string) config('services.google.oauth_client_id', ''));
        if ($expectedClientId === '') {
            return null;
        }

        try {
            $response = Http::timeout(5)->get('https://oauth2.googleapis.com/tokeninfo', [
                'id_token' => $idToken,
            ]);

            if (! $response->successful()) {
                Log::warning('LiveOAuthTokenVerifier Google tokeninfo rejected token', [
                    'status' => $response->status(),
                ]);

                return null;
            }

            $claims = $response->json();
            if (! is_array($claims)) {
                return null;
            }

            $aud = (string) ($claims['aud'] ?? '');
            $sub = (string) ($claims['sub'] ?? '');
            if ($aud !== $expectedClientId || $sub === '') {
                return null;
            }

            $email = isset($claims['email']) && is_string($claims['email']) ? strtolower(trim($claims['email'])) : null;
            $emailVerified = ($claims['email_verified'] ?? false) === true || ($claims['email_verified'] ?? '') === 'true';
            $name = isset($claims['name']) && is_string($claims['name']) ? trim($claims['name']) : null;
            $picture = isset($claims['picture']) && is_string($claims['picture']) ? trim($claims['picture']) : null;

            return new VerifiedOAuthIdentity(
                provider: 'google',
                providerSubject: $sub,
                email: $email,
                emailVerified: $emailVerified,
                displayName: $name,
                avatarUrl: $picture,
            );
        } catch (\Throwable) {
            Log::warning('LiveOAuthTokenVerifier Google verification request failed');

            return null;
        }
    }
}
