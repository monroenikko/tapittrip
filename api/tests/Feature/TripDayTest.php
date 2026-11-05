<?php

declare(strict_types=1);

namespace Tests\Feature;

use App\Domain\Trips\Models\Trip;
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
        $trip = Trip::factory()->create(['owner_id' => $user->id]);

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
            ->assertJsonPath('data.0.local_date', '2026-06-15');
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
