<?php

declare(strict_types=1);

namespace App\Application\Sync\Services;

use App\Application\Sync\Data\PushSyncOperationsData;
use App\Application\Sync\Data\SyncOperationItemData;
use App\Application\Sync\Data\SyncOperationResult;
use App\Domain\Checklists\Models\Checklist;
use App\Domain\Checklists\Models\ChecklistItem;
use App\Domain\Itinerary\Models\ItineraryItem;
use App\Domain\Stays\Models\Stay;
use App\Domain\Sync\Models\SyncCursor;
use App\Domain\Sync\Models\SyncOperation;
use App\Domain\Trips\Models\Trip;
use App\Models\User;
use Illuminate\Support\Facades\DB;

final class PushSyncOperationsService
{
    /**
     * @return array<int, SyncOperationResult>
     */
    public function execute(PushSyncOperationsData $data): array
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
                    if ($trip === null || ! $trip->hasMember($user) || ! in_array($trip->memberRole($user), ['owner', 'editor'], true)) {
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
        if ($op->operationType === 'update') {
            $item = ChecklistItem::find($op->entityId);
            if ($item === null) {
                return $this->rejectUnsupported($user, $deviceKey, $op, 'Checklist item not found');
            }

            // Conflict detection
            if ($op->baseVersion < $item->version) {
                return $this->recordConflict($user, $deviceKey, $op, $item->version, $item->toArray());
            }

            $payload = $op->payload ?? [];
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
            }

            $item->version = $item->version + 1;
            $item->save();

            return $this->recordAccepted($user, $deviceKey, $op, $item->version);
        }

        if ($op->operationType === 'create') {
            $payload = $op->payload ?? [];
            $item = ChecklistItem::find($op->entityId);
            if ($item === null) {
                $checklistId = $payload['checklist_id'] ?? null;
                if (! $checklistId && $op->tripId) {
                    $firstChecklist = Checklist::where('trip_id', $op->tripId)->first();
                    $checklistId = $firstChecklist?->id;
                }

                $item = new ChecklistItem;
                $item->id = $op->entityId;
                $item->trip_id = $op->tripId ?? '';
                $item->checklist_id = (string) $checklistId;
                $item->title = (string) ($payload['title'] ?? 'New Item');
                $item->category = (string) ($payload['category'] ?? 'General');
                $item->quantity = (int) ($payload['quantity'] ?? 1);
                $item->notes = $payload['notes'] ?? null;
                $item->is_packed = (bool) ($payload['is_packed'] ?? false);
                $item->version = 1;
                $item->save();
            }

            return $this->recordAccepted($user, $deviceKey, $op, $item->version);
        }

        if ($op->operationType === 'delete') {
            $item = ChecklistItem::find($op->entityId);
            $item?->delete();

            return $this->recordAccepted($user, $deviceKey, $op, 0);
        }

        return $this->rejectUnsupported($user, $deviceKey, $op, "Unsupported operation type: {$op->operationType}");
    }

    private function handleItineraryItem(User $user, string $deviceKey, SyncOperationItemData $op): SyncOperationResult
    {
        if ($op->operationType === 'update') {
            $item = ItineraryItem::find($op->entityId);
            if ($item === null) {
                return $this->rejectUnsupported($user, $deviceKey, $op, 'Itinerary item not found');
            }

            if ($op->baseVersion < $item->version) {
                return $this->recordConflict($user, $deviceKey, $op, $item->version, $item->toArray());
            }

            $payload = $op->payload ?? [];
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
            if (array_key_exists('planned_start_time', $payload)) {
                $item->planned_start_time = $payload['planned_start_time'];
            }
            if (array_key_exists('planned_end_time', $payload)) {
                $item->planned_end_time = $payload['planned_end_time'];
            }

            $item->version = $item->version + 1;
            $item->save();

            return $this->recordAccepted($user, $deviceKey, $op, $item->version);
        }

        if ($op->operationType === 'delete') {
            $item = ItineraryItem::find($op->entityId);
            $item?->delete();

            return $this->recordAccepted($user, $deviceKey, $op, 0);
        }

        return $this->rejectUnsupported($user, $deviceKey, $op, "Unsupported operation type: {$op->operationType}");
    }

    private function handleStay(User $user, string $deviceKey, SyncOperationItemData $op): SyncOperationResult
    {
        if ($op->operationType === 'update') {
            $stay = Stay::find($op->entityId);
            if ($stay === null) {
                return $this->rejectUnsupported($user, $deviceKey, $op, 'Stay not found');
            }

            if ($op->baseVersion < $stay->version) {
                return $this->recordConflict($user, $deviceKey, $op, $stay->version, $stay->toArray());
            }

            $payload = $op->payload ?? [];
            if (array_key_exists('name', $payload)) {
                $stay->name = (string) $payload['name'];
            }
            if (array_key_exists('address', $payload)) {
                $stay->address = (string) $payload['address'];
            }
            if (array_key_exists('notes', $payload)) {
                $stay->notes = $payload['notes'];
            }

            $stay->version = $stay->version + 1;
            $stay->save();

            return $this->recordAccepted($user, $deviceKey, $op, $stay->version);
        }

        if ($op->operationType === 'delete') {
            $stay = Stay::find($op->entityId);
            $stay?->delete();

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
