<?php

declare(strict_types=1);

namespace App\Application\Checklists\Services;

use App\Application\Checklists\Data\CreateChecklistData;
use App\Domain\Checklists\Models\Checklist;
use App\Domain\Trips\Models\Trip;

final class CreateChecklistService
{
    /**
     * Create a new checklist for a trip.
     */
    public function handle(Trip $trip, CreateChecklistData $data): Checklist
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
}
