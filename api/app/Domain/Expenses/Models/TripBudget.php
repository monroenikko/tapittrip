<?php

declare(strict_types=1);

namespace App\Domain\Expenses\Models;

use App\Domain\Trips\Models\Trip;
use Database\Factories\TripBudgetFactory;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

#[Fillable([
    'trip_id',
    'currency',
    'total_budget_minor',
    'daily_budget_minor',
])]
final class TripBudget extends Model
{
    /** @use HasFactory<TripBudgetFactory> */
    use HasFactory, HasUuids;

    /**
     * Create a new factory instance for the model.
     */
    protected static function newFactory(): TripBudgetFactory
    {
        return TripBudgetFactory::new();
    }

    /**
     * Get the attributes that should be cast.
     *
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'total_budget_minor' => 'integer',
            'daily_budget_minor' => 'integer',
        ];
    }

    /**
     * The trip this budget belongs to.
     *
     * @return BelongsTo<Trip, $this>
     */
    public function trip(): BelongsTo
    {
        return $this->belongsTo(Trip::class);
    }
}
