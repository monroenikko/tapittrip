<?php

declare(strict_types=1);

namespace App\Http\Controllers\Api\V1;

use App\Application\Checklists\Data\CreateChecklistData;
use App\Application\Checklists\Services\ApplyChecklistTemplateService;
use App\Application\Checklists\Services\CreateChecklistService;
use App\Application\Checklists\Services\DeleteChecklistService;
use App\Application\Checklists\Services\GetTripChecklistsService;
use App\Domain\Checklists\Models\Checklist;
use App\Domain\Trips\Models\Trip;
use App\Http\Controllers\Controller;
use App\Http\Requests\Api\V1\Checklists\ApplyChecklistTemplateRequest;
use App\Http\Requests\Api\V1\Checklists\StoreChecklistRequest;
use App\Http\Resources\Api\V1\ChecklistResource;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;
use Illuminate\Http\Response;
use Illuminate\Support\Facades\Gate;

final class ChecklistController extends Controller
{
    /**
     * List all checklists for a trip.
     */
    public function index(
        Request $request,
        Trip $trip,
        GetTripChecklistsService $service,
    ): AnonymousResourceCollection {
        Gate::authorize('view', $trip);

        return ChecklistResource::collection($service->handle($trip));
    }

    /**
     * Store a newly created checklist for a trip.
     */
    public function store(
        StoreChecklistRequest $request,
        Trip $trip,
        CreateChecklistService $service,
    ): JsonResponse {
        Gate::authorize('update', $trip);

        $checklist = $service->handle(
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
        ApplyChecklistTemplateService $service,
    ): JsonResponse {
        Gate::authorize('update', $trip);

        $checklist = $service->handle(
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
        DeleteChecklistService $service,
    ): Response {
        Gate::authorize('update', $checklist->trip);

        $service->handle($checklist);

        return response()->noContent();
    }
}
