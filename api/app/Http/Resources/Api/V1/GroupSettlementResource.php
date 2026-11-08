<?php

declare(strict_types=1);

namespace App\Http\Resources\Api\V1;

use App\Application\Expenses\Data\GroupSettlementResult;
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
        return [
            'trip_id' => $this->tripId,
            'base_currency' => $this->baseCurrency,
            'balances' => $this->balances,
            'suggested_settlements' => $this->suggestedSettlements,
            'settlement_history' => $this->settlementHistory,
        ];
    }
}
