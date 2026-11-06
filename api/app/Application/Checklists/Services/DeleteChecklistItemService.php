<?php

declare(strict_types=1);

namespace App\Application\Checklists\Services;

use App\Domain\Checklists\Models\ChecklistItem;

final class DeleteChecklistItemService
{
    /**
     * Delete a checklist item.
     */
    public function handle(ChecklistItem $item): void
    {
        $item->delete();
    }
}
