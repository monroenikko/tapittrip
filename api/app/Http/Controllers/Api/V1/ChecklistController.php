<?php

declare(strict_types=1);

namespace App\Http\Controllers\Api\V1;

use App\DTOs\Checklists\CreateChecklistData;
use App\Http\Controllers\Controller;
use App\Http\Requests\Api\V1\Checklists\ApplyChecklistTemplateRequest;
use App\Http\Requests\Api\V1\Checklists\StoreChecklistRequest;
use App\Http\Resources\Api\V1\ChecklistResource;
use App\Models\Checklist;
use App\Models\Trip;
use App\Services\Checklists\ChecklistService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;
use Illuminate\Http\Response;
use Illuminate\Support\Facades\Gate;

final class ChecklistController extends Controller
{
    public function __construct(
        private readonly ChecklistService $checklistService,
    ) {}

    /**
     * List all checklists for a trip.
     */
    public function index(Request $request, Trip $trip): AnonymousResourceCollection
    {
        Gate::authorize('view', $trip);

        return ChecklistResource::collection($this->checklistService->getTripChecklists($trip));
    }

    /**
     * Store a newly created checklist for a trip.
     */
    public function store(
        StoreChecklistRequest $request,
        Trip $trip,
    ): JsonResponse {
        Gate::authorize('update', $trip);

        $checklist = $this->checklistService->createChecklist(
            $trip,
            CreateChecklistData::from($request->validated()),
        );

        return (new ChecklistResource($checklist))
            ->response()
            ->setStatusCode(201);
    }

    /**
     * Apply a starter packing template to the trip.
     */
    public function applyTemplate(
        ApplyChecklistTemplateRequest $request,
        Trip $trip,
    ): JsonResponse {
        Gate::authorize('update', $trip);

        $checklist = $this->checklistService->applyTemplate(
            $trip,
            (string) $request->validated('template'),
        );

        return (new ChecklistResource($checklist))
            ->response()
            ->setStatusCode(201);
    }

    /**
     * Display the specified checklist.
     */
    public function show(Request $request, Checklist $checklist): JsonResponse
    {
        Gate::authorize('view', $checklist->trip);

        return (new ChecklistResource($checklist->load('items')))
            ->response();
    }

    /**
     * Remove the specified checklist and all its items.
     */
    public function destroy(
        Request $request,
        Checklist $checklist,
    ): Response {
        Gate::authorize('update', $checklist->trip);

        $this->checklistService->deleteChecklist($checklist);

        return response()->noContent();
    }
}
