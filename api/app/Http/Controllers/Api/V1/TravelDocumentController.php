<?php

declare(strict_types=1);

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Requests\Api\V1\Documents\StoreTravelDocumentRequest;
use App\Http\Requests\Api\V1\Documents\UpdateTravelDocumentRequest;
use App\Http\Requests\Api\V1\Documents\UploadDocumentAttachmentRequest;
use App\Http\Resources\Api\V1\TravelDocumentResource;
use App\Models\TravelDocument;
use App\Models\Trip;
use App\Services\Documents\TravelDocumentService;
use App\Services\Storage\EncryptedAttachmentService;
use App\Support\Http\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Response;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Gate;
use Symfony\Component\HttpKernel\Exception\AccessDeniedHttpException;

final class TravelDocumentController extends Controller
{
    public function __construct(
        private readonly TravelDocumentService $documentService,
        private readonly ApiResponse $response,
    ) {}

    public function index(Request $request, Trip $trip): JsonResponse
    {
        Gate::authorize('view', $trip);

        $documents = $this->documentService->listForTrip($trip, $request->user());

        return $this->response->success(TravelDocumentResource::collection($documents));
    }

    public function store(StoreTravelDocumentRequest $request, Trip $trip): JsonResponse
    {
        Gate::authorize('update', $trip);

        $validated = $request->validated();
        $existed = isset($validated['client_operation_id']) && TravelDocument::query()
            ->where('trip_id', $trip->id)
            ->where('client_operation_id', $validated['client_operation_id'])
            ->exists();

        /** @var UploadedFile|null $file */
        $file = $request->file('file');
        $document = $this->documentService->create($trip, $request->user(), $validated, $file);

        return $this->response->success(
            new TravelDocumentResource($document),
            $existed ? 200 : 201,
        );
    }

    public function uploadAttachment(UploadDocumentAttachmentRequest $request, TravelDocument $document): JsonResponse
    {
        Gate::authorize('update', $document->trip);

        /** @var UploadedFile $file */
        $file = $request->file('file');
        $updated = $this->documentService->uploadAttachment($document, $request->user(), $file);

        return $this->response->success(new TravelDocumentResource($updated));
    }

    public function download(
        Request $request,
        TravelDocument $document,
        EncryptedAttachmentService $attachmentService,
    ): Response {
        if (! $request->hasValidSignature()) {
            throw new AccessDeniedHttpException('Invalid or expired document download signature.');
        }

        Gate::authorize('view', $document->trip);

        if ($document->owner_id !== $request->user()?->id) {
            throw new AccessDeniedHttpException('Only the document owner can download the attached file.');
        }

        if ($document->file_path === null || $document->file_path === '') {
            abort(404, 'No attachment exists for this document.');
        }

        return $attachmentService->downloadDecrypted(
            $document->file_path,
            $document->original_filename ?? 'document',
            $document->mime_type ?? 'application/octet-stream',
            (bool) $document->file_encrypted,
        );
    }

    public function update(UpdateTravelDocumentRequest $request, TravelDocument $document): JsonResponse
    {
        Gate::authorize('update', $document->trip);

        $updated = $this->documentService->update($document, $request->user(), $request->validated());

        return $this->response->success(new TravelDocumentResource($updated));
    }

    public function destroy(Request $request, TravelDocument $document): Response
    {
        Gate::authorize('update', $document->trip);

        $this->documentService->delete($document, $request->user());

        return $this->response->noContent();
    }
}
