<?php

declare(strict_types=1);

namespace App\Domain\Lounges\Models;

use Database\Factories\AirportLoungeFactory;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

#[Fillable([
    'airport_id',
    'terminal_id',
    'name',
    'operator',
    'location_description',
    'is_airside',
    'opening_hours',
    'amenities',
    'access_methods',
    'estimated_price',
    'booking_url',
    'transit_warning',
    'disclaimer',
])]
final class AirportLounge extends Model
{
    /** @use HasFactory<AirportLoungeFactory> */
    use HasFactory, HasUuids;

    /**
     * Create a new factory instance for the model.
     */
    protected static function newFactory(): AirportLoungeFactory
    {
        return AirportLoungeFactory::new();
    }

    /**
     * Get the attributes that should be cast.
     *
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'is_airside' => 'boolean',
            'opening_hours' => 'array',
            'amenities' => 'array',
            'access_methods' => 'array',
            'estimated_price' => 'array',
        ];
    }

    /**
     * The airport this lounge belongs to.
     *
     * @return BelongsTo<Airport, $this>
     */
    public function airport(): BelongsTo
    {
        return $this->belongsTo(Airport::class);
    }

    /**
     * The terminal this lounge is located in.
     *
     * @return BelongsTo<AirportTerminal, $this>
     */
    public function terminal(): BelongsTo
    {
        return $this->belongsTo(AirportTerminal::class, 'terminal_id');
    }
}
