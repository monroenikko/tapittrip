<?php

declare(strict_types=1);

namespace App\Application\Stays\Data;

use Carbon\Carbon;
use Carbon\CarbonInterface;

final readonly class UpdateStayData
{
    /**
     * @param  array<string, mixed>|null  $luggageProfile
     */
    public function __construct(
        public ?string $name = null,
        public ?string $stayType = null,
        public ?string $address = null,
        public ?float $latitude = null,
        public ?float $longitude = null,
        public ?CarbonInterface $checkInAt = null,
        public ?CarbonInterface $checkOutAt = null,
        public ?string $timezone = null,
        public ?string $phone = null,
        public ?string $bookingReference = null,
        public ?string $notes = null,
        public ?array $luggageProfile = null,
        public ?string $placeId = null,
    ) {}

    /**
     * @param  array<string, mixed>  $data
     */
    public static function from(array $data): self
    {
        return new self(
            name: isset($data['name']) ? (string) $data['name'] : null,
            stayType: isset($data['stay_type']) ? (string) $data['stay_type'] : null,
            address: array_key_exists('address', $data) ? ($data['address'] !== null ? (string) $data['address'] : null) : null,
            latitude: isset($data['latitude']) && $data['latitude'] !== null ? (float) $data['latitude'] : null,
            longitude: isset($data['longitude']) && $data['longitude'] !== null ? (float) $data['longitude'] : null,
            checkInAt: isset($data['check_in_at']) && $data['check_in_at'] !== null
                ? Carbon::parse((string) $data['check_in_at'])
                : null,
            checkOutAt: isset($data['check_out_at']) && $data['check_out_at'] !== null
                ? Carbon::parse((string) $data['check_out_at'])
                : null,
            timezone: isset($data['timezone']) ? (string) $data['timezone'] : null,
            phone: array_key_exists('phone', $data) ? ($data['phone'] !== null ? (string) $data['phone'] : null) : null,
            bookingReference: array_key_exists('booking_reference', $data) ? ($data['booking_reference'] !== null ? (string) $data['booking_reference'] : null) : null,
            notes: array_key_exists('notes', $data) ? ($data['notes'] !== null ? (string) $data['notes'] : null) : null,
            luggageProfile: isset($data['luggage_profile']) && is_array($data['luggage_profile']) ? $data['luggage_profile'] : null,
            placeId: array_key_exists('place_id', $data) ? ($data['place_id'] !== null ? (string) $data['place_id'] : null) : null,
        );
    }
}
