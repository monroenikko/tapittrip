<?php

declare(strict_types=1);

namespace Tests\Feature;

use App\Models\ItineraryItem;
use App\Models\Trip;
use App\Models\TripDay;
use App\Models\TripMember;
use App\Models\User;
use Illuminate\Foundation\Testing\DatabaseTransactions;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

final class ActivityVotingAndSmartReplanTest extends TestCase
{
    use DatabaseTransactions;

    public function test_circle_members_can_vote_up_down_and_clear_votes_and_removed_member_votes_are_purged(): void
    {
        $owner = User::factory()->create();
        $editor = User::factory()->create();
        $viewer = User::factory()->create();
        $outsider = User::factory()->create();

        /** @var Trip $trip */
        $trip = Trip::factory()->create(['owner_id' => $owner->id]);

        TripMember::query()->create([
            'trip_id' => $trip->id,
            'user_id' => $editor->id,
            'role' => 'editor',
            'invitation_status' => 'accepted',
        ]);
        $viewerMember = TripMember::query()->create([
            'trip_id' => $trip->id,
            'user_id' => $viewer->id,
            'role' => 'viewer',
            'invitation_status' => 'accepted',
        ]);

        /** @var ItineraryItem $item */
        $item = ItineraryItem::query()->create([
            'trip_id' => $trip->id,
            'kind' => 'attraction',
            'title' => 'Tokyo DisneySea Full Day',
            'sort_order' => 0,
            'status' => 'planned',
            'version' => 1,
        ]);

        // 1. Owner votes 'up'
        Sanctum::actingAs($owner);
        $this->postJson("/api/v1/itinerary-items/{$item->id}/vote", ['vote' => 'up'])
            ->assertOk()
            ->assertJsonPath('data.upvotes_count', 1)
            ->assertJsonPath('data.downvotes_count', 0)
            ->assertJsonPath('data.viewer_vote', 'up');

        // 2. Editor votes 'up'
        Sanctum::actingAs($editor);
        $this->postJson("/api/v1/itinerary-items/{$item->id}/vote", ['vote' => 'up'])
            ->assertOk()
            ->assertJsonPath('data.upvotes_count', 2)
            ->assertJsonPath('data.downvotes_count', 0)
            ->assertJsonPath('data.viewer_vote', 'up');

        // 3. Viewer can also vote ('down'), and can switch or clear vote
        Sanctum::actingAs($viewer);
        $this->postJson("/api/v1/itinerary-items/{$item->id}/vote", ['vote' => 'down'])
            ->assertOk()
            ->assertJsonPath('data.upvotes_count', 2)
            ->assertJsonPath('data.downvotes_count', 1)
            ->assertJsonPath('data.viewer_vote', 'down');

        // 4. Editor clears their vote with 'none'
        Sanctum::actingAs($editor);
        $this->postJson("/api/v1/itinerary-items/{$item->id}/vote", ['vote' => 'none'])
            ->assertOk()
            ->assertJsonPath('data.upvotes_count', 1)
            ->assertJsonPath('data.downvotes_count', 1)
            ->assertJsonPath('data.viewer_vote', null);

        // 5. Removing viewer from Trip Circle purges their vote
        Sanctum::actingAs($owner);
        $this->deleteJson("/api/v1/trips/{$trip->id}/members/{$viewerMember->id}")
            ->assertNoContent();

        $this->getJson("/api/v1/itinerary-items/{$item->id}")
            ->assertOk()
            ->assertJsonPath('data.upvotes_count', 1)
            ->assertJsonPath('data.downvotes_count', 0);

        // 6. Outsider is forbidden
        Sanctum::actingAs($outsider);
        $this->postJson("/api/v1/itinerary-items/{$item->id}/vote", ['vote' => 'up'])
            ->assertForbidden();
    }

    public function test_smart_replan_previews_and_applies_adjustments_without_modifying_visited_stops(): void
    {
        $owner = User::factory()->create();
        $viewer = User::factory()->create();

        /** @var Trip $trip */
        $trip = Trip::factory()->create([
            'owner_id' => $owner->id,
            'title' => 'Kyoto Cultural Journey',
            'destination_country' => 'JP',
            'primary_timezone' => 'Asia/Tokyo',
        ]);

        TripMember::query()->create([
            'trip_id' => $trip->id,
            'user_id' => $viewer->id,
            'role' => 'viewer',
            'invitation_status' => 'accepted',
        ]);

        /** @var TripDay $day */
        $day = TripDay::query()->create([
            'trip_id' => $trip->id,
            'local_date' => '2026-07-10',
            'notes' => 'Day 1',
        ]);

        $visitedStop = ItineraryItem::query()->create([
            'trip_id' => $trip->id,
            'trip_day_id' => $day->id,
            'kind' => 'attraction',
            'title' => 'Fushimi Inari Morning Shrine Walk',
            'starts_at_utc' => '2026-07-10T00:00:00Z',
            'ends_at_utc' => '2026-07-10T02:00:00Z',
            'sort_order' => 0,
            'status' => 'visited',
            'version' => 1,
        ]);

        $plannedTimedStop = ItineraryItem::query()->create([
            'trip_id' => $trip->id,
            'trip_day_id' => $day->id,
            'kind' => 'attraction',
            'title' => 'Arashiyama Bamboo Grove',
            'starts_at_utc' => '2026-07-10T05:00:00Z',
            'ends_at_utc' => '2026-07-10T07:00:00Z',
            'sort_order' => 1,
            'status' => 'planned',
            'version' => 1,
        ]);

        // 1. Viewer can preview replanning (apply = false), but cannot apply (apply = true -> 403)
        Sanctum::actingAs($viewer);
        $preview = $this->postJson("/api/v1/trips/{$trip->id}/ai-plan/replan", [
            'trigger_reason' => 'flight_delay',
            'trip_day_id' => $day->id,
            'delay_minutes' => 90,
            'apply' => false,
        ]);

        $preview
            ->assertOk()
            ->assertJsonPath('data.applied', false)
            ->assertJsonPath('data.preserved_visited_count', 1)
            ->assertJsonPath('data.verified', false);

        // Database not mutated during preview
        $this->assertSame('2026-07-10T05:00:00+00:00', $plannedTimedStop->fresh()->starts_at_utc?->toIso8601String());
        $this->assertSame(2, $trip->itineraryItems()->count());

        $this->postJson("/api/v1/trips/{$trip->id}/ai-plan/replan", [
            'trigger_reason' => 'flight_delay',
            'trip_day_id' => $day->id,
            'apply' => true,
        ])->assertForbidden();

        // 2. Owner applies flight_delay replan (+90 min): visited stop stays untouched, planned timed stop shifts by 90 min, and late-arrival supper stop is added
        Sanctum::actingAs($owner);
        $applied = $this->postJson("/api/v1/trips/{$trip->id}/ai-plan/replan", [
            'trigger_reason' => 'flight_delay',
            'trip_day_id' => $day->id,
            'delay_minutes' => 90,
            'apply' => true,
        ]);

        $applied
            ->assertOk()
            ->assertJsonPath('data.applied', true)
            ->assertJsonPath('data.preserved_visited_count', 1);

        // Visited stop was NOT modified
        $this->assertSame('2026-07-10T00:00:00+00:00', $visitedStop->fresh()->starts_at_utc?->toIso8601String());
        $this->assertSame(1, $visitedStop->fresh()->version);

        // Unvisited timed stop shifted forward by 90 minutes (05:00 -> 06:30 UTC) and version incremented
        $this->assertSame('2026-07-10T06:30:00+00:00', $plannedTimedStop->fresh()->starts_at_utc?->toIso8601String());
        $this->assertSame(2, $plannedTimedStop->fresh()->version);
        $this->assertSame(3, $trip->itineraryItems()->count());
    }
}
