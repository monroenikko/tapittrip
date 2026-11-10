<?php

declare(strict_types=1);

namespace App\Services\Notifications;

use App\DTOs\Notifications\RegisterDeviceData;
use App\DTOs\Notifications\UpdateNotificationPreferencesData;
use App\Models\NotificationPreference;
use App\Models\Reminder;
use App\Models\Trip;
use App\Models\User;
use App\Models\UserDevice;
use Carbon\Carbon;
use Carbon\CarbonInterface;
use Illuminate\Database\Eloquent\Collection;

final class NotificationService
{
    /**
     * Register or update a user's mobile or web device.
     */
    public function registerDevice(User $user, RegisterDeviceData $data): UserDevice
    {
        return UserDevice::updateOrCreate(
            [
                'user_id' => $user->id,
                'device_key' => $data->deviceKey,
            ],
            [
                'platform' => $data->platform,
                'push_token' => $data->pushToken,
                'last_seen_at' => now(),
            ]
        );
    }

    /**
     * Get or create notification preferences for the user.
     */
    public function getPreferences(User $user): NotificationPreference
    {
        return NotificationPreference::firstOrCreate(
            ['user_id' => $user->id],
            [
                'morning_summary_enabled' => true,
                'morning_summary_time' => '08:00',
                'activity_reminders_enabled' => true,
                'activity_reminder_lead_minutes' => 30,
                'checklist_reminders_enabled' => true,
                'stay_reminders_enabled' => true,
                'quiet_hours_enabled' => false,
                'quiet_hours_start' => '22:00',
                'quiet_hours_end' => '07:00',
                'geofence_arrival_enabled' => true,
                'timezone_behavior' => 'destination',
            ]
        );
    }

    /**
     * Update notification preferences for the user.
     */
    public function updatePreferences(User $user, UpdateNotificationPreferencesData $data): NotificationPreference
    {
        $preferences = $this->getPreferences($user);

        $updates = $data->toArray();
        if (! empty($updates)) {
            $preferences->update($updates);
        }

        return $preferences->refresh();
    }

    /**
     * Retrieve reminders for a trip.
     *
     * @return Collection<int, Reminder>
     */
    public function getTripReminders(Trip $trip, ?string $status = null): Collection
    {
        $query = $trip->reminders()->with(['itineraryItem', 'checklist']);

        if ($status !== null) {
            $query->where('status', $status);
        }

        return $query->get();
    }

    /**
     * Generate or recalculate scheduled reminders for a trip based on user preferences.
     *
     * @return Collection<int, Reminder>
     */
    public function scheduleTripReminders(Trip $trip, User $user): Collection
    {
        $preferences = $this->getPreferences($user);

        $tripTz = $trip->primary_timezone ?: 'UTC';
        $activeDedupeKeys = [];

        // 1. Morning Summaries for Trip Days
        if ($preferences->morning_summary_enabled) {
            $days = $trip->days()->with('itineraryItems')->get();
            [$hour, $minute] = explode(':', $preferences->morning_summary_time);

            foreach ($days as $day) {
                $triggerLocal = Carbon::parse($day->local_date, $tripTz)->setTime((int) $hour, (int) $minute);
                $triggerUtc = $triggerLocal->copy()->utc();

                if ($this->isInQuietHours($triggerLocal, $preferences)) {
                    continue;
                }

                $itemCount = $day->itineraryItems->where('status', '!=', 'visited')->count();
                $dedupeKey = "{$trip->id}:morning_summary:{$day->id}:{$triggerUtc->timestamp}";
                $activeDedupeKeys[] = $dedupeKey;

                Reminder::updateOrCreate(
                    [
                        'trip_id' => $trip->id,
                        'dedupe_key' => $dedupeKey,
                    ],
                    [
                        'itinerary_item_id' => null,
                        'checklist_id' => null,
                        'type' => 'morning_summary',
                        'title' => "Today in {$trip->title}",
                        'body' => "Good morning! You have {$itemCount} planned activities for today.",
                        'trigger_at_utc' => $triggerUtc,
                        'timezone' => $tripTz,
                        'delivery_channel' => 'local',
                        'status' => 'scheduled',
                        'source_version' => $trip->version ?? 1,
                    ]
                );
            }
        }

        // 2. Activity Reminders
        if ($preferences->activity_reminders_enabled) {
            $activities = $trip->itineraryItems()
                ->where('status', '!=', 'visited')
                ->whereNotNull('starts_at_utc')
                ->get();

            $leadMinutes = $preferences->activity_reminder_lead_minutes;

            foreach ($activities as $activity) {
                /** @var Carbon $startsAt */
                $startsAt = $activity->starts_at_utc;
                $triggerUtc = $startsAt->copy()->subMinutes($leadMinutes);
                $triggerLocal = $triggerUtc->copy()->setTimezone($activity->timezone ?: $tripTz);

                if ($this->isInQuietHours($triggerLocal, $preferences)) {
                    continue;
                }

                $formattedTime = $startsAt->copy()->setTimezone($activity->timezone ?: $tripTz)->format('H:i');
                $dedupeKey = "{$trip->id}:activity_reminder:{$activity->id}:{$triggerUtc->timestamp}";
                $activeDedupeKeys[] = $dedupeKey;

                Reminder::updateOrCreate(
                    [
                        'trip_id' => $trip->id,
                        'dedupe_key' => $dedupeKey,
                    ],
                    [
                        'itinerary_item_id' => $activity->id,
                        'checklist_id' => null,
                        'type' => 'activity_reminder',
                        'title' => "Upcoming: {$activity->title}",
                        'body' => "Starts in {$leadMinutes} mins at {$formattedTime}.",
                        'trigger_at_utc' => $triggerUtc,
                        'timezone' => $activity->timezone ?: $tripTz,
                        'delivery_channel' => 'local',
                        'status' => 'scheduled',
                        'source_version' => $activity->version ?? 1,
                    ]
                );
            }
        }

        // 3. Stay Check-in & Check-out Reminders
        if ($preferences->stay_reminders_enabled) {
            $stays = $trip->stays;

            foreach ($stays as $stay) {
                $stayTz = $stay->timezone ?: $tripTz;

                if ($stay->check_in_at) {
                    $checkInUtc = Carbon::parse($stay->check_in_at)->utc();
                    $triggerUtc = $checkInUtc->copy()->subHour();
                    $triggerLocal = $triggerUtc->copy()->setTimezone($stayTz);

                    if (! $this->isInQuietHours($triggerLocal, $preferences)) {
                        $dedupeKey = "{$trip->id}:stay_checkin:{$stay->id}:{$triggerUtc->timestamp}";
                        $activeDedupeKeys[] = $dedupeKey;

                        $timeStr = $checkInUtc->copy()->setTimezone($stayTz)->format('H:i');
                        Reminder::updateOrCreate(
                            [
                                'trip_id' => $trip->id,
                                'dedupe_key' => $dedupeKey,
                            ],
                            [
                                'itinerary_item_id' => null,
                                'checklist_id' => null,
                                'type' => 'stay_checkin',
                                'title' => "Check-in Today: {$stay->name}",
                                'body' => "Check-in opens at {$timeStr} for {$stay->name}.",
                                'trigger_at_utc' => $triggerUtc,
                                'timezone' => $stayTz,
                                'delivery_channel' => 'local',
                                'status' => 'scheduled',
                                'source_version' => $stay->version ?? 1,
                            ]
                        );
                    }
                }

                if ($stay->check_out_at) {
                    $checkOutUtc = Carbon::parse($stay->check_out_at)->utc();
                    $triggerUtc = $checkOutUtc->copy()->subHours(2);
                    $triggerLocal = $triggerUtc->copy()->setTimezone($stayTz);

                    if (! $this->isInQuietHours($triggerLocal, $preferences)) {
                        $dedupeKey = "{$trip->id}:stay_checkout:{$stay->id}:{$triggerUtc->timestamp}";
                        $activeDedupeKeys[] = $dedupeKey;

                        $timeStr = $checkOutUtc->copy()->setTimezone($stayTz)->format('H:i');
                        Reminder::updateOrCreate(
                            [
                                'trip_id' => $trip->id,
                                'dedupe_key' => $dedupeKey,
                            ],
                            [
                                'itinerary_item_id' => null,
                                'checklist_id' => null,
                                'type' => 'stay_checkout',
                                'title' => "Check-out Reminder: {$stay->name}",
                                'body' => "Check-out is by {$timeStr}. Remember your room keys and belongings!",
                                'trigger_at_utc' => $triggerUtc,
                                'timezone' => $stayTz,
                                'delivery_channel' => 'local',
                                'status' => 'scheduled',
                                'source_version' => $stay->version ?? 1,
                            ]
                        );
                    }
                }
            }
        }

        // 4. Checklist Reminders (Departure / Packing)
        if ($preferences->checklist_reminders_enabled) {
            $checklists = $trip->checklists()->whereIn('type', ['departure', 'packing'])->get();

            foreach ($checklists as $checklist) {
                if ($trip->start_date) {
                    $triggerLocal = Carbon::parse($trip->start_date, $tripTz)->subDay()->setTime(10, 0);
                    $triggerUtc = $triggerLocal->copy()->utc();

                    if (! $this->isInQuietHours($triggerLocal, $preferences)) {
                        $dedupeKey = "{$trip->id}:checklist_reminder:{$checklist->id}:{$triggerUtc->timestamp}";
                        $activeDedupeKeys[] = $dedupeKey;

                        Reminder::updateOrCreate(
                            [
                                'trip_id' => $trip->id,
                                'dedupe_key' => $dedupeKey,
                            ],
                            [
                                'itinerary_item_id' => null,
                                'checklist_id' => $checklist->id,
                                'type' => 'departure_checklist',
                                'title' => "Ready for Departure? {$checklist->title}",
                                'body' => "Check off your essentials in {$checklist->title} before you leave.",
                                'trigger_at_utc' => $triggerUtc,
                                'timezone' => $tripTz,
                                'delivery_channel' => 'local',
                                'status' => 'scheduled',
                                'source_version' => $trip->version ?? 1,
                            ]
                        );
                    }
                }
            }
        }

        // Cancel any previously scheduled reminders that are no longer active
        $trip->reminders()
            ->where('status', 'scheduled')
            ->whereNotIn('dedupe_key', $activeDedupeKeys)
            ->update(['status' => 'cancelled']);

        return $trip->reminders()
            ->with(['itineraryItem', 'checklist'])
            ->where('status', 'scheduled')
            ->orderBy('trigger_at_utc')
            ->get();
    }

    /**
     * Check if a given local time falls within configured quiet hours.
     */
    private function isInQuietHours(CarbonInterface $localTime, NotificationPreference $preferences): bool
    {
        if (! $preferences->quiet_hours_enabled || ! $preferences->quiet_hours_start || ! $preferences->quiet_hours_end) {
            return false;
        }

        $timeStr = $localTime->format('H:i');
        $start = $preferences->quiet_hours_start;
        $end = $preferences->quiet_hours_end;

        if ($start > $end) {
            // Spans midnight, e.g. 22:00 to 07:00
            return $timeStr >= $start || $timeStr < $end;
        }

        // Within same day, e.g. 13:00 to 15:00
        return $timeStr >= $start && $timeStr < $end;
    }
}
