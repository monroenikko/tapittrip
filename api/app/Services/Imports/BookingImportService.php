<?php

declare(strict_types=1);

namespace App\Services\Imports;

use App\Contracts\BookingExtractorInterface;
use App\DTOs\Itinerary\CreateItineraryItemData;
use App\DTOs\Stays\CreateStayData;
use App\Exceptions\VersionConflictException;
use App\Models\BookingImport;
use App\Models\Trip;
use App\Models\User;
use App\Services\Flights\CreateFlightService;
use App\Services\Itinerary\ItineraryService;
use App\Services\Stays\StayService;
use App\Services\Storage\EncryptedAttachmentService;
use Carbon\CarbonImmutable;
use Illuminate\Database\Eloquent\Collection;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\DB;
use Symfony\Component\HttpKernel\Exception\AccessDeniedHttpException;
use Symfony\Component\HttpKernel\Exception\UnprocessableEntityHttpException;

final class BookingImportService
{
    public function __construct(
        private readonly BookingExtractorInterface $extractor,
        private readonly CreateFlightService $createFlightService,
        private readonly StayService $stayService,
        private readonly ItineraryService $itineraryService,
        private readonly EncryptedAttachmentService $attachmentService,
    ) {}

    /**
     * List all booking imports in the Trip Inbox.
     *
     * @return Collection<int, BookingImport>
     */
    public function listForTrip(Trip $trip, User $viewer): Collection
    {
        return BookingImport::query()
            ->where('trip_id', $trip->id)
            ->with(['user', 'trip'])
            ->orderByDesc('created_at')
            ->get();
    }

    /**
     * Import raw booking confirmation text, parse it with extractor, and store the candidate.
     *
     * @param  array<string, mixed>  $data
     */
    public function importText(Trip $trip, User $actor, array $data, ?UploadedFile $file = null): BookingImport
    {
        return DB::transaction(function () use ($trip, $actor, $data, $file): BookingImport {
            $clientOpId = $data['client_operation_id'] ?? null;
            if (is_string($clientOpId) && $clientOpId !== '') {
                $existing = BookingImport::query()
                    ->where('trip_id', $trip->id)
                    ->where('client_operation_id', $clientOpId)
                    ->first();

                if ($existing !== null) {
                    if ($existing->user_id !== $actor->id) {
                        throw new AccessDeniedHttpException('Operation ID belongs to another user.');
                    }

                    return $existing;
                }
            }

            $fileAttributes = [];
            if ($file !== null) {
                $fileAttributes = $this->attachmentService->storeEncrypted($file, "private/imports/{$trip->id}");
            }

            $rawText = trim((string) ($data['raw_text'] ?? $data['text'] ?? ''));
            if ($rawText === '' && isset($fileAttributes['original_filename'])) {
                $rawText = 'Uploaded booking file: '.$fileAttributes['original_filename'];
            }

            $hintType = isset($data['booking_type']) && is_string($data['booking_type']) ? trim($data['booking_type']) : null;
            $source = $file !== null
                ? 'upload_file'
                : (isset($data['source']) && is_string($data['source']) ? trim($data['source']) : 'paste_text');

            $extracted = $this->extractor->extract($rawText, $hintType);

            if ($extracted === null) {
                return BookingImport::query()->create(array_merge([
                    'trip_id' => $trip->id,
                    'user_id' => $actor->id,
                    'source' => $source,
                    'booking_type' => $hintType ?? 'flight',
                    'raw_text' => $rawText,
                    'extraction_status' => 'failed',
                    'extracted_data' => null,
                    'confidence_score' => 0.0,
                    'error_message' => 'Unable to recognize booking details from the provided text.',
                    'client_operation_id' => $clientOpId,
                    'version' => 1,
                ], $fileAttributes));
            }

            return BookingImport::query()->create(array_merge([
                'trip_id' => $trip->id,
                'user_id' => $actor->id,
                'source' => $source,
                'booking_type' => $extracted->bookingType,
                'raw_text' => $rawText,
                'extraction_status' => 'extracted',
                'extracted_data' => $extracted->toArray(),
                'confidence_score' => $extracted->confidence,
                'client_operation_id' => $clientOpId,
                'version' => 1,
            ], $fileAttributes));
        });
    }

    /**
     * Confirm an extracted booking import, materializing it into a Flight, Stay, or Itinerary Item.
     *
     * @param  array<string, mixed>  $confirmedData
     */
    public function confirm(BookingImport $import, User $actor, array $confirmedData): BookingImport
    {
        $ownerId = $import->trip?->owner_id;
        if ($import->user_id !== $actor->id && $ownerId !== $actor->id) {
            throw new AccessDeniedHttpException('Only the import creator or trip owner can confirm this booking import.');
        }

        return DB::transaction(function () use ($import, $confirmedData): BookingImport {
            $import->refresh();

            if (isset($confirmedData['base_version']) && $import->version !== (int) $confirmedData['base_version']) {
                throw new VersionConflictException(
                    $import->version,
                    [
                        'id' => $import->id,
                        'extraction_status' => $import->extraction_status,
                        'version' => $import->version,
                    ],
                );
            }

            if ($import->extraction_status === 'confirmed') {
                return $import;
            }

            $type = (string) ($confirmedData['booking_type'] ?? $import->booking_type);
            $trip = $import->trip;

            $entityType = null;
            $entityId = null;

            if ($type === 'flight') {
                $flightPayload = $confirmedData['flight'] ?? $import->extracted_data['flight'] ?? null;
                if (! is_array($flightPayload) || ! isset($flightPayload['segments']) || ! is_array($flightPayload['segments'])) {
                    throw new UnprocessableEntityHttpException('Flight booking must include valid segments.');
                }

                $flight = $this->createFlightService->handle($trip, [
                    'airline' => $flightPayload['airline'] ?? null,
                    'booking_reference' => $flightPayload['booking_reference'] ?? null,
                    'segments' => $flightPayload['segments'],
                ]);

                $entityType = 'flight';
                $entityId = $flight->id;
            } elseif ($type === 'stay') {
                $stayPayload = $confirmedData['stay'] ?? $import->extracted_data['stay'] ?? null;
                if (! is_array($stayPayload) || empty($stayPayload['name'])) {
                    throw new UnprocessableEntityHttpException('Stay booking must include an accommodation name.');
                }

                $stayData = CreateStayData::from($stayPayload, $trip->primary_timezone);
                $stay = $this->stayService->create($trip, $stayData);

                $entityType = 'stay';
                $entityId = $stay->id;
            } elseif ($type === 'activity') {
                $activityPayload = $confirmedData['activity'] ?? $import->extracted_data['activity'] ?? null;
                if (! is_array($activityPayload) || empty($activityPayload['title'])) {
                    throw new UnprocessableEntityHttpException('Activity booking must include a title.');
                }

                $itemData = CreateItineraryItemData::from($activityPayload, $trip->primary_timezone);
                $item = $this->itineraryService->createItem($trip, $itemData);

                $entityType = 'itinerary_item';
                $entityId = $item->id;
            } else {
                throw new UnprocessableEntityHttpException("Unsupported booking type: {$type}");
            }

            // Update import with confirmed status and reviewed payload
            $mergedExtracted = array_merge($import->extracted_data ?? [], [
                'confirmed_payload' => $confirmedData,
            ]);

            $import->update([
                'booking_type' => $type,
                'extraction_status' => 'confirmed',
                'confirmed_entity_type' => $entityType,
                'confirmed_entity_id' => $entityId,
                'reviewed_at' => CarbonImmutable::now('UTC'),
                'extracted_data' => $mergedExtracted,
                'version' => $import->version + 1,
            ]);

            return $import->fresh(['trip', 'user']);
        });
    }

    /**
     * Delete / dismiss a booking import record.
     */
    public function delete(BookingImport $import, User $actor): void
    {
        $ownerId = $import->trip?->owner_id;
        if ($import->user_id !== $actor->id && $ownerId !== $actor->id) {
            throw new AccessDeniedHttpException('Only the import creator or trip owner can delete this booking import.');
        }

        $filePath = $import->file_path;
        $import->delete();
        $this->attachmentService->deleteFile($filePath);
    }
}
