<?php

declare(strict_types=1);

namespace App\Http\Resources\Api\V1;

use App\Models\Expense;
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
            'created_by_user_id' => $this->created_by_user_id,
            'category' => $this->category,
            'title' => $this->title,
            'amount_minor' => $this->amount_minor,
            'currency' => $this->currency,
            'exchange_rate' => $this->exchange_rate !== null ? (float) $this->exchange_rate : null,
            'rate_source' => $this->rate_source,
            'rate_captured_at' => $this->rate_captured_at?->toIso8601String(),
            'conversion_status' => $this->conversion_status ?? 'converted',
            'base_amount_minor' => $this->base_amount_minor,
            'expense_date' => $this->expense_date->toDateString(),
            'itinerary_item_id' => $this->itinerary_item_id,
            'stay_id' => $this->stay_id,
            'split_type' => $this->split_type,
            'visibility' => $this->visibility ?? 'shared',
            'notes' => $this->notes,
            'receipt_url' => $this->receipt_url,
            'version' => $this->version,
            'client_operation_id' => $this->client_operation_id,
            'payer' => $this->whenLoaded('payer', fn () => [
                'id' => $this->payer->id,
                'name' => $this->payer->name,
            ]),
            'creator' => $this->whenLoaded('creator', fn () => $this->creator !== null ? [
                'id' => $this->creator->id,
                'name' => $this->creator->name,
            ] : null),
            'itinerary_item' => $this->whenLoaded('itineraryItem', fn () => $this->itineraryItem !== null ? [
                'id' => $this->itineraryItem->id,
                'title' => $this->itineraryItem->title,
            ] : null),
            'stay' => $this->whenLoaded('stay', fn () => $this->stay !== null ? [
                'id' => $this->stay->id,
                'name' => $this->stay->name,
            ] : null),
            'splits' => $this->whenLoaded('splits', fn () => $this->splits->map(fn ($s) => [
                'id' => $s->id,
                'user_id' => $s->user_id,
                'amount_minor' => $s->amount_minor,
                'base_amount_minor' => $s->base_amount_minor,
                'shares' => $s->shares,
                'settled' => $s->settled,
                'user' => $s->relationLoaded('user') && $s->user !== null ? [
                    'id' => $s->user->id,
                    'name' => $s->user->name,
                ] : null,
            ])->values()->all()),
            'created_at' => $this->created_at?->toIso8601String(),
            'updated_at' => $this->updated_at?->toIso8601String(),
        ];
    }
}
