<?php

declare(strict_types=1);

namespace App\Application\Weather\Data;

final readonly class WeatherConditionData
{
    public function __construct(
        public float $temperatureC,
        public float $temperatureF,
        public float $feelsLikeC,
        public float $feelsLikeF,
        public string $condition,
        public string $icon,
        public int $humidity,
        public float $windKph,
        public int $precipitationProbability,
        public string $advisory,
    ) {}

    /**
     * @return array<string, mixed>
     */
    public function toArray(): array
    {
        return [
            'temperature_c' => $this->temperatureC,
            'temperature_f' => $this->temperatureF,
            'feels_like_c' => $this->feelsLikeC,
            'feels_like_f' => $this->feelsLikeF,
            'condition' => $this->condition,
            'icon' => $this->icon,
            'humidity' => $this->humidity,
            'wind_kph' => $this->windKph,
            'precipitation_probability' => $this->precipitationProbability,
            'advisory' => $this->advisory,
        ];
    }

    /**
     * @param  array<string, mixed>  $data
     */
    public static function fromArray(array $data): self
    {
        return new self(
            temperatureC: (float) ($data['temperature_c'] ?? 0.0),
            temperatureF: (float) ($data['temperature_f'] ?? 0.0),
            feelsLikeC: (float) ($data['feels_like_c'] ?? 0.0),
            feelsLikeF: (float) ($data['feels_like_f'] ?? 0.0),
            condition: (string) ($data['condition'] ?? 'Partly Cloudy'),
            icon: (string) ($data['icon'] ?? 'partly_cloudy'),
            humidity: (int) ($data['humidity'] ?? 50),
            windKph: (float) ($data['wind_kph'] ?? 10.0),
            precipitationProbability: (int) ($data['precipitation_probability'] ?? 10),
            advisory: (string) ($data['advisory'] ?? 'Pleasant travel weather.'),
        );
    }
}
