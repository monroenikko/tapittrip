<?php

declare(strict_types=1);

namespace Tests\Feature;

use App\Models\Checklist;
use App\Models\ChecklistItem;
use App\Models\ItineraryItem;
use App\Models\Stay;
use App\Models\Trip;
use App\Models\TripInvitation;
use App\Models\TripMember;
use App\Models\User;
use App\Models\UserBlock;
use Illuminate\Foundation\Testing\DatabaseTransactions;
use Illuminate\Support\Str;
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
        $this->getJson("/api/v1/trips/{$trip->id}/journal")->assertForbidden();
        $this->postJson("/api/v1/trips/{$trip->id}/journal", [
            'title' => 'Blocked Reflection',
            'content' => 'Should not work while pending',
            'entry_date' => '2026-12-02',
        ])->assertForbidden();
    }

    public function test_organizer_can_send_direct_invitation_by_friend_code_with_idempotent_retries_and_no_enumeration(): void
    {
        $owner = User::factory()->create(['display_name' => 'Host Kim', 'friend_code' => 'TRP-HOST11']);
        $companion = User::factory()->create([
            'display_name' => 'Companion Leo',
            'email' => 'hidden-leo@example.com',
            'friend_code' => 'TRP-LEO222',
            'accepts_direct_invites' => true,
        ]);
        $optedOut = User::factory()->create([
            'friend_code' => 'TRP-OPT333',
            'accepts_direct_invites' => false,
        ]);

        $trip = Trip::factory()->create(['owner_id' => $owner->id, 'title' => 'Seoul Autumn']);

        Sanctum::actingAs($owner);

        // Nonexistent code, self-invite, and opted-out user all return identical safe validation error (TC-2.3)
        $unknownResp = $this->postJson("/api/v1/trips/{$trip->id}/invitations/direct", [
            'friend_code' => 'TRP-ZZZZZZ',
            'proposed_role' => 'editor',
        ])->assertUnprocessable();

        $selfResp = $this->postJson("/api/v1/trips/{$trip->id}/invitations/direct", [
            'friend_code' => 'TRP-HOST11',
        ])->assertUnprocessable();

        $optedOutResp = $this->postJson("/api/v1/trips/{$trip->id}/invitations/direct", [
            'friend_code' => 'TRP-OPT333',
        ])->assertUnprocessable();

        $this->assertSame(
            $unknownResp->json('error.details.fields.friend_code'),
            $optedOutResp->json('error.details.fields.friend_code'),
        );
        $this->assertSame(
            $unknownResp->json('error.details.fields.friend_code'),
            $selfResp->json('error.details.fields.friend_code'),
        );

        // Send targeted invite by exact lowercase/trimmed friend code
        $first = $this->postJson("/api/v1/trips/{$trip->id}/invitations/direct", [
            'friend_code' => ' trp-leo222 ',
            'proposed_role' => 'editor',
        ]);

        $first->assertCreated()
            ->assertJsonPath('data.invite_type', 'direct')
            ->assertJsonPath('data.target_display_name', 'Companion Leo')
            ->assertJsonPath('data.proposed_role', 'editor')
            ->assertJsonPath('data.status', 'pending')
            ->assertJsonPath('data.already_pending', false);

        $inviteId = (string) $first->json('data.id');

        // Retrying same targeted invite returns idempotent existing pending invite without duplication
        $retry = $this->postJson("/api/v1/trips/{$trip->id}/invitations/direct", [
            'friend_code' => 'TRP-LEO222',
            'proposed_role' => 'editor',
        ]);

        $retry->assertOk()
            ->assertJsonPath('data.id', $inviteId)
            ->assertJsonPath('data.already_pending', true);

        $this->assertSame(1, TripInvitation::query()->where('trip_id', $trip->id)->count());

        // Organizer list omits recipient email/friend_code
        $list = $this->getJson("/api/v1/trips/{$trip->id}/invitations")->assertOk();
        $this->assertArrayNotHasKey('email', $list->json('data.0'));
        $this->assertArrayNotHasKey('friend_code', $list->json('data.0'));
        $this->assertArrayNotHasKey('token_hash', $list->json('data.0'));
    }

    public function test_direct_invitation_inbox_accept_decline_block_and_recipient_isolation(): void
    {
        $owner = User::factory()->create(['display_name' => 'Host Maya']);
        $recipient = User::factory()->create(['display_name' => 'Traveler Kai']);
        $stranger = User::factory()->create(['display_name' => 'Intruder']);

        $trip = Trip::factory()->create([
            'owner_id' => $owner->id,
            'title' => 'Lisbon Coast',
            'destination_country' => 'PT',
            'start_date' => '2026-12-10',
            'end_date' => '2026-12-16',
        ]);

        Sanctum::actingAs($owner);
        $sent = $this->postJson("/api/v1/trips/{$trip->id}/invitations/direct", [
            'friend_code' => $recipient->friend_code,
            'proposed_role' => 'viewer',
        ])->assertCreated();
        $inviteId = (string) $sent->json('data.id');

        // Pending direct invite grants zero trip access before explicit acceptance (TC-1.6, TC-2.2)
        Sanctum::actingAs($recipient);
        $this->getJson("/api/v1/trips/{$trip->id}")->assertForbidden();

        // Stranger cannot see or redeem another user's direct invitation (TC-2.2)
        Sanctum::actingAs($stranger);
        $this->getJson('/api/v1/me/invitations')->assertOk()->assertJsonCount(0, 'data');
        $this->postJson("/api/v1/me/invitations/{$inviteId}/accept")->assertForbidden();
        $this->postJson("/api/v1/me/invitations/{$inviteId}/decline")->assertForbidden();

        // Target views minimal safe inbox payload without dates/stays leaked
        Sanctum::actingAs($recipient);
        $inbox = $this->getJson('/api/v1/me/invitations')->assertOk()->assertJsonCount(1, 'data');
        $inboxItem = $inbox->json('data.0');
        $this->assertSame('Lisbon Coast', $inboxItem['trip_title']);
        $this->assertArrayNotHasKey('start_date', $inboxItem);
        $this->assertArrayNotHasKey('end_date', $inboxItem);

        // Recipient declines and blocks sender (TC-2.3, TC-2.4)
        $this->postJson("/api/v1/me/invitations/{$inviteId}/decline", [
            'block_sender' => true,
        ])->assertOk()->assertJsonPath('data.status', 'declined');

        // Declined invite cannot later grant access (TC-2.4)
        $this->postJson("/api/v1/me/invitations/{$inviteId}/accept")->assertUnprocessable();
        $this->getJson("/api/v1/trips/{$trip->id}")->assertForbidden();

        // Organizer is blocked silently with the same safe generic validation error
        Sanctum::actingAs($owner);
        $this->postJson("/api/v1/trips/{$trip->id}/invitations/direct", [
            'friend_code' => $recipient->friend_code,
        ])->assertUnprocessable();

        // Unblock and verify acceptance joins once and emits activity feed
        UserBlock::query()->where('blocker_id', $recipient->id)->delete();

        $sent2 = $this->postJson("/api/v1/trips/{$trip->id}/invitations/direct", [
            'friend_code' => $recipient->friend_code,
            'proposed_role' => 'editor',
        ])->assertCreated();
        $invite2Id = (string) $sent2->json('data.id');

        Sanctum::actingAs($recipient);
        $this->postJson("/api/v1/me/invitations/{$invite2Id}/accept")
            ->assertOk()
            ->assertJsonPath('data.already_member', false)
            ->assertJsonPath('data.member.role', 'editor');

        // Idempotent retry on already-accepted direct invitation
        $this->postJson("/api/v1/me/invitations/{$invite2Id}/accept")
            ->assertOk()
            ->assertJsonPath('data.already_member', true);

        $this->assertSame(2, TripMember::query()->where('trip_id', $trip->id)->where('invitation_status', 'accepted')->count());
        $this->getJson("/api/v1/trips/{$trip->id}/feed")->assertOk()->assertJsonPath('data.0.event_type', 'member_joined');
    }

    public function test_explicit_two_party_ownership_transfer_and_concurrency_invariants(): void
    {
        $owner = User::factory()->create(['display_name' => 'Original Organizer']);
        $editor = User::factory()->create(['display_name' => 'Successor Companion']);
        $viewer = User::factory()->create(['display_name' => 'Passive Viewer']);
        $stranger = User::factory()->create();

        $trip = Trip::factory()->create(['owner_id' => $owner->id, 'title' => 'Alps Crossing']);
        $editorMember = TripMember::factory()->create([
            'trip_id' => $trip->id,
            'user_id' => $editor->id,
            'role' => 'editor',
        ]);
        TripMember::factory()->create([
            'trip_id' => $trip->id,
            'user_id' => $viewer->id,
            'role' => 'viewer',
        ]);

        // Non-owners cannot view or initiate ownership transfer
        Sanctum::actingAs($editor);
        $this->postJson("/api/v1/trips/{$trip->id}/ownership-transfer", [
            'target_member_id' => $editorMember->id,
        ])->assertForbidden();

        // Organizer initiates handover with former_owner_role = viewer
        Sanctum::actingAs($owner);
        $created = $this->postJson("/api/v1/trips/{$trip->id}/ownership-transfer", [
            'target_member_id' => $editorMember->id,
            'former_owner_role' => 'viewer',
        ]);
        $created->assertCreated()
            ->assertJsonPath('data.status', 'pending')
            ->assertJsonPath('data.former_owner_role', 'viewer')
            ->assertJsonPath('data.already_pending', false);

        $transferId = (string) $created->json('data.id');

        // Retrying same request is idempotent
        $this->postJson("/api/v1/trips/{$trip->id}/ownership-transfer", [
            'target_member_id' => $editorMember->id,
            'former_owner_role' => 'viewer',
        ])->assertOk()->assertJsonPath('data.id', $transferId)->assertJsonPath('data.already_pending', true);

        // Stranger cannot accept
        Sanctum::actingAs($stranger);
        $this->postJson("/api/v1/me/ownership-transfers/{$transferId}/accept")->assertForbidden();

        // Recipient declines, leaving owner unchanged
        Sanctum::actingAs($editor);
        $this->getJson('/api/v1/me/ownership-transfers')->assertOk()->assertJsonCount(1, 'data');
        $this->postJson("/api/v1/me/ownership-transfers/{$transferId}/decline")
            ->assertOk()
            ->assertJsonPath('data.status', 'declined');

        $trip->refresh();
        $this->assertSame($owner->id, $trip->owner_id);

        // Organizer re-initiates handover and recipient accepts (TC-3.3)
        Sanctum::actingAs($owner);
        $second = $this->postJson("/api/v1/trips/{$trip->id}/ownership-transfer", [
            'target_member_id' => $editorMember->id,
            'former_owner_role' => 'editor',
        ])->assertCreated();
        $transfer2Id = (string) $second->json('data.id');

        Sanctum::actingAs($editor);
        $accepted = $this->postJson("/api/v1/me/ownership-transfers/{$transfer2Id}/accept");
        $accepted->assertOk()
            ->assertJsonPath('data.trip.owner_id', $editor->id)
            ->assertJsonPath('data.transfer.status', 'accepted');

        // Retry acceptance is idempotent and leaves exactly one owner
        $this->postJson("/api/v1/me/ownership-transfers/{$transfer2Id}/accept")
            ->assertOk()
            ->assertJsonPath('data.transfer.status', 'accepted');

        $this->assertSame(
            1,
            TripMember::query()->where('trip_id', $trip->id)->where('role', 'owner')->count()
        );
        $this->assertDatabaseHas('trips', [
            'id' => $trip->id,
            'owner_id' => $editor->id,
        ]);
        $this->assertDatabaseHas('trip_members', [
            'trip_id' => $trip->id,
            'user_id' => $owner->id,
            'role' => 'editor',
        ]);

        // Former owner can no longer delete trip or manage circle roles, and can now leave voluntarily
        Sanctum::actingAs($owner);
        $this->deleteJson("/api/v1/trips/{$trip->id}")->assertForbidden();
        $formerMember = TripMember::query()->where('trip_id', $trip->id)->where('user_id', $owner->id)->firstOrFail();
        $this->deleteJson("/api/v1/trips/{$trip->id}/members/{$formerMember->id}")->assertNoContent();
    }

    public function test_account_deletion_blocks_shared_trip_owners_until_transfer_or_deletion_and_allows_solo_cleanup(): void
    {
        $owner = User::factory()->create();
        $companion = User::factory()->create();

        $sharedTrip = Trip::factory()->create(['owner_id' => $owner->id, 'title' => 'Shared Safari']);
        $soloTrip = Trip::factory()->create(['owner_id' => $owner->id, 'title' => 'Solo Retreat']);

        $companionMember = TripMember::factory()->create([
            'trip_id' => $sharedTrip->id,
            'user_id' => $companion->id,
            'role' => 'editor',
        ]);

        Sanctum::actingAs($owner);

        // Deleting account while owning a trip with active companions is blocked (TC-3.4)
        $this->deleteJson('/api/v1/me')
            ->assertUnprocessable()
            ->assertJsonPath('error.code', 'validation_failed');

        $this->assertDatabaseHas('users', ['id' => $owner->id, 'deleted_at' => null]);

        // Transfer ownership of the shared trip to companion
        $transfer = $this->postJson("/api/v1/trips/{$sharedTrip->id}/ownership-transfer", [
            'target_member_id' => $companionMember->id,
            'former_owner_role' => 'viewer',
        ])->assertCreated();

        Sanctum::actingAs($companion);
        $this->postJson("/api/v1/me/ownership-transfers/{$transfer->json('data.id')}/accept")->assertOk();

        // Now former owner only owns their solo trip and is a companion on sharedTrip -> deletion succeeds & cleans up solo trip
        Sanctum::actingAs($owner);
        $this->deleteJson('/api/v1/me')->assertNoContent();

        $this->assertSoftDeleted('users', ['id' => $owner->id]);
        $this->assertSoftDeleted('trips', ['id' => $soloTrip->id]);
        $this->assertDatabaseHas('trips', [
            'id' => $sharedTrip->id,
            'owner_id' => $companion->id,
            'deleted_at' => null,
        ]);
    }

    public function test_viewer_restrictions_and_stale_sync_rejection_on_downgrade_or_removal(): void
    {
        $owner = User::factory()->create();
        $traveler = User::factory()->create();
        $trip = Trip::factory()->create(['owner_id' => $owner->id]);

        $member = TripMember::factory()->create([
            'trip_id' => $trip->id,
            'user_id' => $traveler->id,
            'role' => 'viewer',
        ]);

        $checklist = Checklist::factory()->create(['trip_id' => $trip->id]);
        $checklistItem = ChecklistItem::factory()->create([
            'checklist_id' => $checklist->id,
            'trip_id' => $trip->id,
            'title' => 'Passport',
            'version' => 1,
        ]);

        // Viewer can read, cannot mutate trip/itinerary/stay/checklist/sync (TC-3.1)
        Sanctum::actingAs($traveler);
        $this->getJson("/api/v1/trips/{$trip->id}")->assertOk();
        $this->patchJson("/api/v1/trips/{$trip->id}", ['title' => 'Hijacked'])->assertForbidden();
        $this->postJson("/api/v1/trips/{$trip->id}/itinerary-items", ['title' => 'Unauthorized Stop'])->assertForbidden();
        $this->postJson("/api/v1/trips/{$trip->id}/stays", ['name' => 'Unauthorized Stay', 'stay_type' => 'hotel'])->assertForbidden();
        $this->postJson("/api/v1/trips/{$trip->id}/checklists", ['title' => 'Unauthorized List'])->assertForbidden();

        // Viewer sync push is rejected with reason and leaves server untouched
        $op1 = (string) Str::uuid();
        $this->postJson('/api/v1/sync/push', [
            'device_key' => 'viewer-device',
            'operations' => [[
                'operation_id' => $op1,
                'trip_id' => $trip->id,
                'entity_type' => 'checklist_item',
                'entity_id' => $checklistItem->id,
                'operation_type' => 'update',
                'base_version' => 1,
                'payload' => ['title' => 'Hacked Passport'],
            ]],
        ])->assertOk()
            ->assertJsonPath('data.results.0.operation_id', $op1)
            ->assertJsonPath('data.results.0.status', 'rejected');

        $checklistItem->refresh();
        $this->assertSame('Passport', $checklistItem->title);

        // Promote to editor -> push succeeds -> downgrade -> queued offline push rejects & removal hides global pull (TC-3.2)
        Sanctum::actingAs($owner);
        $this->patchJson("/api/v1/trips/{$trip->id}/members/{$member->id}", ['role' => 'editor'])->assertOk();

        Sanctum::actingAs($traveler);
        $op2 = (string) Str::uuid();
        $this->postJson('/api/v1/sync/push', [
            'device_key' => 'editor-device',
            'operations' => [[
                'operation_id' => $op2,
                'trip_id' => $trip->id,
                'entity_type' => 'checklist_item',
                'entity_id' => $checklistItem->id,
                'operation_type' => 'update',
                'base_version' => 1,
                'payload' => ['title' => 'Passport & Boarding Pass'],
            ]],
        ])->assertOk()->assertJsonPath('data.results.0.status', 'accepted');

        // Downgrade to viewer while offline edit is queued
        Sanctum::actingAs($owner);
        $this->patchJson("/api/v1/trips/{$trip->id}/members/{$member->id}", ['role' => 'viewer'])->assertOk();

        Sanctum::actingAs($traveler);
        $op3 = (string) Str::uuid();
        $this->postJson('/api/v1/sync/push', [
            'device_key' => 'editor-device',
            'operations' => [[
                'operation_id' => $op3,
                'trip_id' => $trip->id,
                'entity_type' => 'checklist_item',
                'entity_id' => $checklistItem->id,
                'operation_type' => 'update',
                'base_version' => 2,
                'payload' => ['title' => 'Stale Downgraded Edit'],
            ]],
        ])->assertOk()
            ->assertJsonPath('data.results.0.status', 'rejected')
            ->assertJsonPath('data.results.0.conflict_details.reason', 'Unauthorized trip membership or insufficient permissions');

        // Global sync pull includes trip op while still a viewer member
        $this->getJson('/api/v1/sync/pull?device_key=editor-device&cursor=0')
            ->assertOk()
            ->assertJsonFragment(['operation_id' => $op2]);

        // Removing member revokes global pull access to previously touched trip records
        Sanctum::actingAs($owner);
        $this->deleteJson("/api/v1/trips/{$trip->id}/members/{$member->id}")->assertNoContent();

        Sanctum::actingAs($traveler);
        $this->getJson('/api/v1/sync/pull?device_key=editor-device&cursor=0')
            ->assertOk()
            ->assertJsonMissing(['operation_id' => $op2]);
    }

    public function test_friend_code_regeneration_invalidates_prior_code(): void
    {
        $owner = User::factory()->create();
        $target = User::factory()->create();
        $trip = Trip::factory()->create(['owner_id' => $owner->id]);

        $oldCode = (string) $target->friend_code;

        Sanctum::actingAs($target);
        $regen = $this->postJson('/api/v1/me/friend-code/regenerate')->assertOk();
        $newCode = (string) $regen->json('data.friend_code');

        $this->assertNotEmpty($newCode);
        $this->assertNotSame($oldCode, $newCode);
        $this->assertStringStartsWith('TRP-', $newCode);

        // Old friend code no longer delivers direct invites
        Sanctum::actingAs($owner);
        $this->postJson("/api/v1/trips/{$trip->id}/invitations/direct", [
            'friend_code' => $oldCode,
        ])->assertUnprocessable();

        $this->postJson("/api/v1/trips/{$trip->id}/invitations/direct", [
            'friend_code' => $newCode,
        ])->assertCreated();
    }
}
