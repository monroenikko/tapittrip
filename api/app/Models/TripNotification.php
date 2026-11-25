<?php

declare(strict_types=1);

namespace App\Models;

use Database\Factories\TripNotificationFactory;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\SoftDeletes;

#[Fillable([
    'trip_id',
    'user_id',
    'announcement_id',
    'category',
    'title',
    'body',
    'scheduled_for_utc',
    'timezone',
    'trip_local_time_label',
    'status',
    'dedupe_key',
    'read_at',
])]
final class TripNotification extends Model
{
    /** @use HasFactory<TripNotificationFactory> */
    use HasFactory, HasUuids, SoftDeletes;

    protected static function newFactory(): TripNotificationFactory
    {
        return TripNotificationFactory::new();
    }

    /**
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'scheduled_for_utc' => 'datetime',
            'read_at' => 'datetime',
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
    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    /**
     * @return BelongsTo<TripAnnouncement, $this>
     */
    public function announcement(): BelongsTo
    {
        return $this->belongsTo(TripAnnouncement::class, 'announcement_id');
    }
}
