<?php

declare(strict_types=1);

namespace App\Services\Documents;

use App\Exceptions\VersionConflictException;
use App\Models\TravelDocument;
use App\Models\Trip;
use App\Models\User;
use App\Services\Storage\EncryptedAttachmentService;
use Illuminate\Database\Eloquent\Collection;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\DB;
use Symfony\Component\HttpKernel\Exception\AccessDeniedHttpException;

final class TravelDocumentService
{
    public function __construct(
        private readonly EncryptedAttachmentService $attachmentService,
    ) {}

    /**
     * List travel documents visible to the given trip member.
     * Owner-only documents are strictly hidden from other circle members.
     *
     * @return Collection<int, TravelDocument>
     */
    public function listForTrip(Trip $trip, User $viewer): Collection
    {
        return TravelDocument::query()
            ->where('trip_id', $trip->id)
            ->where(function ($query) use ($viewer): void {
                $query->where('owner_id', $viewer->id)
                    ->orWhere('access_policy', 'circle_members');
            })
            ->orderByRaw('expires_on IS NULL ASC, expires_on ASC')
            ->orderByDesc('created_at')
            ->get();
    }

    /**
     * Create a travel document with idempotent client_operation_id support.
     *
     * @param  array<string, mixed>  $data
     */
    public function create(Trip $trip, User $owner, array $data, ?UploadedFile $file = null): TravelDocument
    {
        return DB::transaction(function () use ($trip, $owner, $data, $file): TravelDocument {
            $clientOpId = $data['client_operation_id'] ?? null;
            if (is_string($clientOpId) && $clientOpId !== '') {
                $existing = TravelDocument::query()
                    ->where('trip_id', $trip->id)
                    ->where('client_operation_id', $clientOpId)
                    ->first();

                if ($existing !== null) {
                    if ($existing->owner_id !== $owner->id) {
                        throw new AccessDeniedHttpException('Operation ID belongs to another user.');
                    }

                    return $existing;
                }
            }

            $fileAttributes = [];
            if ($file !== null) {
                $fileAttributes = $this->attachmentService->storeEncrypted($file, "private/documents/{$trip->id}");
            }

            return TravelDocument::query()->create(array_merge([
                'trip_id' => $trip->id,
                'owner_id' => $owner->id,
                'document_type' => (string) $data['document_type'],
                'display_name' => trim((string) $data['display_name']),
                'issuer' => isset($data['issuer']) && trim((string) $data['issuer']) !== ''
                    ? trim((string) $data['issuer'])
                    : null,
                'reference_number' => isset($data['reference_number']) && trim((string) $data['reference_number']) !== ''
                    ? trim((string) $data['reference_number'])
                    : null,
                'notes_private' => isset($data['notes_private']) && trim((string) $data['notes_private']) !== ''
                    ? trim((string) $data['notes_private'])
                    : null,
                'expires_on' => $data['expires_on'] ?? null,
                'access_policy' => (string) ($data['access_policy'] ?? 'owner_only'),
                'client_operation_id' => $clientOpId,
                'version' => 1,
            ], $fileAttributes));
        });
    }

    /**
     * Attach or replace an encrypted binary file on an existing travel document (owner only).
     */
    public function uploadAttachment(TravelDocument $document, User $actor, UploadedFile $file): TravelDocument
    {
        if ($document->owner_id !== $actor->id) {
            throw new AccessDeniedHttpException('Only the document owner can attach files to this travel document.');
        }

        return DB::transaction(function () use ($document, $file): TravelDocument {
            $oldPath = $document->file_path;
            $stored = $this->attachmentService->storeEncrypted($file, "private/documents/{$document->trip_id}");

            $document->fill($stored);
            $document->version++;
            $document->save();

            if ($oldPath !== null && $oldPath !== $stored['file_path']) {
                $this->attachmentService->deleteFile($oldPath);
            }

            return $document->fresh();
        });
    }

    /**
     * Update a travel document (only the document owner may modify it).
     *
     * @param  array<string, mixed>  $data
     */
    public function update(TravelDocument $document, User $actor, array $data): TravelDocument
    {
        if ($document->owner_id !== $actor->id) {
            throw new AccessDeniedHttpException('Only the document owner can modify this travel document.');
        }

        return DB::transaction(function () use ($document, $data): TravelDocument {
            $document->refresh();

            if ($document->version !== (int) $data['base_version']) {
                throw new VersionConflictException(
                    $document->version,
                    [
                        'id' => $document->id,
                        'display_name' => $document->display_name,
                        'document_type' => $document->document_type,
                        'access_policy' => $document->access_policy,
                        'version' => $document->version,
                    ],
                );
            }

            $updatable = [
                'document_type',
                'display_name',
                'issuer',
                'reference_number',
                'notes_private',
                'expires_on',
                'access_policy',
            ];

            foreach ($updatable as $field) {
                if (array_key_exists($field, $data)) {
                    $val = $data[$field];
                    $document->{$field} = is_string($val) ? (trim($val) !== '' ? trim($val) : null) : $val;
                }
            }

            $document->version++;
            $document->save();

            return $document->fresh();
        });
    }

    /**
     * Delete a travel document (document owner or trip organizer).
     */
    public function delete(TravelDocument $document, User $actor): void
    {
        $isDocOwner = $document->owner_id === $actor->id;
        $isTripOwner = $document->trip !== null && $document->trip->owner_id === $actor->id;

        if (! $isDocOwner && ! $isTripOwner) {
            throw new AccessDeniedHttpException('Not authorized to delete this travel document.');
        }

        $filePath = $document->file_path;
        $document->delete();
        $this->attachmentService->deleteFile($filePath);
    }
}
