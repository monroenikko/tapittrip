<?php

declare(strict_types=1);

namespace Tests\Feature;

use App\Models\Trip;
use App\Models\TripMember;
use App\Models\User;
use Illuminate\Foundation\Testing\DatabaseTransactions;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

final class DestinationSafetyTest extends TestCase
{
    use DatabaseTransactions;

    public function test_unauthenticated_requests_are_rejected(): void
    {
        $this->getJson('/api/v1/safety/countries')->assertUnauthorized();
        $this->getJson('/api/v1/safety/countries/JP')->assertUnauthorized();
    }

    public function test_can_list_and_search_curated_country_safety_profiles(): void
    {
        $user = User::factory()->create();
        Sanctum::actingAs($user);

        $this->getJson('/api/v1/safety/countries')
            ->assertOk()
            ->assertJsonStructure([
                'data' => [
                    '*' => [
                        'country_code',
                        'country_name',
                        'flag_emoji',
                        'is_curated',
                        'emergency_numbers' => [
                            'police',
                            'ambulance',
                            'fire',
                            'general_emergency',
                            'tourist_hotline',
                        ],
                        'official_resources',
                        'emergency_phrases',
                        'last_verified_at',
                        'disclaimer',
                    ],
                ],
            ]);

        $filtered = $this->getJson('/api/v1/safety/countries?q=japan')
            ->assertOk()
            ->json('data');

        $this->assertCount(1, $filtered);
        $this->assertSame('JP', $filtered[0]['country_code']);
        $this->assertSame('110', $filtered[0]['emergency_numbers']['police']);
        $this->assertSame('119', $filtered[0]['emergency_numbers']['ambulance']);
    }

    public function test_trip_safety_endpoint_supports_all_four_planning_modes_without_itinerary_and_enforces_membership(): void
    {
        $owner = User::factory()->create();
        $viewer = User::factory()->create();
        $outsider = User::factory()->create();

        foreach (['diy', 'existing', 'guided', 'simple'] as $mode) {
            $trip = Trip::factory()->create([
                'owner_id' => $owner->id,
                'destination_country' => 'Japan',
                'planning_mode' => $mode,
            ]);

            TripMember::factory()->create([
                'trip_id' => $trip->id,
                'user_id' => $viewer->id,
                'role' => 'viewer',
                'invitation_status' => 'accepted',
            ]);

            Sanctum::actingAs($owner);
            $this->getJson("/api/v1/trips/{$trip->id}/safety")
                ->assertOk()
                ->assertJsonPath('data.country_code', 'JP')
                ->assertJsonPath('data.country_name', 'Japan')
                ->assertJsonPath('data.is_curated', true)
                ->assertJsonPath('data.emergency_numbers.police', '110')
                ->assertJsonPath('data.emergency_numbers.ambulance', '119');

            Sanctum::actingAs($viewer);
            $this->getJson("/api/v1/trips/{$trip->id}/safety?country=KR")
                ->assertOk()
                ->assertJsonPath('data.country_code', 'KR')
                ->assertJsonPath('data.emergency_numbers.police', '112');

            Sanctum::actingAs($outsider);
            $this->getJson("/api/v1/trips/{$trip->id}/safety")
                ->assertForbidden();
        }
    }

    public function test_uncurated_country_returns_honest_null_emergency_numbers_without_fabrication(): void
    {
        $user = User::factory()->create();
        Sanctum::actingAs($user);

        $this->getJson('/api/v1/safety/countries/ZZ')
            ->assertOk()
            ->assertJsonPath('data.country_code', 'ZZ')
            ->assertJsonPath('data.is_curated', false)
            ->assertJsonPath('data.emergency_numbers.police', null)
            ->assertJsonPath('data.emergency_numbers.ambulance', null)
            ->assertJsonPath('data.official_resources', []);
    }
}
