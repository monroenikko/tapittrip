<?php

declare(strict_types=1);

namespace App\Domain\Notifications\Models;

use App\Domain\Checklists\Models\Checklist;
use App\Domain\Itinerary\Models\ItineraryItem;
use App\Domain\Trips\Models\Trip;
use Database\Factories\ReminderFactory;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

#[Fillable([
    'trip_id',
    'itinerary_item_id',
    'checklist_id',
    'type',
    'title',
    'body',
    'trigger_at_utc',
    'timezone',
    'delivery_channel',
    'status',
    'dedupe_key',
    'source_version',
])]
final class Reminder extends Model
{
    /** @use HasFactory<ReminderFactory> */
    use HasFactory, HasUuids;

    /**
     * Create a new factory instance for the model.
     */
    protected static function newFactory(): ReminderFactory
    {
        return ReminderFactory::new();
    }

    /**
     * Get the attributes that should be cast.
     *
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'trigger_at_utc' => 'datetime',
            'source_version' => 'integer',
        ];
    }

    /**
     * The trip this reminder belongs to.
     *
     * @return BelongsTo<Trip, $this>
     */
    public function trip(): BelongsTo
    {
        return $this->belongsTo(Trip::class);
    }

    /**
     * The associated itinerary item, if any.
     *
     * @return BelongsTo<ItineraryItem, $this>
     */
    public function itineraryItem(): BelongsTo
    {
        return $this->belongsTo(ItineraryItem::class);
    }

    /**
     * The associated checklist, if any.
     *
     * @return BelongsTo<Checklist, $this>
     */
    public function checklist(): BelongsTo
    {
        return $this->belongsTo(Checklist::class);
    }
}

