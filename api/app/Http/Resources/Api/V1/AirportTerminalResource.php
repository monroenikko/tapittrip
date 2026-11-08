<?php

declare(strict_types=1);

namespace App\Http\Resources\Api\V1;

use App\Domain\Lounges\Models\AirportTerminal;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * @mixin AirportTerminal
 */
final class AirportTerminalResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'airport_id' => $this->airport_id,
            'name' => $this->name,
            'code' => $this->code,
        ];
    }
}
