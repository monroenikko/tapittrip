<?php

declare(strict_types=1);

namespace App\Http\Controllers\Api\V1;

use App\Application\Journal\Data\CreateJournalEntryData;
use App\Application\Journal\Data\UpdateJournalEntryData;
use App\Application\Journal\Services\CreateJournalEntryService;
use App\Application\Journal\Services\DeleteJournalEntryService;
use App\Application\Journal\Services\GetTripJournalService;
use App\Application\Journal\Services\UpdateJournalEntryService;
use App\Application\Journal\Services\UploadJournalPhotoService;
use App\Domain\Journal\Models\JournalEntry;
use App\Domain\Trips\Models\Trip;
use App\Http\Controllers\Controller;
use App\Http\Requests\Api\V1\Journal\CreateJournalEntryRequest;
use App\Http\Requests\Api\V1\Journal\UpdateJournalEntryRequest;
use App\Http\Requests\Api\V1\Journal\UploadJournalPhotoRequest;
use App\Http\Resources\Api\V1\JournalEntryResource;
use App\Support\Http\ApiResponse;
use Illuminate\Auth\Access\AuthorizationException;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Response;

final class TripJournalController extends Controller
{
    public function index(
        Trip $trip,
        Request $request,
        GetTripJournalService $service,
        ApiResponse $response,
    ): JsonResponse {
        $user = $request->user();
        if ($user === null || ! $trip->members()->where('user_id', $user->id)->exists()) {
            throw new AuthorizationException('You are not a member of this trip.');
        }

        $date = $request->query('date');
        $entries = $service->execute($trip, $user, is_string($date) ? $date : null);

        return $response->success(JournalEntryResource::collection($entries));
    }

    public function store(
        Trip $trip,
        CreateJournalEntryRequest $request,
        CreateJournalEntryService $service,
        ApiResponse $response,
    ): JsonResponse {
        $data = CreateJournalEntryData::fromArray($request->validated());
        $entry = $service->execute($trip, $request->user(), $data);

        return $response->success(
            new JournalEntryResource($entry->load(['author', 'itineraryItem'])),
            201,
        );
    }

    public function show(
        JournalEntry $entry,
        Request $request,
        ApiResponse $response,
    ): JsonResponse {
        $user = $request->user();
        if ($user === null || ! $entry->trip->members()->where('user_id', $user->id)->exists()) {
            throw new AuthorizationException('You are not a member of this trip.');
        }

        // Only author or companions if shared
        if ($entry->user_id !== $user->id && ! $entry->is_shared) {
            throw new AuthorizationException('This journal entry is private.');
        }

        return $response->success(new JournalEntryResource($entry->load(['author', 'itineraryItem'])));
    }

    public function update(
        JournalEntry $entry,
        UpdateJournalEntryRequest $request,
        UpdateJournalEntryService $service,
        ApiResponse $response,
    ): JsonResponse {
        $data = UpdateJournalEntryData::fromArray($request->validated());
        $updated = $service->execute($entry, $request->user(), $data);

        return $response->success(new JournalEntryResource($updated));
    }

    public function destroy(
        JournalEntry $entry,
        Request $request,
        DeleteJournalEntryService $service,
        ApiResponse $response,
    ): Response {
        $service->execute($entry, $request->user());

        return $response->noContent();
    }

    public function uploadPhoto(
        JournalEntry $entry,
        UploadJournalPhotoRequest $request,
        UploadJournalPhotoService $service,
        ApiResponse $response,
    ): JsonResponse {
        $file = $request->file('photo');
        $updated = $service->execute($entry, $request->user(), $file);

        return $response->success(new JournalEntryResource($updated));
    }
}
