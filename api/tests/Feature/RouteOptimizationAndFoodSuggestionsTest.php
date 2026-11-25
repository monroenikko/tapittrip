<?php

declare(strict_types=1);

namespace Tests\Feature;

use App\Models\ItineraryItem;
use App\Models\Place;
use App\Models\Stay;
use App\Models\Trip;
use App\Models\TripDay;
use App\Models\TripMember;
use App\Models\User;
use Illuminate\Foundation\Testing\DatabaseTransactions;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

final class RouteOptimizationAndFoodSuggestionsTest extends TestCase
{
    use DatabaseTransactions;

    public function test_route_optimization_preview_reduces_backtracking_respects_fixed_time_constraints_and_does_not_mutate_until_applied(): void
    {
        $owner = User::factory()->create();
        Sanctum::actingAs($owner);

        /** @var Trip $trip */
        $trip = Trip::factory()->create([
            'owner_id' => $owner->id,
            'title' => 'Tokyo Explorer',
            'destination_country' => 'JP',
        ]);

        /** @var TripDay $day */
        $day = TripDay::query()->create([
            'trip_id' => $trip->id,
            'local_date' => '2026-06-01',
            'notes' => 'Day 1',
        ]);

        // Stay in Asakusa (35.7110, 139.7960)
        Stay::query()->create([
            'trip_id' => $trip->id,
            'name' => 'Asakusa View Hotel',
            'stay_type' => 'hotel',
            'latitude' => 35.7110,
            'longitude' => 139.7960,
            'timezone' => 'Asia/Tokyo',
        ]);

        // Stop 0 (current sort 0): Shibuya Crossing (far west: 35.6595, 139.7004) — flexible
        $shibuyaPlace = Place::query()->create([
            'name' => 'Shibuya Sky',
            'provider' => 'manual',
            'latitude' => 35.6595,
            'longitude' => 139.7004,
            'country_code' => 'JP',
        ]);
        $itemShibuya = ItineraryItem::query()->create([
            'trip_id' => $trip->id,
            'trip_day_id' => $day->id,
            'place_id' => $shibuyaPlace->id,
            'kind' => 'attraction',
            'title' => 'Shibuya Sky Observation',
            'sort_order' => 0,
            'status' => 'planned',
            'version' => 1,
        ]);

        // Stop 1 (current sort 1): Senso-ji Temple (right next to Asakusa stay: 35.7147, 139.7967) — flexible
        $sensojiPlace = Place::query()->create([
            'name' => 'Senso-ji Temple',
            'provider' => 'manual',
            'latitude' => 35.7147,
            'longitude' => 139.7967,
            'country_code' => 'JP',
        ]);
        $itemSensoji = ItineraryItem::query()->create([
            'trip_id' => $trip->id,
            'trip_day_id' => $day->id,
            'place_id' => $sensojiPlace->id,
            'kind' => 'attraction',
            'title' => 'Senso-ji Temple Walk',
            'sort_order' => 1,
            'status' => 'planned',
            'version' => 1,
        ]);

        // Stop 2 (current sort 2): Fixed evening dinner reservation in Shinjuku (35.6938, 139.7034) — pinned via starts_at_utc
        $shinjukuPlace = Place::query()->create([
            'name' => 'Shinjuku Omoide Yokocho',
            'provider' => 'manual',
            'latitude' => 35.6938,
            'longitude' => 139.7034,
            'country_code' => 'JP',
        ]);
        $itemDinner = ItineraryItem::query()->create([
            'trip_id' => $trip->id,
            'trip_day_id' => $day->id,
            'place_id' => $shinjukuPlace->id,
            'kind' => 'meal',
            'title' => 'Reserved Shinjuku Dinner',
            'starts_at_utc' => '2026-06-01T10:00:00Z',
            'sort_order' => 2,
            'status' => 'planned',
            'version' => 1,
        ]);

        // 1. Preview mode (apply = false)
        $previewResponse = $this->postJson("/api/v1/trips/{$trip->id}/itinerary-items/optimize-route", [
            'trip_day_id' => $day->id,
            'apply' => false,
            'preserve_fixed_times' => true,
            'max_walking_meters_per_leg' => 1500,
        ]);

        $previewResponse
            ->assertOk()
            ->assertJsonPath('data.applied', false)
            ->assertJsonPath('data.is_already_optimal', false)
            ->assertJsonPath('data.proposed_item_ids.0', $itemSensoji->id)
            ->assertJsonPath('data.proposed_item_ids.1', $itemShibuya->id)
            ->assertJsonPath('data.proposed_item_ids.2', $itemDinner->id)
            ->assertJsonPath('data.pinned_item_ids.0', $itemDinner->id)
            ->assertJsonPath('data.verified', false);

        $this->assertGreaterThan(
            (float) $previewResponse->json('data.optimized_total_distance_km'),
            (float) $previewResponse->json('data.current_total_distance_km'),
        );
        $this->assertGreaterThan(0.0, (float) $previewResponse->json('data.distance_saved_km'));
        $this->assertCount(2, $previewResponse->json('data.segments'));
        $this->assertCount(3, $previewResponse->json('data.segments.0.mode_comparisons'));

        // Verify database sort_order was NOT mutated during preview
        $this->assertSame(0, $itemShibuya->fresh()->sort_order);
        $this->assertSame(1, $itemSensoji->fresh()->sort_order);

        // 2. Apply mode (apply = true) updates sort_order and increments version
        $applyResponse = $this->postJson("/api/v1/trips/{$trip->id}/itinerary-items/optimize-route", [
            'trip_day_id' => $day->id,
            'apply' => true,
            'preserve_fixed_times' => true,
            'expected_versions' => [
                $itemShibuya->id => 1,
                $itemSensoji->id => 1,
                $itemDinner->id => 1,
            ],
        ]);

        $applyResponse
            ->assertOk()
            ->assertJsonPath('data.applied', true);

        $this->assertSame(0, $itemSensoji->fresh()->sort_order);
        $this->assertSame(1, $itemShibuya->fresh()->sort_order);
        $this->assertSame(2, $itemDinner->fresh()->sort_order);
        $this->assertSame(2, $itemSensoji->fresh()->version);
    }

    public function test_route_optimization_handles_unknown_coordinates_and_enforces_viewer_permissions(): void
    {
        $owner = User::factory()->create();
        $viewer = User::factory()->create();
        $outsider = User::factory()->create();

        /** @var Trip $trip */
        $trip = Trip::factory()->create(['owner_id' => $owner->id]);

        TripMember::query()->create([
            'trip_id' => $trip->id,
            'user_id' => $viewer->id,
            'role' => 'viewer',
            'invitation_status' => 'accepted',
        ]);

        ItineraryItem::query()->create([
            'trip_id' => $trip->id,
            'kind' => 'attraction',
            'title' => 'Ungeocoded Stop A',
            'sort_order' => 0,
            'status' => 'planned',
            'version' => 1,
        ]);
        ItineraryItem::query()->create([
            'trip_id' => $trip->id,
            'kind' => 'attraction',
            'title' => 'Ungeocoded Stop B',
            'sort_order' => 1,
            'status' => 'planned',
            'version' => 1,
        ]);

        // Viewer can preview transit segments & route optimization
        Sanctum::actingAs($viewer);
        $preview = $this->postJson("/api/v1/trips/{$trip->id}/itinerary-items/optimize-route", [
            'apply' => false,
        ]);

        $preview
            ->assertOk()
            ->assertJsonPath('data.segments.0.recommended_mode', 'unknown_coordinates')
            ->assertJsonPath('data.segments.0.distance_meters', null)
            ->assertJsonPath('data.segments.0.mode_comparisons.0.estimated_duration_minutes', null);

        // Viewer cannot apply route reorder mutation
        $this->postJson("/api/v1/trips/{$trip->id}/itinerary-items/optimize-route", [
            'apply' => true,
        ])->assertForbidden();

        // Non-member is denied
        Sanctum::actingAs($outsider);
        $this->postJson("/api/v1/trips/{$trip->id}/itinerary-items/optimize-route", [
            'apply' => false,
        ])->assertForbidden();
    }

    public function test_food_suggestions_returns_destination_and_stay_aware_restaurants_filters_and_deduplicates_planned_meals(): void
    {
        $owner = User::factory()->create();
        $outsider = User::factory()->create();

        /** @var Trip $trip */
        $trip = Trip::factory()->create([
            'owner_id' => $owner->id,
            'title' => 'Tokyo Family Adventure',
            'destination_country' => 'JP',
        ]);

        Stay::query()->create([
            'trip_id' => $trip->id,
            'name' => 'Shinjuku Prince Hotel',
            'stay_type' => 'friends_family',
            'address' => '1-30-1 Kabukicho, Private Host Apt 902',
            'timezone' => 'Asia/Tokyo',
        ]);

        Sanctum::actingAs($owner);

        // 1. Full list includes breakfast, lunch, dinner, cafe with stay proximity label, never leaking private address
        $allResponse = $this->getJson("/api/v1/trips/{$trip->id}/food-suggestions");
        $allResponse
            ->assertOk()
            ->assertJsonPath('data.trip_id', $trip->id)
            ->assertJsonPath('data.anchor_stay_name', 'Shinjuku Prince Hotel')
            ->assertJsonPath('data.verified', false);

        $suggestions = $allResponse->json('data.suggestions');
        $this->assertCount(4, $suggestions);
        $this->assertSame('5–10 min walk from Shinjuku Prince Hotel', $suggestions[0]['proximity_label']);
        $this->assertStringNotContainsString('Apt 902', json_encode($suggestions));

        // 2. Filter by meal_type=dinner and dietary=halal
        $dinnerResponse = $this->getJson("/api/v1/trips/{$trip->id}/food-suggestions?meal_type=dinner&dietary=halal");
        $dinnerResponse->assertOk();
        $dinnerSuggestions = $dinnerResponse->json('data.suggestions');
        $this->assertCount(1, $dinnerSuggestions);
        $this->assertSame('dinner', $dinnerSuggestions[0]['meal_type']);

        // 3. Deduplicates once a meal is added to the trip's itinerary
        ItineraryItem::query()->create([
            'trip_id' => $trip->id,
            'kind' => 'meal',
            'title' => $dinnerSuggestions[0]['suggested_action']['payload']['title'],
            'sort_order' => 0,
            'status' => 'planned',
            'version' => 1,
        ]);

        $afterAddResponse = $this->getJson("/api/v1/trips/{$trip->id}/food-suggestions?meal_type=dinner");
        $afterAddResponse->assertOk();
        $this->assertCount(0, $afterAddResponse->json('data.suggestions'));

        // 4. Non-member receives 403 Forbidden
        Sanctum::actingAs($outsider);
        $this->getJson("/api/v1/trips/{$trip->id}/food-suggestions")->assertForbidden();
    }
}
