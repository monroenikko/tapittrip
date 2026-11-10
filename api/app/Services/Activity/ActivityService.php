<?php

declare(strict_types=1);

namespace App\Services\Activity;

use App\DTOs\Activity\RecordActivityEventData;
use App\Models\ActivityEvent;
use App\Models\Trip;
use App\Models\User;
use Carbon\CarbonImmutable;
use Illuminate\Auth\Access\AuthorizationException;
use Illuminate\Database\Eloquent\Collection;

final class ActivityService
{
    /**
     * Get the chronological shared activity and moments feed for a trip.
     *
     * @return Collection<int, ActivityEvent>
     *
     * @throws AuthorizationException
     */
    public function getTripFeed(
        Trip $trip,
        User $user,
        int $limit = 30,
        ?string $beforeId = null,
    ): Collection {
        if (! $trip->hasMember($user->id) && $trip->owner_id !== $user->id) {
            throw new AuthorizationException('You are not a member of this trip.');
        }

        $clampedLimit = max(1, min(100, $limit));

        $query = $trip->activityEvents()
            ->reorder('occurred_at', 'desc')
            ->orderByDesc('id')
            ->with(['actor']);

        if ($beforeId !== null && trim($beforeId) !== '') {
            $cursorEvent = ActivityEvent::query()
                ->where('trip_id', $trip->id)
                ->find($beforeId);

            if ($cursorEvent !== null) {
                $query->where(function ($q) use ($cursorEvent): void {
                    $q->where('occurred_at', '<', $cursorEvent->occurred_at)
                        ->orWhere(function ($sub) use ($cursorEvent): void {
                            $sub->where('occurred_at', '=', $cursorEvent->occurred_at)
                                ->where('id', '<', $cursorEvent->id);
                        });
                });
            }
        }

        return $query->limit($clampedLimit)->get();
    }

    /**
     * Record or update a shared circle activity event (idempotent / deduplicated per TC-8.2).
     */
    public function recordEvent(Trip $trip, User $actor, RecordActivityEventData $data): ActivityEvent
    {
        $occurredAt = $data->occurredAt ?? CarbonImmutable::now($trip->primary_timezone ?: 'UTC');

        // Deduplication: if an event for this entity and event_type already exists, update it
        if ($data->entityType !== null && $data->entityId !== null) {
            /** @var ActivityEvent|null $existing */
            $existing = ActivityEvent::query()
                ->where('trip_id', $trip->id)
                ->where('entity_type', $data->entityType)
                ->where('entity_id', $data->entityId)
                ->where('event_type', $data->eventType)
                ->first();

            if ($existing !== null) {
                $existing->update([
                    'actor_id' => $actor->id,
                    'title' => $data->title,
                    'summary' => $data->summary,
                    'metadata' => $data->metadata,
                    'occurred_at' => $occurredAt,
                ]);

                return $existing->fresh(['actor']);
            }
        }

        /** @var ActivityEvent $event */
        $event = ActivityEvent::create([
            'trip_id' => $trip->id,
            'actor_id' => $actor->id,
            'event_type' => $data->eventType,
            'title' => $data->title,
            'summary' => $data->summary,
            'entity_type' => $data->entityType,
            'entity_id' => $data->entityId,
            'metadata' => $data->metadata,
            'occurred_at' => $occurredAt,
        ]);

        return $event->load(['actor']);
    }

    /**
     * Remove / soft-delete any activity events associated with an unshared or deleted entity.
     */
    public function removeEventForEntity(string $entityType, string $entityId): void
    {
        ActivityEvent::query()
            ->where('entity_type', $entityType)
            ->where('entity_id', $entityId)
            ->delete();
    }
}
