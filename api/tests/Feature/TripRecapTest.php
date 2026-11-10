<?php

declare(strict_types=1);

namespace Tests\Feature;

use App\Models\Expense;
use App\Models\ItineraryItem;
use App\Models\JournalEntry;
use App\Models\Stay;
use App\Models\Trip;
use App\Models\TripMember;
use App\Models\User;
use Carbon\CarbonImmutable;
use Illuminate\Foundation\Testing\DatabaseTransactions;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

final class TripRecapTest extends TestCase
{
    use DatabaseTransactions;

    public function test_trip_member_can_view_trip_recap_with_highlights_album_and_expenses(): void
    {
        $owner = User::factory()->create(['name' => 'Alice', 'display_name' => 'Alice Wonder']);
        $companion = User::factory()->create(['name' => 'Bob', 'display_name' => 'Bob Builder']);

        $trip = Trip::factory()->create([
            'owner_id' => $owner->id,
            'title' => 'Japan Golden Route',
            'destination_country' => 'Japan',
            'start_date' => '2026-11-10',
            'end_date' => '2026-11-16',
            'status' => 'completed',
        ]);

        TripMember::factory()->create([
            'trip_id' => $trip->id,
            'user_id' => $companion->id,
            'role' => 'editor',
            'invitation_status' => 'accepted',
        ]);

        // Itinerary Items: 2 visited, 1 planned
        ItineraryItem::factory()->create([
            'trip_id' => $trip->id,
            'title' => 'Senso-ji Temple',
            'status' => 'visited',
        ]);
        ItineraryItem::factory()->create([
            'trip_id' => $trip->id,
            'title' => 'Fushimi Inari Shrine',
            'status' => 'visited',
        ]);
        ItineraryItem::factory()->create([
            'trip_id' => $trip->id,
            'title' => 'Arashiyama Bamboo Grove',
            'status' => 'planned',
        ]);

        // Stays: 3 nights
        Stay::factory()->create([
            'trip_id' => $trip->id,
            'name' => 'Park Hyatt Tokyo',
            'check_in_at' => CarbonImmutable::parse('2026-11-10 15:00:00'),
            'check_out_at' => CarbonImmutable::parse('2026-11-13 11:00:00'),
        ]);

        // Journal Entries: Owner shared reflection + Companion own reflection
        JournalEntry::factory()->create([
            'trip_id' => $trip->id,
            'user_id' => $owner->id,
            'title' => 'Golden Pavilion Sunset',
            'content' => 'Mesmerizing reflection over the pond.',
            'entry_date' => '2026-11-11',
            'mood' => 'amazed',
            'location_name' => 'Kinkaku-ji',
            'is_shared' => true,
            'photos' => ['https://example.com/kinkakuji.jpg'],
        ]);

        JournalEntry::factory()->create([
            'trip_id' => $trip->id,
            'user_id' => $companion->id,
            'title' => 'Matcha Latte in Gion',
            'content' => 'Best green tea ice cream ever.',
            'entry_date' => '2026-11-12',
            'mood' => 'happy',
            'location_name' => 'Gion',
            'is_shared' => false, // Bob's own private entry is accessible to Bob
            'photos' => ['https://example.com/matcha.jpg'],
        ]);

        // Expense: 15,000 JPY dining
        Expense::factory()->create([
            'trip_id' => $trip->id,
            'payer_id' => $owner->id,
            'title' => 'Omakase Dinner',
            'category' => 'dining',
            'amount_minor' => 15000,
            'currency' => 'JPY',
            'base_amount_minor' => 15000,
        ]);

        Sanctum::actingAs($companion);

        $response = $this->getJson("/api/v1/trips/{$trip->id}/recap");

        $response
            ->assertOk()
            ->assertJsonPath('data.trip.title', 'Japan Golden Route')
            ->assertJsonPath('data.trip.duration_days', 7)
            ->assertJsonPath('data.highlights.total_places_visited', 2)
            ->assertJsonPath('data.highlights.total_places_planned', 3)
            ->assertJsonPath('data.highlights.completion_rate_percentage', 67)
            ->assertJsonPath('data.highlights.total_stays', 1)
            ->assertJsonPath('data.highlights.total_nights', 3)
            ->assertJsonPath('data.highlights.total_companions', 2)
            ->assertJsonPath('data.story_album.total_photos', 2)
            ->assertJsonPath('data.story_album.photos.0.caption', 'Golden Pavilion Sunset')
            ->assertJsonPath('data.story_album.photos.1.caption', 'Matcha Latte in Gion')
            ->assertJsonPath('data.story_album.mood_breakdown.amazed', 1)
            ->assertJsonPath('data.story_album.mood_breakdown.happy', 1)
            ->assertJsonPath('data.expense_summary.total_spent_minor', 15000)
            ->assertJsonPath('data.expense_summary.top_category', 'dining')
            ->assertJsonPath('data.expense_summary.formatted_total_spent', '¥15,000');
    }

    public function test_outsider_cannot_view_trip_recap_forbidden(): void
    {
        $owner = User::factory()->create();
        $stranger = User::factory()->create();
        $trip = Trip::factory()->create(['owner_id' => $owner->id]);

        Sanctum::actingAs($stranger);

        $response = $this->getJson("/api/v1/trips/{$trip->id}/recap");

        $response->assertForbidden();
    }

    public function test_recap_excludes_unshared_journal_entries_from_other_users_strict_privacy(): void
    {
        $owner = User::factory()->create(['name' => 'Alice']);
        $companion = User::factory()->create(['name' => 'Bob']);

        $trip = Trip::factory()->create(['owner_id' => $owner->id]);

        TripMember::factory()->create([
            'trip_id' => $trip->id,
            'user_id' => $companion->id,
            'role' => 'editor',
            'invitation_status' => 'accepted',
        ]);

        // Alice's private journal entry - should NOT be visible to Bob
        JournalEntry::factory()->create([
            'trip_id' => $trip->id,
            'user_id' => $owner->id,
            'title' => 'Secret Thoughts',
            'content' => 'I feel tired and need rest.',
            'entry_date' => '2026-11-11',
            'mood' => 'tired',
            'is_shared' => false,
            'photos' => ['https://example.com/private_selfie.jpg'],
        ]);

        // Alice's shared entry - should be visible to Bob
        JournalEntry::factory()->create([
            'trip_id' => $trip->id,
            'user_id' => $owner->id,
            'title' => 'Team Photo at Shibuya',
            'content' => 'Everyone had a blast.',
            'entry_date' => '2026-11-12',
            'mood' => 'excited',
            'is_shared' => true,
            'photos' => ['https://example.com/group_photo.jpg'],
        ]);

        Sanctum::actingAs($companion);

        $response = $this->getJson("/api/v1/trips/{$trip->id}/recap");

        $response->assertOk();

        $photos = $response->json('data.story_album.photos');
        $this->assertCount(1, $photos);
        $this->assertSame('https://example.com/group_photo.jpg', $photos[0]['url']);

        $moments = $response->json('data.story_album.moments');
        $this->assertCount(1, $moments);
        $this->assertSame('Team Photo at Shibuya', $moments[0]['title']);

        // Assert mood breakdown excludes Alice's private mood ('tired')
        $breakdown = $response->json('data.story_album.mood_breakdown');
        $this->assertArrayNotHasKey('tired', $breakdown);
        $this->assertSame(1, $breakdown['excited']);
    }

    public function test_recap_handles_empty_trip_without_activities_stays_or_expenses(): void
    {
        $owner = User::factory()->create();
        $trip = Trip::factory()->create([
            'owner_id' => $owner->id,
            'title' => 'Solo Weekend',
            'start_date' => null,
            'end_date' => null,
        ]);

        Sanctum::actingAs($owner);

        $response = $this->getJson("/api/v1/trips/{$trip->id}/recap");

        $response
            ->assertOk()
            ->assertJsonPath('data.trip.title', 'Solo Weekend')
            ->assertJsonPath('data.highlights.total_places_visited', 0)
            ->assertJsonPath('data.highlights.total_places_planned', 0)
            ->assertJsonPath('data.highlights.completion_rate_percentage', 0)
            ->assertJsonPath('data.highlights.total_stays', 0)
            ->assertJsonPath('data.highlights.total_nights', 0)
            ->assertJsonPath('data.highlights.total_companions', 1)
            ->assertJsonPath('data.story_album.total_photos', 0)
            ->assertJsonPath('data.story_album.moments', [])
            ->assertJsonPath('data.story_album.top_mood', null)
            ->assertJsonPath('data.expense_summary.total_spent_minor', 0)
            ->assertJsonPath('data.expense_summary.expenses_count', 0)
            ->assertJsonPath('data.expense_summary.top_category', null);
    }

    public function test_recap_calculates_nights_across_multiple_stays(): void
    {
        $owner = User::factory()->create();
        $trip = Trip::factory()->create([
            'owner_id' => $owner->id,
            'destination_country' => 'PH',
        ]);

        Stay::factory()->create([
            'trip_id' => $trip->id,
            'check_in_at' => CarbonImmutable::parse('2026-11-01 14:00:00'),
            'check_out_at' => CarbonImmutable::parse('2026-11-04 12:00:00'), // 3 nights
        ]);

        Stay::factory()->create([
            'trip_id' => $trip->id,
            'check_in_at' => CarbonImmutable::parse('2026-11-04 14:00:00'),
            'check_out_at' => CarbonImmutable::parse('2026-11-06 12:00:00'), // 2 nights
        ]);

        Sanctum::actingAs($owner);

        $response = $this->getJson("/api/v1/trips/{$trip->id}/recap");

        $response
            ->assertOk()
            ->assertJsonPath('data.highlights.total_stays', 2)
            ->assertJsonPath('data.highlights.total_nights', 5);
    }

    public function test_unauthenticated_request_is_rejected(): void
    {
        $trip = Trip::factory()->create();

        $response = $this->getJson("/api/v1/trips/{$trip->id}/recap");

        $response->assertUnauthorized();
    }

    public function test_soft_deleted_entries_and_activities_are_omitted_from_recap(): void
    {
        $owner = User::factory()->create();
        $trip = Trip::factory()->create(['owner_id' => $owner->id]);

        ItineraryItem::factory()->create([
            'trip_id' => $trip->id,
            'title' => 'Active Stop',
            'status' => 'visited',
        ]);

        $item2 = ItineraryItem::factory()->create([
            'trip_id' => $trip->id,
            'title' => 'Deleted Stop',
            'status' => 'visited',
        ]);
        $item2->delete(); // Soft delete

        $entry = JournalEntry::factory()->create([
            'trip_id' => $trip->id,
            'user_id' => $owner->id,
            'title' => 'Deleted Memory',
            'is_shared' => true,
        ]);
        $entry->delete(); // Soft delete

        Sanctum::actingAs($owner);

        $response = $this->getJson("/api/v1/trips/{$trip->id}/recap");

        $response
            ->assertOk()
            ->assertJsonPath('data.highlights.total_places_visited', 1)
            ->assertJsonPath('data.highlights.total_places_planned', 1)
            ->assertJsonPath('data.story_album.total_photos', 0)
            ->assertJsonPath('data.story_album.moments', []);
    }

    public function test_recap_formats_cents_based_currency_appropriately(): void
    {
        $owner = User::factory()->create();
        $trip = Trip::factory()->create([
            'owner_id' => $owner->id,
            'destination_country' => 'US',
        ]);

        Expense::factory()->create([
            'trip_id' => $trip->id,
            'payer_id' => $owner->id,
            'title' => 'Broadway Show',
            'category' => 'activities',
            'amount_minor' => 12550, // $125.50
            'currency' => 'USD',
            'base_amount_minor' => 12550,
        ]);

        Sanctum::actingAs($owner);

        $response = $this->getJson("/api/v1/trips/{$trip->id}/recap");

        $response
            ->assertOk()
            ->assertJsonPath('data.expense_summary.currency', 'USD')
            ->assertJsonPath('data.expense_summary.total_spent_minor', 12550)
            ->assertJsonPath('data.expense_summary.formatted_total_spent', '$125.50');
    }
}
