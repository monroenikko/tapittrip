<?php

declare(strict_types=1);

namespace Tests\Feature;

use App\Models\Checklist;
use App\Models\ItineraryItem;
use App\Models\NotificationPreference;
use App\Models\Reminder;
use App\Models\Stay;
use App\Models\Trip;
use App\Models\TripAnnouncement;
use App\Models\TripDay;
use App\Models\TripMember;
use App\Models\TripNotification;
use App\Models\User;
use App\Models\UserDevice;
use Carbon\Carbon;
use Illuminate\Foundation\Testing\DatabaseTransactions;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

final class NotificationTest extends TestCase
{
    use DatabaseTransactions;

    public function test_user_can_register_and_update_device(): void
    {
        $user = User::factory()->create();
        Sanctum::actingAs($user);

        $response = $this->postJson('/api/v1/devices/register', [
            'platform' => 'ios',
            'device_key' => 'device-uuid-1234',
            'push_token' => 'apns_token_sample_abc',
        ]);

        $response->assertStatus(200)
            ->assertJsonPath('data.platform', 'ios')
            ->assertJsonPath('data.device_key', 'device-uuid-1234');

        $this->assertDatabaseHas('user_devices', [
            'user_id' => $user->id,
            'device_key' => 'device-uuid-1234',
            'platform' => 'ios',
            'push_token' => 'apns_token_sample_abc',
        ]);

        // Re-registering with updated token updates existing record
        $updateResponse = $this->postJson('/api/v1/devices/register', [
            'platform' => 'ios',
            'device_key' => 'device-uuid-1234',
            'push_token' => 'updated_apns_token_xyz',
        ]);

        $updateResponse->assertStatus(200);
        $this->assertEquals(1, UserDevice::where('device_key', 'device-uuid-1234')->count());
        $this->assertDatabaseHas('user_devices', [
            'device_key' => 'device-uuid-1234',
            'push_token' => 'updated_apns_token_xyz',
        ]);
    }

    public function test_user_can_view_and_update_notification_preferences(): void
    {
        $user = User::factory()->create();
        Sanctum::actingAs($user);

        // Get default preferences
        $showResponse = $this->getJson('/api/v1/me/notification-preferences');
        $showResponse->assertStatus(200)
            ->assertJsonPath('data.morning_summary_enabled', true)
            ->assertJsonPath('data.morning_summary_time', '08:00')
            ->assertJsonPath('data.activity_reminders_enabled', true)
            ->assertJsonPath('data.activity_reminder_lead_minutes', 30)
            ->assertJsonPath('data.quiet_hours_enabled', false);

        // Update preferences
        $updateResponse = $this->putJson('/api/v1/me/notification-preferences', [
            'morning_summary_time' => '07:30',
            'activity_reminder_lead_minutes' => 45,
            'quiet_hours_enabled' => true,
            'quiet_hours_start' => '23:00',
            'quiet_hours_end' => '06:30',
        ]);

        $updateResponse->assertStatus(200)
            ->assertJsonPath('data.morning_summary_time', '07:30')
            ->assertJsonPath('data.activity_reminder_lead_minutes', 45)
            ->assertJsonPath('data.quiet_hours_enabled', true)
            ->assertJsonPath('data.quiet_hours_start', '23:00')
            ->assertJsonPath('data.quiet_hours_end', '06:30');
    }

    public function test_can_generate_trip_reminders_without_duplicates(): void
    {
        $user = User::factory()->create();
        Sanctum::actingAs($user);

        $trip = Trip::factory()->create([
            'owner_id' => $user->id,
            'primary_timezone' => 'Asia/Tokyo',
            'start_date' => '2026-12-01',
            'end_date' => '2026-12-05',
        ]);

        $day = TripDay::create([
            'trip_id' => $trip->id,
            'local_date' => '2026-12-01',
        ]);

        $activity = ItineraryItem::factory()->create([
            'trip_id' => $trip->id,
            'trip_day_id' => $day->id,
            'title' => 'Visit Senso-ji Temple',
            'starts_at_utc' => Carbon::parse('2026-12-01 10:00:00', 'Asia/Tokyo')->utc(),
            'timezone' => 'Asia/Tokyo',
            'status' => 'planned',
        ]);

        $stay = Stay::factory()->create([
            'trip_id' => $trip->id,
            'name' => 'Tokyo Bay Hotel',
            'check_in_at' => Carbon::parse('2026-12-01 15:00:00', 'Asia/Tokyo')->utc(),
            'check_out_at' => Carbon::parse('2026-12-05 11:00:00', 'Asia/Tokyo')->utc(),
            'timezone' => 'Asia/Tokyo',
        ]);

        $checklist = Checklist::factory()->create([
            'trip_id' => $trip->id,
            'type' => 'packing',
            'title' => 'Japan Essentials Packing',
        ]);

        // Generate reminders
        $response = $this->postJson("/api/v1/trips/{$trip->id}/reminders/generate");
        $response->assertStatus(200);

        $countInitial = Reminder::where('trip_id', $trip->id)->where('status', 'scheduled')->count();
        $this->assertGreaterThanOrEqual(4, $countInitial);

        // Calling generate again produces no duplicates
        $secondResponse = $this->postJson("/api/v1/trips/{$trip->id}/reminders/generate");
        $secondResponse->assertStatus(200);

        $countAfter = Reminder::where('trip_id', $trip->id)->where('status', 'scheduled')->count();
        $this->assertEquals($countInitial, $countAfter);
    }

    public function test_rescheduling_activity_cancels_old_reminder_and_schedules_new_one(): void
    {
        $user = User::factory()->create();
        Sanctum::actingAs($user);

        $trip = Trip::factory()->create([
            'owner_id' => $user->id,
            'primary_timezone' => 'Asia/Tokyo',
            'start_date' => '2026-12-01',
            'end_date' => '2026-12-05',
        ]);

        $day = TripDay::create([
            'trip_id' => $trip->id,
            'local_date' => '2026-12-01',
        ]);

        $activity = ItineraryItem::factory()->create([
            'trip_id' => $trip->id,
            'trip_day_id' => $day->id,
            'title' => 'Team Dinner at Roppongi',
            'starts_at_utc' => Carbon::parse('2026-12-01 19:00:00', 'Asia/Tokyo')->utc(),
            'timezone' => 'Asia/Tokyo',
            'status' => 'planned',
        ]);

        // Generate initial reminders
        $this->postJson("/api/v1/trips/{$trip->id}/reminders/generate")->assertStatus(200);

        $initialReminder = Reminder::where('itinerary_item_id', $activity->id)
            ->where('status', 'scheduled')
            ->first();
        $this->assertNotNull($initialReminder);

        // Reschedule activity to 20:30
        $activity->update([
            'starts_at_utc' => Carbon::parse('2026-12-01 20:30:00', 'Asia/Tokyo')->utc(),
        ]);

        // Re-generate reminders
        $this->postJson("/api/v1/trips/{$trip->id}/reminders/generate")->assertStatus(200);

        // Old reminder should now be cancelled
        $initialReminder->refresh();
        $this->assertEquals('cancelled', $initialReminder->status);

        // New reminder should be scheduled with new time
        $newReminder = Reminder::where('itinerary_item_id', $activity->id)
            ->where('status', 'scheduled')
            ->first();
        $this->assertNotNull($newReminder);
        $this->assertNotEquals($initialReminder->id, $newReminder->id);
    }

    public function test_quiet_hours_suppresses_reminders(): void
    {
        $user = User::factory()->create();
        Sanctum::actingAs($user);

        // Enable quiet hours from 22:00 to 07:00
        NotificationPreference::create([
            'user_id' => $user->id,
            'morning_summary_enabled' => false,
            'activity_reminders_enabled' => true,
            'activity_reminder_lead_minutes' => 30,
            'checklist_reminders_enabled' => false,
            'stay_reminders_enabled' => false,
            'quiet_hours_enabled' => true,
            'quiet_hours_start' => '22:00',
            'quiet_hours_end' => '07:00',
        ]);

        $trip = Trip::factory()->create([
            'owner_id' => $user->id,
            'primary_timezone' => 'Asia/Tokyo',
        ]);

        // Activity starts at 22:15 local Tokyo time -> trigger at 21:45 (outside quiet hours)
        $outsideActivity = ItineraryItem::factory()->create([
            'trip_id' => $trip->id,
            'title' => 'Evening Stroll',
            'starts_at_utc' => Carbon::parse('2026-12-01 22:15:00', 'Asia/Tokyo')->utc(),
            'timezone' => 'Asia/Tokyo',
            'status' => 'planned',
        ]);

        // Activity starts at 02:00 local Tokyo time -> trigger at 01:30 (inside quiet hours)
        $insideActivity = ItineraryItem::factory()->create([
            'trip_id' => $trip->id,
            'title' => 'Late Night Ramen',
            'starts_at_utc' => Carbon::parse('2026-12-02 02:00:00', 'Asia/Tokyo')->utc(),
            'timezone' => 'Asia/Tokyo',
            'status' => 'planned',
        ]);

        $this->postJson("/api/v1/trips/{$trip->id}/reminders/generate")->assertStatus(200);

        // Outside activity has a scheduled reminder
        $this->assertTrue(
            Reminder::where('itinerary_item_id', $outsideActivity->id)->where('status', 'scheduled')->exists()
        );

        // Inside quiet hours activity is suppressed
        $this->assertFalse(
            Reminder::where('itinerary_item_id', $insideActivity->id)->where('status', 'scheduled')->exists()
        );
    }

    public function test_unauthorized_user_cannot_access_trip_reminders(): void
    {
        $owner = User::factory()->create();
        $stranger = User::factory()->create();

        $trip = Trip::factory()->create(['owner_id' => $owner->id]);

        Sanctum::actingAs($stranger);

        $this->getJson("/api/v1/trips/{$trip->id}/reminders")->assertStatus(403);
        $this->postJson("/api/v1/trips/{$trip->id}/reminders/generate")->assertStatus(403);
    }

    public function test_creating_and_updating_stay_timezone_schedules_and_reschedules_stay_and_linked_item_reminders(): void
    {
        $owner = User::factory()->create();
        Sanctum::actingAs($owner);

        $trip = Trip::factory()->create([
            'owner_id' => $owner->id,
            'primary_timezone' => 'Asia/Tokyo',
        ]);

        // Creating a stay via REST automatically schedules stay check-in/check-out & linked itinerary item reminders
        $createRes = $this->postJson("/api/v1/trips/{$trip->id}/stays", [
            'name' => 'Park Hyatt Kyoto',
            'stay_type' => 'hotel',
            'check_in_at' => '2026-12-10T15:00:00+09:00',
            'check_out_at' => '2026-12-12T11:00:00+09:00',
            'timezone' => 'Asia/Tokyo',
            'create_itinerary_events' => true,
        ]);

        $createRes->assertCreated();
        $stayId = (string) $createRes->json('data.id');

        $scheduledStayReminders = Reminder::where('trip_id', $trip->id)
            ->whereIn('type', ['stay_checkin', 'stay_checkout'])
            ->where('status', 'scheduled')
            ->get();
        $this->assertCount(2, $scheduledStayReminders);
        $this->assertSame('Asia/Tokyo', $scheduledStayReminders->first()->timezone);
        $this->assertSame('14:00', Carbon::parse($scheduledStayReminders->firstWhere('type', 'stay_checkin')->trigger_at_utc)->setTimezone('Asia/Tokyo')->format('H:i'));

        $linkedItems = ItineraryItem::where('stay_id', $stayId)->get();
        $this->assertCount(2, $linkedItems);
        $this->assertSame(2, Reminder::whereIn('itinerary_item_id', $linkedItems->pluck('id'))->where('status', 'scheduled')->count());

        // Changing stay timezone propagates to linked itinerary items and reschedules both stay + item reminders cleanly
        $this->patchJson("/api/v1/stays/{$stayId}", [
            'timezone' => 'Asia/Seoul',
            'base_version' => 1,
        ])->assertOk();

        $freshStayReminders = Reminder::where('trip_id', $trip->id)
            ->whereIn('type', ['stay_checkin', 'stay_checkout'])
            ->where('status', 'scheduled')
            ->get();
        $this->assertCount(2, $freshStayReminders);
        $this->assertTrue($freshStayReminders->every(fn (Reminder $r): bool => $r->timezone === 'Asia/Seoul'));
        $this->assertSame(2, Reminder::where('trip_id', $trip->id)->whereIn('type', ['stay_checkin', 'stay_checkout'])->count());

        foreach ($linkedItems->fresh() as $item) {
            $this->assertSame('Asia/Seoul', $item->timezone);
            $itemRem = Reminder::where('itinerary_item_id', $item->id)->where('status', 'scheduled')->firstOrFail();
            $this->assertSame('Asia/Seoul', $itemRem->timezone);
        }

        // Shifting check-in time cancels old stay check-in reminder and schedules the new time
        $this->patchJson("/api/v1/stays/{$stayId}", [
            'check_in_at' => '2026-12-10T16:30:00+09:00',
            'base_version' => 2,
        ])->assertOk();

        $this->assertSame(1, Reminder::where('trip_id', $trip->id)->where('type', 'stay_checkin')->where('status', 'cancelled')->count());
        $newCheckInRem = Reminder::where('trip_id', $trip->id)->where('type', 'stay_checkin')->where('status', 'scheduled')->firstOrFail();
        $this->assertSame('15:30', Carbon::parse($newCheckInRem->trigger_at_utc)->setTimezone('Asia/Seoul')->format('H:i'));
    }

    public function test_updating_trip_timezone_reschedules_active_reminders(): void
    {
        $owner = User::factory()->create();
        Sanctum::actingAs($owner);

        $trip = Trip::factory()->create([
            'owner_id' => $owner->id,
            'primary_timezone' => 'Asia/Tokyo',
            'start_date' => '2026-12-01',
            'end_date' => '2026-12-02',
        ]);
        TripDay::create([
            'trip_id' => $trip->id,
            'local_date' => '2026-12-01',
        ]);

        // Generate morning summary reminder in Asia/Tokyo (08:00 JST)
        $this->postJson("/api/v1/trips/{$trip->id}/reminders/generate")->assertOk();
        $initialSummary = Reminder::where('trip_id', $trip->id)
            ->where('type', 'morning_summary')
            ->where('status', 'scheduled')
            ->firstOrFail();
        $this->assertSame('Asia/Tokyo', $initialSummary->timezone);

        // Update trip primary_timezone -> old morning summary is cancelled, new one scheduled in Europe/Paris
        $this->patchJson("/api/v1/trips/{$trip->id}", [
            'primary_timezone' => 'Europe/Paris',
        ])->assertOk();

        $this->assertSame('cancelled', $initialSummary->fresh()->status);
        $updatedSummary = Reminder::where('trip_id', $trip->id)
            ->where('type', 'morning_summary')
            ->where('status', 'scheduled')
            ->firstOrFail();
        $this->assertSame('Europe/Paris', $updatedSummary->timezone);
    }

    public function test_updating_preferences_recalculates_reminders_and_cancels_opted_out_announcements(): void
    {
        $owner = User::factory()->create(['home_timezone' => 'Europe/London']);
        $companion = User::factory()->create();

        $trip = Trip::factory()->create([
            'owner_id' => $owner->id,
            'primary_timezone' => 'Asia/Tokyo',
        ]);
        TripMember::factory()->create([
            'trip_id' => $trip->id,
            'user_id' => $companion->id,
            'role' => 'viewer',
            'invitation_status' => 'accepted',
        ]);

        // 14:30 UTC = 23:30 JST (quiet in Tokyo), 14:30 London (not quiet at home)
        $item = ItineraryItem::factory()->create([
            'trip_id' => $trip->id,
            'title' => 'Late Observatory',
            'starts_at_utc' => '2026-12-01T14:30:00Z',
            'timezone' => 'Asia/Tokyo',
            'status' => 'planned',
        ]);

        Sanctum::actingAs($owner);
        NotificationPreference::create([
            'user_id' => $owner->id,
            'quiet_hours_enabled' => false,
            'timezone_behavior' => 'destination',
        ]);
        $this->postJson("/api/v1/trips/{$trip->id}/reminders/generate")->assertOk();
        $this->assertTrue(Reminder::where('itinerary_item_id', $item->id)->where('status', 'scheduled')->exists());

        // Enabling quiet hours immediately cancels the active reminder overlapping destination quiet hours
        $this->putJson('/api/v1/me/notification-preferences', [
            'quiet_hours_enabled' => true,
            'quiet_hours_start' => '22:00',
            'quiet_hours_end' => '07:00',
        ])->assertOk();
        $this->assertFalse(Reminder::where('itinerary_item_id', $item->id)->where('status', 'scheduled')->exists());

        // Opting out of circle announcements cancels pending in-app circle_announcement deliveries
        $announcement = TripAnnouncement::factory()->create([
            'trip_id' => $trip->id,
            'author_id' => $owner->id,
        ]);
        $notice = TripNotification::factory()->create([
            'trip_id' => $trip->id,
            'user_id' => $companion->id,
            'announcement_id' => $announcement->id,
            'category' => 'circle_announcement',
            'status' => 'pending',
        ]);

        Sanctum::actingAs($companion);
        $this->putJson('/api/v1/me/notification-preferences', [
            'circle_announcements_enabled' => false,
        ])->assertOk();

        $this->assertSame('cancelled', $notice->fresh()->status);
    }

    public function test_deleting_trip_cancels_scheduled_reminders_and_pending_notifications(): void
    {
        $owner = User::factory()->create();
        $companion = User::factory()->create();

        $trip = Trip::factory()->create([
            'owner_id' => $owner->id,
            'primary_timezone' => 'Asia/Tokyo',
        ]);
        $reminder = Reminder::create([
            'trip_id' => $trip->id,
            'type' => 'morning_summary',
            'title' => 'Today',
            'body' => 'Summary',
            'trigger_at_utc' => now()->addDay(),
            'timezone' => 'Asia/Tokyo',
            'delivery_channel' => 'local',
            'status' => 'scheduled',
            'dedupe_key' => 'trip-del-1',
            'source_version' => 1,
        ]);
        $announcement = TripAnnouncement::factory()->create([
            'trip_id' => $trip->id,
            'author_id' => $owner->id,
        ]);
        $notice = TripNotification::factory()->create([
            'trip_id' => $trip->id,
            'user_id' => $companion->id,
            'announcement_id' => $announcement->id,
            'status' => 'suppressed_quiet_hours',
        ]);

        Sanctum::actingAs($owner);
        $this->deleteJson("/api/v1/trips/{$trip->id}")->assertNoContent();

        $this->assertSame('cancelled', $reminder->fresh()->status);
        $this->assertSame('cancelled', $notice->fresh()->status);
    }
}
