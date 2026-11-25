<?php

declare(strict_types=1);

namespace App\Models;

use Carbon\CarbonImmutable;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

/**
 * @property string $id
 * @property string $trip_id
 * @property string $user_id
 * @property bool $enabled
 * @property int $duration_minutes
 * @property CarbonImmutable|null $expires_at
 * @property string $audience
 * @property float|null $latitude
 * @property float|null $longitude
 * @property CarbonImmutable|null $last_shared_at
 * @property CarbonImmutable|null $created_at
 * @property CarbonImmutable|null $updated_at
 */
final class TripLocationShare extends Model
{
    use HasFactory, HasUuids;

    /**
     * @var string
     */
    protected $table = 'trip_location_shares';

    /**
     * @var array<int, string>
     */
    protected $fillable = [
        'trip_id',
        'user_id',
        'enabled',
        'duration_minutes',
        'expires_at',
        'audience',
        'latitude',
        'longitude',
        'last_shared_at',
    ];

    /**
     * @var array<string, string>
     */
    protected $casts = [
        'enabled' => 'boolean',
        'duration_minutes' => 'integer',
        'expires_at' => 'immutable_datetime',
        'latitude' => 'float',
        'longitude' => 'float',
        'last_shared_at' => 'immutable_datetime',
    ];

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
    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function isExpired(): bool
    {
        return $this->expires_at !== null && $this->expires_at->isPast();
    }

    public function isActive(): bool
    {
        return $this->enabled && ! $this->isExpired();
    }

    public function isStale(): bool
    {
        if ($this->last_shared_at === null) {
            return true;
        }

        // Considered stale if last updated more than 15 minutes ago
        return $this->last_shared_at->diffInMinutes(now()) >= 15;
    }

    /**
     * Scope only actively sharing records.
     *
     * @param  Builder<$this>  $query
     * @return Builder<$this>
     */
    public function scopeActive(Builder $query): Builder
    {
        return $query->where('enabled', true)
            ->where(function (Builder $sub) {
                $sub->whereNull('expires_at')
                    ->orWhere('expires_at', '>', now());
            });
    }
}
