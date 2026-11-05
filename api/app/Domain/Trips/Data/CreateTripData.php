<?php

declare(strict_types=1);

namespace App\Domain\Trips\Data;

final readonly class CreateTripData
{
    public function __construct(
        public string $title,
        public ?string $startDate = null,
        public ?string $endDate = null,
        public string $primaryTimezone = 'UTC',
        public ?string $originCountry = null,
        public ?string $destinationCountry = null,
        public string $tripType = 'leisure',
        public string $planningMode = 'diy',
    ) {}

    /**
     * @param  array<string, mixed>  $payload
     */
    public static function from(array $payload): self
    {
        return new self(
            title: (string) $payload['title'],
            startDate: isset($payload['start_date']) ? (string) $payload['start_date'] : null,
            endDate: isset($payload['end_date']) ? (string) $payload['end_date'] : null,
            primaryTimezone: (string) ($payload['primary_timezone'] ?? 'UTC'),
            originCountry: isset($payload['origin_country']) ? (string) $payload['origin_country'] : null,
            destinationCountry: isset($payload['destination_country']) ? (string) $payload['destination_country'] : null,
            tripType: (string) ($payload['trip_type'] ?? 'leisure'),
            planningMode: (string) ($payload['planning_mode'] ?? 'diy'),
        );
    }

    /**
     * @return array<string, mixed>
     */
    public function toArray(): array
    {
        return [
            'title' => $this->title,
            'start_date' => $this->startDate,
            'end_date' => $this->endDate,
            'primary_timezone' => $this->primaryTimezone,
            'origin_country' => $this->originCountry,
            'destination_country' => $this->destinationCountry,
            'trip_type' => $this->tripType,
            'planning_mode' => $this->planningMode,
        ];
    }
}
