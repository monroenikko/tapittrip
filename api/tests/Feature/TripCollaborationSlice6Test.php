<?php

declare(strict_types=1);

namespace Tests\Feature;

use App\Models\Trip;
use App\Models\TripMember;
use App\Models\TripTraveler;
use App\Models\User;
use Illuminate\Foundation\Testing\DatabaseTransactions;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

final class TripCollaborationSlice6Test extends TestCase
{
    use DatabaseTransactions;

    public function test_tc9_1_location_sharing_is_off_by_default_requires_opt_in_and_valid_duration(): void
    {
        $owner = User::factory()->create(['name' => 'Owner Alice']);
        $member = User::factory()->create(['name' => 'Member Bob']);
        $outsider = User::factory()->create(['name' => 'Outsider Eve']);

        $trip = Trip::factory()->create(['owner_id' => $owner->id]);

        TripMember::factory()->create([
            'trip_id' => $trip->id,
            'user_id' => $member->id,
            'role' => 'editor',
            'invitation_status' => 'accepted',
        ]);

        // Outsider cannot access
        Sanctum::actingAs($outsider);
        $this->getJson("/api/v1/trips/{$trip->id}/location-share")->assertForbidden();
        $this->postJson("/api/v1/trips/{$trip->id}/location-share", ['enabled' => true])->assertForbidden();

        // Member: off by default
        Sanctum::actingAs($member);
        $getRes = $this->getJson("/api/v1/trips/{$trip->id}/location-share")->assertOk();
        $this->assertFalse($getRes->json('data.enabled'));
        $this->assertFalse($getRes->json('data.is_active'));

        // Validation: duration out of range
        $this->postJson("/api/v1/trips/{$trip->id}/location-share", [
            'enabled' => true,
            'duration_minutes' => 5,
        ])->assertUnprocessable();

        // Enable sharing with explicit consent, duration and coordinates
        $enableRes = $this->postJson("/api/v1/trips/{$trip->id}/location-share", [
            'enabled' => true,
            'duration_minutes' => 60,
            'audience' => 'circle',
            'latitude' => 35.6762,
            'longitude' => 139.6503,
        ])->assertCreated();

        $this->assertTrue($enableRes->json('data.enabled'));
        $this->assertTrue($enableRes->json('data.is_active'));
        $this->assertSame(60, $enableRes->json('data.duration_minutes'));
        $this->assertSame(35.6762, $enableRes->json('data.latitude'));
        $this->assertSame(139.6503, $enableRes->json('data.longitude'));
        $this->assertNotNull($enableRes->json('data.expires_at'));
        $this->assertNotNull($enableRes->json('data.last_shared_at'));

        $this->postJson("/api/v1/trips/{$trip->id}/location-share", [
            'enabled' => true,
            'duration_minutes' => 60,
            'audience' => 'circle',
            'latitude' => 35.6762,
        ])->assertUnprocessable();

        // Managed traveler profile cannot enable location sharing
        $traveler = TripTraveler::factory()->create([
            'trip_id' => $trip->id,
            'managing_user_id' => $member->id,
            'traveler_category' => 'child',
        ]);
        $this->assertDatabaseMissing('trip_location_shares', ['user_id' => $traveler->id]);
    }

    public function test_tc9_2_expiry_stop_and_member_removal_ceases_sharing(): void
    {
        $owner = User::factory()->create(['name' => 'Owner Alice']);
        $member = User::factory()->create(['name' => 'Member Bob']);

        $trip = Trip::factory()->create(['owner_id' => $owner->id]);

        $membership = TripMember::factory()->create([
            'trip_id' => $trip->id,
            'user_id' => $member->id,
            'role' => 'editor',
            'invitation_status' => 'accepted',
        ]);

        Sanctum::actingAs($member);
        $this->postJson("/api/v1/trips/{$trip->id}/location-share", [
            'enabled' => true,
            'duration_minutes' => 60,
            'audience' => 'circle',
            'latitude' => 48.8566,
            'longitude' => 2.3522,
        ])->assertCreated();

        // Active share visible in circle index
        Sanctum::actingAs($owner);
        $indexRes = $this->getJson("/api/v1/trips/{$trip->id}/location-shares")->assertOk();
        $this->assertCount(1, $indexRes->json('data'));
        $this->assertSame($member->id, $indexRes->json('data.0.user_id'));

        // Manually stop sharing
        Sanctum::actingAs($member);
        $stopRes = $this->patchJson("/api/v1/trips/{$trip->id}/location-share", [
            'enabled' => false,
        ])->assertOk();
        $this->assertFalse($stopRes->json('data.enabled'));
        $this->assertFalse($stopRes->json('data.is_active'));
        $this->assertNull($stopRes->json('data.latitude'));
        $this->assertNull($stopRes->json('data.longitude'));

        // Now index returns 0 active shares
        Sanctum::actingAs($owner);
        $indexAfterStop = $this->getJson("/api/v1/trips/{$trip->id}/location-shares")->assertOk();
        $this->assertCount(0, $indexAfterStop->json('data'));

        // Re-enable sharing
        Sanctum::actingAs($member);
        $this->patchJson("/api/v1/trips/{$trip->id}/location-share", [
            'enabled' => true,
            'duration_minutes' => 60,
            'latitude' => 48.8570,
            'longitude' => 2.3530,
        ])->assertOk();

        // Removal of member immediately removes their location share
        Sanctum::actingAs($owner);
        $this->deleteJson("/api/v1/trips/{$trip->id}/members/{$membership->id}")->assertNoContent();

        $this->assertDatabaseMissing('trip_location_shares', [
            'trip_id' => $trip->id,
            'user_id' => $member->id,
        ]);

        $finalIndex = $this->getJson("/api/v1/trips/{$trip->id}/location-shares")->assertOk();
        $this->assertCount(0, $finalIndex->json('data'));
    }

    public function test_tc9_3_organizer_only_audience_isolation(): void
    {
        $owner = User::factory()->create(['name' => 'Owner Alice']);
        $bob = User::factory()->create(['name' => 'Member Bob']);
        $charlie = User::factory()->create(['name' => 'Member Charlie']);

        $trip = Trip::factory()->create(['owner_id' => $owner->id]);

        TripMember::factory()->create([
            'trip_id' => $trip->id,
            'user_id' => $bob->id,
            'role' => 'editor',
            'invitation_status' => 'accepted',
        ]);
        TripMember::factory()->create([
            'trip_id' => $trip->id,
            'user_id' => $charlie->id,
            'role' => 'viewer',
            'invitation_status' => 'accepted',
        ]);

        // Bob shares location to organizer only
        Sanctum::actingAs($bob);
        $this->postJson("/api/v1/trips/{$trip->id}/location-share", [
            'enabled' => true,
            'duration_minutes' => 60,
            'audience' => 'organizer_only',
            'latitude' => 40.7128,
            'longitude' => -74.0060,
        ])->assertCreated();

        // Charlie (viewer) cannot see Bob's coordinates
        Sanctum::actingAs($charlie);
        $charlieView = $this->getJson("/api/v1/trips/{$trip->id}/location-shares")->assertOk();
        $this->assertCount(0, $charlieView->json('data'));

        // Alice (owner) CAN see Bob's coordinates
        Sanctum::actingAs($owner);
        $ownerView = $this->getJson("/api/v1/trips/{$trip->id}/location-shares")->assertOk();
        $this->assertCount(1, $ownerView->json('data'));
        $this->assertSame($bob->id, $ownerView->json('data.0.user_id'));
        $this->assertSame(40.7128, $ownerView->json('data.0.latitude'));
    }
}
