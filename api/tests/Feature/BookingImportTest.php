<?php

declare(strict_types=1);

namespace Tests\Feature;

use App\Models\Trip;
use App\Models\User;
use Illuminate\Foundation\Testing\DatabaseTransactions;
use Illuminate\Support\Str;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

final class BookingImportTest extends TestCase
{
    use DatabaseTransactions;

    public function test_can_import_flight_confirmation_text_and_confirm_into_flight(): void
    {
        $owner = User::factory()->create();
        $trip = Trip::factory()->create(['owner_id' => $owner->id]);

        Sanctum::actingAs($owner);

        $opId = (string) Str::uuid();
        $flightText = "Philippine Airlines Flight Confirmation\nPNR: PR-ABC123\nFlight PR 101\nRoute: MNL -> NRT\nDate: 2027-04-10T08:00:00Z";

        $response = $this->postJson("/api/v1/trips/{$trip->id}/imports", [
            'raw_text' => $flightText,
            'source' => 'paste_text',
            'booking_type' => 'flight',
            'client_operation_id' => $opId,
        ])
            ->assertCreated()
            ->assertJsonPath('data.booking_type', 'flight')
            ->assertJsonPath('data.extraction_status', 'extracted')
            ->assertJsonPath('data.extracted_data.flight.airline', 'Philippine Airlines')
            ->json('data');

        $importId = $response['id'];

        // Confirm the extracted flight
        $confirmed = $this->postJson("/api/v1/imports/{$importId}/confirm", [
            'base_version' => 1,
            'booking_type' => 'flight',
            'flight' => $response['extracted_data']['flight'],
        ])
            ->assertOk()
            ->assertJsonPath('data.extraction_status', 'confirmed')
            ->assertJsonPath('data.confirmed_entity_type', 'flight')
            ->json('data');

        $this->assertNotNull($confirmed['confirmed_entity_id']);

        $this->assertDatabaseHas('flights', [
            'id' => $confirmed['confirmed_entity_id'],
            'trip_id' => $trip->id,
            'airline' => 'Philippine Airlines',
        ]);

        $this->assertDatabaseHas('flight_segments', [
            'flight_id' => $confirmed['confirmed_entity_id'],
            'origin_airport' => 'MNL',
            'destination_airport' => 'NRT',
        ]);
    }

    public function test_can_import_hotel_stay_confirmation_and_confirm_into_stay(): void
    {
        $owner = User::factory()->create();
        $trip = Trip::factory()->create(['owner_id' => $owner->id]);

        Sanctum::actingAs($owner);

        $stayText = "Hotel Reservation: Shinjuku Granbell Hotel\nConfirmation: HTL-998811\nAddress: 2-14-5 Kabukicho, Shinjuku, Tokyo 160-0021";

        $response = $this->postJson("/api/v1/trips/{$trip->id}/imports", [
            'raw_text' => $stayText,
            'booking_type' => 'stay',
        ])
            ->assertCreated()
            ->assertJsonPath('data.booking_type', 'stay')
            ->assertJsonPath('data.extraction_status', 'extracted')
            ->assertJsonPath('data.extracted_data.stay.name', 'Shinjuku Granbell Hotel')
            ->json('data');

        $importId = $response['id'];

        $confirmed = $this->postJson("/api/v1/imports/{$importId}/confirm", [
            'base_version' => 1,
            'booking_type' => 'stay',
            'stay' => $response['extracted_data']['stay'],
        ])
            ->assertOk()
            ->assertJsonPath('data.extraction_status', 'confirmed')
            ->assertJsonPath('data.confirmed_entity_type', 'stay')
            ->json('data');

        $this->assertDatabaseHas('stays', [
            'id' => $confirmed['confirmed_entity_id'],
            'trip_id' => $trip->id,
            'name' => 'Shinjuku Granbell Hotel',
        ]);
    }

    public function test_can_import_activity_voucher_and_confirm_into_itinerary_item(): void
    {
        $owner = User::factory()->create();
        $trip = Trip::factory()->create(['owner_id' => $owner->id]);

        Sanctum::actingAs($owner);

        $activityText = "Tour Ticket: teamLab Planets Tokyo Admission\nPlace: teamLab Planets TOKYO DMM";

        $response = $this->postJson("/api/v1/trips/{$trip->id}/imports", [
            'raw_text' => $activityText,
            'booking_type' => 'activity',
        ])
            ->assertCreated()
            ->assertJsonPath('data.booking_type', 'activity')
            ->assertJsonPath('data.extraction_status', 'extracted')
            ->json('data');

        $importId = $response['id'];

        $confirmed = $this->postJson("/api/v1/imports/{$importId}/confirm", [
            'base_version' => 1,
            'booking_type' => 'activity',
            'activity' => $response['extracted_data']['activity'],
        ])
            ->assertOk()
            ->assertJsonPath('data.extraction_status', 'confirmed')
            ->assertJsonPath('data.confirmed_entity_type', 'itinerary_item')
            ->json('data');

        $this->assertDatabaseHas('itinerary_items', [
            'id' => $confirmed['confirmed_entity_id'],
            'trip_id' => $trip->id,
            'title' => 'teamLab Planets Tokyo Admission',
        ]);
    }

    public function test_enforces_optimistic_concurrency_base_version_conflict_on_confirm(): void
    {
        $owner = User::factory()->create();
        $trip = Trip::factory()->create(['owner_id' => $owner->id]);

        Sanctum::actingAs($owner);

        $created = $this->postJson("/api/v1/trips/{$trip->id}/imports", [
            'raw_text' => 'Flight PR 101 MNL -> NRT',
            'booking_type' => 'flight',
        ])
            ->assertCreated()
            ->json('data');

        $this->postJson("/api/v1/imports/{$created['id']}/confirm", [
            'base_version' => 999, // Stale version
            'booking_type' => 'flight',
            'flight' => $created['extracted_data']['flight'],
        ])
            ->assertStatus(409)
            ->assertJsonPath('error.code', 'version_conflict');
    }

    public function test_idempotent_creation_with_client_operation_id(): void
    {
        $owner = User::factory()->create();
        $trip = Trip::factory()->create(['owner_id' => $owner->id]);
        $opId = (string) Str::uuid();

        Sanctum::actingAs($owner);

        $first = $this->postJson("/api/v1/trips/{$trip->id}/imports", [
            'raw_text' => 'Hotel Shinjuku Granbell',
            'booking_type' => 'stay',
            'client_operation_id' => $opId,
        ])
            ->assertCreated()
            ->json('data');

        $second = $this->postJson("/api/v1/trips/{$trip->id}/imports", [
            'raw_text' => 'Hotel Shinjuku Granbell',
            'booking_type' => 'stay',
            'client_operation_id' => $opId,
        ])
            ->assertOk()
            ->json('data');

        $this->assertSame($first['id'], $second['id']);
    }

    public function test_trip_membership_authorization(): void
    {
        $owner = User::factory()->create();
        $outsider = User::factory()->create();
        $trip = Trip::factory()->create(['owner_id' => $owner->id]);

        Sanctum::actingAs($outsider);

        $this->getJson("/api/v1/trips/{$trip->id}/imports")
            ->assertForbidden();

        $this->postJson("/api/v1/trips/{$trip->id}/imports", [
            'raw_text' => 'Flight test',
        ])
            ->assertForbidden();
    }

    public function test_can_list_and_delete_booking_imports(): void
    {
        $owner = User::factory()->create();
        $trip = Trip::factory()->create(['owner_id' => $owner->id]);

        Sanctum::actingAs($owner);

        $created = $this->postJson("/api/v1/trips/{$trip->id}/imports", [
            'raw_text' => 'Flight test to delete',
            'booking_type' => 'flight',
        ])
            ->assertCreated()
            ->json('data');

        $list = $this->getJson("/api/v1/trips/{$trip->id}/imports")
            ->assertOk()
            ->json('data');

        $this->assertCount(1, $list);

        $this->deleteJson("/api/v1/imports/{$created['id']}")
            ->assertNoContent();

        $this->assertSoftDeleted('booking_imports', [
            'id' => $created['id'],
        ]);
    }
}
