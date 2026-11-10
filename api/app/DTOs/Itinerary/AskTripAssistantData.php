<?php

declare(strict_types=1);

namespace App\DTOs\Itinerary;

final readonly class AskTripAssistantData
{
    public function __construct(
        public string $query,
        public ?string $contextDate = null,
        public ?string $terminalCode = null,
    ) {}

    /**
     * @param  array<string, mixed>  $data
     */
    public static function from(array $data): self
    {
        return new self(
            query: (string) $data['query'],
            contextDate: isset($data['context_date']) ? (string) $data['context_date'] : null,
            terminalCode: isset($data['terminal_code']) ? (string) $data['terminal_code'] : null,
        );
    }
}
