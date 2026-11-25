<?php

declare(strict_types=1);

namespace App\Services\Circles;

use App\DTOs\Activity\RecordActivityEventData;
use App\DTOs\Circles\CreateAnnouncementData;
use App\DTOs\Circles\UpdateAnnouncementData;
use App\Exceptions\VersionConflictException;
use App\Models\Trip;
use App\Models\TripAnnouncement;
use App\Models\User;
use App\Services\Activity\ActivityService;
use App\Services\Notifications\NotificationService;
use Carbon\CarbonImmutable;
use Illuminate\Auth\Access\AuthorizationException;
use Illuminate\Database\Eloquent\Collection;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

final class TripAnnouncementService
{
    public function __construct(
        private readonly ActivityService $activityService,
        private readonly NotificationService $notificationService,
    ) {}

    /**
     * List organizer announcements visible to any accepted circle member in-app (TC-5.1).
     *
     * @return Collection<int, TripAnnouncement>
     *
     * @throws AuthorizationException
     */
    public function listForTrip(Trip $trip, User $user): Collection
    {
        if (! $trip->hasMember($user->id) && $trip->owner_id !== $user->id) {
            throw new AuthorizationException('You are not a member of this trip circle.');
        }

        return $trip->announcements()
            ->with(['author'])
            ->get();
    }

    /**
     * Post an organizer announcement idempotently (supports client_operation_id retries).
     *
     * @throws AuthorizationException
     */
    public function create(Trip $trip, User $actor, CreateAnnouncementData $data): TripAnnouncement
    {
        if ($trip->owner_id !== $actor->id && $trip->memberRole($actor) !== 'owner') {
            throw new AuthorizationException('Only the trip organizer can post circle announcements.');
        }

        return DB::transaction(function () use ($trip, $actor, $data): TripAnnouncement {
            if ($data->clientOperationId !== null && $data->clientOperationId !== '') {
                /** @var TripAnnouncement|null $existing */
                $existing = TripAnnouncement::query()
                    ->where('trip_id', $trip->id)
                    ->where('client_operation_id', $data->clientOperationId)
                    ->with(['author'])
                    ->first();

                if ($existing !== null) {
                    return $existing;
                }
            }

            /** @var TripAnnouncement $announcement */
            $announcement = TripAnnouncement::create([
                'trip_id' => $trip->id,
                'author_id' => $actor->id,
                'title' => trim($data->title),
                'body' => trim($data->body),
                'is_pinned' => $data->isPinned,
                'client_operation_id' => $data->clientOperationId,
                'version' => 1,
            ]);

            $this->activityService->recordEvent($trip, $actor, new RecordActivityEventData(
                eventType: 'announcement_posted',
                title: trim($data->title),
                summary: Str::limit(trim($data->body), 160),
                entityType: 'trip_announcement',
                entityId: $announcement->id,
                metadata: [
                    'announcement_id' => $announcement->id,
                    'is_pinned' => $announcement->is_pinned,
                ],
                occurredAt: CarbonImmutable::now($trip->primary_timezone ?: 'UTC'),
            ));

            $this->notificationService->dispatchAnnouncementNotifications($trip, $announcement, $actor);

            return $announcement->fresh(['author']) ?? $announcement;
        });
    }

    /**
     * Update an existing announcement without creating duplicate feed entries or notices.
     *
     * @throws AuthorizationException
     * @throws VersionConflictException
     */
    public function update(
        TripAnnouncement $announcement,
        User $actor,
        UpdateAnnouncementData $data,
    ): TripAnnouncement {
        $trip = $announcement->trip;
        if ($trip === null || ($trip->owner_id !== $actor->id && $trip->memberRole($actor) !== 'owner')) {
            throw new AuthorizationException('Only the trip organizer can edit circle announcements.');
        }

        return DB::transaction(function () use ($announcement, $trip, $actor, $data): TripAnnouncement {
            /** @var TripAnnouncement $locked */
            $locked = TripAnnouncement::query()
                ->whereKey($announcement->id)
                ->lockForUpdate()
                ->firstOrFail();

            if ($data->baseVersion !== null && $data->baseVersion !== $locked->version) {
                throw new VersionConflictException(
                    serverVersion: (int) $locked->version,
                    serverPayload: [
                        'id' => $locked->id,
                        'trip_id' => $locked->trip_id,
                        'title' => $locked->title,
                        'body' => $locked->body,
                        'is_pinned' => (bool) $locked->is_pinned,
                        'version' => (int) $locked->version,
                    ],
                );
            }

            $updates = ['version' => $locked->version + 1];
            if ($data->title !== null) {
                $updates['title'] = trim($data->title);
            }
            if ($data->body !== null) {
                $updates['body'] = trim($data->body);
            }
            if ($data->isPinned !== null) {
                $updates['is_pinned'] = $data->isPinned;
            }

            $locked->update($updates);

            $this->activityService->recordEvent($trip, $actor, new RecordActivityEventData(
                eventType: 'announcement_posted',
                title: $locked->title,
                summary: Str::limit($locked->body, 160),
                entityType: 'trip_announcement',
                entityId: $locked->id,
                metadata: [
                    'announcement_id' => $locked->id,
                    'is_pinned' => $locked->is_pinned,
                    'edited' => true,
                ],
                occurredAt: CarbonImmutable::now($trip->primary_timezone ?: 'UTC'),
            ));

            $this->notificationService->syncAnnouncementNotifications($trip, $locked, $actor);

            return $locked->fresh(['author']) ?? $locked;
        });
    }

    /**
     * Delete an announcement and cancel any undelivered companion notices.
     *
     * @throws AuthorizationException
     */
    public function delete(TripAnnouncement $announcement, User $actor): void
    {
        $trip = $announcement->trip;
        if ($trip === null || ($trip->owner_id !== $actor->id && $trip->memberRole($actor) !== 'owner')) {
            throw new AuthorizationException('Only the trip organizer can delete circle announcements.');
        }

        DB::transaction(function () use ($announcement): void {
            $this->notificationService->cancelAnnouncementNotifications($announcement);
            $announcement->delete();
        });
    }
}
