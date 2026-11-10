<?php

declare(strict_types=1);

namespace App\Http\Controllers\Api\V1;

use App\DTOs\Journal\CreateJournalEntryData;
use App\DTOs\Journal\UpdateJournalEntryData;
use App\Http\Controllers\Controller;
use App\Http\Requests\Api\V1\Journal\CreateJournalEntryRequest;
use App\Http\Requests\Api\V1\Journal\UpdateJournalEntryRequest;
use App\Http\Requests\Api\V1\Journal\UploadJournalPhotoRequest;
use App\Http\Resources\Api\V1\JournalEntryResource;
use App\Models\JournalEntry;
use App\Models\Trip;
use App\Services\Journal\JournalService;
use App\Support\Http\ApiResponse;
use Illuminate\Auth\Access\AuthorizationException;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Response;

final class TripJournalController extends Controller
{
    public function __construct(
        private readonly JournalService $journalService,
        private readonly ApiResponse $response,
    ) {}

    public function index(
        Trip $trip,
        Request $request,
    ): JsonResponse {
        $user = $request->user();
        if ($user === null || ! $trip->hasMember($user)) {
            throw new AuthorizationException('You are not a member of this trip.');
        }

        $date = $request->query('date');
        $entries = $this->journalService->getTripJournal($trip, $user, is_string($date) ? $date : null);

        return $this->response->success(JournalEntryResource::collection($entries));
    }

    public function store(
        Trip $trip,
        CreateJournalEntryRequest $request,
    ): JsonResponse {
        $data = CreateJournalEntryData::fromArray($request->validated());
        $entry = $this->journalService->createEntry($trip, $request->user(), $data);

        return $this->response->success(
            new JournalEntryResource($entry->load(['author', 'itineraryItem'])),
            201,
        );
    }

    public function show(
        JournalEntry $entry,
        Request $request,
    ): JsonResponse {
        $user = $request->user();
        if ($user === null || ! $entry->trip->hasMember($user)) {
            throw new AuthorizationException('You are not a member of this trip.');
        }

        // Only author or companions if shared
        if ($entry->user_id !== $user->id && ! $entry->is_shared) {
            throw new AuthorizationException('This journal entry is private.');
        }

        return $this->response->success(new JournalEntryResource($entry->load(['author', 'itineraryItem'])));
    }

    public function update(
        JournalEntry $entry,
        UpdateJournalEntryRequest $request,
    ): JsonResponse {
        $data = UpdateJournalEntryData::fromArray($request->validated());
        $updated = $this->journalService->updateEntry($entry, $request->user(), $data);

        return $this->response->success(new JournalEntryResource($updated));
    }

    public function destroy(
        JournalEntry $entry,
        Request $request,
    ): Response {
        $this->journalService->deleteEntry($entry, $request->user());

        return $this->response->noContent();
    }

    public function uploadPhoto(
        JournalEntry $entry,
        UploadJournalPhotoRequest $request,
    ): JsonResponse {
        $file = $request->file('photo');
        $updated = $this->journalService->uploadPhoto($entry, $request->user(), $file);

        return $this->response->success(new JournalEntryResource($updated));
    }
}
