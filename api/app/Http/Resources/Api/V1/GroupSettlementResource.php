<?php

declare(strict_types=1);

namespace App\Http\Resources\Api\V1;

use App\DTOs\Expenses\GroupSettlementResult;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * @mixin GroupSettlementResult
 */
final class GroupSettlementResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return $this->resource->toArray();
    }
}
