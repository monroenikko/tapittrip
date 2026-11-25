<?php

declare(strict_types=1);

namespace App\Services\Identity;

use App\Contracts\OAuthTokenVerifierInterface;
use App\DTOs\Identity\VerifiedOAuthIdentity;

final class FakeOAuthTokenVerifier implements OAuthTokenVerifierInterface
{
    public function verify(string $provider, string $idToken): ?VerifiedOAuthIdentity
    {
        $normalizedProvider = strtolower(trim($provider));
        $trimmed = trim($idToken);

        $verifiedPrefix = "valid-{$normalizedProvider}-token:";
        $unverifiedPrefix = "unverified-{$normalizedProvider}-token:";

        $emailVerified = true;
        if (str_starts_with($trimmed, $verifiedPrefix)) {
            $payload = substr($trimmed, strlen($verifiedPrefix));
        } elseif (str_starts_with($trimmed, $unverifiedPrefix)) {
            $payload = substr($trimmed, strlen($unverifiedPrefix));
            $emailVerified = false;
        } else {
            return null;
        }

        $parts = explode('|', $payload);
        $subject = trim($parts[0] ?? '');
        $email = isset($parts[1]) && trim($parts[1]) !== '' ? strtolower(trim($parts[1])) : null;
        $displayName = isset($parts[2]) && trim($parts[2]) !== '' ? trim($parts[2]) : 'Traveler';

        if ($subject === '') {
            return null;
        }

        return new VerifiedOAuthIdentity(
            provider: $normalizedProvider,
            providerSubject: $subject,
            email: $email,
            emailVerified: $emailVerified,
            displayName: $displayName,
        );
    }
}
