<?php

declare(strict_types=1);

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Requests\Api\V1\Imports\ConfirmBookingImportRequest;
use App\Http\Requests\Api\V1\Imports\StoreBookingImportRequest;
use App\Http\Resources\Api\V1\BookingImportResource;
use App\Models\BookingImport;
use App\Models\Trip;
use App\Services\Imports\BookingImportService;
use App\Services\Storage\EncryptedAttachmentService;
use App\Support\Http\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Response;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Gate;
use Symfony\Component\HttpKernel\Exception\AccessDeniedHttpException;

final class BookingImportController extends Controller
{
    public function __construct(
        private readonly BookingImportService $importService,
        private readonly ApiResponse $response,
    ) {}

    public function index(Request $request, Trip $trip): JsonResponse
    {
        Gate::authorize('view', $trip);

        $imports = $this->importService->listForTrip($trip, $request->user());

        return $this->response->success(BookingImportResource::collection($imports));
    }

    public function store(StoreBookingImportRequest $request, Trip $trip): JsonResponse
    {
        Gate::authorize('update', $trip);

        $validated = $request->validated();
        $existed = isset($validated['client_operation_id']) && BookingImport::query()
            ->where('trip_id', $trip->id)
            ->where('client_operation_id', $validated['client_operation_id'])
            ->exists();

        /** @var UploadedFile|null $file */
        $file = $request->file('file');
        $import = $this->importService->importText($trip, $request->user(), $validated, $file);

        return $this->response->success(
            new BookingImportResource($import),
            $existed ? 200 : 201,
        );
    }

    public function download(
        Request $request,
        BookingImport $import,
        EncryptedAttachmentService $attachmentService,
    ): Response {
        if (! $request->hasValidSignature()) {
            throw new AccessDeniedHttpException('Invalid or expired booking import download signature.');
        }

        Gate::authorize('view', $import->trip);

        $viewerId = $request->user()?->id;
        $ownerId = $import->trip?->owner_id;
        if ($viewerId === null || ($viewerId !== $import->user_id && $viewerId !== $ownerId)) {
            throw new AccessDeniedHttpException('Only the import creator or trip owner can download this attachment.');
        }

        if ($import->file_path === null || $import->file_path === '') {
            abort(404, 'No attachment exists for this booking import.');
        }

        return $attachmentService->downloadDecrypted(
            $import->file_path,
            $import->original_filename ?? 'booking-attachment',
            $import->mime_type ?? 'application/octet-stream',
            (bool) $import->file_encrypted,
        );
    }

    public function show(Request $request, BookingImport $import): JsonResponse
    {
        Gate::authorize('view', $import->trip);

        return $this->response->success(new BookingImportResource($import));
    }

    public function confirm(ConfirmBookingImportRequest $request, BookingImport $import): JsonResponse
    {
        Gate::authorize('update', $import->trip);

        $confirmed = $this->importService->confirm($import, $request->user(), $request->validated());

        return $this->response->success(new BookingImportResource($confirmed));
    }

    public function destroy(Request $request, BookingImport $import): Response
    {
        Gate::authorize('update', $import->trip);

        $this->importService->delete($import, $request->user());

        return response()->noContent();
    }
}
