<?php

declare(strict_types=1);

namespace Tests\Feature;

use App\Domain\Itinerary\Models\ItineraryItem;
use App\Domain\Itinerary\Models\TripDay;
use App\Domain\Stays\Models\Stay;
use App\Domain\Trips\Models\Trip;
use App\Models\User;
use Carbon\Carbon;
use Illuminate\Foundation\Testing\DatabaseTransactions;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

final class TripTodayTest extends TestCase
{
    use DatabaseTransactions;

    public function test_active_trip_returns_today_summary_with_day_progress_and_stay(): void
    {
        $user = User::factory()->create();
        Sanctum::actingAs($user);

        $today = Carbon::now('Asia/Tokyo')->toDateString();
        $startDate = Carbon::now('Asia/Tokyo')->subDays(2)->toDateString();
        $endDate = Carbon::now('Asia/Tokyo')->addDays(2)->toDateString();

        $trip = Trip::factory()->create([
            'owner_id' => $user->id,
            'title' => 'Tokyo Live Exploration',
            'start_date' => $startDate,
            'end_date' => $endDate,
            'primary_timezone' => 'Asia/Tokyo',
        ]);

        $tripDay = TripDay::factory()->create([
            'trip_id' => $trip->id,
            'local_date' => $today,
            'notes' => 'Shibuya & Harajuku',
        ]);

        $item1 = ItineraryItem::factory()->create([
            'trip_id' => $trip->id,
            'trip_day_id' => $tripDay->id,
            'title' => 'Shibuya Crossing Photo Stop',
            'status' => 'visited',
            'sort_order' => 0,
        ]);

        $item2 = ItineraryItem::factory()->create([
            'trip_id' => $trip->id,
            'trip_day_id' => $tripDay->id,
            'title' => 'Meiji Shrine Morning Walk',
            'status' => 'planned',
            'sort_order' => 1,
        ]);

        Stay::factory()->create([
            'trip_id' => $trip->id,
            'name' => 'Shinjuku Granbell Hotel',
            'check_in_at' => Carbon::now('Asia/Tokyo')->subDays(2)->setTime(15, 0),
            'check_out_at' => Carbon::now('Asia/Tokyo')->addDays(3)->setTime(11, 0),
            'timezone' => 'Asia/Tokyo',
        ]);

        $response = $this->getJson("/api/v1/trips/{$trip->id}/today");

        $response->assertOk()
            ->assertJsonPath('data.trip.title', 'Tokyo Live Exploration')
            ->assertJsonPath('data.trip_status', 'active')
            ->assertJsonPath('data.active_day.day_number', 3)
            ->assertJsonPath('data.active_day.total_days', 5)
            ->assertJsonPath('data.active_day.date', $today)
            ->assertJsonPath('data.active_day.notes', 'Shibuya & Harajuku')
            ->assertJsonPath('data.current_stay.name', 'Shinjuku Granbell Hotel')
            ->assertJsonPath('data.next_upcoming_item.id', $item2->id)
            ->assertJsonPath('data.next_upcoming_item.title', 'Meiji Shrine Morning Walk')
            ->assertJsonPath('data.metrics.total_activities', 2)
            ->assertJsonPath('data.metrics.completed_activities', 1)
            ->assertJsonPath('data.metrics.progress_percentage', 50)
            ->assertJsonCount(2, 'data.today_items');
    }

    public function test_pre_trip_returns_countdown_and_upcoming_stay(): void
    {
        $user = User::factory()->create();
        Sanctum::actingAs($user);

        $startDate = Carbon::now('UTC')->addDays(5)->toDateString();
        $endDate = Carbon::now('UTC')->addDays(10)->toDateString();

        $trip = Trip::factory()->create([
            'owner_id' => $user->id,
            'title' => 'Upcoming Bali Adventure',
            'start_date' => $startDate,
            'end_date' => $endDate,
            'primary_timezone' => 'UTC',
        ]);

        Stay::factory()->create([
            'trip_id' => $trip->id,
            'name' => 'Kayon Resort Ubud',
            'check_in_at' => Carbon::parse($startDate)->setTime(15, 0),
            'check_out_at' => Carbon::parse($endDate)->setTime(11, 0),
        ]);

        $response = $this->getJson("/api/v1/trips/{$trip->id}/today");

        $response->assertOk()
            ->assertJsonPath('data.trip_status', 'pre_trip')
            ->assertJsonPath('data.days_until_start', 5)
            ->assertJsonPath('data.active_day', null)
            ->assertJsonPath('data.current_stay.name', 'Kayon Resort Ubud')
            ->assertJsonCount(0, 'data.today_items');
    }

    public function test_trip_with_no_itinerary_items_returns_zero_metrics_without_error(): void
    {
        $user = User::factory()->create();
        Sanctum::actingAs($user);

        $today = Carbon::now('UTC')->toDateString();

        $trip = Trip::factory()->create([
            'owner_id' => $user->id,
            'title' => 'Minimal Stays Only Trip',
            'start_date' => $today,
            'end_date' => Carbon::now('UTC')->addDays(3)->toDateString(),
            'primary_timezone' => 'UTC',
            'planning_mode' => 'existing',
        ]);

        $response = $this->getJson("/api/v1/trips/{$trip->id}/today");

        $response->assertOk()
            ->assertJsonPath('data.trip_status', 'active')
            ->assertJsonPath('data.metrics.total_activities', 0)
            ->assertJsonPath('data.metrics.completed_activities', 0)
            ->assertJsonPath('data.metrics.progress_percentage', 0)
            ->assertJsonPath('data.next_upcoming_item', null)
            ->assertJsonCount(0, 'data.today_items');
    }

    public function test_non_trip_member_cannot_view_today_dashboard(): void
    {
        $owner = User::factory()->create();
        $stranger = User::factory()->create();
        Sanctum::actingAs($stranger);

        $trip = Trip::factory()->create([
            'owner_id' => $owner->id,
            'title' => 'Private Trip',
        ]);

        $response = $this->getJson("/api/v1/trips/{$trip->id}/today");

        $response->assertForbidden();
    }
}
