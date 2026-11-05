<?php

declare(strict_types=1);

namespace App\Application\Itinerary\Services;

use App\Domain\Itinerary\Models\ItineraryItem;
use Illuminate\Support\Facades\DB;

final class DeleteItineraryItemService
{
    public function handle(ItineraryItem $item): void
    {
        DB::transaction(function () use ($item): void {
            $item->delete();
        });
    }
}
