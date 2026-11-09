<?php

declare(strict_types=1);

namespace App\Domain\Journal\Models;

use App\Domain\Itinerary\Models\ItineraryItem;
use App\Domain\Trips\Models\Trip;
use App\Models\User;
use Database\Factories\JournalEntryFactory;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\SoftDeletes;

#[Fillable([
    'trip_id',
    'user_id',
    'itinerary_item_id',
    'title',
    'content',
    'entry_date',
    'location_name',
    'weather',
    'mood',
    'is_shared',
    'photos',
])]
final class JournalEntry extends Model
{
    /** @use HasFactory<JournalEntryFactory> */
    use HasFactory, HasUuids, SoftDeletes;

    /**
     * Create a new factory instance for the model.
     */
    protected static function newFactory(): JournalEntryFactory
    {
        return JournalEntryFactory::new();
    }

    /**
     * Get the attributes that should be cast.
     *
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'entry_date' => 'date:Y-m-d',
            'is_shared' => 'boolean',
            'photos' => 'array',
        ];
    }

    /**
     * The trip this journal entry belongs to.
     *
     * @return BelongsTo<Trip, $this>
     */
    public function trip(): BelongsTo
    {
        return $this->belongsTo(Trip::class);
    }

    /**
     * The author of this journal entry.
     *
     * @return BelongsTo<User, $this>
     */
    public function author(): BelongsTo
    {
        return $this->belongsTo(User::class, 'user_id');
    }

    /**
     * Optional itinerary item linked to this entry.
     *
     * @return BelongsTo<ItineraryItem, $this>
     */
    public function itineraryItem(): BelongsTo
    {
        return $this->belongsTo(ItineraryItem::class);
    }
}
