<?php

declare(strict_types=1);

namespace Tests\Feature;

use App\Models\Stay;
use App\Models\Trip;
use App\Models\User;
use Illuminate\Foundation\Testing\DatabaseTransactions;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

final class StayTransportComparisonTest extends TestCase
{
    use DatabaseTransactions;

    public function test_heavy_luggage_profile_ranks_direct_private_transfer_most_convenient_with_explanation(): void
    {
        $user = User::factory()->create();
        Sanctum::actingAs($user);

        /** @var Trip $trip */
        $trip = Trip::factory()->create(['owner_id' => $user->id]);

        /** @var Stay $stay */
        $stay = Stay::factory()->create([
            'trip_id' => $trip->id,
            'name' => 'Shinjuku Prince Hotel',
            'latitude' => 35.6945,
            'longitude' => 139.7006,
        ]);

        $payload = [
            'origin_name' => 'Tokyo Haneda Airport (HND)',
            'party_size' => 2,
            'luggage_preset' => 'heavy',
            'checked_bags' => 3,
            'carry_ons' => 2,
            'stroller' => true,
        ];

        $response = $this->postJson("/api/v1/stays/{$stay->id}/transport-options", $payload);

        $response
            ->assertOk()
            ->assertJsonPath('data.verified', true)
            ->assertJsonPath('data.status', 'verified_advisory')
            ->assertJsonPath('data.party_size', 2)
            ->assertJsonPath('data.luggage_preset', 'heavy')
            ->assertJsonCount(3, 'data.options');

        $options = collect($response->json('data.options'));

        // Private transfer must win most convenient
        $private = $options->firstWhere('mode', 'private_transfer');
        $this->assertNotNull($private);
        $this->assertTrue($private['is_most_convenient']);
        $this->assertEquals(0, $private['transfers']);
        $this->assertStringContainsString('3 checked bag(s) and stroller', $private['explanation']);

        // Express rail must win fastest
        $rail = $options->firstWhere('mode', 'express_rail');
        $this->assertNotNull($rail);
        $this->assertTrue($rail['is_fastest']);
        $this->assertFalse($rail['is_most_convenient']);

        // Public transit must win cheapest
        $transit = $options->firstWhere('mode', 'public_transit');
        $this->assertNotNull($transit);
        $this->assertTrue($transit['is_cheapest']);
        $this->assertFalse($transit['is_most_convenient']);
    }

    public function test_light_luggage_profile_ranks_express_rail_most_convenient_and_fastest(): void
    {
        $user = User::factory()->create();
        Sanctum::actingAs($user);

        /** @var Trip $trip */
        $trip = Trip::factory()->create(['owner_id' => $user->id]);

        /** @var Stay $stay */
        $stay = Stay::factory()->create([
            'trip_id' => $trip->id,
            'name' => 'Shinjuku Prince Hotel',
            'latitude' => 35.6945,
            'longitude' => 139.7006,
        ]);

        $payload = [
            'origin_name' => 'Tokyo Haneda Airport (HND)',
            'party_size' => 1,
            'luggage_preset' => 'light',
            'backpacks' => 1,
            'checked_bags' => 0,
            'carry_ons' => 0,
            'stroller' => false,
        ];

        $response = $this->postJson("/api/v1/stays/{$stay->id}/transport-options", $payload);

        $response
            ->assertOk()
            ->assertJsonPath('data.verified', true);

        $options = collect($response->json('data.options'));

        // For light luggage, Express rail should win most convenient and fastest
        $rail = $options->firstWhere('mode', 'express_rail');
        $this->assertNotNull($rail);
        $this->assertTrue($rail['is_most_convenient']);
        $this->assertTrue($rail['is_fastest']);
    }

    public function test_unverified_missing_origin_returns_honest_limitation_and_maps_handoff(): void
    {
        $user = User::factory()->create();
        Sanctum::actingAs($user);

        /** @var Trip $trip */
        $trip = Trip::factory()->create(['owner_id' => $user->id]);

        /** @var Stay $stay */
        $stay = Stay::factory()->create([
            'trip_id' => $trip->id,
            'name' => 'Wilderness Tent Camp',
            'address' => null,
            'latitude' => null,
            'longitude' => null,
        ]);

        $payload = [
            'origin_name' => null,
            'party_size' => 1,
        ];

        $response = $this->postJson("/api/v1/stays/{$stay->id}/transport-options", $payload);

        $response
            ->assertOk()
            ->assertJsonPath('data.verified', false)
            ->assertJsonPath('data.status', 'unverified')
            ->assertJsonCount(0, 'data.options');

        $this->assertNotEmpty($response->json('data.google_maps_directions_url'));
        $this->assertStringContainsString('No verified transit routes', $response->json('data.message'));
    }

    public function test_auto_detects_nearest_transit_station_and_primary_airport_when_origin_not_provided(): void
    {
        $user = User::factory()->create();
        Sanctum::actingAs($user);

        /** @var Trip $trip */
        $trip = Trip::factory()->create(['owner_id' => $user->id]);

        /** @var Stay $stay */
        $stay = Stay::factory()->create([
            'trip_id' => $trip->id,
            'name' => 'Hotel Gracery Shinjuku',
            'address' => '1-19-1 Kabukicho, Shinjuku City, Tokyo',
            'latitude' => 35.6953,
            'longitude' => 139.7022,
        ]);

        $payload = [
            'party_size' => 2,
            'luggage_preset' => 'standard',
        ];

        $response = $this->postJson("/api/v1/stays/{$stay->id}/transport-options", $payload);

        $response
            ->assertOk()
            ->assertJsonPath('data.verified', true)
            ->assertJsonPath('data.nearest_transit.station_name', 'Shinjuku Station (South Exit)')
            ->assertJsonPath('data.nearest_transit.nearest_airport_code', 'HND');

        $options = $response->json('data.options');
        $this->assertNotEmpty($options);
        $rail = collect($options)->firstWhere('mode', 'express_rail');
        $this->assertNotNull($rail);
        $this->assertEquals('Shinjuku Station (South Exit)', $rail['dropoff_location']);
        $this->assertGreaterThan(0, $rail['last_mile_walk_meters']);
    }

    public function test_manila_arrival_transport_does_not_suggest_rail_and_recommends_grab_and_p2p_bus(): void
    {
        $user = User::factory()->create();
        Sanctum::actingAs($user);

        /** @var Trip $trip */
        $trip = Trip::factory()->create([
            'owner_id' => $user->id,
            'title' => 'Manila City Trip',
            'destination_country' => 'Philippines',
        ]);

        /** @var Stay $stay */
        $stay = Stay::factory()->create([
            'trip_id' => $trip->id,
            'name' => 'Seda BGC',
            'address' => '30th Street cor 11th Avenue, Bonifacio Global City, Taguig',
            'latitude' => 14.5505,
            'longitude' => 121.0509,
        ]);

        $payload = [
            'origin_name' => 'Ninoy Aquino International Airport (MNL)',
            'party_size' => 2,
            'luggage_preset' => 'standard',
        ];

        $response = $this->postJson("/api/v1/stays/{$stay->id}/transport-options", $payload);

        $response
            ->assertOk()
            ->assertJsonPath('data.verified', true)
            ->assertJsonPath('data.nearest_transit.has_airport_rail', false)
            ->assertJsonPath('data.nearest_transit.nearest_airport_code', 'MNL');

        $options = collect($response->json('data.options'));

        // Manila NAIA has NO express rail station!
        $this->assertNull($options->firstWhere('mode', 'express_rail'));

        // Proposes GrabCar / Airport Taxi and UBE Express P2P Bus
        $grab = $options->firstWhere('mode', 'rideshare');
        $this->assertNotNull($grab);
        $this->assertStringContainsString('GrabCar', $grab['title']);
        $this->assertEquals('PHP', $grab['currency']);

        $bus = $options->firstWhere('mode', 'public_transit');
        $this->assertNotNull($bus);
        $this->assertStringContainsString('UBE Express', $bus['title']);
        $this->assertEquals('PHP', $bus['currency']);
    }

    public function test_bali_arrival_transport_does_not_suggest_rail_and_recommends_private_driver(): void
    {
        $user = User::factory()->create();
        Sanctum::actingAs($user);

        /** @var Trip $trip */
        $trip = Trip::factory()->create([
            'owner_id' => $user->id,
            'title' => 'Bali Getaway',
            'destination_country' => 'Indonesia',
        ]);

        /** @var Stay $stay */
        $stay = Stay::factory()->create([
            'trip_id' => $trip->id,
            'name' => 'The Kayon Resort Ubud',
            'latitude' => -8.4721,
            'longitude' => 115.2719,
        ]);

        $payload = [
            'origin_name' => 'Ngurah Rai International Airport (DPS)',
            'party_size' => 2,
            'luggage_preset' => 'standard',
        ];

        $response = $this->postJson("/api/v1/stays/{$stay->id}/transport-options", $payload);

        $response
            ->assertOk()
            ->assertJsonPath('data.verified', true)
            ->assertJsonPath('data.nearest_transit.has_airport_rail', false);

        $options = collect($response->json('data.options'));

        // Bali has NO express rail station!
        $this->assertNull($options->firstWhere('mode', 'express_rail'));

        // Proposes Private Driver and Grab Lounge
        $driver = $options->firstWhere('mode', 'private_transfer');
        $this->assertNotNull($driver);
        $this->assertStringContainsString('Private Driver', $driver['title']);
        $this->assertEquals('IDR', $driver['currency']);
    }

    public function test_hong_kong_arrival_transport_provides_express_rail_and_urban_taxi(): void
    {
        $user = User::factory()->create();
        Sanctum::actingAs($user);

        /** @var Trip $trip */
        $trip = Trip::factory()->create([
            'owner_id' => $user->id,
            'title' => 'Hong Kong Exploration',
            'destination_country' => 'Hong Kong',
        ]);

        /** @var Stay $stay */
        $stay = Stay::factory()->create([
            'trip_id' => $trip->id,
            'name' => 'The Murray, Hong Kong',
            'address' => '22 Cotton Tree Dr, Central, Hong Kong',
            'latitude' => 22.2785,
            'longitude' => 114.1592,
        ]);

        $payload = [
            'origin_name' => 'Hong Kong International Airport (HKG)',
            'party_size' => 2,
            'luggage_preset' => 'standard',
        ];

        $response = $this->postJson("/api/v1/stays/{$stay->id}/transport-options", $payload);

        $response
            ->assertOk()
            ->assertJsonPath('data.verified', true)
            ->assertJsonPath('data.nearest_transit.has_airport_rail', true)
            ->assertJsonPath('data.nearest_transit.nearest_airport_code', 'HKG');

        $options = collect($response->json('data.options'));

        // Rail option (MTR Airport Express)
        $rail = $options->firstWhere('mode', 'express_rail');
        $this->assertNotNull($rail);
        $this->assertStringContainsString('MTR Airport Express', $rail['title']);
        $this->assertEquals('HKD', $rail['currency']);
        $this->assertEquals(23000, $rail['estimated_cost_minor']); // 2 people * HK$115
        $this->assertStringContainsString('Hong Kong Station', $rail['dropoff_location']);
        $this->assertStringContainsString('travelmode=walking', $rail['last_mile_directions_url']);
        $this->assertStringContainsString(urlencode($rail['dropoff_location']), $rail['last_mile_directions_url']);

        // Taxi option (Urban Red Taxi)
        $taxi = $options->firstWhere('mode', 'private_transfer');
        $this->assertNotNull($taxi);
        $this->assertStringContainsString('Urban Taxi', $taxi['title']);
        $this->assertEquals('HKD', $taxi['currency']);
    }

    public function test_waypoint_guidance_walk_directions_url_encodes_origin_station_and_destination_stay(): void
    {
        $user = User::factory()->create();
        Sanctum::actingAs($user);

        /** @var Trip $trip */
        $trip = Trip::factory()->create(['owner_id' => $user->id]);

        /** @var Stay $stay */
        $stay = Stay::factory()->create([
            'trip_id' => $trip->id,
            'name' => 'Hotel Gracery Shinjuku',
            'address' => '1-19-1 Kabukicho, Shinjuku City, Tokyo',
            'latitude' => 35.6953,
            'longitude' => 139.7022,
        ]);

        $payload = [
            'origin_name' => 'Tokyo Haneda Airport (HND)',
            'party_size' => 1,
            'luggage_preset' => 'standard',
        ];

        $response = $this->postJson("/api/v1/stays/{$stay->id}/transport-options", $payload);

        $response->assertOk();
        $options = collect($response->json('data.options'));

        $rail = $options->firstWhere('mode', 'express_rail');
        $this->assertNotNull($rail);
        $this->assertNotNull($rail['last_mile_directions_url']);

        // Must encode origin as Shinjuku Station (South Exit), destination as coordinates, and travelmode=walking
        $expectedOriginPart = urlencode('Shinjuku Station (South Exit)');
        $this->assertStringContainsString("origin={$expectedOriginPart}", $rail['last_mile_directions_url']);
        $this->assertStringContainsString('destination=35.6953%2C139.7022', $rail['last_mile_directions_url']);
        $this->assertStringContainsString('travelmode=walking', $rail['last_mile_directions_url']);
    }

    public function test_taipei_transit_hub_auto_detection(): void
    {
        $user = User::factory()->create();
        Sanctum::actingAs($user);

        /** @var Trip $trip */
        $trip = Trip::factory()->create([
            'owner_id' => $user->id,
            'title' => 'Taiwan Adventure',
            'destination_country' => 'Taiwan',
        ]);

        /** @var Stay $stay */
        $stay = Stay::factory()->create([
            'trip_id' => $trip->id,
            'name' => 'W Taipei',
            'address' => '10 Zhongxiao East Road Sec. 5, Xinyi District, Taipei',
            'latitude' => 25.0408,
            'longitude' => 121.5670,
        ]);

        $response = $this->postJson("/api/v1/stays/{$stay->id}/transport-options", []);

        $response
            ->assertOk()
            ->assertJsonPath('data.verified', true)
            ->assertJsonPath('data.nearest_transit.nearest_airport_code', 'TPE')
            ->assertJsonPath('data.nearest_transit.has_airport_rail', true);

        $this->assertStringContainsString('Taipei Main Station', (string) $response->json('data.nearest_transit.station_name'));
    }
}
