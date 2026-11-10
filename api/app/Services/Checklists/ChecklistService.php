<?php

declare(strict_types=1);

namespace App\Services\Checklists;

use App\DTOs\Checklists\CreateChecklistData;
use App\DTOs\Checklists\CreateChecklistItemData;
use App\DTOs\Checklists\UpdateChecklistItemData;
use App\Models\Checklist;
use App\Models\ChecklistItem;
use App\Models\Trip;
use Illuminate\Database\Eloquent\Collection;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\File;
use InvalidArgumentException;

final class ChecklistService
{
    /**
     * Get checklist starter templates from database data storage.
     *
     * @return array<string, array{title: string, type: string, description: string, items: array<int, array{title: string, category: string, quantity: int}>}>
     */
    public static function getTemplates(): array
    {
        return Cache::rememberForever('checklist_templates_data', function (): array {
            $path = database_path('data/checklist_templates.json');
            if (File::exists($path)) {
                $decoded = json_decode((string) File::get($path), true);
                if (is_array($decoded)) {
                    return $decoded;
                }
            }

            return [];
        });
    }

    /**
     * Get all checklists for a trip with their items loaded.
     *
     * @return Collection<int, Checklist>
     */
    public function getTripChecklists(Trip $trip): Collection
    {
        return $trip->checklists()
            ->with(['items'])
            ->get();
    }

    /**
     * Create a new checklist for a trip.
     */
    public function createChecklist(Trip $trip, CreateChecklistData $data): Checklist
    {
        /** @var Checklist $checklist */
        $checklist = Checklist::query()->create([
            'trip_id' => $trip->id,
            'title' => $data->title,
            'type' => $data->type,
            'description' => $data->description,
            'sort_order' => $data->sortOrder,
        ]);

        return $checklist->load('items');
    }

    /**
     * Apply a starter template to a trip.
     */
    public function applyTemplate(Trip $trip, string $templateKey): Checklist
    {
        $templates = self::getTemplates();

        if (! array_key_exists($templateKey, $templates)) {
            throw new InvalidArgumentException("Unknown checklist template [{$templateKey}].");
        }

        $template = $templates[$templateKey];

        /** @var array<int, array{title: string, category: string, quantity: int}> $items */
        $items = $template['items'];

        if ($templateKey === 'all_essentials') {
            $items = array_merge(
                $templates['international_essentials']['items'] ?? [],
                $templates['electronics_gear']['items'] ?? [],
                $templates['clothing_apparel']['items'] ?? [],
                $templates['toiletries_health']['items'] ?? [],
            );
        }

        return DB::transaction(function () use ($trip, $template, $items): Checklist {
            /** @var Checklist $checklist */
            $checklist = Checklist::query()->create([
                'trip_id' => $trip->id,
                'title' => $template['title'],
                'type' => $template['type'],
                'description' => $template['description'],
                'sort_order' => $trip->checklists()->count(),
            ]);

            $order = 0;
            foreach ($items as $item) {
                ChecklistItem::query()->create([
                    'checklist_id' => $checklist->id,
                    'trip_id' => $trip->id,
                    'title' => $item['title'],
                    'category' => $item['category'],
                    'is_packed' => false,
                    'quantity' => $item['quantity'],
                    'notes' => null,
                    'photo_url' => null,
                    'sort_order' => $order++,
                    'packed_at' => null,
                    'version' => 1,
                ]);
            }

            return $checklist->load('items');
        });
    }

    /**
     * Delete a checklist.
     */
    public function deleteChecklist(Checklist $checklist): void
    {
        $checklist->delete();
    }

    /**
     * Create a new item inside a checklist.
     */
    public function createItem(Checklist $checklist, CreateChecklistItemData $data): ChecklistItem
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
            'photo_url' => null,
            'sort_order' => $checklist->items()->count(),
            'packed_at' => null,
            'version' => 1,
        ]);

        return $item;
    }

    /**
     * Update an existing checklist item.
     */
    public function updateItem(ChecklistItem $item, UpdateChecklistItemData $data): ChecklistItem
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

        if ($data->notes !== null) {
            $attributes['notes'] = $data->notes;
        }

        if ($data->sortOrder !== null) {
            $attributes['sort_order'] = $data->sortOrder;
        }

        if ($data->isPacked !== null) {
            $attributes['is_packed'] = $data->isPacked;
            $attributes['packed_at'] = $data->isPacked ? now() : null;
        }

        $attributes['version'] = $item->version + 1;

        $item->update($attributes);

        return $item->fresh(['checklist', 'trip']);
    }

    /**
     * Toggle the packed state of a checklist item.
     */
    public function toggleItem(ChecklistItem $item): ChecklistItem
    {
        $newPacked = ! $item->is_packed;

        $item->update([
            'is_packed' => $newPacked,
            'packed_at' => $newPacked ? now() : null,
            'version' => $item->version + 1,
        ]);

        return $item->fresh(['checklist', 'trip']);
    }

    public function toggleItemPacked(ChecklistItem $item): ChecklistItem
    {
        return $this->toggleItem($item);
    }

    /**
     * Delete a checklist item.
     */
    public function deleteItem(ChecklistItem $item): void
    {
        $item->delete();
    }
}
