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

final class AiItineraryTest extends TestCase
{
    use DatabaseTransactions;

    public function test_user_can_generate_ai_itinerary_suggestion(): void
    {
        $user = User::factory()->create();
        Sanctum::actingAs($user);

        $trip = Trip::factory()->create([
            'owner_id' => $user->id,
            'destination_country' => 'JP',
        ]);

        $response = $this->postJson("/api/v1/trips/{$trip->id}/ai-plan/generate", [
            'destination' => 'Tokyo, Japan',
            'duration_days' => 3,
            'budget_tier' => 'moderate',
            'travel_party' => 'family_kids',
            'pace' => 'balanced',
            'interests' => ['food', 'culture', 'nature'],
        ]);

        $response->assertStatus(200)
            ->assertJsonPath('data.destination', 'Tokyo, Japan')
            ->assertJsonPath('data.travel_party', 'family_kids')
            ->assertJsonCount(3, 'data.days')
            ->assertJsonPath('data.days.0.primary_neighborhood', 'Asakusa & Ueno')
            ->assertJsonPath('data.days.1.primary_neighborhood', 'Shibuya & Harajuku');

        $this->assertNotEmpty($response->json('data.days.0.activities'));
    }

    public function test_ai_generation_is_strictly_non_destructive(): void
    {
        $user = User::factory()->create();
        Sanctum::actingAs($user);

        $trip = Trip::factory()->create([
            'owner_id' => $user->id,
            'destination_country' => 'JP',
        ]);

        $initialDayCount = TripDay::where('trip_id', $trip->id)->count();
        $initialItemCount = ItineraryItem::where('trip_id', $trip->id)->count();

        $response = $this->postJson("/api/v1/trips/{$trip->id}/ai-plan/generate", [
            'destination' => 'Tokyo, Japan',
            'duration_days' => 4,
            'budget_tier' => 'moderate',
            'pace' => 'balanced',
        ]);

        $response->assertStatus(200);

        // Invariant: suggestions must not alter persistent trip data before approval
        $this->assertSame($initialDayCount, TripDay::where('trip_id', $trip->id)->count());
        $this->assertSame($initialItemCount, ItineraryItem::where('trip_id', $trip->id)->count());
    }

    public function test_user_can_apply_approved_ai_itinerary_days(): void
    {
        $user = User::factory()->create();
        Sanctum::actingAs($user);

        $trip = Trip::factory()->create([
            'owner_id' => $user->id,
            'destination_country' => 'JP',
            'start_date' => '2026-12-01',
            'version' => 1,
        ]);

        $approvedPlan = [
            'days' => [
                [
                    'day_number' => 1,
                    'title' => 'Day 1: Historic Asakusa',
                    'activities' => [
                        [
                            'title' => 'Senso-ji Temple',
                            'kind' => 'sightseeing',
                            'description' => 'Morning temple visit',
                            'place_name' => 'Senso-ji Temple',
                            'place_address' => '2 Chome-3-1 Asakusa, Taito City, Tokyo',
                            'planned_start_time' => '09:30',
                            'planned_end_time' => '11:00',
                        ],
                        [
                            'title' => 'Asakusa Soba Lunch',
                            'kind' => 'dining',
                            'description' => 'Local noodle lunch',
                            'place_name' => 'Namiki Yabusoba',
                            'place_address' => '2-11-9 Kaminarimon, Taito City, Tokyo',
                            'planned_start_time' => '12:00',
                            'planned_end_time' => '13:00',
                        ],
                    ],
                ],
            ],
        ];

        $response = $this->postJson("/api/v1/trips/{$trip->id}/ai-plan/apply", $approvedPlan);

        $response->assertStatus(200)
            ->assertJsonCount(2, 'data')
            ->assertJsonPath('data.0.title', 'Senso-ji Temple')
            ->assertJsonPath('data.1.title', 'Asakusa Soba Lunch');

        $this->assertDatabaseHas('trip_days', [
            'trip_id' => $trip->id,
            'local_date' => '2026-12-01',
        ]);

        $this->assertDatabaseHas('itinerary_items', [
            'trip_id' => $trip->id,
            'title' => 'Senso-ji Temple',
            'kind' => 'sightseeing',
        ]);

        $trip->refresh();
        $this->assertSame(2, $trip->version);
    }

    public function test_unauthorized_user_cannot_generate_or_apply_ai_plan(): void
    {
        $owner = User::factory()->create();
        $attacker = User::factory()->create();

        $trip = Trip::factory()->create([
            'owner_id' => $owner->id,
        ]);

        Sanctum::actingAs($attacker);

        $this->postJson("/api/v1/trips/{$trip->id}/ai-plan/generate", [
            'destination' => 'Kyoto',
            'duration_days' => 2,
        ])->assertStatus(403);

        $this->postJson("/api/v1/trips/{$trip->id}/ai-plan/apply", [
            'days' => [
                [
                    'day_number' => 1,
                    'activities' => [
                        ['title' => 'Malicious Activity'],
                    ],
                ],
            ],
        ])->assertStatus(403);
    }
}
