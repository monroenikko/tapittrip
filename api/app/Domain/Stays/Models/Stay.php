<?php

declare(strict_types=1);

namespace App\Domain\Stays\Models;

use App\Domain\Itinerary\Models\ItineraryItem;
use App\Domain\Itinerary\Models\Place;
use App\Domain\Trips\Models\Trip;
use Database\Factories\StayFactory;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Casts\Attribute;
use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\SoftDeletes;

#[Fillable([
    'trip_id',
    'place_id',
    'name',
    'stay_type',
    'address',
    'latitude',
    'longitude',
    'check_in_at',
    'check_out_at',
    'timezone',
    'phone',
    'booking_reference',
    'notes',
    'luggage_profile',
    'version',
])]
final class Stay extends Model
{
    /** @use HasFactory<StayFactory> */
    use HasFactory, HasUuids, SoftDeletes;

    /**
     * Create a new factory instance for the model.
     */
    protected static function newFactory(): StayFactory
    {
        return StayFactory::new();
    }

    /**
     * Get the attributes that should be cast.
     *
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'check_in_at' => 'datetime',
            'check_out_at' => 'datetime',
            'latitude' => 'float',
            'longitude' => 'float',
            'booking_reference' => 'encrypted',
            'luggage_profile' => 'array',
            'version' => 'integer',
        ];
    }

    /**
     * The trip this stay belongs to.
     *
     * @return BelongsTo<Trip, $this>
     */
    public function trip(): BelongsTo
    {
        return $this->belongsTo(Trip::class);
    }

    /**
     * The place or physical location associated with this stay (optional).
     *
     * @return BelongsTo<Place, $this>
     */
    public function place(): BelongsTo
    {
        return $this->belongsTo(Place::class);
    }

    /**
     * Itinerary items linked to this stay (e.g. check-in / check-out activities).
     *
     * @return HasMany<ItineraryItem, $this>
     */
    public function itineraryItems(): HasMany
    {
        return $this->hasMany(ItineraryItem::class);
    }

    /**
     * Computed Google Maps search URL.
     *
     * @return Attribute<string, never>
     */
    protected function googleMapsUrl(): Attribute
    {
        return Attribute::make(
            get: function (): string {
                if ($this->latitude !== null && $this->longitude !== null) {
                    return "https://www.google.com/maps/search/?api=1&query={$this->latitude},{$this->longitude}";
                }

                $query = $this->address ?: $this->name;

                return 'https://www.google.com/maps/search/?api=1&query='.urlencode($query);
            }
        );
    }

    /**
     * Computed Google Maps directions URL.
     *
     * @return Attribute<string, never>
     */
    protected function googleMapsDirectionsUrl(): Attribute
    {
        return Attribute::make(
            get: function (): string {
                $destination = ($this->latitude !== null && $this->longitude !== null)
                    ? "{$this->latitude},{$this->longitude}"
                    : ($this->address ?: $this->name);

                return 'https://www.google.com/maps/dir/?api=1&destination='.urlencode($destination);
            }
        );
    }
}
