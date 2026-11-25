<?php

declare(strict_types=1);

namespace App\DTOs\Identity;

final readonly class VerifiedOAuthIdentity
{
    public function __construct(
        public string $provider,
        public string $providerSubject,
        public ?string $email,
        public bool $emailVerified,
        public ?string $displayName = null,
        public ?string $avatarUrl = null,
    ) {}
}
