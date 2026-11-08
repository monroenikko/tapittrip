<?php

declare(strict_types=1);

namespace App\Http\Resources\Api\V1;

use App\Application\Expenses\Data\TripExpensesSummaryResult;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * @mixin TripExpensesSummaryResult
 */
final class TripExpenseSummaryResource extends JsonResource
{
    /**
     * Transform the resource into an array.
     *
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return $this->resource->toArray();
    }
}
