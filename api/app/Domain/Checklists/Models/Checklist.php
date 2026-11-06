<?php

declare(strict_types=1);

namespace App\Domain\Checklists\Models;

use App\Domain\Trips\Models\Trip;
use Database\Factories\ChecklistFactory;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Casts\Attribute;
use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

#[Fillable([
    'trip_id',
    'title',
    'type',
    'description',
    'sort_order',
])]
final class Checklist extends Model
{
    /** @use HasFactory<ChecklistFactory> */
    use HasFactory, HasUuids;

    /**
     * Create a new factory instance for the model.
     */
    protected static function newFactory(): ChecklistFactory
    {
        return ChecklistFactory::new();
    }

    /**
     * Get the attributes that should be cast.
     *
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'sort_order' => 'integer',
        ];
    }

    /**
     * The trip this checklist belongs to.
     *
     * @return BelongsTo<Trip, $this>
     */
    public function trip(): BelongsTo
    {
        return $this->belongsTo(Trip::class);
    }

    /**
     * All items belonging to this checklist.
     *
     * @return HasMany<ChecklistItem, $this>
     */
    public function items(): HasMany
    {
        return $this->hasMany(ChecklistItem::class, 'checklist_id')
            ->orderBy('sort_order')
            ->orderBy('created_at');
    }

    /**
     * Total count of items.
     *
     * @return Attribute<int, never>
     */
    protected function totalItemsCount(): Attribute
    {
        return Attribute::make(
            get: fn (): int => $this->relationLoaded('items')
                ? $this->items->count()
                : $this->items()->count(),
        );
    }

    /**
     * Count of packed items.
     *
     * @return Attribute<int, never>
     */
    protected function packedItemsCount(): Attribute
    {
        return Attribute::make(
            get: fn (): int => $this->relationLoaded('items')
                ? $this->items->where('is_packed', true)->count()
                : $this->items()->where('is_packed', true)->count(),
        );
    }

    /**
     * Progress percentage (0 - 100).
     *
     * @return Attribute<int, never>
     */
    protected function progressPercentage(): Attribute
    {
        return Attribute::make(
            get: function (): int {
                $total = $this->total_items_count;
                if ($total === 0) {
                    return 0;
                }

                return (int) round(($this->packed_items_count / $total) * 100);
            },
        );
    }
}
