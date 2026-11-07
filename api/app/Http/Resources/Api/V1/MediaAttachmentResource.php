<?php

declare(strict_types=1);

namespace App\Http\Resources\Api\V1;

use App\Domain\Media\Models\MediaAttachment;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * @mixin MediaAttachment
 */
final class MediaAttachmentResource extends JsonResource
{
    /**
     * Transform the resource into an array.
     *
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'trip_id' => $this->trip_id,
            'attachable_type' => $this->attachable_type,
            'attachable_id' => $this->attachable_id,
            'uploaded_by_id' => $this->uploaded_by_id,
            'uploaded_by_name' => $this->uploadedBy?->name,
            'original_filename' => $this->original_filename,
            'mime_type' => $this->mime_type,
            'file_size_bytes' => $this->file_size_bytes,
            'formatted_size' => $this->formatted_size,
            'title' => $this->title,
            'notes' => $this->notes,
            'url' => $this->url,
            'is_image' => $this->isImage(),
            'is_pdf' => $this->isPdf(),
            'created_at' => $this->created_at?->toIso8601String(),
            'updated_at' => $this->updated_at?->toIso8601String(),
        ];
    }
}
