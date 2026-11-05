<?php

declare(strict_types=1);

namespace App\Domain\Itinerary\Models;

use Database\Factories\PlaceFactory;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Casts\Attribute;
use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

#[Fillable([
    'provider',
    'provider_place_id',
    'name',
    'formatted_address',
    'country_code',
    'latitude',
    'longitude',
    'photo_reference',
    'attribution',
    'last_refreshed_at',
])]
final class Place extends Model
{
    /** @use HasFactory<PlaceFactory> */
    use HasFactory, HasUuids;

    /**
     * Create a new factory instance for the model.
     */
    protected static function newFactory(): PlaceFactory
    {
        return PlaceFactory::new();
    }

    /**
     * Get the attributes that should be cast.
     *
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'latitude' => 'float',
            'longitude' => 'float',
            'last_refreshed_at' => 'datetime',
        ];
    }

    /**
     * All itinerary items stopping at this place.
     *
     * @return HasMany<ItineraryItem, $this>
     */
    public function itineraryItems(): HasMany
    {
        return $this->hasMany(ItineraryItem::class);
    }

    /**
     * Computed Google Maps deep link for navigation and directions.
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

                $query = $this->formatted_address ?: $this->name;

                return 'https://www.google.com/maps/search/?api=1&query='.urlencode($query);
            }
        );
    }
}
