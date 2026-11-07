<?php

declare(strict_types=1);

namespace App\Http\Controllers\Api\V1;

use App\Application\Checklists\Data\CreateChecklistItemData;
use App\Application\Checklists\Data\UpdateChecklistItemData;
use App\Application\Checklists\Services\CreateChecklistItemService;
use App\Application\Checklists\Services\DeleteChecklistItemService;
use App\Application\Checklists\Services\ToggleChecklistItemService;
use App\Application\Checklists\Services\UpdateChecklistItemService;
use App\Application\Media\Data\UploadMediaData;
use App\Application\Media\Services\UploadMediaService;
use App\Domain\Checklists\Models\Checklist;
use App\Domain\Checklists\Models\ChecklistItem;
use App\Http\Controllers\Controller;
use App\Http\Requests\Api\V1\Checklists\StoreChecklistItemRequest;
use App\Http\Requests\Api\V1\Checklists\UpdateChecklistItemRequest;
use App\Http\Requests\Api\V1\Media\UploadMediaRequest;
use App\Http\Resources\Api\V1\ChecklistItemResource;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Response;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Gate;

final class ChecklistItemController extends Controller
{
    /**
     * Store a newly created item inside a checklist.
     */
    public function store(
        StoreChecklistItemRequest $request,
        Checklist $checklist,
        CreateChecklistItemService $service,
    ): JsonResponse {
        Gate::authorize('update', $checklist->trip);

        $item = $service->handle(
            $checklist,
            CreateChecklistItemData::from($request->validated()),
        );

        return (new ChecklistItemResource($item))
            ->response()
            ->setStatusCode(201);
    }

    /**
     * Update the specified checklist item.
     */
    public function update(
        UpdateChecklistItemRequest $request,
        ChecklistItem $item,
        UpdateChecklistItemService $service,
    ): JsonResponse {
        Gate::authorize('update', $item->trip);

        $updated = $service->handle(
            $item,
            UpdateChecklistItemData::from($request->validated()),
        );

        return (new ChecklistItemResource($updated))
            ->response();
    }

    /**
     * Toggle the packed status of the specified checklist item.
     */
    public function toggle(
        Request $request,
        ChecklistItem $item,
        ToggleChecklistItemService $service,
    ): JsonResponse {
        Gate::authorize('update', $item->trip);

        $toggled = $service->handle($item);

        return (new ChecklistItemResource($toggled))
            ->response();
    }

    /**
     * Remove the specified checklist item.
     */
    public function destroy(
        Request $request,
        ChecklistItem $item,
        DeleteChecklistItemService $service,
    ): Response {
        Gate::authorize('update', $item->trip);

        $service->handle($item);

        return response()->noContent();
    }

    /**
     * Upload and attach a photo to the specified checklist item.
     */
    public function uploadPhoto(
        UploadMediaRequest $request,
        ChecklistItem $item,
        UploadMediaService $service,
    ): JsonResponse {
        Gate::authorize('update', $item->trip);

        /** @var UploadedFile $file */
        $file = $request->file('file');

        $service->handle(
            $item->trip,
            $request->user(),
            new UploadMediaData(
                file: $file,
                title: $request->input('title', $item->title),
                attachableType: 'checklist_item',
                attachableId: $item->id,
                notes: $request->input('notes'),
            ),
        );

        return (new ChecklistItemResource($item->fresh(['checklist', 'trip'])))
            ->response();
    }
}
