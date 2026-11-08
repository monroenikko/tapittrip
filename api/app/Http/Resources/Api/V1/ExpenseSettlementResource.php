<?php

declare(strict_types=1);

namespace App\Http\Resources\Api\V1;

use App\Domain\Expenses\Models\ExpenseSettlement;
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
            'amount_minor' => $this->amount_minor,
            'currency' => $this->currency,
            'settled_at' => $this->settled_at?->toIso8601String(),
            'notes' => $this->notes,
            'payer' => $this->whenLoaded('payer', fn () => [
                'id' => $this->payer->id,
                'name' => $this->payer->name,
                'email' => $this->payer->email,
            ]),
            'payee' => $this->whenLoaded('payee', fn () => [
                'id' => $this->payee->id,
                'name' => $this->payee->name,
                'email' => $this->payee->email,
            ]),
            'created_at' => $this->created_at?->toIso8601String(),
            'updated_at' => $this->updated_at?->toIso8601String(),
        ];
    }
}
