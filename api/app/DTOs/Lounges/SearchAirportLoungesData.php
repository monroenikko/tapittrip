<?php

declare(strict_types=1);

namespace App\DTOs\Lounges;

final readonly class SearchAirportLoungesData
{
    /**
     * @param  array<int, string>|null  $accessMethods
     */
    public function __construct(
        public string $iataCode,
        public ?string $terminalCode = null,
        public ?bool $isAirside = null,
        public ?array $accessMethods = null,
    ) {}
}
