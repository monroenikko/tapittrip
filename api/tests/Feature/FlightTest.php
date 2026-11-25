<?php

declare(strict_types=1);

namespace Tests\Feature;

use App\Models\Trip;
use App\Models\TripMember;
use App\Models\User;
use Illuminate\Foundation\Testing\DatabaseTransactions;
use Illuminate\Support\Facades\DB;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

final class FlightTest extends TestCase
{
    use DatabaseTransactions;

    /** @return array<string, mixed> */
    private function payload(): array
    {
        return [
            'airline' => 'TapIt Air',
            'booking_reference' => 'PRIVATE-REF-901',
            'client_operation_id' => '6f929f0c-c5dc-4620-a87f-3dc0e6bbaf49',
            'segments' => [[
                'flight_number' => 'TT 101',
                'origin_airport' => 'MNL',
                'destination_airport' => 'NRT',
                'scheduled_departure_utc' => '2026-12-20T01:00:00Z',
                'scheduled_arrival_utc' => '2026-12-20T05:30:00Z',
                'origin_timezone' => 'Asia/Manila',
                'destination_timezone' => 'Asia/Tokyo',
                'terminal' => '1',
                'gate' => '12',
            ], [
                'flight_number' => 'TT 102',
                'origin_airport' => 'NRT',
                'destination_airport' => 'CTS',
                'scheduled_departure_utc' => '2026-12-20T07:00:00Z',
                'scheduled_arrival_utc' => '2026-12-20T09:00:00Z',
                'origin_timezone' => 'Asia/Tokyo',
                'destination_timezone' => 'Asia/Tokyo',
            ]],
        ];
    }

    public function test_owner_can_create_multi_leg_flight_and_reference_is_encrypted(): void
    {
        $user = User::factory()->create();
        $trip = Trip::factory()->create(['owner_id' => $user->id]);
        Sanctum::actingAs($user);

        $response = $this->postJson("/api/v1/trips/{$trip->id}/flights", $this->payload());
        $response->assertCreated()
            ->assertJsonPath('data.segments.0.origin_airport', 'MNL')
            ->assertJsonCount(2, 'data.segments');

        $raw = DB::table('flights')->where('id', $response->json('data.id'))->value('booking_reference');
        $this->assertNotSame('PRIVATE-REF-901', $raw);
    }

    public function test_member_can_view_schedule_but_not_booking_reference(): void
    {
        $owner = User::factory()->create();
        $member = User::factory()->create();
        $trip = Trip::factory()->create(['owner_id' => $owner->id]);
        TripMember::factory()->create(['trip_id' => $trip->id, 'user_id' => $member->id, 'role' => 'viewer', 'invitation_status' => 'accepted']);
        Sanctum::actingAs($owner);
        $this->postJson("/api/v1/trips/{$trip->id}/flights", $this->payload())->assertCreated();

        Sanctum::actingAs($member);
        $this->getJson("/api/v1/trips/{$trip->id}/flights")
            ->assertOk()
            ->assertJsonPath('data.0.booking_reference', null);
    }

    public function test_viewer_cannot_create_and_invalid_route_is_rejected(): void
    {
        $owner = User::factory()->create();
        $viewer = User::factory()->create();
        $trip = Trip::factory()->create(['owner_id' => $owner->id]);
        TripMember::factory()->create(['trip_id' => $trip->id, 'user_id' => $viewer->id, 'role' => 'viewer', 'invitation_status' => 'accepted']);
        Sanctum::actingAs($viewer);
        $this->postJson("/api/v1/trips/{$trip->id}/flights", $this->payload())->assertForbidden();

        Sanctum::actingAs($owner);
        $payload = $this->payload();
        $payload['segments'][0]['destination_airport'] = 'MNL';
        $this->postJson("/api/v1/trips/{$trip->id}/flights", $payload)
            ->assertUnprocessable()
            ->assertJsonPath('error.code', 'validation_failed');
    }

    public function test_update_uses_version_and_delete_is_authorized(): void
    {
        $owner = User::factory()->create();
        $trip = Trip::factory()->create(['owner_id' => $owner->id]);
        Sanctum::actingAs($owner);
        $created = $this->postJson("/api/v1/trips/{$trip->id}/flights", $this->payload())->json('data');

        $this->patchJson("/api/v1/flights/{$created['id']}", ['airline' => 'Updated Air', 'base_version' => 1])
            ->assertOk()
            ->assertJsonPath('data.version', 2);
        $this->patchJson("/api/v1/flights/{$created['id']}", ['airline' => 'Stale Air', 'base_version' => 1])
            ->assertConflict()
            ->assertJsonPath('error.code', 'version_conflict');
        $this->deleteJson("/api/v1/flights/{$created['id']}")->assertNoContent();
        $this->assertDatabaseMissing('flights', ['id' => $created['id']]);
    }

    public function test_sync_push_and_pull_flights_redact_booking_reference(): void
    {
        $owner = User::factory()->create();
        $editor = User::factory()->create();
        $trip = Trip::factory()->create(['owner_id' => $owner->id]);
        TripMember::factory()->create([
            'trip_id' => $trip->id,
            'user_id' => $editor->id,
            'role' => 'editor',
            'invitation_status' => 'accepted',
        ]);

        $flightId = '01950000-0000-7000-8000-000000000001';
        Sanctum::actingAs($owner);
        $this->postJson('/api/v1/sync/push', [
            'device_key' => 'owner-device',
            'operations' => [[
                'operation_id' => '01950000-0000-7000-8000-000000000002',
                'trip_id' => $trip->id,
                'entity_type' => 'flight',
                'entity_id' => $flightId,
                'operation_type' => 'create',
                'base_version' => 1,
                'payload' => $this->payload(),
            ]],
        ])->assertOk()->assertJsonPath('data.results.0.status', 'accepted');

        // Bump version to 2 as owner
        $this->patchJson("/api/v1/flights/{$flightId}", [
            'airline' => 'TapIt Express',
            'base_version' => 1,
        ])->assertOk()->assertJsonPath('data.version', 2);

        // Editor pushes stale base_version 1 -> conflict payload redacts booking_reference
        Sanctum::actingAs($editor);
        $this->postJson('/api/v1/sync/push', [
            'device_key' => 'editor-device',
            'operations' => [[
                'operation_id' => '01950000-0000-7000-8000-000000000003',
                'trip_id' => $trip->id,
                'entity_type' => 'flight',
                'entity_id' => $flightId,
                'operation_type' => 'update',
                'base_version' => 1,
                'payload' => ['airline' => 'Editor Air'],
            ]],
        ])->assertOk()
            ->assertJsonPath('data.results.0.status', 'conflict')
            ->assertJsonPath('data.results.0.conflict_details.server_payload.booking_reference', null);

        // Editor pulls operations -> payload has no raw booking_reference
        $pulled = $this->getJson("/api/v1/sync/pull?trip_id={$trip->id}&cursor=0&device_key=editor-device")
            ->assertOk();
        $flightOp = collect($pulled->json('data.operations'))->firstWhere('entity_id', $flightId);
        $this->assertNotNull($flightOp);
        $this->assertArrayNotHasKey('booking_reference', $flightOp['payload'] ?? []);
    }

    public function test_today_summary_includes_flights_and_flight_prep_reminders_sync_without_booking_reference(): void
    {
        $owner = User::factory()->create();
        $viewer = User::factory()->create();
        $trip = Trip::factory()->create(['owner_id' => $owner->id]);
        TripMember::factory()->create([
            'trip_id' => $trip->id,
            'user_id' => $viewer->id,
            'role' => 'viewer',
            'invitation_status' => 'accepted',
        ]);

        Sanctum::actingAs($owner);
        $created = $this->postJson("/api/v1/trips/{$trip->id}/flights", $this->payload())
            ->assertCreated()
            ->json('data');

        // Reminders scheduled automatically on create (2 segments x 2 reminder types = 4 scheduled reminders)
        $reminders = $this->getJson("/api/v1/trips/{$trip->id}/reminders?status=scheduled")
            ->assertOk()
            ->json('data');
        $flightReminders = collect($reminders)->whereIn('type', ['flight_prep', 'flight_gate_departure']);
        $this->assertCount(4, $flightReminders);
        foreach ($flightReminders as $rem) {
            $this->assertStringNotContainsString('PRIVATE-REF-901', $rem['title'].' '.$rem['body']);
        }

        // Today summary for owner includes upcoming_flight with booking_reference
        $this->getJson("/api/v1/trips/{$trip->id}/today")
            ->assertOk()
            ->assertJsonPath('data.upcoming_flight.id', $created['id'])
            ->assertJsonPath('data.upcoming_flight.booking_reference', 'PRIVATE-REF-901')
            ->assertJsonPath('data.upcoming_flight.segments.0.origin_airport', 'MNL')
            ->assertJsonPath('data.upcoming_flight.segments.0.terminal', '1')
            ->assertJsonCount(1, 'data.flights');

        // Today summary for viewer redacts booking_reference
        Sanctum::actingAs($viewer);
        $this->getJson("/api/v1/trips/{$trip->id}/today")
            ->assertOk()
            ->assertJsonPath('data.upcoming_flight.id', $created['id'])
            ->assertJsonPath('data.upcoming_flight.booking_reference', null);

        // Deleting the flight cancels its scheduled reminders
        Sanctum::actingAs($owner);
        $this->deleteJson("/api/v1/flights/{$created['id']}")->assertNoContent();
        $afterDelete = $this->getJson("/api/v1/trips/{$trip->id}/reminders?status=scheduled")
            ->assertOk()
            ->json('data');
        $this->assertCount(
            0,
            collect($afterDelete)->whereIn('type', ['flight_prep', 'flight_gate_departure'])
        );
    }
}
