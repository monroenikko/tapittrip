<?php

declare(strict_types=1);

namespace App\Contracts;

use App\DTOs\Translation\TranslationResultData;

interface TranslationProviderInterface
{
    /**
     * Translate text from sourceLanguage to targetLanguage using an external/cloud provider.
     * Returns null when the provider is unconfigured or unavailable.
     */
    public function translate(
        string $text,
        string $sourceLanguage,
        string $targetLanguage,
    ): ?TranslationResultData;
}
