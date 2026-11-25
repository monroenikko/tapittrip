<?php

declare(strict_types=1);

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

final class TravelDocument extends Model
{
    use HasFactory, HasUuids;

    public const TYPES = [
        'passport_note',
        'visa_reference',
        'travel_insurance',
        'ticket_voucher',
        'health_certificate',
        'other',
    ];

    public const ACCESS_POLICIES = [
        'owner_only',
        'circle_members',
    ];

    protected $fillable = [
        'trip_id',
        'owner_id',
        'document_type',
        'display_name',
        'issuer',
        'reference_number',
        'notes_private',
        'expires_on',
        'access_policy',
        'file_path',
        'original_filename',
        'mime_type',
        'file_size_bytes',
        'file_encrypted',
        'client_operation_id',
        'version',
    ];

    protected function casts(): array
    {
        return [
            'reference_number' => 'encrypted',
            'notes_private' => 'encrypted',
            'expires_on' => 'date:Y-m-d',
            'file_size_bytes' => 'integer',
            'file_encrypted' => 'boolean',
            'version' => 'integer',
        ];
    }

    public function trip(): BelongsTo
    {
        return $this->belongsTo(Trip::class);
    }

    public function owner(): BelongsTo
    {
        return $this->belongsTo(User::class, 'owner_id');
    }
}
