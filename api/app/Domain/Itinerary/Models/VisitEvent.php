<?php

declare(strict_types=1);

namespace App\Domain\Itinerary\Models;

use App\Domain\Users\Models\User;
use Database\Factories\VisitEventFactory;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

#[Fillable([
    'itinerary_item_id',
    'user_id',
    'event_type',
    'method',
    'detected_at',
    'accuracy_m',
])]
final class VisitEvent extends Model
{
    /** @use HasFactory<VisitEventFactory> */
    use HasFactory, HasUuids;

    /**
     * Create a new factory instance for the model.
     */
    protected static function newFactory(): VisitEventFactory
    {
        return VisitEventFactory::new();
    }

    /**
     * Get the attributes that should be cast.
     *
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'detected_at' => 'datetime',
            'accuracy_m' => 'float',
        ];
    }

    /**
     * The itinerary item this visit event belongs to.
     *
     * @return BelongsTo<ItineraryItem, $this>
     */
    public function itineraryItem(): BelongsTo
    {
        return $this->belongsTo(ItineraryItem::class);
    }

    /**
     * The user who recorded/experienced this visit event.
     *
     * @return BelongsTo<User, $this>
     */
    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}
