<?php

declare(strict_types=1);

namespace App\Http\Resources\Api\V1;

use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * @mixin User
 */
final class UserResource extends JsonResource
{
    /**
     * Transform the resource into an array.
     *
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => (string) $this->id,
            'name' => $this->name,
            'display_name' => $this->display_name ?? $this->name,
            'email' => $this->email,
            'avatar_url' => $this->avatar_url,
            'locale' => $this->locale ?? 'en',
            'home_timezone' => $this->home_timezone ?? 'UTC',
            'home_country' => $this->home_country,
            'home_currency' => $this->home_currency,
            'created_at' => $this->created_at?->toIso8601String(),
            'updated_at' => $this->updated_at?->toIso8601String(),
        ];
    }
}
