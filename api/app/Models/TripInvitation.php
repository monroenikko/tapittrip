<?php

declare(strict_types=1);

namespace App\Models;

use Database\Factories\TripInvitationFactory;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\SoftDeletes;

#[Fillable([
    'trip_id',
    'inviter_id',
    'invite_type',
    'token_hash',
    'target_user_id',
    'proposed_role',
    'status',
    'max_uses',
    'use_count',
    'expires_at',
    'revoked_at',
    'responded_at',
])]
final class TripInvitation extends Model
{
    /** @use HasFactory<TripInvitationFactory> */
    use HasFactory, HasUuids, SoftDeletes;

    /**
     * Create a new factory instance for the model.
     */
    protected static function newFactory(): TripInvitationFactory
    {
        return TripInvitationFactory::new();
    }

    /**
     * Get the attributes that should be cast.
     *
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'max_uses' => 'integer',
            'use_count' => 'integer',
            'expires_at' => 'datetime',
            'revoked_at' => 'datetime',
            'responded_at' => 'datetime',
        ];
    }

    /**
     * The trip associated with this invitation.
     *
     * @return BelongsTo<Trip, $this>
     */
    public function trip(): BelongsTo
    {
        return $this->belongsTo(Trip::class);
    }

    /**
     * The organizer who issued this invitation.
     *
     * @return BelongsTo<User, $this>
     */
    public function inviter(): BelongsTo
    {
        return $this->belongsTo(User::class, 'inviter_id');
    }

    /**
     * The targeted recipient user for direct invitations.
     *
     * @return BelongsTo<User, $this>
     */
    public function targetUser(): BelongsTo
    {
        return $this->belongsTo(User::class, 'target_user_id');
    }

    /**
     * Compute the effective lifecycle status considering invite type, expiry, and usage limits.
     */
    public function effectiveStatus(): string
    {
        if ($this->status === 'revoked' || $this->revoked_at !== null) {
            return 'revoked';
        }

        if (($this->invite_type ?? 'link') === 'direct') {
            if ($this->status === 'accepted') {
                return 'accepted';
            }

            if ($this->status === 'declined') {
                return 'declined';
            }

            if ($this->status === 'expired' || $this->expires_at->isPast()) {
                return 'expired';
            }

            return 'pending';
        }

        if ($this->status === 'exhausted' || $this->use_count >= $this->max_uses) {
            return 'exhausted';
        }

        if ($this->status === 'expired' || $this->expires_at->isPast()) {
            return 'expired';
        }

        return 'active';
    }

    /**
     * Determine whether this invitation can currently be accepted.
     */
    public function isRedeemable(): bool
    {
        $status = $this->effectiveStatus();

        return ($this->invite_type ?? 'link') === 'direct'
            ? $status === 'pending'
            : $status === 'active';
    }
}
