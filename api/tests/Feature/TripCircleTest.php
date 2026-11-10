<?php

declare(strict_types=1);

namespace Tests\Feature;

use App\Models\ItineraryItem;
use App\Models\Stay;
use App\Models\Trip;
use App\Models\TripInvitation;
use App\Models\TripMember;
use App\Models\User;
use Illuminate\Foundation\Testing\DatabaseTransactions;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

final class TripCircleTest extends TestCase
{
    use DatabaseTransactions;

    public function test_organizer_can_create_list_and_revoke_invitation_and_token_is_hashed_at_rest(): void
    {
        $owner = User::factory()->create(['display_name' => 'Organizer Alex']);
        $trip = Trip::factory()->create(['owner_id' => $owner->id, 'title' => 'Kyoto Spring']);

        Sanctum::actingAs($owner);

        $createResponse = $this->postJson("/api/v1/trips/{$trip->id}/invitations", [
            'proposed_role' => 'editor',
            'max_uses' => 3,
            'expires_in_days' => 10,
        ]);

        $createResponse
            ->assertCreated()
            ->assertJsonPath('data.proposed_role', 'editor')
            ->assertJsonPath('data.max_uses', 3)
            ->assertJsonPath('data.use_count', 0)
            ->assertJsonPath('data.status', 'active');

        $rawToken = (string) $createResponse->json('data.invite_token');
        $invitationId = (string) $createResponse->json('data.id');
        $this->assertNotEmpty($rawToken);

        // Raw token must never be saved in DB plaintext — only SHA-256 hash
        $this->assertDatabaseHas('trip_invitations', [
            'id' => $invitationId,
            'token_hash' => hash('sha256', $rawToken),
        ]);
        $this->assertDatabaseMissing('trip_invitations', [
            'id' => $invitationId,
            'token_hash' => $rawToken,
        ]);

        // List endpoint must omit raw token and token_hash
        $listResponse = $this->getJson("/api/v1/trips/{$trip->id}/invitations");
        $listResponse->assertOk()->assertJsonCount(1, 'data');
        $this->assertArrayNotHasKey('invite_token', $listResponse->json('data.0'));
        $this->assertArrayNotHasKey('token_hash', $listResponse->json('data.0'));

        // Revoke invitation
        $revokeResponse = $this->deleteJson("/api/v1/trips/{$trip->id}/invitations/{$invitationId}");
        $revokeResponse->assertOk()->assertJsonPath('data.status', 'revoked');
    }

    public function test_non_owners_cannot_create_list_or_revoke_invitations_or_modify_roles(): void
    {
        $owner = User::factory()->create();
        $editor = User::factory()->create();
        $viewer = User::factory()->create();
        $stranger = User::factory()->create();

        $trip = Trip::factory()->create(['owner_id' => $owner->id]);
        $editorMember = TripMember::factory()->create(['trip_id' => $trip->id, 'user_id' => $editor->id, 'role' => 'editor']);
        TripMember::factory()->create(['trip_id' => $trip->id, 'user_id' => $viewer->id, 'role' => 'viewer']);
        $invitation = TripInvitation::factory()->create(['trip_id' => $trip->id, 'inviter_id' => $owner->id]);

        foreach ([$editor, $viewer, $stranger] as $actor) {
            Sanctum::actingAs($actor);

            $this->postJson("/api/v1/trips/{$trip->id}/invitations", ['proposed_role' => 'viewer'])->assertForbidden();
            $this->getJson("/api/v1/trips/{$trip->id}/invitations")->assertForbidden();
            $this->deleteJson("/api/v1/trips/{$trip->id}/invitations/{$invitation->id}")->assertForbidden();
            $this->patchJson("/api/v1/trips/{$trip->id}/members/{$editorMember->id}", ['role' => 'viewer'])->assertForbidden();
        }
    }

    public function test_preview_returns_minimal_safe_summary_without_granting_access_or_leaking_dates(): void
    {
        $owner = User::factory()->create(['display_name' => 'Maya Host', 'email' => 'secret@example.com']);
        $guest = User::factory()->create();

        $trip = Trip::factory()->create([
            'owner_id' => $owner->id,
            'title' => 'Tokyo Food Tour',
            'destination_country' => 'Japan',
            'start_date' => '2026-12-01',
            'end_date' => '2026-12-07',
        ]);

        ItineraryItem::factory()->create(['trip_id' => $trip->id, 'title' => 'Secret Dinner Spot']);
        Stay::factory()->create(['trip_id' => $trip->id, 'name' => 'Private Residence Address']);

        Sanctum::actingAs($owner);
        $created = $this->postJson("/api/v1/trips/{$trip->id}/invitations", [
            'proposed_role' => 'viewer',
        ])->assertCreated();
        $rawToken = (string) $created->json('data.invite_token');

        // Public safe preview (unauthenticated)
        auth()->forgetGuards();
        $preview = $this->getJson("/api/v1/invitations/{$rawToken}");

        $preview
            ->assertOk()
            ->assertJsonPath('data.trip_title', 'Tokyo Food Tour')
            ->assertJsonPath('data.destination_country', 'Japan')
            ->assertJsonPath('data.proposed_role', 'viewer')
            ->assertJsonPath('data.inviter_name', 'Maya Host')
            ->assertJsonPath('data.status', 'active');

        $payload = json_encode($preview->json());
        $this->assertStringNotContainsString('2026-12-01', (string) $payload);
        $this->assertStringNotContainsString('Secret Dinner Spot', (string) $payload);
        $this->assertStringNotContainsString('Private Residence Address', (string) $payload);
        $this->assertStringNotContainsString('secret@example.com', (string) $payload);

        // Previewing must not grant trip access to a guest
        Sanctum::actingAs($guest);
        $this->getJson("/api/v1/trips/{$trip->id}")->assertForbidden();
    }

    public function test_accepting_invitation_admits_traveler_and_records_activity_feed_event(): void
    {
        $owner = User::factory()->create(['display_name' => 'Organizer Sam']);
        $companion = User::factory()->create(['display_name' => 'Traveler Bea']);
        $trip = Trip::factory()->create(['owner_id' => $owner->id, 'title' => 'Seoul Autumn']);

        Sanctum::actingAs($owner);
        $invite = $this->postJson("/api/v1/trips/{$trip->id}/invitations", [
            'proposed_role' => 'viewer',
        ])->assertCreated();
        $rawToken = (string) $invite->json('data.invite_token');

        Sanctum::actingAs($companion);
        $accept = $this->postJson("/api/v1/invitations/{$rawToken}/accept");

        $accept
            ->assertOk()
            ->assertJsonPath('data.already_member', false)
            ->assertJsonPath('data.trip.id', $trip->id)
            ->assertJsonPath('data.trip.role', 'viewer')
            ->assertJsonPath('data.member.display_name', 'Traveler Bea')
            ->assertJsonPath('data.member.role', 'viewer');

        // Trip appears in companion's trips list
        $this->getJson('/api/v1/trips')
            ->assertOk()
            ->assertJsonPath('data.0.id', $trip->id)
            ->assertJsonPath('data.0.role', 'viewer');

        // Activity feed reflects safe member_joined event
        $this->getJson("/api/v1/trips/{$trip->id}/feed")
            ->assertOk()
            ->assertJsonPath('data.0.event_type', 'member_joined')
            ->assertJsonPath('data.0.title', 'Traveler Bea joined the trip circle');

        // Viewer can read members, but cannot mutate itinerary items
        $this->getJson("/api/v1/trips/{$trip->id}/members")
            ->assertOk()
            ->assertJsonCount(2, 'data');

        $this->postJson("/api/v1/trips/{$trip->id}/itinerary-items", [
            'title' => 'Unauthorized Edit',
        ])->assertForbidden();
    }

    public function test_accepting_same_invitation_twice_is_idempotent_and_respects_max_uses(): void
    {
        $owner = User::factory()->create();
        $companionA = User::factory()->create();
        $companionB = User::factory()->create();
        $trip = Trip::factory()->create(['owner_id' => $owner->id]);

        Sanctum::actingAs($owner);
        $invite = $this->postJson("/api/v1/trips/{$trip->id}/invitations", [
            'proposed_role' => 'editor',
            'max_uses' => 1,
        ])->assertCreated();
        $rawToken = (string) $invite->json('data.invite_token');

        // First accept succeeds
        Sanctum::actingAs($companionA);
        $this->postJson("/api/v1/invitations/{$rawToken}/accept")
            ->assertOk()
            ->assertJsonPath('data.already_member', false);

        // Retry by same user is idempotent
        $this->postJson("/api/v1/invitations/{$rawToken}/accept")
            ->assertOk()
            ->assertJsonPath('data.already_member', true);

        // Second user gets rejected since max_uses=1 is exhausted
        Sanctum::actingAs($companionB);
        $this->postJson("/api/v1/invitations/{$rawToken}/accept")
            ->assertUnprocessable();
    }

    public function test_expired_revoked_and_malformed_invitations_fail_safely(): void
    {
        $owner = User::factory()->create();
        $guest = User::factory()->create();
        $trip = Trip::factory()->create(['owner_id' => $owner->id]);

        $revokedToken = bin2hex(random_bytes(16));
        TripInvitation::factory()->create([
            'trip_id' => $trip->id,
            'inviter_id' => $owner->id,
            'token_hash' => hash('sha256', $revokedToken),
            'status' => 'revoked',
            'revoked_at' => now(),
        ]);

        $expiredToken = bin2hex(random_bytes(16));
        TripInvitation::factory()->create([
            'trip_id' => $trip->id,
            'inviter_id' => $owner->id,
            'token_hash' => hash('sha256', $expiredToken),
            'status' => 'active',
            'expires_at' => now()->subMinute(),
        ]);

        Sanctum::actingAs($guest);

        $this->postJson("/api/v1/invitations/{$revokedToken}/accept")->assertUnprocessable();
        $this->postJson("/api/v1/invitations/{$expiredToken}/accept")->assertUnprocessable();
        $this->getJson('/api/v1/invitations/nonexistent-token-123')->assertNotFound();
        $this->postJson('/api/v1/invitations/nonexistent-token-123/accept')->assertNotFound();
    }

    public function test_organizer_updates_member_role_removes_member_and_rejoin_restores_soft_deleted_row(): void
    {
        $owner = User::factory()->create();
        $companion = User::factory()->create(['display_name' => 'Companion Kai']);
        $trip = Trip::factory()->create(['owner_id' => $owner->id]);

        Sanctum::actingAs($owner);
        $invite1 = $this->postJson("/api/v1/trips/{$trip->id}/invitations", ['proposed_role' => 'viewer'])->assertCreated();

        Sanctum::actingAs($companion);
        $joined = $this->postJson("/api/v1/invitations/{$invite1->json('data.invite_token')}/accept")->assertOk();
        $memberId = (string) $joined->json('data.member.id');

        // Promote viewer -> editor
        Sanctum::actingAs($owner);
        $this->patchJson("/api/v1/trips/{$trip->id}/members/{$memberId}", ['role' => 'editor'])
            ->assertOk()
            ->assertJsonPath('data.role', 'editor');

        // Companion now has editor write permission
        Sanctum::actingAs($companion);
        $this->postJson("/api/v1/trips/{$trip->id}/itinerary-items", ['title' => 'Editor Stop'])
            ->assertCreated();

        // Owner removes companion
        Sanctum::actingAs($owner);
        $this->deleteJson("/api/v1/trips/{$trip->id}/members/{$memberId}")
            ->assertNoContent();
        $this->assertSoftDeleted('trip_members', ['id' => $memberId]);

        // Removed companion immediately loses all access
        Sanctum::actingAs($companion);
        $this->getJson("/api/v1/trips/{$trip->id}")->assertForbidden();
        $this->getJson("/api/v1/trips/{$trip->id}/feed")->assertForbidden();
        $this->getJson('/api/v1/trips')->assertOk()->assertJsonCount(0, 'data');

        // Re-invite restores soft-deleted member cleanly without unique constraint conflict
        Sanctum::actingAs($owner);
        $invite2 = $this->postJson("/api/v1/trips/{$trip->id}/invitations", ['proposed_role' => 'viewer'])->assertCreated();

        Sanctum::actingAs($companion);
        $rejoined = $this->postJson("/api/v1/invitations/{$invite2->json('data.invite_token')}/accept");
        $rejoined->assertOk()->assertJsonPath('data.member.id', $memberId)->assertJsonPath('data.member.role', 'viewer');

        $this->getJson("/api/v1/trips/{$trip->id}")->assertOk();
    }

    public function test_companion_can_leave_circle_while_sole_organizer_cannot_leave(): void
    {
        $owner = User::factory()->create();
        $companion = User::factory()->create();
        $trip = Trip::factory()->create(['owner_id' => $owner->id]);

        /** @var TripMember $ownerMember */
        $ownerMember = $trip->members()->where('user_id', $owner->id)->firstOrFail();
        $companionMember = TripMember::factory()->create([
            'trip_id' => $trip->id,
            'user_id' => $companion->id,
            'role' => 'editor',
        ]);

        // Companion leaves on their own
        Sanctum::actingAs($companion);
        $this->deleteJson("/api/v1/trips/{$trip->id}/members/{$companionMember->id}")->assertNoContent();
        $this->getJson("/api/v1/trips/{$trip->id}")->assertForbidden();

        // Sole organizer cannot leave
        Sanctum::actingAs($owner);
        $this->deleteJson("/api/v1/trips/{$trip->id}/members/{$ownerMember->id}")->assertUnprocessable();
    }

    public function test_pending_and_declined_membership_records_grant_zero_trip_access(): void
    {
        $owner = User::factory()->create();
        $pendingUser = User::factory()->create();
        $trip = Trip::factory()->create(['owner_id' => $owner->id]);

        TripMember::factory()->create([
            'trip_id' => $trip->id,
            'user_id' => $pendingUser->id,
            'role' => 'editor',
            'invitation_status' => 'pending',
        ]);

        Sanctum::actingAs($pendingUser);

        $this->getJson('/api/v1/trips')->assertOk()->assertJsonCount(0, 'data');
        $this->getJson("/api/v1/trips/{$trip->id}")->assertForbidden();
        $this->getJson("/api/v1/trips/{$trip->id}/feed")->assertForbidden();
    }
}

