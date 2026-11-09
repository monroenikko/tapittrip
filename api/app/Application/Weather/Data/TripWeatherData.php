<?php

declare(strict_types=1);

namespace App\Application\Weather\Data;

final readonly class TripWeatherData
{
    /**
     * @param  list<DailyForecastData>  $forecast
     */
    public function __construct(
        public string $destination,
        public float $latitude,
        public float $longitude,
        public string $timezone,
        public WeatherConditionData $current,
        public array $forecast,
        public string $providerAttribution,
    ) {}

    /**
     * @return array<string, mixed>
     */
    public function toArray(): array
    {
        return [
            'destination' => $this->destination,
            'latitude' => $this->latitude,
            'longitude' => $this->longitude,
            'timezone' => $this->timezone,
            'current' => $this->current->toArray(),
            'forecast' => array_map(fn (DailyForecastData $item): array => $item->toArray(), $this->forecast),
            'provider_attribution' => $this->providerAttribution,
        ];
    }

    /**
     * @param  array<string, mixed>  $data
     */
    public static function fromArray(array $data): self
    {
        $currentData = is_array($data['current'] ?? null) ? $data['current'] : [];
        $rawForecast = is_array($data['forecast'] ?? null) ? $data['forecast'] : [];

        return new self(
            destination: (string) ($data['destination'] ?? 'Destination'),
            latitude: (float) ($data['latitude'] ?? 0.0),
            longitude: (float) ($data['longitude'] ?? 0.0),
            timezone: (string) ($data['timezone'] ?? 'UTC'),
            current: WeatherConditionData::fromArray($currentData),
            forecast: array_values(array_map(
                fn (mixed $item): DailyForecastData => is_array($item)
                    ? DailyForecastData::fromArray($item)
                    : new DailyForecastData('', '', 0.0, 0.0, 0.0, 0.0, 'Partly Cloudy', 'partly_cloudy', 10),
                $rawForecast
            )),
            providerAttribution: (string) ($data['provider_attribution'] ?? 'Live Weather via Open-Meteo'),
        );
    }
}
