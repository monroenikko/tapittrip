<?php

declare(strict_types=1);

namespace App\Http\Resources\Api\V1;

use App\Domain\Expenses\Models\Expense;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * @mixin Expense
 */
final class ExpenseResource extends JsonResource
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
            'payer_id' => $this->payer_id,
            'category' => $this->category,
            'title' => $this->title,
            'amount_minor' => $this->amount_minor,
            'currency' => $this->currency,
            'exchange_rate' => (float) $this->exchange_rate,
            'base_amount_minor' => $this->base_amount_minor,
            'expense_date' => $this->expense_date->toDateString(),
            'itinerary_item_id' => $this->itinerary_item_id,
            'stay_id' => $this->stay_id,
            'split_type' => $this->split_type,
            'notes' => $this->notes,
            'receipt_url' => $this->receipt_url,
            'version' => $this->version,
            'payer' => $this->whenLoaded('payer', fn () => [
                'id' => $this->payer->id,
                'name' => $this->payer->name,
                'email' => $this->payer->email,
            ]),
            'itinerary_item' => $this->whenLoaded('itineraryItem', fn () => [
                'id' => $this->itineraryItem?->id,
                'title' => $this->itineraryItem?->title,
            ]),
            'stay' => $this->whenLoaded('stay', fn () => [
                'id' => $this->stay?->id,
                'name' => $this->stay?->name,
            ]),
            'created_at' => $this->created_at?->toIso8601String(),
            'updated_at' => $this->updated_at?->toIso8601String(),
        ];
    }
}
