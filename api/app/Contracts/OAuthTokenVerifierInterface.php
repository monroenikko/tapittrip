<?php

declare(strict_types=1);

namespace App\Contracts;

use App\DTOs\Identity\VerifiedOAuthIdentity;

interface OAuthTokenVerifierInterface
{
    /**
     * Verify a third-party OAuth ID token (Google or Apple) and return normalized identity claims.
     * Returns null when the token is invalid, expired, or fails audience/signature checks.
     */
    public function verify(string $provider, string $idToken): ?VerifiedOAuthIdentity;
}
