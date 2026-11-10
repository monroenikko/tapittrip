<?php

declare(strict_types=1);

namespace App\Models;

use Database\Factories\TripTravelerFactory;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\SoftDeletes;

#[Fillable([
    'trip_id',
    'linked_member_id',
    'managing_user_id',
    'display_name',
    'traveler_category',
    'restricted_notes',
    'version',
])]
final class TripTraveler extends Model
{
    /** @use HasFactory<TripTravelerFactory> */
    use HasFactory, HasUuids, SoftDeletes;

    protected static function newFactory(): TripTravelerFactory
    {
        return TripTravelerFactory::new();
    }

    /**
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'restricted_notes' => 'encrypted',
            'version' => 'integer',
        ];
    }

    /**
     * @return BelongsTo<Trip, $this>
     */
    public function trip(): BelongsTo
    {
        return $this->belongsTo(Trip::class);
    }

    /**
     * @return BelongsTo<TripMember, $this>
     */
    public function linkedMember(): BelongsTo
    {
        return $this->belongsTo(TripMember::class, 'linked_member_id');
    }

    /**
     * @return BelongsTo<User, $this>
     */
    public function managingUser(): BelongsTo
    {
        return $this->belongsTo(User::class, 'managing_user_id');
    }

    /**
     * @return HasMany<ChecklistItem, $this>
     */
    public function assignedChecklistItems(): HasMany
    {
        return $this->hasMany(ChecklistItem::class, 'assigned_traveler_id');
    }
}
