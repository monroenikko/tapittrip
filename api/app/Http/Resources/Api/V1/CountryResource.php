<?php

declare(strict_types=1);

namespace App\Http\Resources\Api\V1;

use App\Models\Country;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * @mixin Country
 */
final class CountryResource extends JsonResource
{
    /**
     * Transform the resource into an array.
     *
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'code' => $this->code,
            'name' => $this->name,
            'currency_code' => $this->currency_code,
            'flag_emoji' => $this->flag_emoji,
            'is_zero_decimal' => (bool) $this->is_zero_decimal,
        ];
    }
}
