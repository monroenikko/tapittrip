<?php

declare(strict_types=1);

namespace Tests\Feature;

use App\Domain\Checklists\Models\Checklist;
use App\Domain\Itinerary\Models\ItineraryItem;
use App\Domain\Itinerary\Models\TripDay;
use App\Domain\Notifications\Models\NotificationPreference;
use App\Domain\Notifications\Models\Reminder;
use App\Domain\Notifications\Models\UserDevice;
use App\Domain\Stays\Models\Stay;
use App\Domain\Trips\Models\Trip;
use App\Models\User;
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
}
