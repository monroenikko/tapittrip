<?php

declare(strict_types=1);

namespace App\DTOs\Imports;

final readonly class ExtractedBookingData
{
    /**
     * @param  array<string, mixed>|null  $flight
     * @param  array<string, mixed>|null  $stay
     * @param  array<string, mixed>|null  $activity
     * @param  array<string, mixed>  $rawExtracted
     */
    public function __construct(
        public string $bookingType,
        public float $confidence,
        public string $summary,
        public ?array $flight = null,
        public ?array $stay = null,
        public ?array $activity = null,
        public array $rawExtracted = [],
    ) {}

    /**
     * @return array<string, mixed>
     */
    public function toArray(): array
    {
        return [
            'booking_type' => $this->bookingType,
            'confidence' => $this->confidence,
            'summary' => $this->summary,
            'flight' => $this->flight,
            'stay' => $this->stay,
            'activity' => $this->activity,
            'raw_extracted' => $this->rawExtracted,
        ];
    }

    /**
     * @param  array<string, mixed>  $data
     */
    public static function fromArray(array $data): self
    {
        return new self(
            bookingType: (string) ($data['booking_type'] ?? 'flight'),
            confidence: (float) ($data['confidence'] ?? 0.90),
            summary: (string) ($data['summary'] ?? 'Booking reservation'),
            flight: isset($data['flight']) && is_array($data['flight']) ? $data['flight'] : null,
            stay: isset($data['stay']) && is_array($data['stay']) ? $data['stay'] : null,
            activity: isset($data['activity']) && is_array($data['activity']) ? $data['activity'] : null,
            rawExtracted: isset($data['raw_extracted']) && is_array($data['raw_extracted']) ? $data['raw_extracted'] : [],
        );
    }
}
