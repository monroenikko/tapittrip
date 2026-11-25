<?php

declare(strict_types=1);

namespace App\Http\Resources\Api\V1;

use App\Models\TravelDocument;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\URL;

/**
 * @mixin TravelDocument
 */
final class TravelDocumentResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        $viewerId = $request->user()?->id;
        $isOwner = $viewerId !== null && $viewerId === $this->owner_id;

        $expiresOnStr = $this->expires_on instanceof Carbon
            ? $this->expires_on->format('Y-m-d')
            : (is_string($this->expires_on) ? $this->expires_on : null);

        $daysUntilExpiry = null;
        $isExpired = false;
        if ($expiresOnStr !== null) {
            $expiryDate = Carbon::createFromFormat('Y-m-d', $expiresOnStr)->startOfDay();
            $today = Carbon::now('UTC')->startOfDay();
            $daysUntilExpiry = (int) $today->diffInDays($expiryDate, false);
            $isExpired = $daysUntilExpiry < 0;
        }

        return [
            'id' => $this->id,
            'trip_id' => $this->trip_id,
            'owner_id' => $this->owner_id,
            'is_owner' => $isOwner,
            'document_type' => $this->document_type,
            'display_name' => $this->display_name,
            'issuer' => $this->issuer,
            'reference_number' => $isOwner ? $this->reference_number : null,
            'notes_private' => $this->notes_private,
            'expires_on' => $expiresOnStr,
            'is_expired' => $isExpired,
            'days_until_expiry' => $daysUntilExpiry,
            'access_policy' => $this->access_policy,
            'has_attachment' => $this->file_path !== null && $this->file_path !== '',
            'original_filename' => $isOwner ? $this->original_filename : null,
            'mime_type' => $isOwner ? $this->mime_type : null,
            'file_size_bytes' => $isOwner ? $this->file_size_bytes : null,
            'download_url' => ($isOwner && $this->file_path !== null && $this->file_path !== '')
                ? URL::temporarySignedRoute('documents.download', now()->addMinutes(10), ['document' => $this->id])
                : null,
            'version' => $this->version,
            'created_at' => $this->created_at?->toISOString(),
            'updated_at' => $this->updated_at?->toISOString(),
        ];
    }
}
