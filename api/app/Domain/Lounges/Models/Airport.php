<?php

declare(strict_types=1);

namespace App\Domain\Lounges\Models;

use Database\Factories\AirportFactory;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

#[Fillable([
    'iata_code',
    'name',
    'city',
    'country',
    'latitude',
    'longitude',
    'timezone',
])]
final class Airport extends Model
{
    /** @use HasFactory<AirportFactory> */
    use HasFactory, HasUuids;

    /**
     * Create a new factory instance for the model.
     */
    protected static function newFactory(): AirportFactory
    {
        return AirportFactory::new();
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
        ];
    }

    /**
     * Terminals in this airport.
     *
     * @return HasMany<AirportTerminal, $this>
     */
    public function terminals(): HasMany
    {
        return $this->hasMany(AirportTerminal::class);
    }

    /**
     * Lounges in this airport.
     *
     * @return HasMany<AirportLounge, $this>
     */
    public function lounges(): HasMany
    {
        return $this->hasMany(AirportLounge::class);
    }
}
