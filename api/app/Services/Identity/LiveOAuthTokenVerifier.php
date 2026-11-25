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

        // Apple OAuth requires configured Apple client ID and JWKS signature verification.
        return null;
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
