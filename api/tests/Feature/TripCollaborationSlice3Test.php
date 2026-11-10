<?php

declare(strict_types=1);

namespace Tests\Feature;

use App\Models\ActivityEvent;
use App\Models\ItineraryItem;
use App\Models\NotificationPreference;
use App\Models\Reminder;
use App\Models\Stay;
use App\Models\Trip;
use App\Models\TripDay;
use App\Models\TripMember;
use App\Models\TripNotification;
use App\Models\User;
use Carbon\CarbonImmutable;
use Illuminate\Foundation\Testing\DatabaseTransactions;
use Illuminate\Support\Str;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

final class TripCollaborationSlice3Test extends TestCase
{
    use DatabaseTransactions;

    public function test_tc4_1_authorized_editor_changes_propagate_without_duplication(): void
    {
        $owner = User::factory()->create(['display_name' => 'Owner Maya']);
        $editor = User::factory()->create(['display_name' => 'Editor Ken']);

        $trip = Trip::factory()->create([
            'owner_id' => $owner->id,
            'title' => 'Osaka Food Run',
            'primary_timezone' => 'Asia/Tokyo',
        ]);
        TripMember::factory()->create([
            'trip_id' => $trip->id,
            'user_id' => $editor->id,
            'role' => 'editor',
            'invitation_status' => 'accepted',
        ]);

        $day = TripDay::factory()->create([
            'trip_id' => $trip->id,
            'local_date' => '2026-12-02',
        ]);

        $item = ItineraryItem::factory()->create([
            'trip_id' => $trip->id,
            'trip_day_id' => $day->id,
            'title' => 'Kuromon Market',
            'sort_order' => 0,
            'version' => 1,
        ]);

        Sanctum::actingAs($editor);
        $patchRes = $this->patchJson("/api/v1/itinerary-items/{$item->id}", [
            'title' => 'Kuromon Market Breakfast',
            'base_version' => 1,
        ]);

        $patchRes->assertOk()
            ->assertJsonPath('data.title', 'Kuromon Market Breakfast')
            ->assertJsonPath('data.version', 2);

        Sanctum::actingAs($owner);
        $listRes = $this->getJson("/api/v1/trips/{$trip->id}/itinerary-items");
        $listRes->assertOk();

        $this->assertCount(1, $listRes->json('data'));
        $this->assertSame('Kuromon Market Breakfast', $listRes->json('data.0.title'));
        $this->assertSame(1, Trip::where('id', $trip->id)->count());
    }

    public function test_tc4_2_offline_sync_itinerary_and_stay_operations_are_idempotent_and_isolated(): void
    {
        $owner = User::factory()->create();
        $editor = User::factory()->create();

        $tripA = Trip::factory()->create(['owner_id' => $owner->id, 'primary_timezone' => 'Asia/Tokyo']);
        $tripB = Trip::factory()->create(['owner_id' => $owner->id, 'primary_timezone' => 'Asia/Tokyo']);

        TripMember::factory()->create([
            'trip_id' => $tripA->id,
            'user_id' => $editor->id,
            'role' => 'editor',
            'invitation_status' => 'accepted',
        ]);

        $dayA = TripDay::factory()->create(['trip_id' => $tripA->id, 'local_date' => '2026-12-05']);
        $itemB = ItineraryItem::factory()->create(['trip_id' => $tripB->id, 'title' => 'Other Trip Item', 'version' => 1]);
        $stayA = Stay::factory()->create([
            'trip_id' => $tripA->id,
            'name' => 'Cross Hotel',
            'stay_type' => 'hotel',
            'timezone' => 'Asia/Tokyo',
            'version' => 1,
        ]);

        $newItemId = (string) Str::uuid();
        $opCreateId = (string) Str::uuid();
        $opStayUpdateId = (string) Str::uuid();
        $opCrossTripId = (string) Str::uuid();

        Sanctum::actingAs($editor);
        $payload = [
            'device_key' => 'ios-editor-1',
            'operations' => [
                [
                    'operation_id' => $opCreateId,
                    'trip_id' => $tripA->id,
                    'entity_type' => 'itinerary_item',
                    'entity_id' => $newItemId,
                    'operation_type' => 'create',
                    'base_version' => 1,
                    'payload' => [
                        'trip_day_id' => $dayA->id,
                        'kind' => 'meal',
                        'title' => 'Dotonbori Takoyaki',
                        'starts_at_utc' => '2026-12-05T10:00:00Z',
                        'ends_at_utc' => '2026-12-05T11:30:00Z',
                        'timezone' => 'Asia/Tokyo',
                        'sort_order' => 0,
                        'status' => 'planned',
                    ],
                ],
                [
                    'operation_id' => $opStayUpdateId,
                    'trip_id' => $tripA->id,
                    'entity_type' => 'stay',
                    'entity_id' => $stayA->id,
                    'operation_type' => 'update',
                    'base_version' => 1,
                    'payload' => [
                        'name' => 'Cross Hotel Osaka',
                        'check_in_at' => '2026-12-05T06:00:00Z',
                        'timezone' => 'Asia/Tokyo',
                    ],
                ],
                [
                    'operation_id' => $opCrossTripId,
                    'trip_id' => $tripA->id,
                    'entity_type' => 'itinerary_item',
                    'entity_id' => $itemB->id,
                    'operation_type' => 'update',
                    'base_version' => 1,
                    'payload' => ['title' => 'Tampered'],
                ],
            ],
        ];

        $pushRes = $this->postJson('/api/v1/sync/push', $payload);
        $pushRes->assertOk()
            ->assertJsonPath('data.results.0.status', 'accepted')
            ->assertJsonPath('data.results.1.status', 'accepted')
            ->assertJsonPath('data.results.2.status', 'rejected');

        // Re-pushing identical client operation_ids is idempotent without duplicate rows
        $retryRes = $this->postJson('/api/v1/sync/push', $payload);
        $retryRes->assertOk()
            ->assertJsonPath('data.results.0.status', 'accepted')
            ->assertJsonPath('data.results.1.status', 'accepted');

        $this->assertSame(1, ItineraryItem::where('id', $newItemId)->count());
        $this->assertSame('Dotonbori Takoyaki', ItineraryItem::findOrFail($newItemId)->title);
        $this->assertSame('Cross Hotel Osaka', $stayA->fresh()->name);
        $this->assertSame('Other Trip Item', $itemB->fresh()->title);

        Sanctum::actingAs($owner);
        $pullRes = $this->getJson("/api/v1/sync/pull?device_key=owner-device-1&trip_id={$tripA->id}&cursor=0");
        $pullRes->assertOk();
        $this->assertGreaterThanOrEqual(2, count($pullRes->json('data.operations')));
    }

    public function test_tc4_3_concurrent_itinerary_reorder_and_stay_edits_detect_version_conflicts(): void
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

        $item1 = ItineraryItem::factory()->create(['trip_id' => $trip->id, 'title' => 'Fushimi Inari', 'sort_order' => 0, 'version' => 1]);
        $item2 = ItineraryItem::factory()->create(['trip_id' => $trip->id, 'title' => 'Kiyomizu-dera', 'sort_order' => 1, 'version' => 1]);
        $stay = Stay::factory()->create(['trip_id' => $trip->id, 'name' => 'Gion Ryokan', 'version' => 1]);

        // Owner updates item1 (v1 -> v2)
        Sanctum::actingAs($owner);
        $this->patchJson("/api/v1/itinerary-items/{$item1->id}", [
            'title' => 'Fushimi Inari Early Walk',
            'base_version' => 1,
        ])->assertOk()->assertJsonPath('data.version', 2);

        // Editor tries PATCH with stale base_version=1 -> 409 version_conflict
        Sanctum::actingAs($editor);
        $conflictPatch = $this->patchJson("/api/v1/itinerary-items/{$item1->id}", [
            'title' => 'Late Evening Walk',
            'base_version' => 1,
        ]);

        $conflictPatch->assertStatus(409)
            ->assertJsonPath('error.code', 'version_conflict')
            ->assertJsonPath('error.details.server_version', 2)
            ->assertJsonPath('error.details.server_payload.title', 'Fushimi Inari Early Walk');
        $this->assertSame('Fushimi Inari Early Walk', $item1->fresh()->title);

        // Editor tries reorder with stale expected_versions for item1 -> 409
        $conflictReorder = $this->postJson("/api/v1/trips/{$trip->id}/itinerary-items/reorder", [
            'item_ids' => [$item2->id, $item1->id],
            'expected_versions' => [
                $item1->id => 1,
                $item2->id => 1,
            ],
        ]);

        $conflictReorder->assertStatus(409)
            ->assertJsonPath('error.code', 'version_conflict')
            ->assertJsonPath('error.details.server_version', 2);
        $this->assertSame(0, $item1->fresh()->sort_order);

        // Retrying reorder with fresh versions succeeds
        $this->postJson("/api/v1/trips/{$trip->id}/itinerary-items/reorder", [
            'item_ids' => [$item2->id, $item1->id],
            'expected_versions' => [
                $item1->id => 2,
                $item2->id => 1,
            ],
        ])->assertOk();
        $this->assertSame(0, $item2->fresh()->sort_order);
        $this->assertSame(1, $item1->fresh()->sort_order);

        // Stay REST version conflict
        Sanctum::actingAs($owner);
        $this->patchJson("/api/v1/stays/{$stay->id}", [
            'name' => 'Gion Ryokan Deluxe',
            'base_version' => 1,
        ])->assertOk()->assertJsonPath('data.version', 2);

        Sanctum::actingAs($editor);
        $this->patchJson("/api/v1/stays/{$stay->id}", [
            'name' => 'Stale Ryokan Rename',
            'base_version' => 1,
        ])->assertStatus(409)
            ->assertJsonPath('error.code', 'version_conflict')
            ->assertJsonPath('error.details.server_version', 2);
    }

    public function test_tc4_4_and_tc4_5_stay_privacy_redaction_and_multi_trip_isolation(): void
    {
        $owner = User::factory()->create();
        $editor = User::factory()->create();

        $sharedTrip = Trip::factory()->create(['owner_id' => $owner->id, 'title' => 'Shared Tokyo']);
        $editorOwnTrip = Trip::factory()->create(['owner_id' => $editor->id, 'title' => 'Editor Solo Trip']);

        TripMember::factory()->create([
            'trip_id' => $sharedTrip->id,
            'user_id' => $editor->id,
            'role' => 'editor',
            'invitation_status' => 'accepted',
        ]);

        $hotelStay = Stay::factory()->create([
            'trip_id' => $sharedTrip->id,
            'name' => 'Shinjuku Prince Hotel',
            'stay_type' => 'hotel',
            'address' => '1-30-1 Kabukicho, Shinjuku',
            'phone' => '+81-3-3205-1111',
            'booking_reference' => 'HOTEL-SECRET-777',
            'version' => 2,
        ]);

        $privateHomeStay = Stay::factory()->create([
            'trip_id' => $sharedTrip->id,
            'name' => 'Aunt Akiko Apartment',
            'stay_type' => 'friends_family',
            'address' => '99 Secret Lane, Setagaya',
            'latitude' => 35.646,
            'longitude' => 139.653,
            'phone' => '+81-90-1234-5678',
            'booking_reference' => 'HOST-KEY-999',
            'notes' => 'Doorbell pin 1234',
            'version' => 2,
        ]);

        $soloStay = Stay::factory()->create([
            'trip_id' => $editorOwnTrip->id,
            'name' => 'Solo Busan Hotel',
            'stay_type' => 'hotel',
            'booking_reference' => 'MY-SOLO-REF',
            'version' => 1,
        ]);

        // Owner sees full private stay fields
        Sanctum::actingAs($owner);
        $ownerStayRes = $this->getJson("/api/v1/stays/{$privateHomeStay->id}");
        $ownerStayRes->assertOk()
            ->assertJsonPath('data.booking_reference', 'HOST-KEY-999')
            ->assertJsonPath('data.phone', '+81-90-1234-5678')
            ->assertJsonPath('data.address', '99 Secret Lane, Setagaya')
            ->assertJsonPath('data.notes', 'Doorbell pin 1234');

        // Companion sees redacted hotel booking details and fully redacted friends_family address/coords/notes
        Sanctum::actingAs($editor);
        $editorStaysRes = $this->getJson("/api/v1/trips/{$sharedTrip->id}/stays");
        $editorStaysRes->assertOk();

        $staysById = collect($editorStaysRes->json('data'))->keyBy('id');
        $this->assertArrayHasKey($hotelStay->id, $staysById);
        $this->assertArrayHasKey($privateHomeStay->id, $staysById);
        $this->assertArrayNotHasKey($soloStay->id, $staysById);

        $this->assertNull($staysById[$hotelStay->id]['booking_reference']);
        $this->assertNull($staysById[$hotelStay->id]['phone']);
        $this->assertSame('1-30-1 Kabukicho, Shinjuku', $staysById[$hotelStay->id]['address']);

        $this->assertNull($staysById[$privateHomeStay->id]['booking_reference']);
        $this->assertNull($staysById[$privateHomeStay->id]['phone']);
        $this->assertNull($staysById[$privateHomeStay->id]['address']);
        $this->assertNull($staysById[$privateHomeStay->id]['latitude']);
        $this->assertNull($staysById[$privateHomeStay->id]['longitude']);
        $this->assertNull($staysById[$privateHomeStay->id]['google_maps_url']);
        $this->assertNull($staysById[$privateHomeStay->id]['notes']);

        // Conflict response against Stay also redacts private organizer fields
        $conflictStayRes = $this->patchJson("/api/v1/stays/{$privateHomeStay->id}", [
            'name' => 'Outdated Stay Rename',
            'base_version' => 1,
        ]);
        $conflictStayRes->assertStatus(409)
            ->assertJsonPath('error.details.server_payload.booking_reference', null)
            ->assertJsonPath('error.details.server_payload.phone', null)
            ->assertJsonPath('error.details.server_payload.address', null)
            ->assertJsonPath('error.details.server_payload.notes', null);

        // Sync conflict payload also redacts private organizer fields
        $syncConflictRes = $this->postJson('/api/v1/sync/push', [
            'device_key' => 'editor-phone',
            'operations' => [
                [
                    'operation_id' => (string) Str::uuid(),
                    'trip_id' => $sharedTrip->id,
                    'entity_type' => 'stay',
                    'entity_id' => $privateHomeStay->id,
                    'operation_type' => 'update',
                    'base_version' => 1,
                    'payload' => ['name' => 'Sync Rename'],
                ],
            ],
        ]);

        $syncConflictRes->assertOk()
            ->assertJsonPath('data.results.0.status', 'conflict')
            ->assertJsonPath('data.results.0.conflict_details.server_payload.booking_reference', null)
            ->assertJsonPath('data.results.0.conflict_details.server_payload.address', null);
    }

    public function test_tc5_1_organizer_announcements_work_without_push_devices_and_prevent_duplicates(): void
    {
        $owner = User::factory()->create(['display_name' => 'Leader Sam']);
        $companionNoPush = User::factory()->create(['display_name' => 'NoPush Mia']);
        $companionOptOut = User::factory()->create(['display_name' => 'Quiet Leo']);

        $trip = Trip::factory()->create([
            'owner_id' => $owner->id,
            'primary_timezone' => 'Asia/Tokyo',
        ]);
        TripMember::factory()->create([
            'trip_id' => $trip->id,
            'user_id' => $companionNoPush->id,
            'role' => 'viewer',
            'invitation_status' => 'accepted',
        ]);
        TripMember::factory()->create([
            'trip_id' => $trip->id,
            'user_id' => $companionOptOut->id,
            'role' => 'editor',
            'invitation_status' => 'accepted',
        ]);

        NotificationPreference::create([
            'user_id' => $companionOptOut->id,
            'circle_announcements_enabled' => false,
            'timezone_behavior' => 'destination',
        ]);

        // Companion without organizer role cannot post announcements
        Sanctum::actingAs($companionOptOut);
        $this->postJson("/api/v1/trips/{$trip->id}/announcements", [
            'title' => 'Unauthorized Notice',
            'body' => 'Should be forbidden',
        ])->assertForbidden();

        // Organizer posts with client_operation_id and retries idempotently
        Sanctum::actingAs($owner);
        $clientOpId = (string) Str::uuid();
        $firstPost = $this->postJson("/api/v1/trips/{$trip->id}/announcements", [
            'title' => 'Meet at Gate B',
            'body' => 'Boarding starts at 08:30 sharp.',
            'is_pinned' => true,
            'client_operation_id' => $clientOpId,
        ]);
        $firstPost->assertCreated()
            ->assertJsonPath('data.title', 'Meet at Gate B')
            ->assertJsonPath('data.is_pinned', true);
        $announcementId = (string) $firstPost->json('data.id');

        $retryPost = $this->postJson("/api/v1/trips/{$trip->id}/announcements", [
            'title' => 'Meet at Gate B',
            'body' => 'Boarding starts at 08:30 sharp.',
            'is_pinned' => true,
            'client_operation_id' => $clientOpId,
        ]);
        $retryPost->assertCreated()->assertJsonPath('data.id', $announcementId);

        // Zero duplicate notices or feed events
        $this->assertSame(1, ActivityEvent::where('entity_id', $announcementId)->count());
        $this->assertSame(1, TripNotification::where('user_id', $companionNoPush->id)->where('announcement_id', $announcementId)->count());
        $this->assertSame(0, TripNotification::where('user_id', $companionOptOut->id)->where('announcement_id', $announcementId)->count());

        // Companion with opt-out can STILL read announcements in-app (TC-5.1)
        Sanctum::actingAs($companionOptOut);
        $this->getJson("/api/v1/trips/{$trip->id}/announcements")
            ->assertOk()
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.title', 'Meet at Gate B');
        $this->getJson('/api/v1/me/notifications')
            ->assertOk()
            ->assertJsonCount(0, 'data');

        // Companion without OS push token reads announcement & receives 1 in-app notification
        Sanctum::actingAs($companionNoPush);
        $this->getJson("/api/v1/trips/{$trip->id}/announcements")
            ->assertOk()
            ->assertJsonCount(1, 'data');

        $inboxRes = $this->getJson('/api/v1/me/notifications');
        $inboxRes->assertOk()->assertJsonCount(1, 'data');
        $notifId = (string) $inboxRes->json('data.0.id');

        // Editing announcement updates notification in place without creating duplicates
        Sanctum::actingAs($owner);
        $this->patchJson("/api/v1/announcements/{$announcementId}", [
            'title' => 'Meet at Gate C instead',
            'base_version' => 1,
        ])->assertOk()->assertJsonPath('data.version', 2);

        $this->assertSame(1, TripNotification::where('user_id', $companionNoPush->id)->where('announcement_id', $announcementId)->count());

        Sanctum::actingAs($companionNoPush);
        $this->postJson("/api/v1/me/notifications/{$notifId}/read")
            ->assertOk()
            ->assertJsonPath('data.is_read', true);

        // Deleting announcement cancels pending notices
        Sanctum::actingAs($owner);
        $this->deleteJson("/api/v1/announcements/{$announcementId}")->assertNoContent();
        $this->assertSame('cancelled', TripNotification::findOrFail($notifId)->status);
    }

    public function test_tc5_2_quiet_hours_timezone_behavior_and_auto_reminder_rescheduling(): void
    {
        $owner = User::factory()->create(['home_timezone' => 'Europe/London']);
        $trip = Trip::factory()->create([
            'owner_id' => $owner->id,
            'primary_timezone' => 'Asia/Tokyo',
            'start_date' => '2026-12-01',
            'end_date' => '2026-12-03',
        ]);

        // 14:00 UTC = 23:00 JST (destination quiet hours 22:00-07:00), 14:00 Europe/London (home NOT quiet)
        $item = ItineraryItem::factory()->create([
            'trip_id' => $trip->id,
            'title' => 'Night Views at Roppongi',
            'starts_at_utc' => '2026-12-01T14:30:00Z',
            'timezone' => 'Asia/Tokyo',
            'status' => 'planned',
            'version' => 1,
        ]);

        Sanctum::actingAs($owner);
        $this->putJson('/api/v1/me/notification-preferences', [
            'quiet_hours_enabled' => true,
            'quiet_hours_start' => '22:00',
            'quiet_hours_end' => '07:00',
            'timezone_behavior' => 'destination',
            'activity_reminder_lead_minutes' => 30,
        ])->assertOk();

        $destGen = $this->postJson("/api/v1/trips/{$trip->id}/reminders/generate");
        $destGen->assertOk();
        $activityDest = collect($destGen->json('data'))->where('itinerary_item_id', $item->id);
        $this->assertCount(0, $activityDest);

        // Switching to 'home' evaluates quiet hours in Europe/London (14:00 UTC = outside 22:00-07:00)
        $this->putJson('/api/v1/me/notification-preferences', [
            'timezone_behavior' => 'home',
        ])->assertOk();

        $homeGen = $this->postJson("/api/v1/trips/{$trip->id}/reminders/generate");
        $homeGen->assertOk();
        $activityHome = collect($homeGen->json('data'))->where('itinerary_item_id', $item->id)->values();
        $this->assertCount(1, $activityHome);
        $oldReminderId = (string) $activityHome->first()['id'];
        $this->assertSame('Asia/Tokyo', $activityHome->first()['timezone']);

        // Updating itinerary item via REST cancels stale reminder and schedules updated one automatically
        $this->patchJson("/api/v1/itinerary-items/{$item->id}", [
            'starts_at_utc' => '2026-12-01T10:30:00Z',
            'base_version' => 1,
        ])->assertOk();

        $this->assertSame('cancelled', Reminder::findOrFail($oldReminderId)->status);
        $scheduledAfterEdit = Reminder::where('itinerary_item_id', $item->id)->where('status', 'scheduled')->get();
        $this->assertCount(1, $scheduledAfterEdit);
        $this->assertSame(2, $scheduledAfterEdit->first()->source_version);
        $this->assertTrue(CarbonImmutable::parse('2026-12-01T10:00:00Z')->equalTo($scheduledAfterEdit->first()->trigger_at_utc));

        // Deleting itinerary item cancels its scheduled reminder immediately
        $this->deleteJson("/api/v1/itinerary-items/{$item->id}")->assertNoContent();
        $this->assertSame(0, Reminder::where('itinerary_item_id', $item->id)->where('status', 'scheduled')->count());

        // Updating and deleting a stay cancels old stay reminders and reschedules cleanly
        // (09:00Z -> trigger 08:00 London; 11:00Z -> trigger 09:00 London, outside 22:00-07:00 quiet hours)
        $stay = Stay::factory()->create([
            'trip_id' => $trip->id,
            'name' => 'Shibuya Hotel',
            'check_in_at' => '2026-12-01T09:00:00Z',
            'check_out_at' => '2026-12-03T11:00:00Z',
            'timezone' => 'Asia/Tokyo',
            'version' => 1,
        ]);
        $this->postJson("/api/v1/trips/{$trip->id}/reminders/generate")->assertOk();
        $this->assertSame(2, Reminder::where('trip_id', $trip->id)->whereIn('type', ['stay_checkin', 'stay_checkout'])->where('status', 'scheduled')->count());

        $this->patchJson("/api/v1/stays/{$stay->id}", [
            'check_in_at' => '2026-12-01T10:00:00Z',
            'base_version' => 1,
        ])->assertOk();
        $this->assertGreaterThanOrEqual(1, Reminder::where('trip_id', $trip->id)->where('type', 'stay_checkin')->where('status', 'cancelled')->count());
        $this->assertSame(1, Reminder::where('trip_id', $trip->id)->where('type', 'stay_checkin')->where('status', 'scheduled')->count());

        $this->deleteJson("/api/v1/stays/{$stay->id}")->assertNoContent();
        $this->assertSame(0, Reminder::where('trip_id', $trip->id)->whereIn('type', ['stay_checkin', 'stay_checkout'])->where('status', 'scheduled')->count());

        // Quiet hours on companion announcement notification (24-hour quiet test window or home TZ)
        $companion = User::factory()->create(['home_timezone' => 'UTC']);
        TripMember::factory()->create([
            'trip_id' => $trip->id,
            'user_id' => $companion->id,
            'role' => 'viewer',
            'invitation_status' => 'accepted',
        ]);
        NotificationPreference::create([
            'user_id' => $companion->id,
            'circle_announcements_enabled' => true,
            'quiet_hours_enabled' => true,
            'quiet_hours_start' => '00:00',
            'quiet_hours_end' => '23:59',
            'timezone_behavior' => 'home',
        ]);

        $this->postJson("/api/v1/trips/{$trip->id}/announcements", [
            'title' => 'Quiet Hours Test',
            'body' => 'Deferred notice check',
        ])->assertCreated();

        $companionNotice = TripNotification::where('trip_id', $trip->id)->where('user_id', $companion->id)->firstOrFail();
        $this->assertSame('suppressed_quiet_hours', $companionNotice->status);
        $this->assertNotNull($companionNotice->trip_local_time_label);
    }

    public function test_tc5_3_removed_member_notifications_cancelled_immediately_and_payloads_safe(): void
    {
        $owner = User::factory()->create();
        $companion = User::factory()->create();

        $trip = Trip::factory()->create(['owner_id' => $owner->id, 'primary_timezone' => 'Asia/Tokyo']);
        $member = TripMember::factory()->create([
            'trip_id' => $trip->id,
            'user_id' => $companion->id,
            'role' => 'editor',
            'invitation_status' => 'accepted',
        ]);

        Stay::factory()->create([
            'trip_id' => $trip->id,
            'stay_type' => 'friends_family',
            'address' => '888 Top Secret Home Rd',
            'booking_reference' => 'CONFIDENTIAL-PNR-999',
        ]);

        Sanctum::actingAs($owner);
        $this->postJson("/api/v1/trips/{$trip->id}/announcements", [
            'title' => 'Morning Departure',
            'body' => 'Meet in the lobby at 09:00.',
        ])->assertCreated();

        $notice = TripNotification::where('trip_id', $trip->id)->where('user_id', $companion->id)->firstOrFail();
        $this->assertStringNotContainsString('CONFIDENTIAL-PNR-999', $notice->title.$notice->body);
        $this->assertStringNotContainsString('888 Top Secret Home Rd', $notice->title.$notice->body);
        $this->assertSame('pending', $notice->status);

        // Remove companion -> pending notification is cancelled immediately
        $this->deleteJson("/api/v1/trips/{$trip->id}/members/{$member->id}")->assertNoContent();
        $this->assertSame('cancelled', $notice->fresh()->status);

        // Removed companion gets zero notices from inbox & future announcements create zero notices for them
        Sanctum::actingAs($companion);
        $this->getJson('/api/v1/me/notifications')->assertOk()->assertJsonCount(0, 'data');
        $this->getJson("/api/v1/trips/{$trip->id}/announcements")->assertForbidden();

        Sanctum::actingAs($owner);
        $this->postJson("/api/v1/trips/{$trip->id}/announcements", [
            'title' => 'After Removal Update',
            'body' => 'Only active members receive this.',
        ])->assertCreated();

        $this->assertSame(
            1,
            TripNotification::where('trip_id', $trip->id)->where('user_id', $companion->id)->count()
        );
    }
}
