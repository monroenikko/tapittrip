<?php

declare(strict_types=1);

namespace App\Application\Itinerary\Data;

final readonly class CreatePlaceData
{
    public function __construct(
        public string $name,
        public string $provider = 'manual',
        public ?string $providerPlaceId = null,
        public ?string $formattedAddress = null,
        public ?string $countryCode = null,
        public ?float $latitude = null,
        public ?float $longitude = null,
        public ?string $photoReference = null,
        public ?string $attribution = null,
    ) {}

    /**
     * @param  array<string, mixed>  $data
     */
    public static function from(array $data): self
    {
        return new self(
            name: (string) $data['name'],
            provider: (string) ($data['provider'] ?? 'manual'),
            providerPlaceId: isset($data['provider_place_id']) ? (string) $data['provider_place_id'] : null,
            formattedAddress: isset($data['formatted_address']) ? (string) $data['formatted_address'] : null,
            countryCode: isset($data['country_code']) ? strtoupper((string) $data['country_code']) : null,
            latitude: isset($data['latitude']) && $data['latitude'] !== null ? (float) $data['latitude'] : null,
            longitude: isset($data['longitude']) && $data['longitude'] !== null ? (float) $data['longitude'] : null,
            photoReference: isset($data['photo_reference']) ? (string) $data['photo_reference'] : null,
            attribution: isset($data['attribution']) ? (string) $data['attribution'] : null,
        );
    }
}
