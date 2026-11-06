<?php

declare(strict_types=1);

namespace App\Application\Checklists\Services;

use App\Domain\Checklists\Models\ChecklistItem;

final class ToggleChecklistItemService
{
    /**
     * Toggle the packed status of a checklist item.
     */
    public function handle(ChecklistItem $item): ChecklistItem
    {
        $newPackedStatus = ! $item->is_packed;

        $item->update([
            'is_packed' => $newPackedStatus,
            'packed_at' => $newPackedStatus ? now() : null,
            'version' => $item->version + 1,
        ]);

        return $item->fresh(['checklist', 'trip']);
    }
}
