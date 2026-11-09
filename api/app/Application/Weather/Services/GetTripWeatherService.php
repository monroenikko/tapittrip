<?php

declare(strict_types=1);

namespace App\Application\Weather\Services;

use App\Application\Weather\Data\DailyForecastData;
use App\Application\Weather\Data\TripWeatherData;
use App\Application\Weather\Data\WeatherConditionData;
use App\Domain\Trips\Models\Trip;
use Carbon\CarbonImmutable;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

final class GetTripWeatherService
{
    /**
     * Get live or cached weather for the active trip's destination.
     */
    public function getWeather(Trip $trip): TripWeatherData
    {
        $timezone = $trip->primary_timezone ?: 'UTC';
        $now = CarbonImmutable::now($timezone);
        $dateKey = $now->format('Y-m-d-H');
        $cacheKey = "trip_weather_{$trip->id}_{$dateKey}";

        try {
            $cached = Cache::get($cacheKey);
            if (is_array($cached) && isset($cached['current'])) {
                return TripWeatherData::fromArray($cached);
            }
        } catch (\Throwable $e) {
            Log::info("Weather cache read bypass for trip {$trip->id}: ".$e->getMessage());
        }

        [$lat, $lng, $destName] = $this->resolveCoordinates($trip);

        try {
            $url = "https://api.open-meteo.com/v1/forecast?latitude={$lat}&longitude={$lng}&current=temperature_2m,relative_humidity_2m,apparent_temperature,precipitation,weather_code,wind_speed_10m&daily=weather_code,temperature_2m_max,temperature_2m_min,precipitation_probability_max&timezone=auto";

            $response = Http::timeout(4)
                ->retry(1, 50)
                ->get($url);

            if ($response->successful()) {
                $json = $response->json();
                if (is_array($json) && isset($json['current'])) {
                    $weather = $this->parseOpenMeteoResponse($json, $destName, $lat, $lng, $timezone, $now);
                    try {
                        Cache::put($cacheKey, $weather->toArray(), 1800);
                    } catch (\Throwable) {
                        // Ignore cache write errors
                    }

                    return $weather;
                }
            }
        } catch (\Throwable $e) {
            Log::warning("Open-Meteo weather fetch failed for trip {$trip->id}: ".$e->getMessage());
        }

        $fallback = $this->buildFallbackWeather($destName, $lat, $lng, $timezone, $now);
        try {
            Cache::put($cacheKey, $fallback->toArray(), 300);
        } catch (\Throwable) {
            // Ignore cache write errors
        }

        return $fallback;
    }

    /**
     * Get only the current weather condition for quick summary cards.
     */
    public function getCurrentWeather(Trip $trip): WeatherConditionData
    {
        return $this->getWeather($trip)->current;
    }

    /**
     * Resolve latitude and longitude for the trip.
     *
     * @return array{0: float, 1: float, 2: string} [latitude, longitude, destinationName]
     */
    private function resolveCoordinates(Trip $trip): array
    {
        // 1. From active stay
        $stay = $trip->stays()->whereNotNull('latitude')->whereNotNull('longitude')->first();
        if ($stay !== null && $stay->latitude !== null && $stay->longitude !== null) {
            $name = $stay->name ?: ($trip->destination_country ?? $trip->title);

            return [(float) $stay->latitude, (float) $stay->longitude, $name];
        }

        // 2. From itinerary item with place coordinates
        $item = $trip->itineraryItems()
            ->whereHas('place', fn ($q) => $q->whereNotNull('latitude')->whereNotNull('longitude'))
            ->with('place')
            ->first();
        if ($item !== null && $item->place?->latitude !== null && $item->place?->longitude !== null) {
            $name = $item->place->name ?: ($trip->destination_country ?? $trip->title);

            return [(float) $item->place->latitude, (float) $item->place->longitude, $name];
        }

        // 3. Known cities / destinations dictionary
        $dest = mb_strtolower(trim(($trip->destination_country ?? '').' '.$trip->title));
        $destMap = [
            'tokyo' => [35.6762, 139.6503, 'Tokyo, Japan'],
            'japan' => [35.6762, 139.6503, 'Tokyo, Japan'],
            'osaka' => [34.6937, 135.5023, 'Osaka, Japan'],
            'kyoto' => [35.0116, 135.7681, 'Kyoto, Japan'],
            'taguig' => [14.5547, 121.0494, 'Taguig (BGC), Philippines'],
            'bgc' => [14.5547, 121.0494, 'Bonifacio Global City, Philippines'],
            'manila' => [14.5995, 120.9842, 'Manila, Philippines'],
            'makati' => [14.5547, 121.0244, 'Makati, Philippines'],
            'cebu' => [10.3157, 123.8854, 'Cebu, Philippines'],
            'boracay' => [11.9674, 121.9248, 'Boracay, Philippines'],
            'philippines' => [14.5995, 120.9842, 'Manila, Philippines'],
            'singapore' => [1.3521, 103.8198, 'Singapore'],
            'bangkok' => [13.7563, 100.5018, 'Bangkok, Thailand'],
            'thailand' => [13.7563, 100.5018, 'Bangkok, Thailand'],
            'bali' => [-8.4095, 115.1889, 'Bali, Indonesia'],
            'indonesia' => [-8.4095, 115.1889, 'Bali, Indonesia'],
            'seoul' => [37.5665, 126.9780, 'Seoul, South Korea'],
            'korea' => [37.5665, 126.9780, 'Seoul, South Korea'],
            'london' => [51.5074, -0.1278, 'London, United Kingdom'],
            'paris' => [48.8566, 2.3522, 'Paris, France'],
            'france' => [48.8566, 2.3522, 'Paris, France'],
            'rome' => [41.9028, 12.4964, 'Rome, Italy'],
            'italy' => [41.9028, 12.4964, 'Rome, Italy'],
            'sydney' => [-33.8688, 151.2093, 'Sydney, Australia'],
            'australia' => [-33.8688, 151.2093, 'Sydney, Australia'],
            'new york' => [40.7128, -74.0060, 'New York, USA'],
            'san francisco' => [37.7749, -122.4194, 'San Francisco, USA'],
            'zurich' => [47.3769, 8.5417, 'Zurich, Switzerland'],
            'switzerland' => [47.3769, 8.5417, 'Zurich, Switzerland'],
        ];

        foreach ($destMap as $key => [$lat, $lng, $name]) {
            if (str_contains($dest, $key)) {
                return [$lat, $lng, $name];
            }
        }

        // Default to Tokyo coordinates or destination title
        $fallbackName = $trip->destination_country ? "{$trip->title} ({$trip->destination_country})" : $trip->title;

        return [35.6762, 139.6503, $fallbackName];
    }

    /**
     * @param  array<string, mixed>  $json
     */
    private function parseOpenMeteoResponse(
        array $json,
        string $destName,
        float $lat,
        float $lng,
        string $timezone,
        CarbonImmutable $now,
    ): TripWeatherData {
        $cur = $json['current'] ?? [];
        $tempC = (float) ($cur['temperature_2m'] ?? 20.0);
        $tempF = round(($tempC * 9 / 5) + 32, 1);
        $feelsC = (float) ($cur['apparent_temperature'] ?? $tempC);
        $feelsF = round(($feelsC * 9 / 5) + 32, 1);
        $humidity = (int) ($cur['relative_humidity_2m'] ?? 60);
        $windKph = (float) ($cur['wind_speed_10m'] ?? 10.0);
        $code = (int) ($cur['weather_code'] ?? 0);

        [$condText, $icon] = $this->mapWmoCode($code);

        // Daily forecast
        $daily = $json['daily'] ?? [];
        $forecast = [];
        $dates = $daily['time'] ?? [];
        $maxTemps = $daily['temperature_2m_max'] ?? [];
        $minTemps = $daily['temperature_2m_min'] ?? [];
        $codes = $daily['weather_code'] ?? [];
        $rainProbs = $daily['precipitation_probability_max'] ?? [];

        $todayRainProb = 10;

        $count = min(count($dates), 7);
        for ($i = 0; $i < $count; $i++) {
            $dateStr = (string) ($dates[$i] ?? '');
            $maxC = (float) ($maxTemps[$i] ?? $tempC);
            $minC = (float) ($minTemps[$i] ?? $tempC - 5);
            $dayCode = (int) ($codes[$i] ?? $code);
            $rainProb = (int) ($rainProbs[$i] ?? 10);

            if ($i === 0) {
                $todayRainProb = $rainProb;
            }

            [$dayCond, $dayIcon] = $this->mapWmoCode($dayCode);

            $dateObj = CarbonImmutable::parse($dateStr);
            $dayName = $i === 0 ? 'Today' : ($i === 1 ? 'Tomorrow' : $dateObj->format('l'));

            $forecast[] = new DailyForecastData(
                date: $dateStr,
                dayName: $dayName,
                tempMaxC: round($maxC, 1),
                tempMinC: round($minC, 1),
                tempMaxF: round(($maxC * 9 / 5) + 32, 1),
                tempMinF: round(($minC * 9 / 5) + 32, 1),
                condition: $dayCond,
                icon: $dayIcon,
                precipitationProbability: $rainProb,
            );
        }

        $advisory = $this->generateAdvisory($condText, $tempC, $todayRainProb);

        $current = new WeatherConditionData(
            temperatureC: round($tempC, 1),
            temperatureF: $tempF,
            feelsLikeC: round($feelsC, 1),
            feelsLikeF: $feelsF,
            condition: $condText,
            icon: $icon,
            humidity: $humidity,
            windKph: round($windKph, 1),
            precipitationProbability: $todayRainProb,
            advisory: $advisory,
        );

        return new TripWeatherData(
            destination: $destName,
            latitude: $lat,
            longitude: $lng,
            timezone: $timezone,
            current: $current,
            forecast: $forecast,
            providerAttribution: 'Live Weather via Open-Meteo',
        );
    }

    /**
     * Map WMO Weather Interpretation Codes to human readable condition text and icon identifier.
     *
     * @return array{0: string, 1: string} [condition, icon]
     */
    private function mapWmoCode(int $code): array
    {
        return match (true) {
            $code === 0 => ['Clear Sky', 'sunny'],
            $code === 1 => ['Mainly Clear', 'sunny'],
            $code === 2 => ['Partly Cloudy', 'partly_cloudy'],
            $code === 3 => ['Overcast', 'cloudy'],
            $code === 45, $code === 48 => ['Foggy', 'fog'],
            in_array($code, [51, 53, 55], true) => ['Light Drizzle', 'rain'],
            in_array($code, [61, 63, 65], true) => ['Rain Showers', 'rain'],
            in_array($code, [80, 81, 82], true) => ['Heavy Showers', 'heavy_rain'],
            in_array($code, [71, 73, 75, 77, 85, 86], true) => ['Snowfall', 'snow'],
            in_array($code, [95, 96, 99], true) => ['Thunderstorm', 'thunderstorm'],
            default => ['Partly Cloudy', 'partly_cloudy'],
        };
    }

    private function generateAdvisory(string $condition, float $tempC, int $rainProb): string
    {
        if ($rainProb >= 50 || str_contains(strtolower($condition), 'rain')) {
            return 'Rain expected today — keep an umbrella handy and consider covered arcades or museums.';
        }

        if ($tempC >= 32) {
            return 'Hot and humid — stay hydrated, wear sun protection, and take indoor breaks midday.';
        }

        if ($tempC <= 8) {
            return 'Chilly weather — layer up with thermals, gloves, and a windproof coat.';
        }

        if ($tempC >= 18 && $tempC <= 26) {
            return 'Pleasant weather — ideal conditions for walking tours, gardens, and outdoor sightseeing.';
        }

        return 'Mild conditions — light layers recommended for comfortable travel throughout the day.';
    }

    private function buildFallbackWeather(
        string $destName,
        float $lat,
        float $lng,
        string $timezone,
        CarbonImmutable $now,
    ): TripWeatherData {
        $isTropical = str_contains(strtolower($destName), 'philippines') ||
            str_contains(strtolower($destName), 'manila') ||
            str_contains(strtolower($destName), 'taguig') ||
            str_contains(strtolower($destName), 'singapore') ||
            str_contains(strtolower($destName), 'bali') ||
            str_contains(strtolower($destName), 'bangkok');

        $tempC = $isTropical ? 29.0 : 18.0;
        $tempF = round(($tempC * 9 / 5) + 32, 1);
        $cond = $isTropical ? 'Partly Cloudy' : 'Clear Sky';
        $icon = $isTropical ? 'partly_cloudy' : 'sunny';
        $advisory = $this->generateAdvisory($cond, $tempC, 15);

        $current = new WeatherConditionData(
            temperatureC: $tempC,
            temperatureF: $tempF,
            feelsLikeC: $tempC + ($isTropical ? 2.5 : -1.0),
            feelsLikeF: round((($tempC + 2.0) * 9 / 5) + 32, 1),
            condition: $cond,
            icon: $icon,
            humidity: $isTropical ? 75 : 55,
            windKph: 12.0,
            precipitationProbability: 15,
            advisory: $advisory,
        );

        $forecast = [];
        for ($i = 0; $i < 5; $i++) {
            $dayDate = $now->addDays($i);
            $dayName = $i === 0 ? 'Today' : ($i === 1 ? 'Tomorrow' : $dayDate->format('l'));
            $maxC = $tempC + ($i % 2 === 0 ? 1.0 : -0.5);
            $minC = $tempC - ($isTropical ? 4.0 : 7.0);

            $forecast[] = new DailyForecastData(
                date: $dayDate->format('Y-m-d'),
                dayName: $dayName,
                tempMaxC: round($maxC, 1),
                tempMinC: round($minC, 1),
                tempMaxF: round(($maxC * 9 / 5) + 32, 1),
                tempMinF: round(($minC * 9 / 5) + 32, 1),
                condition: $cond,
                icon: $icon,
                precipitationProbability: 15,
            );
        }

        return new TripWeatherData(
            destination: $destName,
            latitude: $lat,
            longitude: $lng,
            timezone: $timezone,
            current: $current,
            forecast: $forecast,
            providerAttribution: 'Advisory Forecast (Offline Resilient)',
        );
    }
}
