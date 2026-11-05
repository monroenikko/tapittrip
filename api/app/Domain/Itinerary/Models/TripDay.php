<?php

declare(strict_types=1);

namespace App\Domain\Itinerary\Models;

use App\Domain\Trips\Models\Trip;
use Database\Factories\TripDayFactory;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

#[Fillable([
    'trip_id',
    'local_date',
    'notes',
])]
final class TripDay extends Model
{
    /** @use HasFactory<TripDayFactory> */
    use HasFactory, HasUuids;

    /**
     * Create a new factory instance for the model.
     */
    protected static function newFactory(): TripDayFactory
    {
        return TripDayFactory::new();
    }

    /**
     * Get the attributes that should be cast.
     *
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'local_date' => 'date:Y-m-d',
        ];
    }

    /**
     * The trip this day belongs to.
     *
     * @return BelongsTo<Trip, $this>
     */
    public function trip(): BelongsTo
    {
        return $this->belongsTo(Trip::class);
    }

    /**
     * All itinerary items planned for this day.
     *
     * @return HasMany<ItineraryItem, $this>
     */
    public function itineraryItems(): HasMany
    {
        return $this->hasMany(ItineraryItem::class)
            ->orderBy('sort_order')
            ->orderBy('starts_at_utc')
            ->orderBy('created_at');
    }
}
