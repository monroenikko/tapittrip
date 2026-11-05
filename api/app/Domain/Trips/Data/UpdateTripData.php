<?php

declare(strict_types=1);

namespace App\Domain\Trips\Data;

final readonly class UpdateTripData
{
    public function __construct(
        public ?string $title = null,
        public ?string $startDate = null,
        public ?string $endDate = null,
        public ?string $primaryTimezone = null,
        public ?string $originCountry = null,
        public ?string $destinationCountry = null,
        public ?string $tripType = null,
        public ?string $planningMode = null,
        public ?string $status = null,
    ) {}

    /**
     * @param  array<string, mixed>  $payload
     */
    public static function from(array $payload): self
    {
        return new self(
            title: isset($payload['title']) ? (string) $payload['title'] : null,
            startDate: array_key_exists('start_date', $payload) ? ($payload['start_date'] ? (string) $payload['start_date'] : null) : null,
            endDate: array_key_exists('end_date', $payload) ? ($payload['end_date'] ? (string) $payload['end_date'] : null) : null,
            primaryTimezone: isset($payload['primary_timezone']) ? (string) $payload['primary_timezone'] : null,
            originCountry: array_key_exists('origin_country', $payload) ? ($payload['origin_country'] ? (string) $payload['origin_country'] : null) : null,
            destinationCountry: array_key_exists('destination_country', $payload) ? ($payload['destination_country'] ? (string) $payload['destination_country'] : null) : null,
            tripType: isset($payload['trip_type']) ? (string) $payload['trip_type'] : null,
            planningMode: isset($payload['planning_mode']) ? (string) $payload['planning_mode'] : null,
            status: isset($payload['status']) ? (string) $payload['status'] : null,
        );
    }

    /**
     * @param  array<string, mixed>  $payload
     * @return array<string, mixed>
     */
    public function toUpdatePayload(array $payload): array
    {
        $fields = [
            'title' => $this->title,
            'start_date' => $this->startDate,
            'end_date' => $this->endDate,
            'primary_timezone' => $this->primaryTimezone,
            'origin_country' => $this->originCountry,
            'destination_country' => $this->destinationCountry,
            'trip_type' => $this->tripType,
            'planning_mode' => $this->planningMode,
            'status' => $this->status,
        ];

        // Only include fields that were present in the validated request
        return array_intersect_key($fields, $payload);
    }
}
