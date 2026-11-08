<?php

declare(strict_types=1);

namespace App\Domain\Sync\Models;

use App\Domain\Trips\Models\Trip;
use App\Models\User;
use Database\Factories\SyncCursorFactory;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

#[Fillable([
    'user_id',
    'device_key',
    'trip_id',
    'last_server_sequence',
])]
final class SyncCursor extends Model
{
    /** @use HasFactory<SyncCursorFactory> */
    use HasFactory, HasUuids;

    /**
     * Create a new factory instance for the model.
     */
    protected static function newFactory(): SyncCursorFactory
    {
        return SyncCursorFactory::new();
    }

    /**
     * Get the attributes that should be cast.
     *
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'last_server_sequence' => 'integer',
        ];
    }

    /**
     * The user associated with the cursor.
     *
     * @return BelongsTo<User, $this>
     */
    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    /**
     * The trip associated with the cursor, if scoped.
     *
     * @return BelongsTo<Trip, $this>
     */
    public function trip(): BelongsTo
    {
        return $this->belongsTo(Trip::class);
    }
}
