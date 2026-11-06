<?php

declare(strict_types=1);

namespace App\Application\Stays\Data;

final readonly class CompareStayTransportData
{
    public function __construct(
        public ?string $originName = null,
        public ?float $originLatitude = null,
        public ?float $originLongitude = null,
        public int $partySize = 1,
        public string $luggagePreset = 'standard',
        public int $backpacks = 1,
        public int $carryOns = 1,
        public int $checkedBags = 0,
        public int $oversized = 0,
        public bool $stroller = false,
    ) {}

    /**
     * @param  array<string, mixed>  $data
     */
    public static function from(array $data): self
    {
        $preset = (string) ($data['luggage_preset'] ?? 'standard');

        $backpacks = isset($data['backpacks']) ? (int) $data['backpacks'] : match ($preset) {
            'light' => 1,
            'heavy' => 2,
            default => 1,
        };

        $carryOns = isset($data['carry_ons']) ? (int) $data['carry_ons'] : match ($preset) {
            'light' => 0,
            'heavy' => 2,
            default => 1,
        };

        $checkedBags = isset($data['checked_bags']) ? (int) $data['checked_bags'] : match ($preset) {
            'light' => 0,
            'heavy' => 3,
            default => 1,
        };

        $oversized = isset($data['oversized']) ? (int) $data['oversized'] : match ($preset) {
            'heavy' => 1,
            default => 0,
        };

        $stroller = isset($data['stroller']) ? (bool) $data['stroller'] : ($preset === 'heavy');

        $originRaw = $data['origin_name'] ?? $data['origin'] ?? null;
        $originName = $originRaw !== null && trim((string) $originRaw) !== '' ? trim((string) $originRaw) : null;

        return new self(
            originName: $originName,
            originLatitude: isset($data['origin_latitude']) && $data['origin_latitude'] !== null ? (float) $data['origin_latitude'] : null,
            originLongitude: isset($data['origin_longitude']) && $data['origin_longitude'] !== null ? (float) $data['origin_longitude'] : null,
            partySize: max(1, (int) ($data['party_size'] ?? 1)),
            luggagePreset: $preset,
            backpacks: max(0, $backpacks),
            carryOns: max(0, $carryOns),
            checkedBags: max(0, $checkedBags),
            oversized: max(0, $oversized),
            stroller: $stroller,
        );
    }
}
