<?php

declare(strict_types=1);

namespace App\Http\Resources\Api\V1;

use App\Domain\Expenses\Models\TripBudget;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * @mixin TripBudget
 */
final class TripBudgetResource extends JsonResource
{
    /**
     * Transform the resource into an array.
     *
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'trip_id' => $this->trip_id,
            'currency' => $this->currency,
            'total_budget_minor' => $this->total_budget_minor,
            'daily_budget_minor' => $this->daily_budget_minor,
            'created_at' => $this->created_at?->toIso8601String(),
            'updated_at' => $this->updated_at?->toIso8601String(),
        ];
    }
}
