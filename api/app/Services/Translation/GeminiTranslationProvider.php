<?php

declare(strict_types=1);

namespace App\Services\Translation;

use App\Contracts\TranslationProviderInterface;
use App\DTOs\Translation\TranslationResultData;
use Illuminate\Support\Facades\Http;

final class GeminiTranslationProvider implements TranslationProviderInterface
{
    public function translate(
        string $text,
        string $sourceLanguage,
        string $targetLanguage,
    ): ?TranslationResultData {
        $apiKey = (string) config('services.gemini.key', env('GEMINI_API_KEY', ''));
        if (trim($apiKey) === '') {
            return null;
        }

        $model = (string) config('services.gemini.model', 'gemini-2.5-flash');
        $endpoint = "https://generativelanguage.googleapis.com/v1beta/models/{$model}:generateContent?key={$apiKey}";

        $prompt = sprintf(
            'Translate the following traveler phrase from "%s" to "%s". Return ONLY a valid JSON object with keys "translated_text" and "phonetic". Phrase: %s',
            $sourceLanguage,
            $targetLanguage,
            $text
        );

        try {
            $response = Http::timeout(8)->post($endpoint, [
                'contents' => [
                    ['parts' => [['text' => $prompt]]],
                ],
                'generationConfig' => [
                    'responseMimeType' => 'application/json',
                    'temperature' => 0.1,
                ],
            ]);

            if (! $response->successful()) {
                return null;
            }

            $rawText = (string) data_get($response->json(), 'candidates.0.content.parts.0.text', '');
            $decoded = json_decode($rawText, true);
            if (! is_array($decoded) || empty($decoded['translated_text'])) {
                return null;
            }

            $translated = trim(strip_tags((string) $decoded['translated_text']));
            $phonetic = trim(strip_tags((string) ($decoded['phonetic'] ?? $translated)));

            if ($translated === '') {
                return null;
            }

            return new TranslationResultData(
                sourceText: $text,
                translatedText: mb_substr($translated, 0, 1000),
                phonetic: mb_substr($phonetic, 0, 1000),
                sourceLanguage: strtolower($sourceLanguage),
                targetLanguage: strtolower($targetLanguage),
                provider: 'gemini',
                isOfflineMatch: false,
                disclaimer: TranslationService::DISCLAIMER,
            );
        } catch (\Throwable) {
            return null;
        }
    }
}
