<?php

declare(strict_types=1);

namespace App\Http\Resources\Api\V1;

use App\Models\BookingImport;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;
use Illuminate\Support\Facades\URL;

/**
 * @mixin BookingImport
 */
final class BookingImportResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        $viewerId = $request->user()?->id;
        $ownerId = $this->relationLoaded('trip')
            ? $this->trip?->owner_id
            : $this->trip()->value('owner_id');
        $canViewSensitive = $viewerId !== null && ($viewerId === $this->user_id || $viewerId === $ownerId);

        $extractedData = $this->extracted_data;
        if (! $canViewSensitive && is_array($extractedData)) {
            $extractedData = $this->redactExtractedData($extractedData);
        }

        return [
            'id' => $this->id,
            'trip_id' => $this->trip_id,
            'user_id' => $this->user_id,
            'source' => $this->source,
            'has_attachment' => $this->file_path !== null && $this->file_path !== '',
            'original_filename' => $canViewSensitive ? $this->original_filename : null,
            'mime_type' => $canViewSensitive ? $this->mime_type : null,
            'file_size_bytes' => $canViewSensitive ? $this->file_size_bytes : null,
            'download_url' => ($canViewSensitive && $this->file_path !== null && $this->file_path !== '')
                ? URL::temporarySignedRoute('imports.download', now()->addMinutes(10), ['import' => $this->id])
                : null,
            'booking_type' => $this->booking_type,
            'raw_text' => $canViewSensitive ? $this->raw_text : null,
            'extraction_status' => $this->extraction_status,
            'extracted_data' => $extractedData,
            'confidence_score' => $this->confidence_score,
            'confirmed_entity_type' => $this->confirmed_entity_type,
            'confirmed_entity_id' => $this->confirmed_entity_id,
            'reviewed_at' => $this->reviewed_at?->toIso8601String(),
            'error_message' => $this->error_message,
            'version' => $this->version,
            'created_at' => $this->created_at?->toIso8601String(),
            'updated_at' => $this->updated_at?->toIso8601String(),
        ];
    }

    /**
     * @param  array<string, mixed>  $data
     * @return array<string, mixed>
     */
    private function redactExtractedData(array $data): array
    {
        if (isset($data['flight']) && is_array($data['flight'])) {
            $data['flight']['booking_reference'] = null;
        }
        if (isset($data['stay']) && is_array($data['stay'])) {
            $data['stay']['booking_reference'] = null;
            $data['stay']['phone'] = null;
            if (($data['stay']['stay_type'] ?? null) === 'friends_family') {
                $data['stay']['address'] = null;
                $data['stay']['notes'] = null;
            }
        }
        if (isset($data['confirmed_payload']) && is_array($data['confirmed_payload'])) {
            $data['confirmed_payload'] = $this->redactExtractedData($data['confirmed_payload']);
        }

        return $data;
    }
}
