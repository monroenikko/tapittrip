<?php

declare(strict_types=1);

namespace Tests\Feature;

use App\Models\Trip;
use App\Models\User;
use Illuminate\Foundation\Testing\DatabaseTransactions;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

final class TripDayTest extends TestCase
{
    use DatabaseTransactions;

    public function test_user_can_list_and_create_trip_days(): void
    {
        $user = User::factory()->create();
        Sanctum::actingAs($user);

        /** @var Trip $trip */
        $trip = Trip::factory()->create([
            'owner_id' => $user->id,
            'start_date' => '2026-06-15',
            'end_date' => '2026-06-15',
        ]);

        $response = $this->postJson("/api/v1/trips/{$trip->id}/days", [
            'local_date' => '2026-06-15',
            'notes' => 'Arrival in Kyoto, check into Ryokan',
        ]);

        $response
            ->assertCreated()
            ->assertJsonPath('data.local_date', '2026-06-15')
            ->assertJsonPath('data.notes', 'Arrival in Kyoto, check into Ryokan');

        $this->assertDatabaseHas('trip_days', [
            'trip_id' => $trip->id,
            'local_date' => '2026-06-15',
        ]);

        $listResponse = $this->getJson("/api/v1/trips/{$trip->id}/days");
        $listResponse
            ->assertOk()
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.local_date', '2026-06-15')
            ->assertJsonPath('data.0.day_number', 1);
    }

    public function test_trip_days_are_auto_populated_from_start_date_to_end_date(): void
    {
        $user = User::factory()->create();
        Sanctum::actingAs($user);

        // Create trip with 4 days: Nov 1 to Nov 4
        $response = $this->postJson('/api/v1/trips', [
            'title' => 'Autumn in Tokyo',
            'destination_country' => 'JP',
            'origin_country' => 'PH',
            'start_date' => '2026-11-01',
            'end_date' => '2026-11-04',
            'primary_timezone' => 'Asia/Tokyo',
            'trip_type' => 'leisure',
            'planning_mode' => 'diy',
        ]);

        $response->assertCreated();
        $tripId = $response->json('data.id');

        $listResponse = $this->getJson("/api/v1/trips/{$tripId}/days");
        $listResponse
            ->assertOk()
            ->assertJsonCount(4, 'data')
            ->assertJsonPath('data.0.day_number', 1)
            ->assertJsonPath('data.0.local_date', '2026-11-01')
            ->assertJsonPath('data.0.title', 'Day 1')
            ->assertJsonPath('data.3.day_number', 4)
            ->assertJsonPath('data.3.local_date', '2026-11-04')
            ->assertJsonPath('data.3.title', 'Day 4');
    }

    public function test_updating_trip_end_date_auto_populates_extended_days(): void
    {
        $user = User::factory()->create();
        Sanctum::actingAs($user);

        /** @var Trip $trip */
        $trip = Trip::factory()->create([
            'owner_id' => $user->id,
            'start_date' => '2026-11-01',
            'end_date' => '2026-11-02',
        ]);

        // Extend end date to Nov 4 (from 2 days to 4 days)
        $updateResponse = $this->patchJson("/api/v1/trips/{$trip->id}", [
            'end_date' => '2026-11-04',
        ]);
        $updateResponse->assertOk();

        $listResponse = $this->getJson("/api/v1/trips/{$trip->id}/days");
        $listResponse
            ->assertOk()
            ->assertJsonCount(4, 'data')
            ->assertJsonPath('data.3.day_number', 4)
            ->assertJsonPath('data.3.local_date', '2026-11-04');
    }

    public function test_non_member_cannot_access_trip_days(): void
    {
        $owner = User::factory()->create();
        $stranger = User::factory()->create();

        /** @var Trip $trip */
        $trip = Trip::factory()->create(['owner_id' => $owner->id]);

        Sanctum::actingAs($stranger);

        $this->getJson("/api/v1/trips/{$trip->id}/days")->assertForbidden();
        $this->postJson("/api/v1/trips/{$trip->id}/days", ['local_date' => '2026-06-15'])->assertForbidden();
    }
}
