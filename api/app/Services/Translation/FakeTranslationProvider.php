<?php

declare(strict_types=1);

namespace App\Services\Translation;

use App\Contracts\TranslationProviderInterface;
use App\DTOs\Translation\TranslationResultData;

final class FakeTranslationProvider implements TranslationProviderInterface
{
    public function translate(
        string $text,
        string $sourceLanguage,
        string $targetLanguage,
    ): ?TranslationResultData {
        $trimmed = trim($text);
        if ($trimmed === '' || strtolower($trimmed) === '[unavailable]') {
            return null;
        }

        $target = strtolower(trim($targetLanguage));
        $dictionary = [
            'ja' => [
                'no peanuts please' => [
                    'local' => 'ピーナッツは入れないでください。',
                    'phonetic' => 'Piinattsu wa irenaide kudasai.',
                ],
                'where is the train station?' => [
                    'local' => '駅はどこですか？',
                    'phonetic' => 'Eki wa doko desu ka?',
                ],
            ],
            'ko' => [
                'no peanuts please' => [
                    'local' => '땅콩은 빼 주세요.',
                    'phonetic' => 'Ttangkong-eun ppae juseyo.',
                ],
            ],
            'tl' => [
                'no peanuts please' => [
                    'local' => 'Walang mani po, pakiusap.',
                    'phonetic' => 'Wah-lahng mah-nee poh, pah-kee-oo-sahp.',
                ],
            ],
        ];

        $lower = strtolower($trimmed);
        if (isset($dictionary[$target][$lower])) {
            return new TranslationResultData(
                sourceText: $trimmed,
                translatedText: $dictionary[$target][$lower]['local'],
                phonetic: $dictionary[$target][$lower]['phonetic'],
                sourceLanguage: strtolower($sourceLanguage),
                targetLanguage: $target,
                provider: 'deterministic_test_adapter',
                isOfflineMatch: false,
                disclaimer: TranslationService::DISCLAIMER,
            );
        }

        return new TranslationResultData(
            sourceText: $trimmed,
            translatedText: "[{$target}] {$trimmed}",
            phonetic: $trimmed,
            sourceLanguage: strtolower($sourceLanguage),
            targetLanguage: $target,
            provider: 'deterministic_test_adapter',
            isOfflineMatch: false,
            disclaimer: TranslationService::DISCLAIMER,
        );
    }
}
