<?php

declare(strict_types=1);

namespace App\Domain\Itinerary\Models;

use App\Domain\Trips\Models\Trip;
use Database\Factories\ItineraryItemFactory;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\SoftDeletes;

#[Fillable([
    'trip_id',
    'trip_day_id',
    'place_id',
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
}
