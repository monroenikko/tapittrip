<?php

declare(strict_types=1);

namespace App\Application\Weather\Data;

final readonly class DailyForecastData
{
    public function __construct(
        public string $date,
        public string $dayName,
        public float $tempMaxC,
        public float $tempMinC,
        public float $tempMaxF,
        public float $tempMinF,
        public string $condition,
        public string $icon,
        public int $precipitationProbability,
    ) {}

    /**
     * @return array<string, mixed>
     */
    public function toArray(): array
    {
        return [
            'date' => $this->date,
            'day_name' => $this->dayName,
            'temp_max_c' => $this->tempMaxC,
            'temp_min_c' => $this->tempMinC,
            'temp_max_f' => $this->tempMaxF,
            'temp_min_f' => $this->tempMinF,
            'condition' => $this->condition,
            'icon' => $this->icon,
            'precipitation_probability' => $this->precipitationProbability,
        ];
    }

    /**
     * @param  array<string, mixed>  $data
     */
    public static function fromArray(array $data): self
    {
        return new self(
            date: (string) ($data['date'] ?? ''),
            dayName: (string) ($data['day_name'] ?? ''),
            tempMaxC: (float) ($data['temp_max_c'] ?? 0.0),
            tempMinC: (float) ($data['temp_min_c'] ?? 0.0),
            tempMaxF: (float) ($data['temp_max_f'] ?? 0.0),
            tempMinF: (float) ($data['temp_min_f'] ?? 0.0),
            condition: (string) ($data['condition'] ?? 'Partly Cloudy'),
            icon: (string) ($data['icon'] ?? 'partly_cloudy'),
            precipitationProbability: (int) ($data['precipitation_probability'] ?? 10),
        );
    }
}
