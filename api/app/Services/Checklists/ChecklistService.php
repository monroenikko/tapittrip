<?php

declare(strict_types=1);

namespace App\Services\Checklists;

use App\DTOs\Checklists\CreateChecklistData;
use App\DTOs\Checklists\CreateChecklistItemData;
use App\DTOs\Checklists\UpdateChecklistItemData;
use App\Exceptions\VersionConflictException;
use App\Models\Checklist;
use App\Models\ChecklistItem;
use App\Models\Trip;
use App\Models\TripTraveler;
use App\Models\User;
use Illuminate\Database\Eloquent\Collection;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\File;
use Illuminate\Validation\ValidationException;
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
            ->with(['items.assignedUser', 'items.assignedTraveler', 'items.completedBy'])
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
        $trip = $checklist->trip;
        $this->validateAssignee($trip, $data->assignedUserId, $data->assignedTravelerId);

        /** @var ChecklistItem $item */
        $item = ChecklistItem::query()->create([
            'checklist_id' => $checklist->id,
            'trip_id' => $checklist->trip_id,
            'assigned_user_id' => $data->assignedUserId,
            'assigned_traveler_id' => $data->assignedTravelerId,
            'title' => $data->title,
            'category' => $data->category,
            'is_packed' => false,
            'quantity' => $data->quantity,
            'notes' => $data->notes,
            'photo_url' => null,
            'sort_order' => $checklist->items()->count(),
            'packed_at' => null,
            'completed_by_user_id' => null,
            'version' => 1,
        ]);

        return $item->load(['assignedUser', 'assignedTraveler', 'completedBy']);
    }

    /**
     * Update an existing checklist item.
     *
     * @throws VersionConflictException
     */
    public function updateItem(
        ChecklistItem $item,
        UpdateChecklistItemData $data,
        ?User $actor = null,
    ): ChecklistItem {
        $trip = $item->trip;
        $this->validateAssignee($trip, $data->assignedUserId, $data->assignedTravelerId);

        return DB::transaction(function () use ($item, $data, $actor): ChecklistItem {
            /** @var ChecklistItem $locked */
            $locked = ChecklistItem::query()
                ->whereKey($item->id)
                ->lockForUpdate()
                ->firstOrFail();

            if ($data->baseVersion !== null && $data->baseVersion !== $locked->version) {
                throw new VersionConflictException(
                    serverVersion: (int) $locked->version,
                    serverPayload: $this->serializeConflictPayload($locked),
                );
            }

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

            if ($data->assignedUserId !== null) {
                $attributes['assigned_user_id'] = $data->assignedUserId;
                $attributes['assigned_traveler_id'] = null;
            } elseif ($data->assignedTravelerId !== null) {
                $attributes['assigned_traveler_id'] = $data->assignedTravelerId;
                $attributes['assigned_user_id'] = null;
            } else {
                if ($data->clearAssignedUser) {
                    $attributes['assigned_user_id'] = null;
                }
                if ($data->clearAssignedTraveler) {
                    $attributes['assigned_traveler_id'] = null;
                }
            }

            if ($data->isPacked !== null) {
                $attributes['is_packed'] = $data->isPacked;
                $attributes['packed_at'] = $data->isPacked ? now() : null;
                $attributes['completed_by_user_id'] = $data->isPacked ? $actor?->id : null;
            }

            if ($attributes !== []) {
                $attributes['version'] = $locked->version + 1;
                $locked->update($attributes);
            }

            return $locked->fresh([
                'checklist',
                'trip',
                'assignedUser',
                'assignedTraveler',
                'completedBy',
            ]) ?? $locked;
        });
    }

    /**
     * Toggle the packed state of a checklist item.
     *
     * @throws VersionConflictException
     */
    public function toggleItem(
        ChecklistItem $item,
        ?User $actor = null,
        ?int $baseVersion = null,
    ): ChecklistItem {
        return DB::transaction(function () use ($item, $actor, $baseVersion): ChecklistItem {
            /** @var ChecklistItem $locked */
            $locked = ChecklistItem::query()
                ->whereKey($item->id)
                ->lockForUpdate()
                ->firstOrFail();

            if ($baseVersion !== null && $baseVersion !== $locked->version) {
                throw new VersionConflictException(
                    serverVersion: (int) $locked->version,
                    serverPayload: $this->serializeConflictPayload($locked),
                );
            }

            $newPacked = ! $locked->is_packed;

            $locked->update([
                'is_packed' => $newPacked,
                'packed_at' => $newPacked ? now() : null,
                'completed_by_user_id' => $newPacked ? $actor?->id : null,
                'version' => $locked->version + 1,
            ]);

            return $locked->fresh([
                'checklist',
                'trip',
                'assignedUser',
                'assignedTraveler',
                'completedBy',
            ]) ?? $locked;
        });
    }

    private function validateAssignee(
        Trip $trip,
        ?string $assignedUserId,
        ?string $assignedTravelerId,
    ): void {
        if ($assignedUserId !== null && $assignedTravelerId !== null) {
            throw ValidationException::withMessages([
                'assigned_user_id' => ['Assign a task to either a circle member or a managed traveler, not both.'],
            ]);
        }

        if ($assignedUserId !== null && ! $trip->hasMember($assignedUserId)) {
            throw ValidationException::withMessages([
                'assigned_user_id' => ['The assigned user must be an accepted member of this trip circle.'],
            ]);
        }

        if ($assignedTravelerId !== null) {
            $travelerExists = TripTraveler::query()
                ->where('id', $assignedTravelerId)
                ->where('trip_id', $trip->id)
                ->exists();

            if (! $travelerExists) {
                throw ValidationException::withMessages([
                    'assigned_traveler_id' => ['The assigned managed traveler does not belong to this trip circle.'],
                ]);
            }
        }
    }

    /**
     * @return array<string, mixed>
     */
    private function serializeConflictPayload(ChecklistItem $item): array
    {
        return [
            'id' => $item->id,
            'trip_id' => $item->trip_id,
            'checklist_id' => $item->checklist_id,
            'title' => $item->title,
            'is_packed' => (bool) $item->is_packed,
            'assigned_user_id' => $item->assigned_user_id,
            'assigned_traveler_id' => $item->assigned_traveler_id,
            'completed_by_user_id' => $item->completed_by_user_id,
            'notes' => $item->notes,
            'version' => (int) $item->version,
        ];
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
