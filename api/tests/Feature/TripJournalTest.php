<?php

declare(strict_types=1);

namespace Tests\Feature;

use App\Domain\Journal\Models\JournalEntry;
use App\Domain\Trips\Models\Trip;
use App\Domain\Trips\Models\TripMember;
use App\Models\User;
use Illuminate\Foundation\Testing\DatabaseTransactions;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

final class TripJournalTest extends TestCase
{
    use DatabaseTransactions;

    public function test_user_can_create_journal_entry(): void
    {
        $owner = User::factory()->create();
        Sanctum::actingAs($owner);

        $trip = Trip::factory()->create(['owner_id' => $owner->id]);

        $response = $this->postJson("/api/v1/trips/{$trip->id}/journal", [
            'title' => 'First day in Tokyo',
            'content' => 'Landed at Narita, took the Narita Express to Shinjuku. The ramen was incredible!',
            'entry_date' => '2026-11-09',
            'location_name' => 'Shinjuku, Tokyo',
            'mood' => 'amazed',
            'weather' => 'sunny',
            'is_shared' => false,
        ]);

        $response
            ->assertCreated()
            ->assertJsonPath('data.title', 'First day in Tokyo')
            ->assertJsonPath('data.mood', 'amazed')
            ->assertJsonPath('data.is_shared', false)
            ->assertJsonPath('data.is_author', true)
            ->assertJsonPath('data.photos', []);

        $this->assertDatabaseHas('journal_entries', [
            'trip_id' => $trip->id,
            'user_id' => $owner->id,
            'title' => 'First day in Tokyo',
            'is_shared' => false,
        ]);
    }

    public function test_companion_can_only_see_shared_entries(): void
    {
        $owner = User::factory()->create();
        $companion = User::factory()->create();
        $outsider = User::factory()->create();

        $trip = Trip::factory()->create(['owner_id' => $owner->id]);
        TripMember::factory()->create([
            'trip_id' => $trip->id,
            'user_id' => $companion->id,
            'role' => 'viewer',
        ]);

        // Owner creates 1 private entry and 1 shared entry
        $privateEntry = JournalEntry::factory()->create([
            'trip_id' => $trip->id,
            'user_id' => $owner->id,
            'title' => 'Secret Thoughts',
            'is_shared' => false,
        ]);

        $sharedEntry = JournalEntry::factory()->create([
            'trip_id' => $trip->id,
            'user_id' => $owner->id,
            'title' => 'Group Photos at Shibuya',
            'is_shared' => true,
        ]);

        // Owner can see both
        Sanctum::actingAs($owner);
        $ownerResp = $this->getJson("/api/v1/trips/{$trip->id}/journal");
        $ownerResp->assertOk();
        $this->assertCount(2, $ownerResp->json('data'));

        // Companion only sees shared entry
        Sanctum::actingAs($companion);
        $companionResp = $this->getJson("/api/v1/trips/{$trip->id}/journal");
        $companionResp->assertOk();
        $this->assertCount(1, $companionResp->json('data'));
        $this->assertSame($sharedEntry->id, $companionResp->json('data.0.id'));

        // Companion trying to GET private entry directly is forbidden
        $forbiddenResp = $this->getJson("/api/v1/journal-entries/{$privateEntry->id}");
        $forbiddenResp->assertForbidden();

        // Outsider cannot access journal at all
        Sanctum::actingAs($outsider);
        $outsiderResp = $this->getJson("/api/v1/trips/{$trip->id}/journal");
        $outsiderResp->assertForbidden();
    }

    public function test_author_can_update_journal_entry_and_toggle_sharing(): void
    {
        $owner = User::factory()->create();
        Sanctum::actingAs($owner);

        $trip = Trip::factory()->create(['owner_id' => $owner->id]);
        $entry = JournalEntry::factory()->create([
            'trip_id' => $trip->id,
            'user_id' => $owner->id,
            'title' => 'Draft Reflection',
            'is_shared' => false,
        ]);

        $response = $this->patchJson("/api/v1/journal-entries/{$entry->id}", [
            'title' => 'Published Reflection',
            'is_shared' => true,
            'mood' => 'happy',
        ]);

        $response
            ->assertOk()
            ->assertJsonPath('data.title', 'Published Reflection')
            ->assertJsonPath('data.is_shared', true)
            ->assertJsonPath('data.mood', 'happy');

        $this->assertDatabaseHas('journal_entries', [
            'id' => $entry->id,
            'is_shared' => true,
        ]);
    }

    public function test_non_author_companion_cannot_update_or_delete_entry(): void
    {
        $owner = User::factory()->create();
        $companion = User::factory()->create();

        $trip = Trip::factory()->create(['owner_id' => $owner->id]);
        TripMember::factory()->create([
            'trip_id' => $trip->id,
            'user_id' => $companion->id,
            'role' => 'editor',
        ]);

        $entry = JournalEntry::factory()->create([
            'trip_id' => $trip->id,
            'user_id' => $owner->id,
            'is_shared' => true,
        ]);

        Sanctum::actingAs($companion);

        $updateResp = $this->patchJson("/api/v1/journal-entries/{$entry->id}", [
            'title' => 'Hacked Title',
        ]);
        $updateResp->assertForbidden();

        $deleteResp = $this->deleteJson("/api/v1/journal-entries/{$entry->id}");
        $deleteResp->assertForbidden();
    }

    public function test_author_can_upload_photo_to_journal_entry(): void
    {
        Storage::fake('public');

        $owner = User::factory()->create();
        Sanctum::actingAs($owner);

        $trip = Trip::factory()->create(['owner_id' => $owner->id]);
        $entry = JournalEntry::factory()->create([
            'trip_id' => $trip->id,
            'user_id' => $owner->id,
            'photos' => [],
        ]);

        $photo = UploadedFile::fake()->image('sunset.jpg', 800, 600);

        $response = $this->postJson("/api/v1/journal-entries/{$entry->id}/photos", [
            'photo' => $photo,
        ]);

        $response->assertOk();
        $photos = $response->json('data.photos');
        $this->assertCount(1, $photos);
        $this->assertStringContainsString('journal-photos', $photos[0]);

        $entry->refresh();
        $this->assertCount(1, $entry->photos);
    }
}
