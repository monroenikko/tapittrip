<?php

declare(strict_types=1);

namespace App\Services\Notifications;

use App\DTOs\Notifications\RegisterDeviceData;
use App\DTOs\Notifications\UpdateNotificationPreferencesData;
use App\Models\Flight;
use App\Models\ItineraryItem;
use App\Models\NotificationPreference;
use App\Models\Reminder;
use App\Models\Stay;
use App\Models\Trip;
use App\Models\TripAnnouncement;
use App\Models\TripNotification;
use App\Models\User;
use App\Models\UserDevice;
use Carbon\Carbon;
use Carbon\CarbonImmutable;
use Carbon\CarbonInterface;
use Illuminate\Auth\Access\AuthorizationException;
use Illuminate\Database\Eloquent\Collection;
use Illuminate\Support\Str;

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
                'circle_announcements_enabled' => true,
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

        $refreshed = $preferences->refresh();

        if (array_key_exists('circle_announcements_enabled', $updates) && ! $refreshed->circle_announcements_enabled) {
            TripNotification::query()
                ->where('user_id', $user->id)
                ->where('category', 'circle_announcement')
                ->whereIn('status', ['pending', 'suppressed_quiet_hours'])
                ->update(['status' => 'cancelled']);
        }

        $reminderAffectingKeys = [
            'morning_summary_enabled',
            'morning_summary_time',
            'activity_reminders_enabled',
            'activity_reminder_lead_minutes',
            'checklist_reminders_enabled',
            'stay_reminders_enabled',
            'quiet_hours_enabled',
            'quiet_hours_start',
            'quiet_hours_end',
            'timezone_behavior',
        ];

        if (array_intersect(array_keys($updates), $reminderAffectingKeys) !== []) {
            $tripsWithReminders = Trip::query()
                ->where('owner_id', $user->id)
                ->whereHas('reminders', fn ($q) => $q->where('status', 'scheduled'))
                ->get();

            foreach ($tripsWithReminders as $trip) {
                $this->scheduleTripReminders($trip, $user);
            }
        }

        return $refreshed;
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
                $localDateStr = $day->local_date instanceof CarbonInterface
                    ? $day->local_date->format('Y-m-d')
                    : (string) $day->local_date;
                $triggerLocal = Carbon::parse($localDateStr, $tripTz)->setTime((int) $hour, (int) $minute);
                $triggerUtc = $triggerLocal->copy()->utc();
                $evalTz = $this->resolveQuietHoursTimezone($user, $preferences, $tripTz, $tripTz);

                if ($this->isInQuietHours($triggerUtc->copy()->setTimezone($evalTz), $preferences)) {
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
                $dedupeKey = $this->scheduleActivityReminder($trip, $user, $preferences, $activity);
                if ($dedupeKey !== null) {
                    $activeDedupeKeys[] = $dedupeKey;
                }
            }
        }

        // 3. Stay Check-in & Check-out Reminders
        if ($preferences->stay_reminders_enabled) {
            $stays = $trip->stays;

            foreach ($stays as $stay) {
                foreach ($this->scheduleStayReminders($trip, $user, $preferences, $stay) as $dedupeKey) {
                    $activeDedupeKeys[] = $dedupeKey;
                }
            }
        }

        // 4. Checklist Reminders (Departure / Packing)
        if ($preferences->checklist_reminders_enabled) {
            $checklists = $trip->checklists()->whereIn('type', ['departure', 'packing'])->get();

            foreach ($checklists as $checklist) {
                if ($trip->start_date) {
                    $startDateStr = $trip->start_date instanceof CarbonInterface
                        ? $trip->start_date->format('Y-m-d')
                        : (string) $trip->start_date;
                    $triggerLocal = Carbon::parse($startDateStr, $tripTz)->subDay()->setTime(10, 0);
                    $triggerUtc = $triggerLocal->copy()->utc();
                    $evalTz = $this->resolveQuietHoursTimezone($user, $preferences, $tripTz, $tripTz);

                    if (! $this->isInQuietHours($triggerUtc->copy()->setTimezone($evalTz), $preferences)) {
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

        // 5. Flight Prep & Gate Departure Reminders
        if ($preferences->activity_reminders_enabled) {
            $flights = $trip->flights()->with('segments')->get();

            foreach ($flights as $flight) {
                foreach ($this->scheduleFlightReminders($trip, $user, $preferences, $flight) as $dedupeKey) {
                    $activeDedupeKeys[] = $dedupeKey;
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

    /**
     * Cancel and reschedule reminders for an updated itinerary item (TC-5.2).
     */
    public function syncRemindersForItineraryItem(ItineraryItem $item): void
    {
        $this->cancelRemindersForItineraryItem($item);

        $trip = $item->trip()->with('owner')->first();
        if ($trip === null || $trip->owner === null) {
            return;
        }

        $preferences = $this->getPreferences($trip->owner);
        if (! $preferences->activity_reminders_enabled || $item->status === 'visited' || $item->status === 'skipped' || $item->starts_at_utc === null) {
            return;
        }

        $this->scheduleActivityReminder($trip, $trip->owner, $preferences, $item);
    }

    /**
     * Cancel all scheduled reminders for an itinerary item (e.g. deletion).
     */
    public function cancelRemindersForItineraryItem(ItineraryItem $item): void
    {
        Reminder::query()
            ->where('itinerary_item_id', $item->id)
            ->where('status', 'scheduled')
            ->update(['status' => 'cancelled']);
    }

    /**
     * Cancel and reschedule reminders for an updated stay and its linked itinerary items (TC-5.2).
     */
    public function syncRemindersForStay(Stay $stay): void
    {
        $this->cancelRemindersForStay($stay);

        foreach ($stay->itineraryItems as $linkedItem) {
            $this->syncRemindersForItineraryItem($linkedItem);
        }

        $trip = $stay->trip()->with('owner')->first();
        if ($trip === null || $trip->owner === null) {
            return;
        }

        $preferences = $this->getPreferences($trip->owner);
        if (! $preferences->stay_reminders_enabled) {
            return;
        }

        $this->scheduleStayReminders($trip, $trip->owner, $preferences, $stay);
    }

    /**
     * Cancel scheduled stay reminders when a stay changes or is deleted.
     */
    public function cancelRemindersForStay(Stay $stay): void
    {
        Reminder::query()
            ->where('trip_id', $stay->trip_id)
            ->whereIn('type', ['stay_checkin', 'stay_checkout'])
            ->where('dedupe_key', 'like', "{$stay->trip_id}:stay_%:{$stay->id}:%")
            ->where('status', 'scheduled')
            ->update(['status' => 'cancelled']);
    }

    /**
     * Cancel and reschedule reminders for a created or updated flight.
     */
    public function syncRemindersForFlight(Flight $flight): void
    {
        $this->cancelRemindersForFlight($flight);

        $trip = $flight->trip()->with('owner')->first();
        if ($trip === null || $trip->owner === null) {
            return;
        }

        $preferences = $this->getPreferences($trip->owner);
        if (! $preferences->activity_reminders_enabled) {
            return;
        }

        $flight->loadMissing('segments');
        $this->scheduleFlightReminders($trip, $trip->owner, $preferences, $flight);
    }

    /**
     * Cancel scheduled flight prep and gate departure reminders when a flight changes or is deleted.
     */
    public function cancelRemindersForFlight(Flight $flight): void
    {
        Reminder::query()
            ->where('trip_id', $flight->trip_id)
            ->whereIn('type', ['flight_prep', 'flight_gate_departure'])
            ->where('dedupe_key', 'like', "{$flight->trip_id}:flight_%:{$flight->id}:%")
            ->where('status', 'scheduled')
            ->update(['status' => 'cancelled']);
    }

    /**
     * Dispatch or upsert companion notifications for a new organizer announcement (TC-5.1, TC-5.2).
     */
    public function dispatchAnnouncementNotifications(Trip $trip, TripAnnouncement $announcement, User $actor): void
    {
        $this->syncAnnouncementNotifications($trip, $announcement, $actor);
    }

    /**
     * Synchronize companion notifications for an edited or retried announcement without duplicates.
     */
    public function syncAnnouncementNotifications(Trip $trip, TripAnnouncement $announcement, User $actor): void
    {
        $tripTz = $trip->primary_timezone ?: 'UTC';
        $localTimeLabel = CarbonImmutable::now($tripTz)->format('M j, H:i T');
        $dedupeKey = "announcement:{$announcement->id}";
        $safeTitle = Str::limit(trim($announcement->title), 160);
        $safeBody = Str::limit(trim($announcement->body), 500)." ({$localTimeLabel})";

        $acceptedMembers = $trip->members()
            ->where('invitation_status', 'accepted')
            ->with('user')
            ->get();

        $eligibleUserIds = [];

        foreach ($acceptedMembers as $member) {
            if ($member->user === null || $member->user_id === $actor->id) {
                continue;
            }

            $prefs = $this->getPreferences($member->user);
            if (! $prefs->circle_announcements_enabled) {
                continue;
            }

            $eligibleUserIds[] = $member->user_id;
            $schedule = $this->computeAnnouncementSchedule(
                $member->user,
                $prefs,
                CarbonImmutable::now('UTC'),
                $tripTz,
            );

            /** @var TripNotification|null $existing */
            $existing = TripNotification::query()
                ->where('user_id', $member->user_id)
                ->where('dedupe_key', $dedupeKey)
                ->first();

            if ($existing !== null) {
                $existing->update([
                    'title' => $safeTitle,
                    'body' => $safeBody,
                    'scheduled_for_utc' => $schedule['scheduled_for_utc'],
                    'timezone' => $schedule['timezone'],
                    'trip_local_time_label' => $localTimeLabel,
                    'status' => $existing->status === 'delivered' ? 'delivered' : $schedule['status'],
                ]);

                continue;
            }

            TripNotification::create([
                'trip_id' => $trip->id,
                'user_id' => $member->user_id,
                'announcement_id' => $announcement->id,
                'category' => 'circle_announcement',
                'title' => $safeTitle,
                'body' => $safeBody,
                'scheduled_for_utc' => $schedule['scheduled_for_utc'],
                'timezone' => $schedule['timezone'],
                'trip_local_time_label' => $localTimeLabel,
                'status' => $schedule['status'],
                'dedupe_key' => $dedupeKey,
            ]);
        }

        // Cancel any previously created notices for users who opted out or left the circle
        $cancelQuery = TripNotification::query()
            ->where('announcement_id', $announcement->id)
            ->whereIn('status', ['pending', 'suppressed_quiet_hours']);

        if ($eligibleUserIds !== []) {
            $cancelQuery->whereNotIn('user_id', $eligibleUserIds);
        }

        $cancelQuery->update(['status' => 'cancelled']);
    }

    /**
     * Cancel pending or suppressed notifications for a deleted announcement.
     */
    public function cancelAnnouncementNotifications(TripAnnouncement $announcement): void
    {
        TripNotification::query()
            ->where('announcement_id', $announcement->id)
            ->whereIn('status', ['pending', 'suppressed_quiet_hours'])
            ->update(['status' => 'cancelled']);
    }

    /**
     * Immediately cancel pending notifications for a member removed from a trip (TC-5.3).
     */
    public function cancelMemberTripNotifications(Trip $trip, User|string $user): int
    {
        $userId = $user instanceof User ? $user->id : $user;

        return TripNotification::query()
            ->where('trip_id', $trip->id)
            ->where('user_id', $userId)
            ->whereIn('status', ['pending', 'suppressed_quiet_hours'])
            ->update(['status' => 'cancelled']);
    }

    /**
     * List non-cancelled notifications belonging strictly to trips the user is currently in.
     *
     * @return Collection<int, TripNotification>
     */
    public function listUserNotifications(User $user): Collection
    {
        return TripNotification::query()
            ->where('user_id', $user->id)
            ->where('status', '!=', 'cancelled')
            ->whereHas('trip.members', function ($query) use ($user): void {
                $query->where('user_id', $user->id)
                    ->where('invitation_status', 'accepted')
                    ->whereNull('deleted_at');
            })
            ->with(['trip'])
            ->orderByDesc('created_at')
            ->get();
    }

    /**
     * Mark a notification as read for the owning recipient.
     *
     * @throws AuthorizationException
     */
    public function markNotificationRead(TripNotification $notification, User $user): TripNotification
    {
        if ($notification->user_id !== $user->id) {
            throw new AuthorizationException('You do not have access to this notification.');
        }

        if ($notification->read_at === null) {
            $notification->read_at = CarbonImmutable::now('UTC');
            $notification->save();
        }

        return $notification->fresh(['trip']) ?? $notification;
    }

    private function resolveQuietHoursTimezone(
        User $user,
        NotificationPreference $preferences,
        ?string $itemTimezone,
        string $tripTimezone,
    ): string {
        if ($preferences->timezone_behavior === 'home' && ! empty($user->home_timezone)) {
            return $user->home_timezone;
        }

        return $itemTimezone ?: $tripTimezone;
    }

    private function scheduleActivityReminder(
        Trip $trip,
        User $user,
        NotificationPreference $preferences,
        ItineraryItem $activity,
    ): ?string {
        if ($activity->starts_at_utc === null) {
            return null;
        }

        $tripTz = $trip->primary_timezone ?: 'UTC';
        $leadMinutes = $preferences->activity_reminder_lead_minutes;

        /** @var Carbon $startsAt */
        $startsAt = $activity->starts_at_utc;
        $triggerUtc = $startsAt->copy()->subMinutes($leadMinutes);
        $evalTz = $this->resolveQuietHoursTimezone($user, $preferences, $activity->timezone ?: $tripTz, $tripTz);

        if ($this->isInQuietHours($triggerUtc->copy()->setTimezone($evalTz), $preferences)) {
            return null;
        }

        $formattedTime = $startsAt->copy()->setTimezone($activity->timezone ?: $tripTz)->format('H:i');
        $dedupeKey = "{$trip->id}:activity_reminder:{$activity->id}:{$triggerUtc->timestamp}";

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

        return $dedupeKey;
    }

    /**
     * @return array<int, string>
     */
    private function scheduleStayReminders(
        Trip $trip,
        User $user,
        NotificationPreference $preferences,
        Stay $stay,
    ): array {
        $tripTz = $trip->primary_timezone ?: 'UTC';
        $stayTz = $stay->timezone ?: $tripTz;
        $evalTz = $this->resolveQuietHoursTimezone($user, $preferences, $stayTz, $tripTz);
        $keys = [];

        if ($stay->check_in_at) {
            $checkInUtc = Carbon::parse($stay->check_in_at)->utc();
            $triggerUtc = $checkInUtc->copy()->subHour();

            if (! $this->isInQuietHours($triggerUtc->copy()->setTimezone($evalTz), $preferences)) {
                $dedupeKey = "{$trip->id}:stay_checkin:{$stay->id}:{$triggerUtc->timestamp}";
                $keys[] = $dedupeKey;

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

            if (! $this->isInQuietHours($triggerUtc->copy()->setTimezone($evalTz), $preferences)) {
                $dedupeKey = "{$trip->id}:stay_checkout:{$stay->id}:{$triggerUtc->timestamp}";
                $keys[] = $dedupeKey;

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

        return $keys;
    }

    /**
     * Schedule flight prep (3 hours prior) and gate departure (45 minutes prior) reminders.
     * Never includes booking_reference in reminder payloads.
     *
     * @return array<int, string>
     */
    private function scheduleFlightReminders(
        Trip $trip,
        User $user,
        NotificationPreference $preferences,
        Flight $flight,
    ): array {
        $tripTz = $trip->primary_timezone ?: 'UTC';
        $keys = [];

        foreach ($flight->segments as $segment) {
            if ($segment->scheduled_departure_utc === null) {
                continue;
            }

            $originTz = $segment->origin_timezone ?: $tripTz;
            $evalTz = $this->resolveQuietHoursTimezone($user, $preferences, $originTz, $tripTz);
            $depUtc = Carbon::parse($segment->scheduled_departure_utc)->utc();
            $localDepStr = $depUtc->copy()->setTimezone($originTz)->format('H:i');

            // 1. Flight Prep Reminder (3 hours before scheduled departure)
            $prepTriggerUtc = $depUtc->copy()->subHours(3);
            if (! $this->isInQuietHours($prepTriggerUtc->copy()->setTimezone($evalTz), $preferences)) {
                $prepKey = "{$trip->id}:flight_prep:{$flight->id}:{$segment->id}:{$prepTriggerUtc->timestamp}";
                $keys[] = $prepKey;
                $terminalLabel = ! empty($segment->terminal) ? " from Terminal {$segment->terminal}" : '';

                Reminder::updateOrCreate(
                    [
                        'trip_id' => $trip->id,
                        'dedupe_key' => $prepKey,
                    ],
                    [
                        'itinerary_item_id' => null,
                        'checklist_id' => null,
                        'type' => 'flight_prep',
                        'title' => "Flight Prep: {$segment->flight_number} ({$segment->origin_airport} → {$segment->destination_airport})",
                        'body' => "Scheduled departure at {$localDepStr}{$terminalLabel}. Verify check-in and live gate status with your airline.",
                        'trigger_at_utc' => $prepTriggerUtc,
                        'timezone' => $originTz,
                        'delivery_channel' => 'local',
                        'status' => 'scheduled',
                        'source_version' => $flight->version ?? 1,
                    ]
                );
            }

            // 2. Gate Departure Reminder (45 minutes before scheduled departure)
            $gateTriggerUtc = $depUtc->copy()->subMinutes(45);
            if (! $this->isInQuietHours($gateTriggerUtc->copy()->setTimezone($evalTz), $preferences)) {
                $gateKey = "{$trip->id}:flight_gate:{$flight->id}:{$segment->id}:{$gateTriggerUtc->timestamp}";
                $keys[] = $gateKey;
                $gateLabel = ! empty($segment->gate) ? " from Gate {$segment->gate}" : '';

                Reminder::updateOrCreate(
                    [
                        'trip_id' => $trip->id,
                        'dedupe_key' => $gateKey,
                    ],
                    [
                        'itinerary_item_id' => null,
                        'checklist_id' => null,
                        'type' => 'flight_gate_departure',
                        'title' => "Boarding Soon: {$segment->flight_number} to {$segment->destination_airport}",
                        'body' => "Scheduled flight departs{$gateLabel} in 45 minutes. Allow 15 minutes to leave the lounge and reach your gate.",
                        'trigger_at_utc' => $gateTriggerUtc,
                        'timezone' => $originTz,
                        'delivery_channel' => 'local',
                        'status' => 'scheduled',
                        'source_version' => $flight->version ?? 1,
                    ]
                );
            }
        }

        return $keys;
    }

    /**
     * @return array{status: string, scheduled_for_utc: CarbonImmutable, timezone: string}
     */
    private function computeAnnouncementSchedule(
        User $recipient,
        NotificationPreference $preferences,
        CarbonImmutable $nowUtc,
        string $tripTz,
    ): array {
        $evalTz = $this->resolveQuietHoursTimezone($recipient, $preferences, $tripTz, $tripTz);
        $localNow = $nowUtc->setTimezone($evalTz);

        if ($this->isInQuietHours($localNow, $preferences) && ! empty($preferences->quiet_hours_end)) {
            [$endHour, $endMinute] = array_map('intval', explode(':', $preferences->quiet_hours_end));
            $endLocal = $localNow->setTime($endHour, $endMinute, 0);
            if ($endLocal->lessThanOrEqualTo($localNow)) {
                $endLocal = $endLocal->addDay();
            }

            return [
                'status' => 'suppressed_quiet_hours',
                'scheduled_for_utc' => $endLocal->utc(),
                'timezone' => $evalTz,
            ];
        }

        return [
            'status' => 'pending',
            'scheduled_for_utc' => $nowUtc,
            'timezone' => $evalTz,
        ];
    }
}
