<?php

declare(strict_types=1);

namespace App\Application\Checklists\Services;

use App\Application\Checklists\Data\UpdateChecklistItemData;
use App\Domain\Checklists\Models\ChecklistItem;

final class UpdateChecklistItemService
{
    /**
     * Update an existing checklist item.
     */
    public function handle(ChecklistItem $item, UpdateChecklistItemData $data): ChecklistItem
    {
        $attributes = [];

        if ($data->title !== null) {
            $attributes['title'] = $data->title;
        }

        if ($data->category !== null) {
            $attributes['category'] = $data->category;
        }

        if ($data->quantity !== null) {
            $attributes['quantity'] = $data->quantity;
        }

        if ($data->notes !== null || $data->notes === '') {
            $attributes['notes'] = $data->notes ?: null;
        }

        if ($data->photoUrl !== null || $data->photoUrl === '') {
            $attributes['photo_url'] = $data->photoUrl ?: null;
        }

        if ($data->sortOrder !== null) {
            $attributes['sort_order'] = $data->sortOrder;
        }

        if ($data->isPacked !== null) {
            $attributes['is_packed'] = $data->isPacked;
            $attributes['packed_at'] = $data->isPacked ? ($item->packed_at ?? now()) : null;
        }

        $attributes['version'] = $item->version + 1;

        $item->update($attributes);

        return $item->fresh(['checklist', 'trip']);
    }
}
