<?php

declare(strict_types=1);

namespace App\Http\Controllers\Api\V1;

use App\Application\Media\Data\UploadMediaData;
use App\Application\Media\Services\DeleteMediaService;
use App\Application\Media\Services\GetTripMediaService;
use App\Application\Media\Services\UploadMediaService;
use App\Domain\Media\Models\MediaAttachment;
use App\Domain\Trips\Models\Trip;
use App\Http\Controllers\Controller;
use App\Http\Requests\Api\V1\Media\UploadMediaRequest;
use App\Http\Resources\Api\V1\MediaAttachmentResource;
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
    /**
     * List all media attachments and documents for a trip.
     */
    public function index(
        Request $request,
        Trip $trip,
        GetTripMediaService $service,
    ): AnonymousResourceCollection {
        Gate::authorize('view', $trip);

        $attachableType = $request->query('attachable_type');
        $media = $service->handle($trip, is_string($attachableType) ? $attachableType : null);

        return MediaAttachmentResource::collection($media);
    }

    /**
     * Upload and attach a media file or document.
     */
    public function store(
        UploadMediaRequest $request,
        Trip $trip,
        UploadMediaService $service,
    ): JsonResponse {
        Gate::authorize('update', $trip);

        /** @var UploadedFile $file */
        $file = $request->file('file');

        $attachment = $service->handle(
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
        DeleteMediaService $service,
    ): Response {
        Gate::authorize('update', $trip);

        if ($media->trip_id !== $trip->id) {
            abort(404, 'Media attachment not found for this trip.');
        }

        $service->handle($media);

        return response()->noContent();
    }
}
