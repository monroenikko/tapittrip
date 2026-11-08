<?php

declare(strict_types=1);

namespace Tests\Feature;

use App\Domain\Itinerary\Models\ItineraryItem;
use App\Domain\Trips\Models\Trip;
use App\Models\User;
use Illuminate\Foundation\Testing\DatabaseTransactions;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

final class VisitEventTest extends TestCase
{
    use DatabaseTransactions;

    public function test_can_record_suggested_visit_event(): void
    {
        $user = User::factory()->create();
        Sanctum::actingAs($user);

        $trip = Trip::factory()->create(['owner_id' => $user->id]);

        $item = ItineraryItem::factory()->create([
            'trip_id' => $trip->id,
            'status' => 'planned',
        ]);

        $response = $this->postJson("/api/v1/itinerary-items/{$item->id}/visit-events", [
            'event_type' => 'suggested',
            'method' => 'geofence',
            'accuracy_m' => 25.4,
        ]);

        $response->assertStatus(201)
            ->assertJsonPath('data.event_type', 'suggested')
            ->assertJsonPath('data.method', 'geofence')
            ->assertJsonPath('data.accuracy_m', 25.4);

        $this->assertDatabaseHas('visit_events', [
            'itinerary_item_id' => $item->id,
            'user_id' => $user->id,
            'event_type' => 'suggested',
            'method' => 'geofence',
        ]);

        // Item remains planned because arrival has not yet been confirmed by traveler
        $item->refresh();
        $this->assertEquals('planned', $item->status);
    }

    public function test_confirming_arrival_marks_item_visited(): void
    {
        $user = User::factory()->create();
        Sanctum::actingAs($user);

        $trip = Trip::factory()->create(['owner_id' => $user->id]);

        $item = ItineraryItem::factory()->create([
            'trip_id' => $trip->id,
            'status' => 'planned',
        ]);

        $response = $this->postJson("/api/v1/itinerary-items/{$item->id}/visit-events", [
            'event_type' => 'confirmed',
            'method' => 'geofence',
            'accuracy_m' => 12.0,
        ]);

        $response->assertStatus(201)
            ->assertJsonPath('data.event_type', 'confirmed');

        $item->refresh();
        $this->assertEquals('visited', $item->status);
    }

    public function test_revoking_arrival_returns_item_to_planned(): void
    {
        $user = User::factory()->create();
        Sanctum::actingAs($user);

        $trip = Trip::factory()->create(['owner_id' => $user->id]);

        $item = ItineraryItem::factory()->create([
            'trip_id' => $trip->id,
            'status' => 'visited',
        ]);

        $response = $this->postJson("/api/v1/itinerary-items/{$item->id}/visit-events", [
            'event_type' => 'revoked',
            'method' => 'manual',
        ]);

        $response->assertStatus(201)
            ->assertJsonPath('data.event_type', 'revoked');

        $item->refresh();
        $this->assertEquals('planned', $item->status);
    }

    public function test_unauthorized_user_cannot_record_visit_events(): void
    {
        $owner = User::factory()->create();
        $stranger = User::factory()->create();

        $trip = Trip::factory()->create(['owner_id' => $owner->id]);

        $item = ItineraryItem::factory()->create([
            'trip_id' => $trip->id,
            'status' => 'planned',
        ]);

        Sanctum::actingAs($stranger);

        $this->postJson("/api/v1/itinerary-items/{$item->id}/visit-events", [
            'event_type' => 'confirmed',
            'method' => 'manual',
        ])->assertStatus(403);
    }
}
