<?php

declare(strict_types=1);

namespace Tests\Feature;

use App\Domain\Itinerary\Models\Place;
use App\Models\User;
use Illuminate\Foundation\Testing\DatabaseTransactions;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

final class PlaceTest extends TestCase
{
    use DatabaseTransactions;

    public function test_user_can_create_and_retrieve_place(): void
    {
        $user = User::factory()->create();
        Sanctum::actingAs($user);

        $payload = [
            'name' => 'Fushimi Inari Taisha',
            'formatted_address' => '68 Fukakusa Yabunouchicho, Fushimi Ward, Kyoto',
            'country_code' => 'JP',
            'latitude' => 34.9671,
            'longitude' => 135.7727,
            'provider' => 'manual',
            'attribution' => 'TapItTrip Curated',
        ];

        $response = $this->postJson('/api/v1/places', $payload);

        $response
            ->assertCreated()
            ->assertJsonPath('data.name', 'Fushimi Inari Taisha')
            ->assertJsonPath('data.latitude', 34.9671)
            ->assertJsonPath('data.longitude', 135.7727)
            ->assertJsonPath('data.google_maps_url', 'https://www.google.com/maps/search/?api=1&query=34.9671,135.7727');

        $placeId = (string) $response->json('data.id');

        $showResponse = $this->getJson("/api/v1/places/{$placeId}");
        $showResponse
            ->assertOk()
            ->assertJsonPath('data.id', $placeId)
            ->assertJsonPath('data.name', 'Fushimi Inari Taisha');
    }

    public function test_user_can_search_places_by_keyword(): void
    {
        $user = User::factory()->create();
        Sanctum::actingAs($user);

        Place::factory()->create(['name' => 'Kinkaku-ji Golden Pavilion']);
        Place::factory()->create(['name' => 'Ginkaku-ji Silver Pavilion']);
        Place::factory()->create(['name' => 'Tokyo Tower']);

        $response = $this->getJson('/api/v1/places/search?q=Pavilion');

        $response
            ->assertOk()
            ->assertJsonCount(2, 'data');
    }
}
