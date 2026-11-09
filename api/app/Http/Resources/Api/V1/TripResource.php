<?php

declare(strict_types=1);

namespace App\Http\Resources\Api\V1;

use App\Application\Expenses\Services\CountryCurrencyResolver;
use App\Domain\Trips\Models\Trip;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * @mixin Trip
 */
final class TripResource extends JsonResource
{
    /**
     * Transform the resource into an array.
     *
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        $currentUser = $request->user();
        $role = $currentUser ? $this->memberRole($currentUser) : null;
        $destinationCurrency = CountryCurrencyResolver::resolveTripCurrency($this->destination_country, $this->title);

        return [
            'id' => (string) $this->id,
            'owner_id' => (string) $this->owner_id,
            'title' => $this->title,
            'start_date' => $this->start_date?->format('Y-m-d'),
            'end_date' => $this->end_date?->format('Y-m-d'),
            'primary_timezone' => $this->primary_timezone,
            'origin_country' => $this->origin_country,
            'destination_country' => $this->destination_country,
            'destination_currency' => $destinationCurrency,
            'trip_type' => $this->trip_type,
            'planning_mode' => $this->planning_mode,
            'status' => $this->status,
            'version' => (int) $this->version,
            'role' => $role,
            'created_at' => $this->created_at?->toIso8601String(),
            'updated_at' => $this->updated_at?->toIso8601String(),
        ];
    }
}
