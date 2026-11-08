<?php

declare(strict_types=1);

namespace App\Domain\Sync\Models;

use App\Domain\Trips\Models\Trip;
use App\Models\User;
use Database\Factories\SyncOperationFactory;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

#[Fillable([
    'operation_id',
    'user_id',
    'trip_id',
    'device_key',
    'entity_type',
    'entity_id',
    'operation_type',
    'payload',
    'base_version',
    'server_sequence',
    'status',
    'conflict_details',
    'processed_at',
])]
final class SyncOperation extends Model
{
    /** @use HasFactory<SyncOperationFactory> */
    use HasFactory, HasUuids;

    /**
     * Create a new factory instance for the model.
     */
    protected static function newFactory(): SyncOperationFactory
    {
        return SyncOperationFactory::new();
    }

    /**
     * Get the attributes that should be cast.
     *
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'payload' => 'array',
            'conflict_details' => 'array',
            'base_version' => 'integer',
            'server_sequence' => 'integer',
            'processed_at' => 'datetime',
        ];
    }

    /**
     * The user who submitted the operation.
     *
     * @return BelongsTo<User, $this>
     */
    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    /**
     * The trip associated with the operation, if any.
     *
     * @return BelongsTo<Trip, $this>
     */
    public function trip(): BelongsTo
    {
        return $this->belongsTo(Trip::class);
    }
}
