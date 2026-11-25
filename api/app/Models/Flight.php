<?php

declare(strict_types=1);

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

final class Flight extends Model
{
    use HasFactory, HasUuids;

    protected $fillable = ['trip_id', 'airline', 'booking_reference', 'client_operation_id', 'version'];

    protected function casts(): array
    {
        return [
            'booking_reference' => 'encrypted',
            'version' => 'integer',
        ];
    }

    public function trip(): BelongsTo
    {
        return $this->belongsTo(Trip::class);
    }

    public function segments(): HasMany
    {
        return $this->hasMany(FlightSegment::class)->orderBy('scheduled_departure_utc');
    }
}
