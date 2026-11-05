<?php

declare(strict_types=1);

namespace Tests\Feature;

use App\Domain\Stays\Models\Stay;
use App\Domain\Trips\Models\Trip;
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
            'name' => 'The Kayon Resort Ubud',
            'latitude' => -8.4721,
            'longitude' => 115.2719,
        ]);

        $payload = [
            'origin_name' => 'Ngurah Rai International Airport (DPS)',
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
}
