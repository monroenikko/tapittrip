<?php

declare(strict_types=1);

namespace App\Http\Resources\Api\V1;

use App\DTOs\Translation\PhrasebookBundleData;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * @mixin PhrasebookBundleData
 */
final class PhrasebookResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'language_code' => $this->languageCode,
            'language_name' => $this->languageName,
            'native_name' => $this->nativeName,
            'flag_emoji' => $this->flagEmoji,
            'country_code' => $this->countryCode,
            'categories' => $this->categories,
            'phrases' => $this->phrases,
            'disclaimer' => $this->disclaimer,
        ];
    }
}
