<?php

declare(strict_types=1);

namespace App\Application\Stays\Services;

use App\Domain\Stays\Models\Stay;
use Illuminate\Support\Facades\DB;

final class DeleteStayService
{
    public function handle(Stay $stay): void
    {
        DB::transaction(function () use ($stay): void {
            // Decouple linked itinerary items so they are never orphaned or deleted
            $stay->itineraryItems()->update(['stay_id' => null]);

            $stay->delete();
        });
    }
}
