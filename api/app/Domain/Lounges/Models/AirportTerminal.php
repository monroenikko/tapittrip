<?php

declare(strict_types=1);

namespace App\Domain\Lounges\Models;

use Database\Factories\AirportTerminalFactory;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

#[Fillable([
    'airport_id',
    'name',
    'code',
])]
final class AirportTerminal extends Model
{
    /** @use HasFactory<AirportTerminalFactory> */
    use HasFactory, HasUuids;

    /**
     * Create a new factory instance for the model.
     */
    protected static function newFactory(): AirportTerminalFactory
    {
        return AirportTerminalFactory::new();
    }

    /**
     * The airport this terminal belongs to.
     *
     * @return BelongsTo<Airport, $this>
     */
    public function airport(): BelongsTo
    {
        return $this->belongsTo(Airport::class);
    }

    /**
     * Lounges located in this terminal.
     *
     * @return HasMany<AirportLounge, $this>
     */
    public function lounges(): HasMany
    {
        return $this->hasMany(AirportLounge::class, 'terminal_id');
    }
}
