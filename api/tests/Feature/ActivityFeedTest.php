<?php

declare(strict_types=1);

namespace Tests\Feature;

use App\Models\ActivityEvent;
use App\Models\Trip;
use App\Models\TripMember;
use App\Models\User;
use Carbon\CarbonImmutable;
use Illuminate\Foundation\Testing\DatabaseTransactions;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

final class ActivityFeedTest extends TestCase
{
    use DatabaseTransactions;

    public function test_trip_member_can_view_activity_feed_with_actor_and_metadata(): void
    {
        $owner = User::factory()->create(['name' => 'Alice']);
        $companion = User::factory()->create(['name' => 'Bob']);
        $trip = Trip::factory()->create(['owner_id' => $owner->id]);

        TripMember::factory()->create([
            'trip_id' => $trip->id,
            'user_id' => $companion->id,
            'role' => 'editor',
        ]);

        ActivityEvent::factory()->create([
            'trip_id' => $trip->id,
            'actor_id' => $owner->id,
            'event_type' => 'moment_shared',
            'title' => 'Senso-ji Temple Morning',
            'summary' => 'Early walk through the historic temple grounds.',
            'entity_type' => 'journal_entry',
            'entity_id' => '00000000-0000-0000-0000-000000000001',
            'metadata' => [
                'mood' => 'peaceful',
                'photos' => ['https://example.com/sensoji.jpg'],
            ],
            'occurred_at' => now(),
        ]);

        Sanctum::actingAs($companion);

        $response = $this->getJson("/api/v1/trips/{$trip->id}/feed");

        $response
            ->assertOk()
            ->assertJsonPath('data.0.title', 'Senso-ji Temple Morning')
            ->assertJsonPath('data.0.event_type', 'moment_shared')
            ->assertJsonPath('data.0.actor.name', 'Alice')
            ->assertJsonPath('data.0.metadata.mood', 'peaceful')
            ->assertJsonPath('data.0.metadata.photos.0', 'https://example.com/sensoji.jpg');
    }

    public function test_outsider_cannot_view_trip_activity_feed(): void
    {
        $owner = User::factory()->create();
        $outsider = User::factory()->create();
        $trip = Trip::factory()->create(['owner_id' => $owner->id]);

        Sanctum::actingAs($outsider);

        $response = $this->getJson("/api/v1/trips/{$trip->id}/feed");

        $response->assertForbidden();
    }

    public function test_creating_shared_journal_entry_creates_activity_feed_event(): void
    {
        $owner = User::factory()->create();
        $trip = Trip::factory()->create(['owner_id' => $owner->id]);
        Sanctum::actingAs($owner);

        $response = $this->postJson("/api/v1/trips/{$trip->id}/journal", [
            'title' => 'Shibuya Crossing at Night',
            'content' => 'Neon lights everywhere and so much energy!',
            'entry_date' => '2026-11-10',
            'location_name' => 'Shibuya, Tokyo',
            'mood' => 'excited',
            'is_shared' => true,
        ]);

        $response->assertCreated();
        $entryId = $response->json('data.id');

        $this->assertDatabaseHas('activity_events', [
            'trip_id' => $trip->id,
            'actor_id' => $owner->id,
            'event_type' => 'moment_shared',
            'entity_type' => 'journal_entry',
            'entity_id' => $entryId,
            'title' => 'Shibuya Crossing at Night',
        ]);

        $feedResponse = $this->getJson("/api/v1/trips/{$trip->id}/feed");
        $feedResponse->assertOk()
            ->assertJsonPath('data.0.title', 'Shibuya Crossing at Night')
            ->assertJsonPath('data.0.summary', 'Neon lights everywhere and so much energy!');
    }

    public function test_private_journal_entry_does_not_create_activity_feed_event_tc_8_2(): void
    {
        $owner = User::factory()->create();
        $trip = Trip::factory()->create(['owner_id' => $owner->id]);
        Sanctum::actingAs($owner);

        $response = $this->postJson("/api/v1/trips/{$trip->id}/journal", [
            'title' => 'Personal Note - Not for Circle',
            'content' => 'Private reflection about personal spending and budget.',
            'entry_date' => '2026-11-10',
            'is_shared' => false,
        ]);

        $response->assertCreated();
        $entryId = $response->json('data.id');

        $this->assertDatabaseMissing('activity_events', [
            'trip_id' => $trip->id,
            'entity_id' => $entryId,
        ]);

        $feedResponse = $this->getJson("/api/v1/trips/{$trip->id}/feed");
        $feedResponse->assertOk()->assertExactJson(['data' => []]);
    }

    public function test_unsharing_journal_entry_removes_it_from_activity_feed_tc_8_1_and_tc_8_2(): void
    {
        $owner = User::factory()->create();
        $trip = Trip::factory()->create(['owner_id' => $owner->id]);
        Sanctum::actingAs($owner);

        // Initially shared
        $createResponse = $this->postJson("/api/v1/trips/{$trip->id}/journal", [
            'title' => 'Trip Highlights',
            'content' => 'Fun moments at the ramen festival.',
            'entry_date' => '2026-11-10',
            'is_shared' => true,
        ]);
        $entryId = $createResponse->json('data.id');

        // Confirm event exists in feed
        $this->assertDatabaseHas('activity_events', [
            'entity_id' => $entryId,
            'deleted_at' => null,
        ]);

        // Now author toggles is_shared to false
        $updateResponse = $this->patchJson("/api/v1/journal-entries/{$entryId}", [
            'is_shared' => false,
        ]);
        $updateResponse->assertOk();

        // Feed event must be soft-deleted / removed
        $this->assertSoftDeleted('activity_events', [
            'entity_id' => $entryId,
        ]);

        $feedResponse = $this->getJson("/api/v1/trips/{$trip->id}/feed");
        $feedResponse->assertOk()->assertExactJson(['data' => []]);
    }

    public function test_deleting_journal_entry_removes_it_from_activity_feed(): void
    {
        $owner = User::factory()->create();
        $trip = Trip::factory()->create(['owner_id' => $owner->id]);
        Sanctum::actingAs($owner);

        $createResponse = $this->postJson("/api/v1/trips/{$trip->id}/journal", [
            'title' => 'Moment to be deleted',
            'content' => 'Short lived post.',
            'entry_date' => '2026-11-10',
            'is_shared' => true,
        ]);
        $entryId = $createResponse->json('data.id');

        $this->assertDatabaseHas('activity_events', [
            'entity_id' => $entryId,
            'deleted_at' => null,
        ]);

        $deleteResponse = $this->deleteJson("/api/v1/journal-entries/{$entryId}");
        $deleteResponse->assertNoContent();

        $this->assertSoftDeleted('activity_events', [
            'entity_id' => $entryId,
        ]);
    }

    public function test_activity_feed_pagination_with_before_cursor(): void
    {
        $owner = User::factory()->create();
        $trip = Trip::factory()->create(['owner_id' => $owner->id]);
        Sanctum::actingAs($owner);

        $time1 = CarbonImmutable::parse('2026-11-10 10:00:00');
        $time2 = CarbonImmutable::parse('2026-11-10 12:00:00');
        $time3 = CarbonImmutable::parse('2026-11-10 14:00:00');

        $event1 = ActivityEvent::factory()->create([
            'trip_id' => $trip->id,
            'actor_id' => $owner->id,
            'title' => 'Morning Event',
            'occurred_at' => $time1,
        ]);

        $event2 = ActivityEvent::factory()->create([
            'trip_id' => $trip->id,
            'actor_id' => $owner->id,
            'title' => 'Noon Event',
            'occurred_at' => $time2,
        ]);

        $event3 = ActivityEvent::factory()->create([
            'trip_id' => $trip->id,
            'actor_id' => $owner->id,
            'title' => 'Afternoon Event',
            'occurred_at' => $time3,
        ]);

        // First page with limit=2 (should get event3 and event2)
        $firstPage = $this->getJson("/api/v1/trips/{$trip->id}/feed?limit=2");
        $firstPage->assertOk()
            ->assertJsonCount(2, 'data')
            ->assertJsonPath('data.0.id', $event3->id)
            ->assertJsonPath('data.1.id', $event2->id);

        // Next page before event2 cursor (should get event1)
        $secondPage = $this->getJson("/api/v1/trips/{$trip->id}/feed?limit=2&before={$event2->id}");
        $secondPage->assertOk()
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.id', $event1->id);
    }

    public function test_idempotent_event_recording_updates_without_duplication(): void
    {
        $owner = User::factory()->create();
        $trip = Trip::factory()->create(['owner_id' => $owner->id]);
        Sanctum::actingAs($owner);

        // Initial creation
        $createResponse = $this->postJson("/api/v1/trips/{$trip->id}/journal", [
            'title' => 'Initial Title',
            'content' => 'Initial content',
            'entry_date' => '2026-11-10',
            'is_shared' => true,
        ]);
        $entryId = $createResponse->json('data.id');

        $this->assertEquals(1, ActivityEvent::query()->where('entity_id', $entryId)->count());

        // Update the entry while still shared
        $updateResponse = $this->patchJson("/api/v1/journal-entries/{$entryId}", [
            'title' => 'Updated Title',
        ]);
        $updateResponse->assertOk();

        // Must still be exactly 1 row, updated with new title
        $this->assertEquals(1, ActivityEvent::query()->where('entity_id', $entryId)->count());
        $this->assertDatabaseHas('activity_events', [
            'entity_id' => $entryId,
            'title' => 'Updated Title',
        ]);
    }
}
