<?php

declare(strict_types=1);

namespace App\Http\Controllers\Api\V1;

use App\DTOs\Media\UploadMediaData;
use App\Http\Controllers\Controller;
use App\Http\Requests\Api\V1\Media\UploadMediaRequest;
use App\Http\Resources\Api\V1\MediaAttachmentResource;
use App\Models\MediaAttachment;
use App\Models\Trip;
use App\Services\Media\MediaService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;
use Illuminate\Http\Response;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Gate;
use Illuminate\Support\Facades\Storage;
use Symfony\Component\HttpFoundation\StreamedResponse;

final class MediaController extends Controller
{
    public function __construct(
        private readonly MediaService $service,
    ) {}

    /**
     * List all media attachments and documents for a trip.
     */
    public function index(Request $request, Trip $trip): AnonymousResourceCollection
    {
        Gate::authorize('view', $trip);

        $attachableType = $request->query('attachable_type');
        $media = $this->service->getTripMedia($trip, is_string($attachableType) ? $attachableType : null);

        return MediaAttachmentResource::collection($media);
    }

    /**
     * Upload and attach a media file or document.
     */
    public function store(UploadMediaRequest $request, Trip $trip): JsonResponse
    {
        Gate::authorize('update', $trip);

        /** @var UploadedFile $file */
        $file = $request->file('file');

        $attachment = $this->service->upload(
            $trip,
            $request->user(),
            UploadMediaData::from($request->validated(), $file),
        );

        return (new MediaAttachmentResource($attachment))
            ->response()
            ->setStatusCode(201);
    }

    /**
     * View or download an authenticated private media attachment.
     */
    public function show(
        Request $request,
        Trip $trip,
        MediaAttachment $media,
    ): StreamedResponse {
        Gate::authorize('view', $trip);

        if ($media->trip_id !== $trip->id) {
            abort(404, 'Media attachment not found for this trip.');
        }

        if (! Storage::disk('local')->exists($media->file_path)) {
            abort(404, 'File not found on storage disk.');
        }

        return Storage::disk('local')->response(
            $media->file_path,
            $media->original_filename,
            [
                'Content-Type' => $media->mime_type,
                'Cache-Control' => 'private, max-age=3600',
            ],
        );
    }

    /**
     * Delete a media attachment.
     */
    public function destroy(
        Request $request,
        Trip $trip,
        MediaAttachment $media,
    ): Response {
        Gate::authorize('update', $trip);

        if ($media->trip_id !== $trip->id) {
            abort(404, 'Media attachment not found for this trip.');
        }

        $this->service->delete($media);

        return response()->noContent();
    }
}
