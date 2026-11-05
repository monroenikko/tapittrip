<?php

declare(strict_types=1);

namespace App\Application\Stays\Data;

use App\Application\Itinerary\Data\CreatePlaceData;
use Carbon\Carbon;
use Carbon\CarbonInterface;

final readonly class CreateStayData
{
    /**
     * @param  array<string, mixed>|null  $luggageProfile
     */
    public function __construct(
        public string $name,
        public string $stayType = 'hotel',
        public ?string $address = null,
        public ?float $latitude = null,
        public ?float $longitude = null,
        public ?CarbonInterface $checkInAt = null,
        public ?CarbonInterface $checkOutAt = null,
        public string $timezone = 'UTC',
        public ?string $phone = null,
        public ?string $bookingReference = null,
        public ?string $notes = null,
        public ?array $luggageProfile = null,
        public ?string $placeId = null,
        public ?CreatePlaceData $place = null,
        public bool $createItineraryEvents = false,
    ) {}

    /**
     * @param  array<string, mixed>  $data
     */
    public static function from(array $data, ?string $defaultTimezone = 'UTC'): self
    {
        $timezone = (string) ($data['timezone'] ?? $defaultTimezone ?? 'UTC');

        return new self(
            name: (string) $data['name'],
            stayType: (string) ($data['stay_type'] ?? 'hotel'),
            address: isset($data['address']) ? (string) $data['address'] : null,
            latitude: isset($data['latitude']) && $data['latitude'] !== null ? (float) $data['latitude'] : null,
            longitude: isset($data['longitude']) && $data['longitude'] !== null ? (float) $data['longitude'] : null,
            checkInAt: isset($data['check_in_at']) && $data['check_in_at'] !== null
                ? Carbon::parse((string) $data['check_in_at'])
                : null,
            checkOutAt: isset($data['check_out_at']) && $data['check_out_at'] !== null
                ? Carbon::parse((string) $data['check_out_at'])
                : null,
            timezone: $timezone,
            phone: isset($data['phone']) ? (string) $data['phone'] : null,
            bookingReference: isset($data['booking_reference']) ? (string) $data['booking_reference'] : null,
            notes: isset($data['notes']) ? (string) $data['notes'] : null,
            luggageProfile: isset($data['luggage_profile']) && is_array($data['luggage_profile']) ? $data['luggage_profile'] : null,
            placeId: isset($data['place_id']) ? (string) $data['place_id'] : null,
            place: isset($data['place']) && is_array($data['place']) ? CreatePlaceData::from($data['place']) : null,
            createItineraryEvents: (bool) ($data['create_itinerary_events'] ?? false),
        );
    }
}
