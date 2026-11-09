<?php

declare(strict_types=1);

namespace Tests\Feature;

use App\Domain\Trips\Models\Trip;
use App\Models\User;
use Illuminate\Foundation\Testing\DatabaseTransactions;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

final class TripWeatherTest extends TestCase
{
    use DatabaseTransactions;

    private User $user;

    private Trip $trip;

    protected function setUp(): void
    {
        parent::setUp();

        $this->user = User::factory()->create();
        Sanctum::actingAs($this->user);

        $this->trip = Trip::factory()->create([
            'owner_id' => $this->user->id,
            'title' => 'BGC Taguig Exploration',
            'destination_country' => 'Philippines',
            'start_date' => '2026-11-10',
            'end_date' => '2026-11-15',
            'primary_timezone' => 'Asia/Manila',
        ]);
    }

    public function test_trip_member_can_fetch_weather_forecast(): void
    {
        $response = $this->getJson("/api/v1/trips/{$this->trip->id}/weather");

        $response->assertOk()
            ->assertJsonStructure([
                'data' => [
                    'destination',
                    'latitude',
                    'longitude',
                    'timezone',
                    'current' => [
                        'temperature_c',
                        'temperature_f',
                        'feels_like_c',
                        'feels_like_f',
                        'condition',
                        'icon',
                        'humidity',
                        'wind_kph',
                        'precipitation_probability',
                        'advisory',
                    ],
                    'forecast' => [
                        '*' => [
                            'date',
                            'day_name',
                            'temp_max_c',
                            'temp_min_c',
                            'temp_max_f',
                            'temp_min_f',
                            'condition',
                            'icon',
                            'precipitation_probability',
                        ],
                    ],
                    'provider_attribution',
                ],
            ]);

        $this->assertNotEmpty($response->json('data.destination'));
    }

    public function test_non_trip_member_cannot_fetch_trip_weather(): void
    {
        $otherUser = User::factory()->create();
        Sanctum::actingAs($otherUser);

        $response = $this->getJson("/api/v1/trips/{$this->trip->id}/weather");

        $response->assertForbidden();
    }

    public function test_today_summary_endpoint_includes_weather_object(): void
    {
        $response = $this->getJson("/api/v1/trips/{$this->trip->id}/today");

        $response->assertOk()
            ->assertJsonStructure([
                'data' => [
                    'trip',
                    'trip_status',
                    'weather' => [
                        'temperature_c',
                        'temperature_f',
                        'condition',
                        'icon',
                        'humidity',
                        'wind_kph',
                        'precipitation_probability',
                        'advisory',
                    ],
                ],
            ]);

        $this->assertNotNull($response->json('data.weather.temperature_c'));
        $this->assertNotNull($response->json('data.weather.condition'));
    }

    public function test_trip_weather_with_custom_coordinates_and_location(): void
    {
        $response = $this->getJson("/api/v1/trips/{$this->trip->id}/weather?latitude=35.2323&longitude=139.1069&location=Hakone");

        $response->assertOk()
            ->assertJsonPath('data.destination', 'Hakone')
            ->assertJsonPath('data.latitude', 35.2323)
            ->assertJsonPath('data.longitude', 139.1069);
    }
}
