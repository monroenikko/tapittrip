<?php

declare(strict_types=1);

namespace App\Http\Controllers\Api\V1;

use App\Application\Media\Data\UploadMediaData;
use App\Application\Media\Services\UploadMediaService;
use App\DTOs\Checklists\CreateChecklistItemData;
use App\DTOs\Checklists\UpdateChecklistItemData;
use App\Http\Controllers\Controller;
use App\Http\Requests\Api\V1\Checklists\StoreChecklistItemRequest;
use App\Http\Requests\Api\V1\Checklists\UpdateChecklistItemRequest;
use App\Http\Requests\Api\V1\Media\UploadMediaRequest;
use App\Http\Resources\Api\V1\ChecklistItemResource;
use App\Models\Checklist;
use App\Models\ChecklistItem;
use App\Services\Checklists\ChecklistService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Response;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Gate;

final class ChecklistItemController extends Controller
{
    public function __construct(
        private readonly ChecklistService $checklistService,
    ) {}

    /**
     * Store a newly created item inside a checklist.
     */
    public function store(
        StoreChecklistItemRequest $request,
        Checklist $checklist,
    ): JsonResponse {
        Gate::authorize('update', $checklist->trip);

        $item = $this->checklistService->createItem(
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
    ): JsonResponse {
        Gate::authorize('update', $item->trip);

        $updated = $this->checklistService->updateItem(
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
    ): JsonResponse {
        Gate::authorize('update', $item->trip);

        $toggled = $this->checklistService->toggleItem($item);

        return (new ChecklistItemResource($toggled))
            ->response();
    }

    /**
     * Remove the specified checklist item.
     */
    public function destroy(
        Request $request,
        ChecklistItem $item,
    ): Response {
        Gate::authorize('update', $item->trip);

        $this->checklistService->deleteItem($item);

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
