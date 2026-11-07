<?php

declare(strict_types=1);

namespace App\Domain\Media\Models;

use App\Domain\Trips\Models\Trip;
use App\Models\User;
use Database\Factories\MediaAttachmentFactory;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Casts\Attribute;
use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

#[Fillable([
    'trip_id',
    'attachable_type',
    'attachable_id',
    'uploaded_by_id',
    'original_filename',
    'file_path',
    'mime_type',
    'file_size_bytes',
    'title',
    'notes',
])]
final class MediaAttachment extends Model
{
    /** @use HasFactory<MediaAttachmentFactory> */
    use HasFactory, HasUuids;

    /**
     * Create a new factory instance for the model.
     */
    protected static function newFactory(): MediaAttachmentFactory
    {
        return MediaAttachmentFactory::new();
    }

    /**
     * Get the attributes that should be cast.
     *
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'file_size_bytes' => 'integer',
        ];
    }

    /**
     * The trip this media attachment belongs to.
     *
     * @return BelongsTo<Trip, $this>
     */
    public function trip(): BelongsTo
    {
        return $this->belongsTo(Trip::class);
    }

    /**
     * The user who uploaded this attachment.
     *
     * @return BelongsTo<User, $this>
     */
    public function uploadedBy(): BelongsTo
    {
        return $this->belongsTo(User::class, 'uploaded_by_id');
    }

    /**
     * Check if attachment is an image.
     */
    public function isImage(): bool
    {
        return str_starts_with($this->mime_type, 'image/');
    }

    /**
     * Check if attachment is a PDF.
     */
    public function isPdf(): bool
    {
        return $this->mime_type === 'application/pdf';
    }

    /**
     * Authenticated download / view URL.
     *
     * @return Attribute<string, never>
     */
    protected function url(): Attribute
    {
        return Attribute::make(
            get: fn (): string => url("/api/v1/trips/{$this->trip_id}/media/{$this->id}"),
        );
    }

    /**
     * Human-readable file size formatting.
     *
     * @return Attribute<string, never>
     */
    protected function formattedSize(): Attribute
    {
        return Attribute::make(
            get: function (): string {
                $bytes = $this->file_size_bytes;
                if ($bytes >= 1048576) {
                    return round($bytes / 1048576, 1).' MB';
                }
                if ($bytes >= 1024) {
                    return round($bytes / 1024).' KB';
                }

                return $bytes.' B';
            },
        );
    }
}
