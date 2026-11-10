<?php

declare(strict_types=1);

namespace App\Models;

use Database\Factories\TripAnnouncementFactory;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\SoftDeletes;

#[Fillable([
    'trip_id',
    'author_id',
    'title',
    'body',
    'is_pinned',
    'client_operation_id',
    'version',
])]
final class TripAnnouncement extends Model
{
    /** @use HasFactory<TripAnnouncementFactory> */
    use HasFactory, HasUuids, SoftDeletes;

    protected static function newFactory(): TripAnnouncementFactory
    {
        return TripAnnouncementFactory::new();
    }

    /**
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'is_pinned' => 'boolean',
            'version' => 'integer',
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
    public function author(): BelongsTo
    {
        return $this->belongsTo(User::class, 'author_id');
    }

    /**
     * @return HasMany<TripNotification, $this>
     */
    public function notifications(): HasMany
    {
        return $this->hasMany(TripNotification::class, 'announcement_id');
    }
}

