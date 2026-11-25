<?php

declare(strict_types=1);

namespace App\DTOs\Safety;

final readonly class DestinationSafetyProfileData
{
    /**
     * @param  array{
     *     police: string|null,
     *     ambulance: string|null,
     *     fire: string|null,
     *     general_emergency: string|null,
     *     tourist_hotline: string|null
     * }  $emergencyNumbers
     * @param  array<int, array{
     *     title: string,
     *     publisher: string,
     *     category: string,
     *     url: string,
     *     last_verified_at: string
     * }>  $officialResources
     * @param  array<int, array{
     *     category: string,
     *     english: string,
     *     local_text: string,
     *     phonetic: string
     * }>  $emergencyPhrases
     */
    public function __construct(
        public string $countryCode,
        public string $countryName,
        public string $flagEmoji,
        public bool $isCurated,
        public array $emergencyNumbers,
        public array $officialResources,
        public array $emergencyPhrases,
        public string $lastVerifiedAt,
        public string $disclaimer,
    ) {}
}
