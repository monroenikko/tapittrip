<?php

declare(strict_types=1);

namespace Tests\Feature;

use App\Domain\Itinerary\Models\ItineraryItem;
use App\Domain\Stays\Models\Stay;
use App\Domain\Trips\Models\Trip;
use App\Models\User;
use Illuminate\Foundation\Testing\DatabaseTransactions;
use Illuminate\Support\Facades\DB;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

final class StayTest extends TestCase
{
    use DatabaseTransactions;

    public function test_user_can_create_multiple_stays_in_different_cities_without_booking_through_app(): void
    {
        $user = User::factory()->create();
        Sanctum::actingAs($user);

        /** @var Trip $trip */
        $trip = Trip::factory()->create(['owner_id' => $user->id]);

        // Stay 1: Tokyo Hotel
        $tokyoPayload = [
            'name' => 'Shinjuku Granbell Hotel',
            'stay_type' => 'hotel',
            'address' => '2-14-5 Kabukicho, Shinjuku City, Tokyo',
            'latitude' => 35.6961,
            'longitude' => 139.7053,
            'check_in_at' => '2026-05-10T15:00:00+09:00',
            'check_out_at' => '2026-05-13T11:00:00+09:00',
            'timezone' => 'Asia/Tokyo',
            'booking_reference' => 'CONF-TOKYO-101',
            'notes' => 'Non-smoking twin room on high floor.',
        ];

        $resp1 = $this->postJson("/api/v1/trips/{$trip->id}/stays", $tokyoPayload);
        $resp1
            ->assertCreated()
            ->assertJsonPath('data.name', 'Shinjuku Granbell Hotel')
            ->assertJsonPath('data.stay_type', 'hotel')
            ->assertJsonPath('data.booking_reference', 'CONF-TOKYO-101');

        // Stay 2: Kyoto Ryokan (Different city)
        $kyotoPayload = [
            'name' => 'Kyoto Gion Ryokan Q-beh',
            'stay_type' => 'hotel',
            'address' => '4-468 Washio-cho, Higashiyama-ku, Kyoto',
            'latitude' => 34.9995,
            'longitude' => 135.7801,
            'check_in_at' => '2026-05-13T16:00:00+09:00',
            'check_out_at' => '2026-05-16T10:00:00+09:00',
            'timezone' => 'Asia/Tokyo',
            'booking_reference' => 'CONF-KYOTO-202',
        ];

        $resp2 = $this->postJson("/api/v1/trips/{$trip->id}/stays", $kyotoPayload);
        $resp2
            ->assertCreated()
            ->assertJsonPath('data.name', 'Kyoto Gion Ryokan Q-beh');

        // List both stays
        $listResp = $this->getJson("/api/v1/trips/{$trip->id}/stays");
        $listResp
            ->assertOk()
            ->assertJsonCount(2, 'data');
    }

    public function test_booking_reference_is_encrypted_at_rest_in_database(): void
    {
        $user = User::factory()->create();
        Sanctum::actingAs($user);

        /** @var Trip $trip */
        $trip = Trip::factory()->create(['owner_id' => $user->id]);

        $plainReference = 'SECRET-CONF-CODE-7788';

        $payload = [
            'name' => 'The Kayon Resort Ubud',
            'stay_type' => 'hotel',
            'check_in_at' => '2026-06-01T14:00:00+08:00',
            'check_out_at' => '2026-06-05T12:00:00+08:00',
            'timezone' => 'Asia/Makassar',
            'booking_reference' => $plainReference,
        ];

        $response = $this->postJson("/api/v1/trips/{$trip->id}/stays", $payload);
        $response->assertCreated();

        $stayId = $response->json('data.id');

        // Check raw database value in PostgreSQL
        $rawReference = DB::table('stays')->where('id', $stayId)->value('booking_reference');

        // It MUST NOT match the plaintext
        $this->assertNotNull($rawReference);
        $this->assertNotEquals($plainReference, $rawReference);
        $this->assertStringNotContainsString($plainReference, $rawReference);

        // Eloquent model must cleanly decrypt it
        /** @var Stay $stay */
        $stay = Stay::query()->findOrFail($stayId);
        $this->assertEquals($plainReference, $stay->booking_reference);
    }

    public function test_stay_check_in_and_check_out_itinerary_events_created_when_requested(): void
    {
        $user = User::factory()->create();
        Sanctum::actingAs($user);

        /** @var Trip $trip */
        $trip = Trip::factory()->create(['owner_id' => $user->id]);

        $payload = [
            'name' => 'Bali Beach Villa',
            'stay_type' => 'rental',
            'check_in_at' => '2026-07-01T15:00:00+08:00',
            'check_out_at' => '2026-07-05T11:00:00+08:00',
            'timezone' => 'Asia/Makassar',
            'create_itinerary_events' => true,
        ];

        $response = $this->postJson("/api/v1/trips/{$trip->id}/stays", $payload);
        $response->assertCreated();

        $stayId = $response->json('data.id');

        $this->assertDatabaseHas('itinerary_items', [
            'trip_id' => $trip->id,
            'stay_id' => $stayId,
            'title' => 'Check-in: Bali Beach Villa',
        ]);

        $this->assertDatabaseHas('itinerary_items', [
            'trip_id' => $trip->id,
            'stay_id' => $stayId,
            'title' => 'Check-out: Bali Beach Villa',
        ]);
    }

    public function test_stay_deletion_preserves_linked_itinerary_items_without_orphaning(): void
    {
        $user = User::factory()->create();
        Sanctum::actingAs($user);

        /** @var Trip $trip */
        $trip = Trip::factory()->create(['owner_id' => $user->id]);

        $createResp = $this->postJson("/api/v1/trips/{$trip->id}/stays", [
            'name' => 'Osaka Boutique Hotel',
            'check_in_at' => '2026-08-01T15:00:00+09:00',
            'check_out_at' => '2026-08-03T11:00:00+09:00',
            'timezone' => 'Asia/Tokyo',
            'create_itinerary_events' => true,
        ]);

        $stayId = $createResp->json('data.id');

        // Delete the stay
        $delResp = $this->deleteJson("/api/v1/stays/{$stayId}");
        $delResp->assertNoContent();

        // Stay is soft deleted
        $this->assertSoftDeleted('stays', ['id' => $stayId]);

        // Linked itinerary items still exist and are not deleted or orphaned!
        $items = ItineraryItem::query()->where('trip_id', $trip->id)->get();
        $this->assertCount(2, $items);
        foreach ($items as $item) {
            $this->assertNull($item->stay_id);
            $this->assertNull($item->deleted_at);
        }
    }

    public function test_membership_authorization_prevents_unauthorized_access(): void
    {
        $owner = User::factory()->create();
        $stranger = User::factory()->create();

        /** @var Trip $trip */
        $trip = Trip::factory()->create(['owner_id' => $owner->id]);

        /** @var Stay $stay */
        $stay = Stay::factory()->create(['trip_id' => $trip->id]);

        Sanctum::actingAs($stranger);

        // Cannot view stays of other user's trip
        $this->getJson("/api/v1/trips/{$trip->id}/stays")->assertForbidden();

        // Cannot view stay directly
        $this->getJson("/api/v1/stays/{$stay->id}")->assertForbidden();

        // Cannot delete stay
        $this->deleteJson("/api/v1/stays/{$stay->id}")->assertForbidden();
    }

    public function test_check_out_must_be_after_check_in(): void
    {
        $user = User::factory()->create();
        Sanctum::actingAs($user);

        /** @var Trip $trip */
        $trip = Trip::factory()->create(['owner_id' => $user->id]);

        $invalidPayload = [
            'name' => 'Invalid Timing Hotel',
            'check_in_at' => '2026-09-10T15:00:00Z',
            'check_out_at' => '2026-09-08T11:00:00Z', // Before check-in
        ];

        $response = $this->postJson("/api/v1/trips/{$trip->id}/stays", $invalidPayload);
        $response
            ->assertStatus(422)
            ->assertJsonPath('error.code', 'validation_failed')
            ->assertJsonStructure(['error' => ['details' => ['fields' => ['check_out_at']]]]);
    }
}
