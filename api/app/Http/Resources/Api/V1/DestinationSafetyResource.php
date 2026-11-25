<?php

declare(strict_types=1);

namespace App\Http\Resources\Api\V1;

use App\DTOs\Safety\DestinationSafetyProfileData;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * @mixin DestinationSafetyProfileData
 */
final class DestinationSafetyResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'country_code' => $this->countryCode,
            'country_name' => $this->countryName,
            'flag_emoji' => $this->flagEmoji,
            'is_curated' => $this->isCurated,
            'emergency_numbers' => $this->emergencyNumbers,
            'official_resources' => $this->officialResources,
            'emergency_phrases' => $this->emergencyPhrases,
            'last_verified_at' => $this->lastVerifiedAt,
            'disclaimer' => $this->disclaimer,
        ];
    }
}
