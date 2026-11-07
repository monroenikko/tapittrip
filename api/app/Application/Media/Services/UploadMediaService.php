<?php

declare(strict_types=1);

namespace App\Application\Media\Services;

use App\Application\Media\Data\UploadMediaData;
use App\Domain\Checklists\Models\ChecklistItem;
use App\Domain\Media\Models\MediaAttachment;
use App\Domain\Trips\Models\Trip;
use App\Models\User;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Storage;
use Illuminate\Validation\ValidationException;

final class UploadMediaService
{
    private const ALLOWED_MIME_TYPES = [
        'image/jpeg',
        'image/png',
        'image/webp',
        'image/heic',
        'application/pdf',
    ];

    private const MAX_BYTES = 10485760; // 10 MB

    /**
     * Upload and attach a media file or document to a trip or checklist item.
     */
    public function handle(Trip $trip, User $user, UploadMediaData $data): MediaAttachment
    {
        $file = $data->file;

        $mimeType = $file->getMimeType() ?: $file->getClientMimeType() ?: 'application/octet-stream';
        $fileSizeBytes = $file->getSize();

        if (! in_array($mimeType, self::ALLOWED_MIME_TYPES, true)) {
            throw ValidationException::withMessages([
                'file' => ['The uploaded file type is not supported. Allowed formats: JPG, PNG, WEBP, HEIC, PDF.'],
            ]);
        }

        if ($fileSizeBytes > self::MAX_BYTES) {
            throw ValidationException::withMessages([
                'file' => ['File exceeds maximum allowed size of 10 MB.'],
            ]);
        }

        return DB::transaction(function () use ($trip, $user, $data, $file, $mimeType, $fileSizeBytes): MediaAttachment {
            // Save file in private disk under trip-scoped folder
            $storedPath = Storage::disk('local')->putFile('trips/'.$trip->id, $file);

            if (! $storedPath) {
                throw new \RuntimeException('Failed to store uploaded file.');
            }

            /** @var MediaAttachment $attachment */
            $attachment = MediaAttachment::query()->create([
                'trip_id' => $trip->id,
                'attachable_type' => $data->attachableType,
                'attachable_id' => $data->attachableId,
                'uploaded_by_id' => $user->id,
                'original_filename' => $file->getClientOriginalName(),
                'file_path' => $storedPath,
                'mime_type' => $mimeType,
                'file_size_bytes' => $fileSizeBytes,
                'title' => $data->title ?: pathinfo($file->getClientOriginalName(), PATHINFO_FILENAME),
                'notes' => $data->notes,
            ]);

            // If attached to a checklist item in this trip, set photo_url
            if ($data->attachableType === 'checklist_item' && $data->attachableId !== null) {
                /** @var ChecklistItem|null $item */
                $item = ChecklistItem::query()
                    ->where('id', $data->attachableId)
                    ->where('trip_id', $trip->id)
                    ->first();

                if ($item) {
                    $item->update([
                        'photo_url' => $attachment->url,
                        'version' => $item->version + 1,
                    ]);
                }
            }

            return $attachment->load(['uploadedBy', 'trip']);
        });
    }
}
