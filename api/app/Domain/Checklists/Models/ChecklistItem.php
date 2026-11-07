<?php

declare(strict_types=1);

namespace App\Domain\Checklists\Models;

use App\Domain\Media\Models\MediaAttachment;
use App\Domain\Trips\Models\Trip;
use Database\Factories\ChecklistItemFactory;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

#[Fillable([
    'checklist_id',
    'trip_id',
    'title',
    'category',
    'is_packed',
    'quantity',
    'notes',
    'photo_url',
    'sort_order',
    'packed_at',
    'version',
])]
final class ChecklistItem extends Model
{
    /** @use HasFactory<ChecklistItemFactory> */
    use HasFactory, HasUuids;

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
