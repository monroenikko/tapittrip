<?php

declare(strict_types=1);

namespace App\Models;

use Database\Factories\ChecklistItemFactory;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\SoftDeletes;

#[Fillable([
    'checklist_id',
    'trip_id',
    'assigned_user_id',
    'assigned_traveler_id',
    'title',
    'category',
    'is_packed',
    'quantity',
    'notes',
    'photo_url',
    'sort_order',
    'packed_at',
    'completed_by_user_id',
    'version',
])]
final class ChecklistItem extends Model
{
    /** @use HasFactory<ChecklistItemFactory> */
    use HasFactory, HasUuids, SoftDeletes;

    /**
     * Create a new factory instance for the model.
     */
    protected static function newFactory(): ChecklistItemFactory
    {
        return ChecklistItemFactory::new();
    }

    /**
     * Get the attributes that should be cast.
     *
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'is_packed' => 'boolean',
            'quantity' => 'integer',
            'sort_order' => 'integer',
            'version' => 'integer',
            'packed_at' => 'datetime',
        ];
    }

    /**
     * The checklist this item belongs to.
     *
     * @return BelongsTo<Checklist, $this>
     */
    public function checklist(): BelongsTo
    {
        return $this->belongsTo(Checklist::class);
    }

    /**
     * The trip this item belongs to.
     *
     * @return BelongsTo<Trip, $this>
     */
    public function trip(): BelongsTo
    {
        return $this->belongsTo(Trip::class);
    }

    /**
     * Accepted trip member responsible for this item, if assigned to a member.
     *
     * @return BelongsTo<User, $this>
     */
    public function assignedUser(): BelongsTo
    {
        return $this->belongsTo(User::class, 'assigned_user_id');
    }

    /**
     * Managed traveler profile responsible for this item, if any.
     *
     * @return BelongsTo<TripTraveler, $this>
     */
    public function assignedTraveler(): BelongsTo
    {
        return $this->belongsTo(TripTraveler::class, 'assigned_traveler_id');
    }

    /**
     * User who last marked this item packed/completed.
     *
     * @return BelongsTo<User, $this>
     */
    public function completedBy(): BelongsTo
    {
        return $this->belongsTo(User::class, 'completed_by_user_id');
    }

    /**
     * All media attachments associated with this checklist item.
     *
     * @return HasMany<MediaAttachment, $this>
     */
    public function mediaAttachments(): HasMany
    {
        return $this->hasMany(MediaAttachment::class, 'attachable_id')
            ->where('attachable_type', 'checklist_item')
            ->orderBy('created_at', 'desc');
    }
}
