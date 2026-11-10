<?php

declare(strict_types=1);

namespace App\Http\Controllers\Api\V1;

use App\DTOs\Sync\PullSyncChangesData;
use App\DTOs\Sync\PushSyncOperationsData;
use App\Http\Controllers\Controller;
use App\Http\Requests\Api\V1\Sync\PullSyncChangesRequest;
use App\Http\Requests\Api\V1\Sync\PushSyncOperationsRequest;
use App\Services\Sync\SyncService;
use App\Support\Http\ApiResponse;
use Illuminate\Http\JsonResponse;

final class SyncController extends Controller
{
    public function __construct(
        private readonly SyncService $service,
        private readonly ApiResponse $response,
    ) {}

    /**
     * Push a batch of client offline mutations.
     */
    public function push(PushSyncOperationsRequest $request): JsonResponse
    {
        $data = PushSyncOperationsData::fromArray($request->user()->id, $request->validated());
        $results = $this->service->push($data);

        return $this->response->success([
            'results' => array_map(static fn ($r) => $r->toArray(), $results),
        ]);
    }

    /**
     * Pull updates from the server using monotonic sequence cursors.
     */
    public function pull(PullSyncChangesRequest $request): JsonResponse
    {
        $validated = $request->validated();
        $data = new PullSyncChangesData(
            userId: $request->user()->id,
            deviceKey: (string) $validated['device_key'],
            cursor: isset($validated['cursor']) ? (int) $validated['cursor'] : 0,
            tripId: isset($validated['trip_id']) ? (string) $validated['trip_id'] : null,
            limit: isset($validated['limit']) ? (int) $validated['limit'] : 50,
        );

        $result = $this->service->pull($data);

        return $this->response->success($result->toArray());
    }
}
