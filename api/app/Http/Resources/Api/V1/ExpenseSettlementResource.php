<?php

declare(strict_types=1);

namespace App\Http\Resources\Api\V1;

use App\Models\ExpenseSettlement;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * @mixin ExpenseSettlement
 */
final class ExpenseSettlementResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'trip_id' => $this->trip_id,
            'payer_id' => $this->payer_id,
            'payee_id' => $this->payee_id,
            'created_by_user_id' => $this->created_by_user_id,
            'amount_minor' => $this->amount_minor,
            'currency' => $this->currency,
            'exchange_rate' => $this->exchange_rate !== null ? (float) $this->exchange_rate : null,
            'base_amount_minor' => $this->base_amount_minor,
            'rate_source' => $this->rate_source,
            'rate_captured_at' => $this->rate_captured_at?->toIso8601String(),
            'settled_at' => $this->settled_at?->toIso8601String(),
            'notes' => $this->notes,
            'client_operation_id' => $this->client_operation_id,
            'payer' => $this->whenLoaded('payer', fn () => [
                'id' => $this->payer->id,
                'name' => $this->payer->name,
            ]),
            'payee' => $this->whenLoaded('payee', fn () => [
                'id' => $this->payee->id,
                'name' => $this->payee->name,
            ]),
            'created_at' => $this->created_at?->toIso8601String(),
            'updated_at' => $this->updated_at?->toIso8601String(),
        ];
    }
}
