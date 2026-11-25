<?php

declare(strict_types=1);

namespace App\DTOs\Translation;

final readonly class PhrasebookBundleData
{
    /**
     * @param  array<int, string>  $categories
     * @param  array<int, array{
     *     id: string,
     *     category: string,
     *     english: string,
     *     local_text: string,
     *     phonetic: string,
     *     context_note: string|null
     * }>  $phrases
     */
    public function __construct(
        public string $languageCode,
        public string $languageName,
        public string $nativeName,
        public string $flagEmoji,
        public string $countryCode,
        public array $categories,
        public array $phrases,
        public string $disclaimer,
    ) {}
}
