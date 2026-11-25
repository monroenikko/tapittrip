<?php

declare(strict_types=1);

namespace App\Models;

use Database\Factories\BookingImportFactory;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\SoftDeletes;

#[Fillable([
    'trip_id',
    'user_id',
    'source',
    'file_path',
    'original_filename',
    'mime_type',
    'file_size_bytes',
    'file_encrypted',
    'booking_type',
    'raw_text',
    'extraction_status',
    'extracted_data',
    'confidence_score',
    'confirmed_entity_type',
    'confirmed_entity_id',
    'reviewed_at',
    'error_message',
    'client_operation_id',
    'version',
])]
final class BookingImport extends Model
{
    /** @use HasFactory<BookingImportFactory> */
    use HasFactory, HasUuids, SoftDeletes;

    protected static function newFactory(): BookingImportFactory
    {
        return BookingImportFactory::new();
    }

    /**
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'raw_text' => 'encrypted',
            'extracted_data' => 'encrypted:array',
            'confidence_score' => 'float',
            'file_size_bytes' => 'integer',
            'file_encrypted' => 'boolean',
            'reviewed_at' => 'datetime',
            'version' => 'integer',
        ];
    }

    /**
     * The trip this booking import belongs to.
     *
     * @return BelongsTo<Trip, $this>
     */
    public function trip(): BelongsTo
    {
        return $this->belongsTo(Trip::class);
    }

    /**
     * The user who initiated the import.
     *
     * @return BelongsTo<User, $this>
     */
    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}
