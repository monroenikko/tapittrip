<?php

declare(strict_types=1);

namespace App\DTOs\Translation;

final readonly class TranslationResultData
{
    public function __construct(
        public string $sourceText,
        public string $translatedText,
        public string $phonetic,
        public string $sourceLanguage,
        public string $targetLanguage,
        public string $provider,
        public bool $isOfflineMatch,
        public string $disclaimer,
    ) {}
}
