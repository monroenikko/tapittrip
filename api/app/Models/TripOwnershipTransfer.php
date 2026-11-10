<?php

declare(strict_types=1);

namespace App\Models;

use Database\Factories\TripOwnershipTransferFactory;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\SoftDeletes;

#[Fillable([
    'trip_id',
    'from_user_id',
    'to_user_id',
    'former_owner_role',
    'status',
    'expires_at',
    'responded_at',
])]
final class TripOwnershipTransfer extends Model
{
    /** @use HasFactory<TripOwnershipTransferFactory> */
    use HasFactory, HasUuids, SoftDeletes;

    protected static function newFactory(): TripOwnershipTransferFactory
    {
        return TripOwnershipTransferFactory::new();
    }

    /**
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'expires_at' => 'datetime',
            'responded_at' => 'datetime',
        ];
    }

    /**
     * @return BelongsTo<Trip, $this>
     */
    public function trip(): BelongsTo
    {
        return $this->belongsTo(Trip::class);
    }

    /**
     * @return BelongsTo<User, $this>
     */
    public function fromUser(): BelongsTo
    {
        return $this->belongsTo(User::class, 'from_user_id');
    }

    /**
     * @return BelongsTo<User, $this>
     */
    public function toUser(): BelongsTo
    {
        return $this->belongsTo(User::class, 'to_user_id');
    }

    /**
     * Compute effective handover lifecycle status considering expiry.
     */
    public function effectiveStatus(): string
    {
        if (in_array($this->status, ['accepted', 'declined', 'cancelled'], true)) {
            return $this->status;
        }

        if ($this->status === 'expired' || $this->expires_at->isPast()) {
            return 'expired';
        }

        return 'pending';
    }
}
