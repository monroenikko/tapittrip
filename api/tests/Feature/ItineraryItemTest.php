<?php

declare(strict_types=1);

namespace Tests\Feature;

use App\Domain\Itinerary\Models\ItineraryItem;
use App\Domain\Itinerary\Models\TripDay;
use App\Domain\Trips\Models\Trip;
use App\Models\User;
use Illuminate\Foundation\Testing\DatabaseTransactions;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

final class ItineraryItemTest extends TestCase
{
    use DatabaseTransactions;

    public function test_user_can_create_itinerary_item_with_inline_place(): void
    {
        $user = User::factory()->create();
        Sanctum::actingAs($user);

        /** @var Trip $trip */
        $trip = Trip::factory()->create(['owner_id' => $user->id]);

        $payload = [
            'title' => 'Senso-ji Temple Morning Visit',
            'kind' => 'attraction',
            'notes' => 'Visit early to avoid crowds. Bring coins for omikuji.',
            'starts_at_utc' => '2026-05-10T00:00:00Z',
            'ends_at_utc' => '2026-05-10T02:00:00Z',
            'place' => [
                'name' => 'Senso-ji Temple',
                'formatted_address' => '2 Chome-3-1 Asakusa, Taito City, Tokyo 111-0032',
                'country_code' => 'JP',
                'latitude' => 35.7147,
                'longitude' => 139.7967,
                'provider' => 'manual',
                'attribution' => 'OpenStreetMap',
            ],
        ];

        $response = $this->postJson("/api/v1/trips/{$trip->id}/itinerary-items", $payload);

        $response
            ->assertCreated()
            ->assertJsonPath('data.title', 'Senso-ji Temple Morning Visit')
            ->assertJsonPath('data.kind', 'attraction')
            ->assertJsonPath('data.sort_order', 0)
            ->assertJsonPath('data.status', 'planned')
            ->assertJsonPath('data.version', 1)
            ->assertJsonPath('data.place.name', 'Senso-ji Temple')
            ->assertJsonPath('data.place.country_code', 'JP');

        $this->assertDatabaseHas('itinerary_items', [
            'trip_id' => $trip->id,
            'title' => 'Senso-ji Temple Morning Visit',
        ]);

        $this->assertDatabaseHas('places', [
            'name' => 'Senso-ji Temple',
            'country_code' => 'JP',
        ]);
    }

    public function test_creating_multiple_items_increments_sort_order_automatically(): void
    {
        $user = User::factory()->create();
        Sanctum::actingAs($user);

        /** @var Trip $trip */
        $trip = Trip::factory()->create(['owner_id' => $user->id]);

        $this->postJson("/api/v1/trips/{$trip->id}/itinerary-items", [
            'title' => 'Stop 1: Arrival & Coffee',
        ])->assertCreated()->assertJsonPath('data.sort_order', 0);

        $this->postJson("/api/v1/trips/{$trip->id}/itinerary-items", [
            'title' => 'Stop 2: Museum Visit',
        ])->assertCreated()->assertJsonPath('data.sort_order', 1);

        $this->postJson("/api/v1/trips/{$trip->id}/itinerary-items", [
            'title' => 'Stop 3: Traditional Dinner',
        ])->assertCreated()->assertJsonPath('data.sort_order', 2);
    }

    public function test_user_can_update_itinerary_item_and_version_increments(): void
    {
        $user = User::factory()->create();
        Sanctum::actingAs($user);

        /** @var Trip $trip */
        $trip = Trip::factory()->create(['owner_id' => $user->id]);

        /** @var ItineraryItem $item */
        $item = ItineraryItem::factory()->create([
            'trip_id' => $trip->id,
            'title' => 'Old Title',
            'status' => 'planned',
            'version' => 1,
        ]);

        $response = $this->patchJson("/api/v1/itinerary-items/{$item->id}", [
            'title' => 'Updated Exciting Activity',
            'status' => 'visited',
            'notes' => 'Completed ahead of schedule.',
        ]);

        $response
            ->assertOk()
            ->assertJsonPath('data.title', 'Updated Exciting Activity')
            ->assertJsonPath('data.status', 'visited')
            ->assertJsonPath('data.version', 2);

        $this->assertDatabaseHas('itinerary_items', [
            'id' => $item->id,
            'title' => 'Updated Exciting Activity',
            'status' => 'visited',
            'version' => 2,
        ]);
    }

    public function test_user_can_reorder_three_stops(): void
    {
        $user = User::factory()->create();
        Sanctum::actingAs($user);

        /** @var Trip $trip */
        $trip = Trip::factory()->create(['owner_id' => $user->id]);

        $itemA = ItineraryItem::factory()->create(['trip_id' => $trip->id, 'title' => 'Stop A', 'sort_order' => 0]);
        $itemB = ItineraryItem::factory()->create(['trip_id' => $trip->id, 'title' => 'Stop B', 'sort_order' => 1]);
        $itemC = ItineraryItem::factory()->create(['trip_id' => $trip->id, 'title' => 'Stop C', 'sort_order' => 2]);

        // Reorder to C, A, B
        $response = $this->postJson("/api/v1/trips/{$trip->id}/itinerary-items/reorder", [
            'item_ids' => [$itemC->id, $itemA->id, $itemB->id],
        ]);

        $response->assertOk();

        $this->assertDatabaseHas('itinerary_items', ['id' => $itemC->id, 'sort_order' => 0]);
        $this->assertDatabaseHas('itinerary_items', ['id' => $itemA->id, 'sort_order' => 1]);
        $this->assertDatabaseHas('itinerary_items', ['id' => $itemB->id, 'sort_order' => 2]);
    }

    public function test_user_can_soft_delete_itinerary_item(): void
    {
        $user = User::factory()->create();
        Sanctum::actingAs($user);

        /** @var Trip $trip */
        $trip = Trip::factory()->create(['owner_id' => $user->id]);

        /** @var ItineraryItem $item */
        $item = ItineraryItem::factory()->create(['trip_id' => $trip->id]);

        $response = $this->deleteJson("/api/v1/itinerary-items/{$item->id}");
        $response->assertNoContent();

        $this->assertSoftDeleted('itinerary_items', ['id' => $item->id]);
    }

    public function test_non_trip_member_cannot_view_or_modify_itinerary_items(): void
    {
        $owner = User::factory()->create();
        $stranger = User::factory()->create();

        /** @var Trip $trip */
        $trip = Trip::factory()->create(['owner_id' => $owner->id]);

        /** @var ItineraryItem $item */
        $item = ItineraryItem::factory()->create(['trip_id' => $trip->id]);

        Sanctum::actingAs($stranger);

        $this->getJson("/api/v1/trips/{$trip->id}/itinerary-items")->assertForbidden();
        $this->postJson("/api/v1/trips/{$trip->id}/itinerary-items", ['title' => 'Hacked Stop'])->assertForbidden();
        $this->getJson("/api/v1/itinerary-items/{$item->id}")->assertForbidden();
        $this->patchJson("/api/v1/itinerary-items/{$item->id}", ['title' => 'Defaced'])->assertForbidden();
        $this->deleteJson("/api/v1/itinerary-items/{$item->id}")->assertForbidden();
    }

    public function test_filtering_items_by_trip_day(): void
    {
        $user = User::factory()->create();
        Sanctum::actingAs($user);

        /** @var Trip $trip */
        $trip = Trip::factory()->create(['owner_id' => $user->id]);

        $day1 = TripDay::factory()->create(['trip_id' => $trip->id, 'local_date' => '2026-05-10']);
        $day2 = TripDay::factory()->create(['trip_id' => $trip->id, 'local_date' => '2026-05-11']);

        $itemDay1 = ItineraryItem::factory()->create(['trip_id' => $trip->id, 'trip_day_id' => $day1->id, 'title' => 'Day 1 Item']);
        $itemDay2 = ItineraryItem::factory()->create(['trip_id' => $trip->id, 'trip_day_id' => $day2->id, 'title' => 'Day 2 Item']);

        $response = $this->getJson("/api/v1/trips/{$trip->id}/itinerary-items?trip_day_id={$day1->id}");

        $response
            ->assertOk()
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.id', $itemDay1->id);
    }

    public function test_user_can_create_itinerary_item_with_kind_aliases_normalized(): void
    {
        $user = User::factory()->create();
        Sanctum::actingAs($user);

        /** @var Trip $trip */
        $trip = Trip::factory()->create(['owner_id' => $user->id]);

        $payload = [
            'title' => 'Bonifacio High Street Walk',
            'kind' => 'sightseeing',
        ];

        $response = $this->postJson("/api/v1/trips/{$trip->id}/itinerary-items", $payload);

        $response
            ->assertCreated()
            ->assertJsonPath('data.kind', 'attraction');

        $dinnerPayload = [
            'title' => 'Dinner at Wildflour',
            'kind' => 'dining',
        ];

        $dinnerResponse = $this->postJson("/api/v1/trips/{$trip->id}/itinerary-items", $dinnerPayload);

        $dinnerResponse
            ->assertCreated()
            ->assertJsonPath('data.kind', 'meal');
    }

    public function test_ai_suggested_activities_with_arbitrary_kinds_and_places_succeed(): void
    {
        $user = User::factory()->create();
        Sanctum::actingAs($user);

        /** @var Trip $trip */
        $trip = Trip::factory()->create(['owner_id' => $user->id]);

        // Museum (arbitrary kind -> attraction), place with address instead of formatted_address
        $payload = [
            'title' => 'Explore The Mind Museum',
            'kind' => 'museum',
            'place' => [
                'name' => 'The Mind Museum',
                'address' => 'JY Campos Park, 3rd Ave, BGC, Taguig',
            ],
            'notes' => 'Interactive science exhibitions.',
        ];

        $response = $this->postJson("/api/v1/trips/{$trip->id}/itinerary-items", $payload);

        $response
            ->assertCreated()
            ->assertJsonPath('data.title', 'Explore The Mind Museum')
            ->assertJsonPath('data.kind', 'attraction')
            ->assertJsonPath('data.place.name', 'The Mind Museum')
            ->assertJsonPath('data.place.formatted_address', 'JY Campos Park, 3rd Ave, BGC, Taguig');

        // Coffee / Bakery (mapped to meal)
        $cafeResponse = $this->postJson("/api/v1/trips/{$trip->id}/itinerary-items", [
            'title' => 'Morning Coffee at % Arabica',
            'kind' => 'coffee & pastries',
            'place' => [
                'name' => '% Arabica Manila BGC',
            ],
        ]);

        $cafeResponse
            ->assertCreated()
            ->assertJsonPath('data.kind', 'meal');

        // Empty place name safely converts to null place rather than 422 failure
        $emptyPlaceResponse = $this->postJson("/api/v1/trips/{$trip->id}/itinerary-items", [
            'title' => 'Quiet Stroll & Toddler Recharge',
            'kind' => 'relaxation',
            'place' => [
                'name' => '',
            ],
        ]);

        $emptyPlaceResponse
            ->assertCreated()
            ->assertJsonPath('data.title', 'Quiet Stroll & Toddler Recharge')
            ->assertJsonPath('data.kind', 'attraction')
            ->assertJsonPath('data.place', null);
    }
}
