<?php

declare(strict_types=1);

namespace App\Http\Resources\Api\V1;

use App\DTOs\Translation\TranslationResultData;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * @mixin TranslationResultData
 */
final class TranslationResultResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'source_text' => $this->sourceText,
            'translated_text' => $this->translatedText,
            'phonetic' => $this->phonetic,
            'source_language' => $this->sourceLanguage,
            'target_language' => $this->targetLanguage,
            'provider' => $this->provider,
            'is_offline_match' => $this->isOfflineMatch,
            'disclaimer' => $this->disclaimer,
        ];
    }
}
