<?php

declare(strict_types=1);

namespace App\Application\Checklists\Services;

use App\Application\Checklists\Data\CreateChecklistItemData;
use App\Domain\Checklists\Models\Checklist;
use App\Domain\Checklists\Models\ChecklistItem;

final class CreateChecklistItemService
{
    /**
     * Create a new item inside a checklist.
     */
    public function handle(Checklist $checklist, CreateChecklistItemData $data): ChecklistItem
    {
        /** @var ChecklistItem $item */
        $item = ChecklistItem::query()->create([
            'checklist_id' => $checklist->id,
            'trip_id' => $checklist->trip_id,
            'title' => $data->title,
            'category' => $data->category,
            'is_packed' => false,
            'quantity' => $data->quantity,
            'notes' => $data->notes,
            'photo_url' => $data->photoUrl,
            'sort_order' => $data->sortOrder,
            'packed_at' => null,
            'version' => 1,
        ]);

        return $item;
    }
}
