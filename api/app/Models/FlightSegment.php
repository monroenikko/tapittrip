<?php

declare(strict_types=1);

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

final class FlightSegment extends Model
{
    use HasFactory, HasUuids;

    protected $fillable = ['flight_number', 'origin_airport', 'destination_airport', 'scheduled_departure_utc', 'scheduled_arrival_utc', 'origin_timezone', 'destination_timezone', 'terminal', 'gate'];

    protected function casts(): array
    {
        return [
            'scheduled_departure_utc' => 'immutable_datetime',
            'scheduled_arrival_utc' => 'immutable_datetime',
        ];
    }

    public function flight(): BelongsTo
    {
        return $this->belongsTo(Flight::class);
    }
}
