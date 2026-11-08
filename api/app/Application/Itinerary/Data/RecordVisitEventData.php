<?php

declare(strict_types=1);

namespace App\Application\Itinerary\Data;

final readonly class RecordVisitEventData
{
    public function __construct(
        public string $eventType, // suggested, confirmed, revoked
        public string $method = 'manual', // manual, geofence
        public ?float $accuracyM = null,
        public ?string $detectedAt = null,
    ) {}

    /**
     * @param  array<string, mixed>  $data
     */
    public static function from(array $data): self
    {
        return new self(
            eventType: (string) $data['event_type'],
            method: (string) ($data['method'] ?? 'manual'),
            accuracyM: isset($data['accuracy_m']) ? (float) $data['accuracy_m'] : null,
            detectedAt: isset($data['detected_at']) ? (string) $data['detected_at'] : null,
        );
    }
}

