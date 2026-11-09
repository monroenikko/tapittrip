<?php

declare(strict_types=1);

namespace Tests\Unit;

use App\Application\Weather\Services\GetTripWeatherService;
use App\Domain\Stays\Models\Stay;
use App\Domain\Trips\Models\Trip;
use App\Models\User;
use Illuminate\Foundation\Testing\DatabaseTransactions;
use Illuminate\Support\Facades\Http;
use Tests\TestCase;

final class GetTripWeatherServiceTest extends TestCase
{
    use DatabaseTransactions;

    private Trip $trip;

    private GetTripWeatherService $service;

    protected function setUp(): void
    {
        parent::setUp();

        $user = User::factory()->create();
        $this->trip = Trip::factory()->create([
            'owner_id' => $user->id,
            'title' => 'Tokyo Cherry Blossom Trip',
            'destination_country' => 'Japan',
            'start_date' => '2026-11-10',
            'end_date' => '2026-11-16',
            'primary_timezone' => 'Asia/Tokyo',
        ]);

        $this->service = new GetTripWeatherService;
    }

    public function test_resolves_coordinates_from_stay_when_available(): void
    {
        Stay::create([
            'trip_id' => $this->trip->id,
            'name' => 'Shibuya Excel Hotel Tokyu',
            'stay_type' => 'hotel',
            'latitude' => 35.6595,
            'longitude' => 139.7005,
            'timezone' => 'Asia/Tokyo',
            'version' => 1,
        ]);

        $fallback = $this->service->getWeather($this->trip);

        $this->assertSame(35.6595, $fallback->latitude);
        $this->assertSame(139.7005, $fallback->longitude);
        $this->assertStringContainsString('Shibuya Excel Hotel Tokyu', $fallback->destination);
    }

    public function test_parses_open_meteo_live_response_correctly(): void
    {
        $fakeMeteoJson = [
            'latitude' => 35.6762,
            'longitude' => 139.6503,
            'timezone' => 'Asia/Tokyo',
            'current' => [
                'temperature_2m' => 18.5,
                'apparent_temperature' => 17.8,
                'relative_humidity_2m' => 52,
                'weather_code' => 2, // Partly cloudy
                'wind_speed_10m' => 14.2,
                'precipitation' => 0.0,
            ],
            'daily' => [
                'time' => ['2026-11-10', '2026-11-11', '2026-11-12'],
                'temperature_2m_max' => [20.0, 19.2, 17.5],
                'temperature_2m_min' => [12.0, 11.5, 10.0],
                'weather_code' => [2, 61, 0], // Partly cloudy, Rain showers, Clear
                'precipitation_probability_max' => [20, 75, 5],
            ],
        ];

        Http::fake([
            'api.open-meteo.com/*' => Http::response($fakeMeteoJson, 200),
        ]);

        $weather = $this->service->getWeather($this->trip);

        $this->assertSame('Tokyo, Japan', $weather->destination);
        $this->assertSame(18.5, $weather->current->temperatureC);
        $this->assertSame(65.3, $weather->current->temperatureF);
        $this->assertSame('Partly Cloudy', $weather->current->condition);
        $this->assertSame('partly_cloudy', $weather->current->icon);
        $this->assertSame(52, $weather->current->humidity);
        $this->assertSame(14.2, $weather->current->windKph);
        $this->assertSame(20, $weather->current->precipitationProbability);
        $this->assertStringContainsString('Live Weather via Open-Meteo', $weather->providerAttribution);

        $this->assertCount(3, $weather->forecast);
        $this->assertSame('Today', $weather->forecast[0]->dayName);
        $this->assertSame(20.0, $weather->forecast[0]->tempMaxC);
        $this->assertSame('Tomorrow', $weather->forecast[1]->dayName);
        $this->assertSame('Rain Showers', $weather->forecast[1]->condition);
        $this->assertSame(75, $weather->forecast[1]->precipitationProbability);
    }

    public function test_falls_back_to_offline_resilient_weather_on_http_error(): void
    {
        Http::fake([
            'api.open-meteo.com/*' => Http::response(['error' => 'Service Unavailable'], 503),
        ]);

        $weather = $this->service->getWeather($this->trip);

        $this->assertNotNull($weather->current);
        $this->assertNotEmpty($weather->forecast);
        $this->assertStringContainsString('Offline Resilient', $weather->providerAttribution);
    }
}
