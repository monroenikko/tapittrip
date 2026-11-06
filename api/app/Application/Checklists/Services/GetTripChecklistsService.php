<?php

declare(strict_types=1);

namespace App\Application\Checklists\Services;

use App\Domain\Checklists\Models\Checklist;
use App\Domain\Trips\Models\Trip;
use Illuminate\Database\Eloquent\Collection;

final class GetTripChecklistsService
{
    /**
     * Get all checklists for a trip with their items loaded.
     *
     * @return Collection<int, Checklist>
     */
    public function handle(Trip $trip): Collection
    {
        return $trip->checklists()
            ->with(['items'])
            ->get();
    }
}
