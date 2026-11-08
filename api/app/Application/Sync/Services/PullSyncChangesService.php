<?php

declare(strict_types=1);

namespace App\Application\Sync\Services;

use App\Application\Sync\Data\PullSyncChangesData;
use App\Application\Sync\Data\PullSyncResult;
use App\Domain\Sync\Models\SyncCursor;
use App\Domain\Sync\Models\SyncOperation;
use App\Domain\Trips\Models\Trip;
use App\Domain\Trips\Models\TripMember;
use App\Models\User;
use Symfony\Component\HttpKernel\Exception\AccessDeniedHttpException;
use Symfony\Component\HttpKernel\Exception\NotFoundHttpException;

final class PullSyncChangesService
{
    public function execute(PullSyncChangesData $data): PullSyncResult
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
            $userTripIds = TripMember::where('user_id', $user->id)->pluck('trip_id')->all();

            $query->where(function ($q) use ($user, $userTripIds): void {
                $q->where('user_id', $user->id);
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
}
