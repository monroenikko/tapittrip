<?php

declare(strict_types=1);

namespace App\Models;

use Database\Factories\ExpenseFactory;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\SoftDeletes;

#[Fillable([
    'trip_id',
    'payer_id',
    'created_by_user_id',
    'category',
    'title',
    'amount_minor',
    'currency',
    'exchange_rate',
    'rate_source',
    'rate_captured_at',
    'conversion_status',
    'base_amount_minor',
    'expense_date',
    'itinerary_item_id',
    'stay_id',
    'split_type',
    'visibility',
    'notes',
    'receipt_url',
    'version',
    'client_operation_id',
])]
final class Expense extends Model
{
    /** @use HasFactory<ExpenseFactory> */
    use HasFactory, HasUuids, SoftDeletes;

    /**
     * Create a new factory instance for the model.
     */
    protected static function newFactory(): ExpenseFactory
    {
        return ExpenseFactory::new();
    }

    /**
     * Get the attributes that should be cast.
     *
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'amount_minor' => 'integer',
            'base_amount_minor' => 'integer',
            'exchange_rate' => 'decimal:6',
            'rate_captured_at' => 'datetime',
            'expense_date' => 'date:Y-m-d',
            'version' => 'integer',
        ];
    }

    /**
     * Restrict expenses to shared group records or the viewer's own personal expenses.
     *
     * @param  Builder<Expense>  $query
     */
    public function scopeVisibleTo(Builder $query, ?User $user): void
    {
        if ($user === null) {
            $query->where('visibility', 'shared');

            return;
        }

        $query->where(function (Builder $q) use ($user): void {
            $q->where('visibility', 'shared')
                ->orWhere('created_by_user_id', $user->id)
                ->orWhere(function (Builder $fallback) use ($user): void {
                    $fallback->whereNull('created_by_user_id')
                        ->where('payer_id', $user->id);
                });
        });
    }

    public function isOwnedBy(?User $user): bool
    {
        if ($user === null) {
            return false;
        }

        if ($this->created_by_user_id !== null) {
            return $this->created_by_user_id === $user->id;
        }

        return $this->payer_id === $user->id;
    }

    public function isVisibleTo(?User $user): bool
    {
        if ($this->visibility === 'shared') {
            return true;
        }

        return $this->isOwnedBy($user);
    }

    /**
     * The trip this expense is logged for.
     *
     * @return BelongsTo<Trip, $this>
     */
    public function trip(): BelongsTo
    {
        return $this->belongsTo(Trip::class);
    }

    /**
     * The user who paid for this expense.
     *
     * @return BelongsTo<User, $this>
     */
    public function payer(): BelongsTo
    {
        return $this->belongsTo(User::class, 'payer_id');
    }

    /**
     * The user who logged/owns this expense record.
     *
     * @return BelongsTo<User, $this>
     */
    public function creator(): BelongsTo
    {
        return $this->belongsTo(User::class, 'created_by_user_id');
    }

    /**
     * Associated itinerary stop, if any.
     *
     * @return BelongsTo<ItineraryItem, $this>
     */
    public function itineraryItem(): BelongsTo
    {
        return $this->belongsTo(ItineraryItem::class);
    }

    /**
     * Associated stay, if any.
     *
     * @return BelongsTo<Stay, $this>
     */
    public function stay(): BelongsTo
    {
        return $this->belongsTo(Stay::class);
    }

    /**
     * Splits of this expense among travelers.
     *
     * @return HasMany<ExpenseSplit, $this>
     */
    public function splits(): HasMany
    {
        return $this->hasMany(ExpenseSplit::class, 'expense_id');
    }
}
