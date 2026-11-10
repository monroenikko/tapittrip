<?php

declare(strict_types=1);

namespace App\Services\Sync;

use App\Domain\Stays\StayPrivacy;
use App\DTOs\Sync\PullSyncChangesData;
use App\DTOs\Sync\PullSyncResult;
use App\DTOs\Sync\PushSyncOperationsData;
use App\DTOs\Sync\SyncOperationItemData;
use App\DTOs\Sync\SyncOperationResult;
use App\Models\Checklist;
use App\Models\ChecklistItem;
use App\Models\ItineraryItem;
use App\Models\Stay;
use App\Models\SyncCursor;
use App\Models\SyncOperation;
use App\Models\Trip;
use App\Models\TripDay;
use App\Models\TripMember;
use App\Models\TripTraveler;
use App\Models\User;
use App\Services\Notifications\NotificationService;
use Carbon\CarbonImmutable;
use Illuminate\Support\Facades\DB;
use Symfony\Component\HttpKernel\Exception\AccessDeniedHttpException;
use Symfony\Component\HttpKernel\Exception\NotFoundHttpException;

final class SyncService
{
    /**
     * Push a batch of client offline mutations, verifying idempotency and permissions.
     *
     * @return array<int, SyncOperationResult>
     */
    public function push(PushSyncOperationsData $data): array
    {
        $user = User::findOrFail($data->userId);
        $results = [];
        $maxSequence = 0;

        DB::transaction(function () use ($data, $user, &$results, &$maxSequence): void {
            foreach ($data->operations as $operation) {
                // 1. Idempotency Check: deduplicate if operation_id already processed
                $existing = SyncOperation::where('operation_id', $operation->operationId)
                    ->where('user_id', $user->id)
                    ->first();

                if ($existing !== null) {
                    $results[] = new SyncOperationResult(
                        operationId: $existing->operation_id,
                        status: $existing->status,
                        serverSequence: $existing->server_sequence,
                        currentVersion: null,
                        conflictDetails: $existing->conflict_details,
                    );
                    if ($existing->server_sequence > $maxSequence) {
                        $maxSequence = $existing->server_sequence;
                    }

                    continue;
                }

                // 2. Authorization Check for trip
                $tripId = $operation->tripId;
                if ($tripId !== null) {
                    $trip = Trip::find($tripId);
                    $role = $trip?->memberRole($user);
                    $isAuthorizedEditor = $trip !== null && $trip->hasMember($user) && in_array($role, ['owner', 'editor'], true);
                    $isViewerOwnChecklistCompletion = $trip !== null
                        && $trip->hasMember($user)
                        && $role === 'viewer'
                        && $operation->entityType === 'checklist_item'
                        && $operation->operationType === 'update'
                        && empty(array_diff(array_keys($operation->payload ?? []), ['is_packed', 'packed_at']))
                        && ChecklistItem::query()
                            ->where('id', $operation->entityId)
                            ->where('trip_id', $trip->id)
                            ->where('assigned_user_id', $user->id)
                            ->exists();

                    if (! $isAuthorizedEditor && ! $isViewerOwnChecklistCompletion) {
                        $rejectedOp = SyncOperation::create([
                            'operation_id' => $operation->operationId,
                            'user_id' => $user->id,
                            'trip_id' => $tripId,
                            'device_key' => $data->deviceKey,
                            'entity_type' => $operation->entityType,
                            'entity_id' => $operation->entityId,
                            'operation_type' => $operation->operationType,
                            'payload' => $operation->payload,
                            'base_version' => $operation->baseVersion,
                            'status' => 'rejected',
                            'conflict_details' => ['reason' => 'Unauthorized trip membership or insufficient permissions'],
                            'processed_at' => now(),
                        ]);
                        $rejectedOp->refresh();

                        $results[] = new SyncOperationResult(
                            operationId: $operation->operationId,
                            status: 'rejected',
                            serverSequence: $rejectedOp->server_sequence,
                            currentVersion: null,
                            conflictDetails: $rejectedOp->conflict_details,
                        );

                        continue;
                    }
                }

                // 3. Process Entity Mutation & Detect Conflicts
                $result = $this->applyMutation($user, $data->deviceKey, $operation);
                $results[] = $result;

                if ($result->serverSequence !== null && $result->serverSequence > $maxSequence) {
                    $maxSequence = $result->serverSequence;
                }
            }

            // Update SyncCursor if operations were processed
            if ($maxSequence > 0) {
                SyncCursor::updateOrCreate(
                    [
                        'user_id' => $user->id,
                        'device_key' => $data->deviceKey,
                        'trip_id' => $data->operations[0]->tripId ?? null,
                    ],
                    [
                        'last_server_sequence' => $maxSequence,
                    ]
                );
            }
        });

        return $results;
    }

    /**
     * Pull updates from the server using monotonic sequence cursors.
     */
    public function pull(PullSyncChangesData $data): PullSyncResult
    {
        $user = User::findOrFail($data->userId);

        $query = SyncOperation::query()
            ->where('server_sequence', '>', $data->cursor)
            ->where('status', 'accepted')
            ->orderBy('server_sequence', 'asc');

        if ($data->tripId !== null) {
            $trip = Trip::find($data->tripId);
            if ($trip === null) {
                throw new NotFoundHttpException('Trip not found');
            }
            if (! $trip->hasMember($user)) {
                throw new AccessDeniedHttpException('User is not a member of this trip');
            }

            $query->where('trip_id', $data->tripId);
        } else {
            $userTripIds = TripMember::query()
                ->where('user_id', $user->id)
                ->where('invitation_status', 'accepted')
                ->pluck('trip_id')
                ->all();

            $query->where(function ($q) use ($user, $userTripIds): void {
                $q->where(function ($sub) use ($user): void {
                    $sub->whereNull('trip_id')
                        ->where('user_id', $user->id);
                });
                if ($userTripIds !== []) {
                    $q->orWhereIn('trip_id', $userTripIds);
                }
            });
        }

        $records = $query->limit($data->limit + 1)->get();
        $hasMore = $records->count() > $data->limit;
        $items = $hasMore ? $records->slice(0, $data->limit) : $records;

        $newCursor = $data->cursor;
        $operations = [];

        foreach ($items as $op) {
            $operations[] = [
                'id' => $op->id,
                'operation_id' => $op->operation_id,
                'trip_id' => $op->trip_id,
                'device_key' => $op->device_key,
                'entity_type' => $op->entity_type,
                'entity_id' => $op->entity_id,
                'operation_type' => $op->operation_type,
                'payload' => $op->payload,
                'base_version' => $op->base_version,
                'server_sequence' => $op->server_sequence,
                'created_at' => $op->created_at?->toIso8601String(),
            ];

            if ($op->server_sequence > $newCursor) {
                $newCursor = $op->server_sequence;
            }
        }

        // Update cursor in database if we moved forward
        if ($newCursor > $data->cursor && $data->deviceKey !== '') {
            SyncCursor::updateOrCreate(
                [
                    'user_id' => $user->id,
                    'device_key' => $data->deviceKey,
                    'trip_id' => $data->tripId,
                ],
                [
                    'last_server_sequence' => $newCursor,
                ]
            );
        }

        return new PullSyncResult(
            cursor: $newCursor,
            operations: $operations,
            hasMore: $hasMore,
        );
    }

    private function applyMutation(User $user, string $deviceKey, SyncOperationItemData $op): SyncOperationResult
    {
        return match ($op->entityType) {
            'checklist_item' => $this->handleChecklistItem($user, $deviceKey, $op),
            'itinerary_item' => $this->handleItineraryItem($user, $deviceKey, $op),
            'stay' => $this->handleStay($user, $deviceKey, $op),
            'trip' => $this->handleTrip($user, $deviceKey, $op),
            default => $this->rejectUnsupported($user, $deviceKey, $op, "Unsupported entity type: {$op->entityType}"),
        };
    }

    private function handleChecklistItem(User $user, string $deviceKey, SyncOperationItemData $op): SyncOperationResult
    {
        if ($op->tripId === null) {
            return $this->rejectUnsupported($user, $deviceKey, $op, 'trip_id is required for checklist_item sync operations');
        }

        if ($op->operationType === 'update') {
            $item = ChecklistItem::find($op->entityId);
            if ($item === null) {
                return $this->rejectUnsupported($user, $deviceKey, $op, 'Checklist item not found');
            }
            if ($item->trip_id !== $op->tripId) {
                return $this->rejectUnsupported($user, $deviceKey, $op, 'Checklist item does not belong to the specified trip');
            }

            // Conflict detection
            if ($op->baseVersion < $item->version) {
                return $this->recordConflict($user, $deviceKey, $op, $item->version, $this->serializeChecklistConflictPayload($item));
            }

            $payload = $op->payload ?? [];
            $trip = Trip::find($op->tripId);
            if (array_key_exists('assigned_user_id', $payload) || array_key_exists('assigned_traveler_id', $payload)) {
                $assignedUser = $payload['assigned_user_id'] ?? null;
                $assignedTraveler = $payload['assigned_traveler_id'] ?? null;
                if ($assignedUser !== null && $assignedTraveler !== null) {
                    return $this->rejectUnsupported($user, $deviceKey, $op, 'Checklist item cannot be assigned to both user and traveler');
                }
                if ($assignedUser !== null && ($trip === null || ! $trip->hasMember((string) $assignedUser))) {
                    return $this->rejectUnsupported($user, $deviceKey, $op, 'Assigned user is not an accepted member of this trip');
                }
                if ($assignedTraveler !== null && ! TripTraveler::where('id', (string) $assignedTraveler)->where('trip_id', $op->tripId)->exists()) {
                    return $this->rejectUnsupported($user, $deviceKey, $op, 'Assigned traveler does not belong to this trip');
                }
                if (array_key_exists('assigned_user_id', $payload)) {
                    $item->assigned_user_id = $assignedUser !== null ? (string) $assignedUser : null;
                    if ($item->assigned_user_id !== null) {
                        $item->assigned_traveler_id = null;
                    }
                }
                if (array_key_exists('assigned_traveler_id', $payload)) {
                    $item->assigned_traveler_id = $assignedTraveler !== null ? (string) $assignedTraveler : null;
                    if ($item->assigned_traveler_id !== null) {
                        $item->assigned_user_id = null;
                    }
                }
            }

            if (array_key_exists('title', $payload)) {
                $item->title = (string) $payload['title'];
            }
            if (array_key_exists('category', $payload)) {
                $item->category = (string) $payload['category'];
            }
            if (array_key_exists('quantity', $payload)) {
                $item->quantity = (int) $payload['quantity'];
            }
            if (array_key_exists('notes', $payload)) {
                $item->notes = $payload['notes'];
            }
            if (array_key_exists('sort_order', $payload)) {
                $item->sort_order = (int) $payload['sort_order'];
            }
            if (array_key_exists('is_packed', $payload)) {
                $isPacked = (bool) $payload['is_packed'];
                $item->is_packed = $isPacked;
                $item->packed_at = $isPacked ? now() : null;
                $item->completed_by_user_id = $isPacked ? $user->id : null;
            }

            $item->version = $item->version + 1;
            $item->save();

            return $this->recordAccepted($user, $deviceKey, $op, $item->version);
        }

        if ($op->operationType === 'create') {
            $payload = $op->payload ?? [];
            $item = ChecklistItem::withTrashed()->find($op->entityId);
            if ($item !== null) {
                if ($item->trip_id !== $op->tripId) {
                    return $this->rejectUnsupported($user, $deviceKey, $op, 'Checklist item does not belong to the specified trip');
                }
                if ($item->trashed()) {
                    $item->restore();
                }

                return $this->recordAccepted($user, $deviceKey, $op, $item->version);
            }

            $checklistId = $payload['checklist_id'] ?? null;
            if (is_string($checklistId) && $checklistId !== '') {
                $checklistValid = Checklist::where('id', $checklistId)->where('trip_id', $op->tripId)->exists();
                if (! $checklistValid) {
                    return $this->rejectUnsupported($user, $deviceKey, $op, 'Invalid checklist_id for this trip');
                }
            } else {
                $firstChecklist = Checklist::where('trip_id', $op->tripId)->first();
                $checklistId = $firstChecklist?->id;
                if (! $checklistId) {
                    return $this->rejectUnsupported($user, $deviceKey, $op, 'No checklist found for this trip');
                }
            }

            $assignedUser = isset($payload['assigned_user_id']) ? (string) $payload['assigned_user_id'] : null;
            $assignedTraveler = isset($payload['assigned_traveler_id']) ? (string) $payload['assigned_traveler_id'] : null;
            $trip = Trip::find($op->tripId);
            if ($assignedUser !== null && $assignedTraveler !== null) {
                return $this->rejectUnsupported($user, $deviceKey, $op, 'Checklist item cannot be assigned to both user and traveler');
            }
            if ($assignedUser !== null && ($trip === null || ! $trip->hasMember($assignedUser))) {
                return $this->rejectUnsupported($user, $deviceKey, $op, 'Assigned user is not an accepted member of this trip');
            }
            if ($assignedTraveler !== null && ! TripTraveler::where('id', $assignedTraveler)->where('trip_id', $op->tripId)->exists()) {
                return $this->rejectUnsupported($user, $deviceKey, $op, 'Assigned traveler does not belong to this trip');
            }

            $isPacked = (bool) ($payload['is_packed'] ?? false);
            $item = new ChecklistItem;
            $item->id = $op->entityId;
            $item->trip_id = $op->tripId;
            $item->checklist_id = (string) $checklistId;
            $item->assigned_user_id = $assignedUser;
            $item->assigned_traveler_id = $assignedTraveler;
            $item->title = (string) ($payload['title'] ?? 'New Item');
            $item->category = (string) ($payload['category'] ?? 'other');
            $item->quantity = (int) ($payload['quantity'] ?? 1);
            $item->notes = $payload['notes'] ?? null;
            $item->is_packed = $isPacked;
            $item->packed_at = $isPacked ? now() : null;
            $item->completed_by_user_id = $isPacked ? $user->id : null;
            $item->version = 1;
            $item->save();

            return $this->recordAccepted($user, $deviceKey, $op, $item->version);
        }

        if ($op->operationType === 'delete') {
            $item = ChecklistItem::find($op->entityId);
            if ($item !== null) {
                if ($item->trip_id !== $op->tripId) {
                    return $this->rejectUnsupported($user, $deviceKey, $op, 'Checklist item does not belong to the specified trip');
                }
                if ($op->baseVersion < $item->version) {
                    return $this->recordConflict($user, $deviceKey, $op, $item->version, $this->serializeChecklistConflictPayload($item));
                }
                $item->delete();
            }

            return $this->recordAccepted($user, $deviceKey, $op, 0);
        }

        return $this->rejectUnsupported($user, $deviceKey, $op, "Unsupported operation type: {$op->operationType}");
    }

    /**
     * @return array<string, mixed>
     */
    private function serializeChecklistConflictPayload(ChecklistItem $item): array
    {
        return [
            'id' => $item->id,
            'trip_id' => $item->trip_id,
            'checklist_id' => $item->checklist_id,
            'title' => $item->title,
            'is_packed' => (bool) $item->is_packed,
            'assigned_user_id' => $item->assigned_user_id,
            'assigned_traveler_id' => $item->assigned_traveler_id,
            'completed_by_user_id' => $item->completed_by_user_id,
            'notes' => $item->notes,
            'version' => (int) $item->version,
        ];
    }

    private function handleItineraryItem(User $user, string $deviceKey, SyncOperationItemData $op): SyncOperationResult
    {
        if ($op->tripId === null) {
            return $this->rejectUnsupported($user, $deviceKey, $op, 'trip_id is required for itinerary_item sync operations');
        }

        if ($op->operationType === 'create') {
            $existing = ItineraryItem::withTrashed()->find($op->entityId);
            if ($existing !== null) {
                if ($existing->trip_id !== $op->tripId) {
                    return $this->rejectUnsupported($user, $deviceKey, $op, 'Itinerary item belongs to another trip');
                }
                if ($existing->trashed()) {
                    $existing->restore();
                }

                return $this->recordAccepted($user, $deviceKey, $op, $existing->version);
            }

            $payload = $op->payload ?? [];
            $tripDayId = $payload['trip_day_id'] ?? null;
            if (is_string($tripDayId) && $tripDayId !== '') {
                $dayExists = TripDay::query()
                    ->where('id', $tripDayId)
                    ->where('trip_id', $op->tripId)
                    ->exists();
                if (! $dayExists) {
                    return $this->rejectUnsupported($user, $deviceKey, $op, 'Invalid trip_day_id for this trip');
                }
            } else {
                $tripDayId = null;
            }

            $item = new ItineraryItem([
                'trip_id' => $op->tripId,
                'trip_day_id' => $tripDayId,
                'place_id' => is_string($payload['place_id'] ?? null) ? $payload['place_id'] : null,
                'stay_id' => is_string($payload['stay_id'] ?? null) ? $payload['stay_id'] : null,
                'kind' => (string) ($payload['kind'] ?? 'activity'),
                'title' => (string) ($payload['title'] ?? 'Untitled stop'),
                'notes' => array_key_exists('notes', $payload) ? $payload['notes'] : null,
                'starts_at_utc' => ! empty($payload['starts_at_utc'])
                    ? CarbonImmutable::parse((string) $payload['starts_at_utc'])->utc()
                    : null,
                'ends_at_utc' => ! empty($payload['ends_at_utc'])
                    ? CarbonImmutable::parse((string) $payload['ends_at_utc'])->utc()
                    : null,
                'timezone' => is_string($payload['timezone'] ?? null) ? $payload['timezone'] : null,
                'sort_order' => (int) ($payload['sort_order'] ?? 0),
                'status' => (string) ($payload['status'] ?? 'planned'),
                'version' => 1,
            ]);
            $item->id = $op->entityId;
            $item->save();

            return $this->recordAccepted($user, $deviceKey, $op, $item->version);
        }

        if ($op->operationType === 'update') {
            $item = ItineraryItem::find($op->entityId);
            if ($item === null) {
                return $this->rejectUnsupported($user, $deviceKey, $op, 'Itinerary item not found');
            }
            if ($item->trip_id !== $op->tripId) {
                return $this->rejectUnsupported($user, $deviceKey, $op, 'Itinerary item does not belong to the specified trip');
            }

            if ($op->baseVersion < $item->version) {
                return $this->recordConflict($user, $deviceKey, $op, $item->version, $this->serializeItineraryConflictPayload($item));
            }

            $payload = $op->payload ?? [];
            if (array_key_exists('trip_day_id', $payload)) {
                $tripDayId = $payload['trip_day_id'];
                if (is_string($tripDayId) && $tripDayId !== '') {
                    $dayExists = TripDay::query()
                        ->where('id', $tripDayId)
                        ->where('trip_id', $op->tripId)
                        ->exists();
                    if (! $dayExists) {
                        return $this->rejectUnsupported($user, $deviceKey, $op, 'Invalid trip_day_id for this trip');
                    }
                    $item->trip_day_id = $tripDayId;
                } else {
                    $item->trip_day_id = null;
                }
            }
            if (array_key_exists('kind', $payload)) {
                $item->kind = (string) $payload['kind'];
            }
            if (array_key_exists('title', $payload)) {
                $item->title = (string) $payload['title'];
            }
            if (array_key_exists('notes', $payload)) {
                $item->notes = $payload['notes'];
            }
            if (array_key_exists('status', $payload)) {
                $item->status = (string) $payload['status'];
            }
            if (array_key_exists('sort_order', $payload)) {
                $item->sort_order = (int) $payload['sort_order'];
            }
            if (array_key_exists('timezone', $payload)) {
                $item->timezone = $payload['timezone'] !== null ? (string) $payload['timezone'] : null;
            }
            if (array_key_exists('starts_at_utc', $payload)) {
                $item->starts_at_utc = ! empty($payload['starts_at_utc'])
                    ? CarbonImmutable::parse((string) $payload['starts_at_utc'])->utc()
                    : null;
            }
            if (array_key_exists('ends_at_utc', $payload)) {
                $item->ends_at_utc = ! empty($payload['ends_at_utc'])
                    ? CarbonImmutable::parse((string) $payload['ends_at_utc'])->utc()
                    : null;
            }

            $item->version = $item->version + 1;
            $item->save();

            app(NotificationService::class)->syncRemindersForItineraryItem($item);

            return $this->recordAccepted($user, $deviceKey, $op, $item->version);
        }

        if ($op->operationType === 'delete') {
            $item = ItineraryItem::find($op->entityId);
            if ($item !== null) {
                if ($item->trip_id !== $op->tripId) {
                    return $this->rejectUnsupported($user, $deviceKey, $op, 'Itinerary item does not belong to the specified trip');
                }
                if ($op->baseVersion < $item->version) {
                    return $this->recordConflict($user, $deviceKey, $op, $item->version, $this->serializeItineraryConflictPayload($item));
                }

                app(NotificationService::class)->cancelRemindersForItineraryItem($item);
                $item->delete();
            }

            return $this->recordAccepted($user, $deviceKey, $op, 0);
        }

        return $this->rejectUnsupported($user, $deviceKey, $op, "Unsupported operation type: {$op->operationType}");
    }

    /**
     * @return array<string, mixed>
     */
    private function serializeItineraryConflictPayload(ItineraryItem $item): array
    {
        return [
            'id' => $item->id,
            'trip_id' => $item->trip_id,
            'trip_day_id' => $item->trip_day_id,
            'kind' => $item->kind,
            'title' => $item->title,
            'notes' => $item->notes,
            'starts_at_utc' => $item->starts_at_utc?->toIso8601String(),
            'ends_at_utc' => $item->ends_at_utc?->toIso8601String(),
            'timezone' => $item->timezone,
            'sort_order' => $item->sort_order,
            'status' => $item->status,
            'version' => $item->version,
            'updated_at' => $item->updated_at?->toIso8601String(),
        ];
    }

    private function handleStay(User $user, string $deviceKey, SyncOperationItemData $op): SyncOperationResult
    {
        if ($op->tripId === null) {
            return $this->rejectUnsupported($user, $deviceKey, $op, 'trip_id is required for stay sync operations');
        }

        if ($op->operationType === 'create') {
            $existing = Stay::withTrashed()->find($op->entityId);
            if ($existing !== null) {
                if ($existing->trip_id !== $op->tripId) {
                    return $this->rejectUnsupported($user, $deviceKey, $op, 'Stay does not belong to the specified trip');
                }
                if ($existing->trashed()) {
                    $existing->restore();
                }

                return $this->recordAccepted($user, $deviceKey, $op, $existing->version);
            }

            $payload = $op->payload ?? [];
            $trip = Trip::find($op->tripId);
            $stay = new Stay([
                'trip_id' => $op->tripId,
                'place_id' => is_string($payload['place_id'] ?? null) ? $payload['place_id'] : null,
                'name' => (string) ($payload['name'] ?? 'Untitled Stay'),
                'stay_type' => (string) ($payload['stay_type'] ?? 'hotel'),
                'address' => array_key_exists('address', $payload) ? $payload['address'] : null,
                'latitude' => isset($payload['latitude']) && is_numeric($payload['latitude']) ? (float) $payload['latitude'] : null,
                'longitude' => isset($payload['longitude']) && is_numeric($payload['longitude']) ? (float) $payload['longitude'] : null,
                'check_in_at' => ! empty($payload['check_in_at'])
                    ? CarbonImmutable::parse((string) $payload['check_in_at'])->utc()
                    : null,
                'check_out_at' => ! empty($payload['check_out_at'])
                    ? CarbonImmutable::parse((string) $payload['check_out_at'])->utc()
                    : null,
                'timezone' => is_string($payload['timezone'] ?? null)
                    ? $payload['timezone']
                    : ($trip?->primary_timezone ?? 'UTC'),
                'phone' => ($trip?->owner_id === $user->id && array_key_exists('phone', $payload)) ? $payload['phone'] : null,
                'booking_reference' => ($trip?->owner_id === $user->id && array_key_exists('booking_reference', $payload))
                    ? $payload['booking_reference']
                    : null,
                'notes' => array_key_exists('notes', $payload) ? $payload['notes'] : null,
                'luggage_profile' => isset($payload['luggage_profile']) && is_array($payload['luggage_profile'])
                    ? $payload['luggage_profile']
                    : null,
                'version' => 1,
            ]);
            $stay->id = $op->entityId;
            $stay->save();

            return $this->recordAccepted($user, $deviceKey, $op, $stay->version);
        }

        if ($op->operationType === 'update') {
            $stay = Stay::with('trip')->find($op->entityId);
            if ($stay === null) {
                return $this->rejectUnsupported($user, $deviceKey, $op, 'Stay not found');
            }
            if ($stay->trip_id !== $op->tripId) {
                return $this->rejectUnsupported($user, $deviceKey, $op, 'Stay does not belong to the specified trip');
            }

            if ($op->baseVersion < $stay->version) {
                return $this->recordConflict(
                    $user,
                    $deviceKey,
                    $op,
                    $stay->version,
                    StayPrivacy::redactServerPayload($stay, $user),
                );
            }

            $payload = $op->payload ?? [];
            $isOwner = StayPrivacy::isOwner($stay, $user);

            if (array_key_exists('name', $payload)) {
                $stay->name = (string) $payload['name'];
            }
            if (array_key_exists('stay_type', $payload)) {
                $stay->stay_type = (string) $payload['stay_type'];
            }
            if (array_key_exists('address', $payload)) {
                $stay->address = $payload['address'] !== null ? (string) $payload['address'] : null;
            }
            if (array_key_exists('latitude', $payload)) {
                $stay->latitude = $payload['latitude'] !== null ? (float) $payload['latitude'] : null;
            }
            if (array_key_exists('longitude', $payload)) {
                $stay->longitude = $payload['longitude'] !== null ? (float) $payload['longitude'] : null;
            }
            if (array_key_exists('check_in_at', $payload)) {
                $stay->check_in_at = ! empty($payload['check_in_at'])
                    ? CarbonImmutable::parse((string) $payload['check_in_at'])->utc()
                    : null;
            }
            if (array_key_exists('check_out_at', $payload)) {
                $stay->check_out_at = ! empty($payload['check_out_at'])
                    ? CarbonImmutable::parse((string) $payload['check_out_at'])->utc()
                    : null;
            }
            if (array_key_exists('timezone', $payload) && $payload['timezone'] !== null) {
                $stay->timezone = (string) $payload['timezone'];
            }
            if ($isOwner && array_key_exists('phone', $payload)) {
                $stay->phone = $payload['phone'] !== null ? (string) $payload['phone'] : null;
            }
            if ($isOwner && array_key_exists('booking_reference', $payload)) {
                $stay->booking_reference = $payload['booking_reference'] !== null ? (string) $payload['booking_reference'] : null;
            }
            if (array_key_exists('notes', $payload)) {
                $stay->notes = $payload['notes'];
            }
            if (array_key_exists('luggage_profile', $payload) && is_array($payload['luggage_profile'])) {
                $stay->luggage_profile = $payload['luggage_profile'];
            }

            $stay->version = $stay->version + 1;
            $stay->save();

            app(NotificationService::class)->syncRemindersForStay($stay);

            return $this->recordAccepted($user, $deviceKey, $op, $stay->version);
        }

        if ($op->operationType === 'delete') {
            $stay = Stay::with('trip')->find($op->entityId);
            if ($stay !== null) {
                if ($stay->trip_id !== $op->tripId) {
                    return $this->rejectUnsupported($user, $deviceKey, $op, 'Stay does not belong to the specified trip');
                }
                if ($op->baseVersion < $stay->version) {
                    return $this->recordConflict(
                        $user,
                        $deviceKey,
                        $op,
                        $stay->version,
                        StayPrivacy::redactServerPayload($stay, $user),
                    );
                }

                app(NotificationService::class)->cancelRemindersForStay($stay);
                $stay->itineraryItems()->update(['stay_id' => null]);
                $stay->delete();
            }

            return $this->recordAccepted($user, $deviceKey, $op, 0);
        }

        return $this->rejectUnsupported($user, $deviceKey, $op, "Unsupported operation type: {$op->operationType}");
    }

    private function handleTrip(User $user, string $deviceKey, SyncOperationItemData $op): SyncOperationResult
    {
        $trip = Trip::find($op->entityId);
        if ($trip === null) {
            return $this->rejectUnsupported($user, $deviceKey, $op, 'Trip not found');
        }
        if (! $trip->hasMember($user) || ! in_array($trip->memberRole($user), ['owner', 'editor'], true)) {
            return $this->rejectUnsupported($user, $deviceKey, $op, 'Forbidden: not authorized to modify trip');
        }

        if ($op->operationType === 'update') {
            if ($op->baseVersion < $trip->version) {
                return $this->recordConflict($user, $deviceKey, $op, $trip->version, $trip->toArray());
            }

            $payload = $op->payload ?? [];
            if (array_key_exists('title', $payload)) {
                $trip->title = (string) $payload['title'];
            }
            if (array_key_exists('description', $payload)) {
                $trip->description = $payload['description'];
            }
            if (array_key_exists('traveler_mode', $payload)) {
                $trip->traveler_mode = (string) $payload['traveler_mode'];
            }

            $trip->version = $trip->version + 1;
            $trip->save();

            return $this->recordAccepted($user, $deviceKey, $op, $trip->version);
        }

        return $this->rejectUnsupported($user, $deviceKey, $op, "Unsupported operation type: {$op->operationType}");
    }

    /**
     * @param  array<string, mixed>  $serverPayload
     */
    private function recordConflict(
        User $user,
        string $deviceKey,
        SyncOperationItemData $op,
        int $serverVersion,
        array $serverPayload,
    ): SyncOperationResult {
        $conflictDetails = [
            'server_version' => $serverVersion,
            'server_payload' => $serverPayload,
        ];

        $syncOp = SyncOperation::create([
            'operation_id' => $op->operationId,
            'user_id' => $user->id,
            'trip_id' => $op->tripId,
            'device_key' => $deviceKey,
            'entity_type' => $op->entityType,
            'entity_id' => $op->entityId,
            'operation_type' => $op->operationType,
            'payload' => $op->payload,
            'base_version' => $op->baseVersion,
            'status' => 'conflict',
            'conflict_details' => $conflictDetails,
            'processed_at' => now(),
        ]);
        $syncOp->refresh();

        return new SyncOperationResult(
            operationId: $op->operationId,
            status: 'conflict',
            serverSequence: $syncOp->server_sequence,
            currentVersion: $serverVersion,
            conflictDetails: $conflictDetails,
        );
    }

    private function recordAccepted(
        User $user,
        string $deviceKey,
        SyncOperationItemData $op,
        int $currentVersion,
    ): SyncOperationResult {
        $syncOp = SyncOperation::create([
            'operation_id' => $op->operationId,
            'user_id' => $user->id,
            'trip_id' => $op->tripId,
            'device_key' => $deviceKey,
            'entity_type' => $op->entityType,
            'entity_id' => $op->entityId,
            'operation_type' => $op->operationType,
            'payload' => $op->payload,
            'base_version' => $op->baseVersion,
            'status' => 'accepted',
            'conflict_details' => null,
            'processed_at' => now(),
        ]);
        $syncOp->refresh();

        return new SyncOperationResult(
            operationId: $op->operationId,
            status: 'accepted',
            serverSequence: $syncOp->server_sequence,
            currentVersion: $currentVersion,
            conflictDetails: null,
        );
    }

    private function rejectUnsupported(
        User $user,
        string $deviceKey,
        SyncOperationItemData $op,
        string $reason,
    ): SyncOperationResult {
        $syncOp = SyncOperation::create([
            'operation_id' => $op->operationId,
            'user_id' => $user->id,
            'trip_id' => $op->tripId,
            'device_key' => $deviceKey,
            'entity_type' => $op->entityType,
            'entity_id' => $op->entityId,
            'operation_type' => $op->operationType,
            'payload' => $op->payload,
            'base_version' => $op->baseVersion,
            'status' => 'rejected',
            'conflict_details' => ['reason' => $reason],
            'processed_at' => now(),
        ]);
        $syncOp->refresh();

        return new SyncOperationResult(
            operationId: $op->operationId,
            status: 'rejected',
            serverSequence: $syncOp->server_sequence,
            currentVersion: null,
            conflictDetails: ['reason' => $reason],
        );
    }
}
