<?php

declare(strict_types=1);

namespace App\Domain\Itinerary\Models;

use App\Domain\Notifications\Models\Reminder;
use App\Domain\Stays\Models\Stay;
use App\Domain\Trips\Models\Trip;
use Database\Factories\ItineraryItemFactory;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\SoftDeletes;

#[Fillable([
    'trip_id',
    'trip_day_id',
    'place_id',
    'stay_id',
    'kind',
    'title',
    'notes',
    'starts_at_utc',
    'ends_at_utc',
    'timezone',
    'sort_order',
    'status',
    'version',
])]
final class ItineraryItem extends Model
{
    /** @use HasFactory<ItineraryItemFactory> */
    use HasFactory, HasUuids, SoftDeletes;

    /**
     * Create a new factory instance for the model.
     */
    protected static function newFactory(): ItineraryItemFactory
    {
        return ItineraryItemFactory::new();
    }

    /**
     * Get the attributes that should be cast.
     *
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'starts_at_utc' => 'datetime',
            'ends_at_utc' => 'datetime',
            'sort_order' => 'integer',
            'version' => 'integer',
        ];
    }

    /**
     * The trip this itinerary item belongs to.
     *
     * @return BelongsTo<Trip, $this>
     */
    public function trip(): BelongsTo
    {
        return $this->belongsTo(Trip::class);
    }

    /**
     * The trip day this item is scheduled on (optional).
     *
     * @return BelongsTo<TripDay, $this>
     */
    public function day(): BelongsTo
    {
        return $this->belongsTo(TripDay::class, 'trip_day_id');
    }

    /**
     * The place or physical stop associated with this item (optional).
     *
     * @return BelongsTo<Place, $this>
     */
    public function place(): BelongsTo
    {
        return $this->belongsTo(Place::class);
    }

    /**
     * The stay this item is associated with (e.g. check-in / check-out, optional).
     *
     * @return BelongsTo<Stay, $this>
     */
    public function stay(): BelongsTo
    {
        return $this->belongsTo(Stay::class);
    }

    /**
     * All reminders attached to this itinerary item.
     *
     * @return HasMany<Reminder, $this>
     */
    public function reminders(): HasMany
    {
        return $this->hasMany(Reminder::class);
    }

    /**
     * All visit events (suggested, confirmed, revoked) recorded for this item.
     *
     * @return HasMany<VisitEvent, $this>
     */
    public function visitEvents(): HasMany
    {
        return $this->hasMany(VisitEvent::class)
            ->orderBy('detected_at', 'desc');
    }
}
