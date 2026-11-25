<?php

declare(strict_types=1);

namespace App\Services\Translation;

use App\Contracts\TranslationProviderInterface;
use App\DTOs\Translation\PhrasebookBundleData;
use App\DTOs\Translation\TranslationResultData;
use App\Models\Trip;

final class TranslationService
{
    public const DISCLAIMER = 'Phrasebook entries and machine translations are provided for travel assistance only. For medical allergies or legal declarations, verify accuracy with a qualified professional.';

    public const CATEGORIES = [
        'essentials',
        'dining',
        'transit',
        'hotel',
        'shopping',
        'emergency',
    ];

    public function __construct(
        private readonly TranslationProviderInterface $translationProvider,
    ) {}

    /**
     * List all supported destination phrasebook languages.
     *
     * @return array<int, array<string, mixed>>
     */
    public function listLanguages(): array
    {
        $result = [];
        foreach ($this->phrasebooks() as $code => $pack) {
            $result[] = [
                'language_code' => $code,
                'language_name' => $pack['language_name'],
                'native_name' => $pack['native_name'],
                'flag_emoji' => $pack['flag_emoji'],
                'country_code' => $pack['country_code'],
                'phrase_count' => count($pack['phrases']),
            ];
        }

        return $result;
    }

    /**
     * Resolve a phrasebook for a trip's destination country (with optional language override and category filter).
     */
    public function getForTrip(
        Trip $trip,
        ?string $languageOverride = null,
        ?string $category = null,
        ?string $query = null,
    ): PhrasebookBundleData {
        $target = ($languageOverride !== null && trim($languageOverride) !== '')
            ? trim($languageOverride)
            : (string) ($trip->destination_country ?? 'ja');

        return $this->getPhrasebook($target, $category, $query);
    }

    /**
     * Resolve a phrasebook by language code (e.g. 'ja') or country code/name (e.g. 'JP', 'Japan').
     */
    public function getPhrasebook(
        string $languageOrCountry,
        ?string $category = null,
        ?string $query = null,
    ): PhrasebookBundleData {
        $langCode = $this->resolveLanguageCode($languageOrCountry);
        $packs = $this->phrasebooks();
        $pack = $packs[$langCode] ?? $packs['ja'];

        $phrases = $pack['phrases'];

        if ($category !== null && trim($category) !== '' && strtolower(trim($category)) !== 'all') {
            $cat = strtolower(trim($category));
            $phrases = array_values(array_filter(
                $phrases,
                static fn (array $p): bool => $p['category'] === $cat
            ));
        }

        if ($query !== null && trim($query) !== '') {
            $q = strtolower(trim($query));
            $phrases = array_values(array_filter(
                $phrases,
                static fn (array $p): bool => str_contains(strtolower($p['english']), $q)
                    || str_contains(strtolower($p['local_text']), $q)
                    || str_contains(strtolower($p['phonetic']), $q)
            ));
        }

        return new PhrasebookBundleData(
            languageCode: $pack['language_code'],
            languageName: $pack['language_name'],
            nativeName: $pack['native_name'],
            flagEmoji: $pack['flag_emoji'],
            countryCode: $pack['country_code'],
            categories: self::CATEGORIES,
            phrases: $phrases,
            disclaimer: self::DISCLAIMER,
        );
    }

    /**
     * Translate text using offline phrasebook matching first, then cloud provider when consented.
     */
    public function translate(
        string $text,
        string $sourceLanguage,
        string $targetLanguage,
        bool $consentCloud,
    ): ?TranslationResultData {
        $sanitized = trim((string) preg_replace('/[\x00-\x1F\x7F]/u', ' ', strip_tags($text)));
        $targetCode = $this->resolveLanguageCode($targetLanguage);
        $sourceCode = strtolower(trim($sourceLanguage)) ?: 'en';

        // 1. Check exact / case-insensitive match in curated offline phrasebook first
        $packs = $this->phrasebooks();
        if (isset($packs[$targetCode])) {
            $needle = rtrim(strtolower($sanitized), '.!?');
            foreach ($packs[$targetCode]['phrases'] as $phrase) {
                $candidate = rtrim(strtolower($phrase['english']), '.!?');
                if ($candidate === $needle || strtolower($phrase['english']) === strtolower($sanitized)) {
                    return new TranslationResultData(
                        sourceText: $sanitized,
                        translatedText: $phrase['local_text'],
                        phonetic: $phrase['phonetic'],
                        sourceLanguage: $sourceCode,
                        targetLanguage: $targetCode,
                        provider: 'offline_phrasebook',
                        isOfflineMatch: true,
                        disclaimer: self::DISCLAIMER,
                    );
                }
            }
        }

        // 2. If not found in offline phrasebook, require explicit cloud consent
        if (! $consentCloud) {
            return null;
        }

        return $this->translationProvider->translate($sanitized, $sourceCode, $targetCode);
    }

    public function resolveLanguageCode(string $input): string
    {
        $norm = strtolower(trim($input));
        $packs = $this->phrasebooks();

        if (isset($packs[$norm])) {
            return $norm;
        }

        foreach ($packs as $code => $pack) {
            if (strtolower($pack['country_code']) === $norm
                || strtolower($pack['language_name']) === $norm
                || in_array($norm, $pack['aliases'], true)) {
                return $code;
            }
        }

        return 'ja';
    }

    /**
     * @return array<string, array<string, mixed>>
     */
    private function phrasebooks(): array
    {
        return [
            'ja' => [
                'language_code' => 'ja',
                'language_name' => 'Japanese',
                'native_name' => '日本語',
                'flag_emoji' => '🇯🇵',
                'country_code' => 'JP',
                'aliases' => ['japan', 'jp', 'tokyo', 'osaka', 'kyoto'],
                'phrases' => [
                    [
                        'id' => 'ja-ess-1',
                        'category' => 'essentials',
                        'english' => 'Excuse me / Thank you.',
                        'local_text' => 'すみません / ありがとうございます。',
                        'phonetic' => 'Sumimasen / Arigatou gozaimasu.',
                        'context_note' => 'Polite everyday greeting and attention-getter.',
                    ],
                    [
                        'id' => 'ja-ess-2',
                        'category' => 'essentials',
                        'english' => 'Do you speak English?',
                        'local_text' => '英語を話せますか？',
                        'phonetic' => 'Eigo o hanasemasu ka?',
                        'context_note' => null,
                    ],
                    [
                        'id' => 'ja-din-1',
                        'category' => 'dining',
                        'english' => 'I have a food allergy.',
                        'local_text' => '食物アレルギーがあります。',
                        'phonetic' => 'Shokumotsu arerugii ga arimasu.',
                        'context_note' => 'Show to restaurant staff before ordering.',
                    ],
                    [
                        'id' => 'ja-din-2',
                        'category' => 'dining',
                        'english' => 'Check, please.',
                        'local_text' => 'お会計をお願いします。',
                        'phonetic' => 'O-kaikei o onegaishimasu.',
                        'context_note' => null,
                    ],
                    [
                        'id' => 'ja-trn-1',
                        'category' => 'transit',
                        'english' => 'Does this train go to the airport?',
                        'local_text' => 'この電車は空港に行きますか？',
                        'phonetic' => 'Kono densha wa kuukou ni ikimasu ka?',
                        'context_note' => null,
                    ],
                    [
                        'id' => 'ja-htl-1',
                        'category' => 'hotel',
                        'english' => 'Can you store my luggage before check-in?',
                        'local_text' => 'チェックイン前に荷物を預かってもらえますか？',
                        'phonetic' => 'Chekku-in mae ni nimotsu o azukatte moraemasu ka?',
                        'context_note' => null,
                    ],
                    [
                        'id' => 'ja-shp-1',
                        'category' => 'shopping',
                        'english' => 'Is this tax-free?',
                        'local_text' => 'これは免税になりますか？',
                        'phonetic' => 'Kore wa menzei ni narimasu ka?',
                        'context_note' => null,
                    ],
                    [
                        'id' => 'ja-emg-1',
                        'category' => 'emergency',
                        'english' => 'Help! Please call an ambulance.',
                        'local_text' => '助けて！救急車を呼んでください。',
                        'phonetic' => 'Tasukete! Kyuukyuusha o yonde kudasai.',
                        'context_note' => 'Emergency medical number in Japan is 119.',
                    ],
                ],
            ],
            'tl' => [
                'language_code' => 'tl',
                'language_name' => 'Filipino (Tagalog)',
                'native_name' => 'Wikang Filipino',
                'flag_emoji' => '🇵🇭',
                'country_code' => 'PH',
                'aliases' => ['philippines', 'ph', 'tagalog', 'filipino', 'manila', 'cebu'],
                'phrases' => [
                    [
                        'id' => 'tl-ess-1',
                        'category' => 'essentials',
                        'english' => 'Thank you very much.',
                        'local_text' => 'Maraming salamat po.',
                        'phonetic' => 'Mah-rah-ming sah-lah-maht poh.',
                        'context_note' => '"Po" adds polite respect.',
                    ],
                    [
                        'id' => 'tl-din-1',
                        'category' => 'dining',
                        'english' => 'I have a food allergy.',
                        'local_text' => 'May allergy po ako sa pagkain.',
                        'phonetic' => 'May ah-ler-jee poh ah-koh sah pahg-kah-in.',
                        'context_note' => null,
                    ],
                    [
                        'id' => 'tl-trn-1',
                        'category' => 'transit',
                        'english' => 'Please drop me off at the terminal.',
                        'local_text' => 'Pakibaba na lang po ako sa terminal.',
                        'phonetic' => 'Pah-kee-bah-bah nah lahng poh ah-koh sah ter-mee-nahl.',
                        'context_note' => null,
                    ],
                    [
                        'id' => 'tl-htl-1',
                        'category' => 'hotel',
                        'english' => 'I have a reservation.',
                        'local_text' => 'May booking po ako.',
                        'phonetic' => 'May boo-king poh ah-koh.',
                        'context_note' => null,
                    ],
                    [
                        'id' => 'tl-shp-1',
                        'category' => 'shopping',
                        'english' => 'How much is this?',
                        'local_text' => 'Magkano po ito?',
                        'phonetic' => 'Mahg-kah-noh poh ee-toh?',
                        'context_note' => null,
                    ],
                    [
                        'id' => 'tl-emg-1',
                        'category' => 'emergency',
                        'english' => 'Help! We need an ambulance.',
                        'local_text' => 'Tulong! Kailangan namin ng ambulansya.',
                        'phonetic' => 'Too-long! Kah-ee-lahng-ahn nah-min nahng ahm-boo-lahn-syah.',
                        'context_note' => 'National emergency number in the Philippines is 911.',
                    ],
                ],
            ],
            'ko' => [
                'language_code' => 'ko',
                'language_name' => 'Korean',
                'native_name' => '한국어',
                'flag_emoji' => '🇰🇷',
                'country_code' => 'KR',
                'aliases' => ['south korea', 'korea', 'kr', 'seoul', 'busan'],
                'phrases' => [
                    [
                        'id' => 'ko-ess-1',
                        'category' => 'essentials',
                        'english' => 'Hello / Thank you.',
                        'local_text' => '안녕하세요 / 감사합니다.',
                        'phonetic' => 'Annyeonghaseyo / Kamsahamnida.',
                        'context_note' => null,
                    ],
                    [
                        'id' => 'ko-din-1',
                        'category' => 'dining',
                        'english' => 'Not spicy, please.',
                        'local_text' => '안 맵게 해 주세요.',
                        'phonetic' => 'An maepge hae juseyo.',
                        'context_note' => null,
                    ],
                    [
                        'id' => 'ko-trn-1',
                        'category' => 'transit',
                        'english' => 'Where is the subway station?',
                        'local_text' => '지하철역이 어디예요?',
                        'phonetic' => 'Jihacheol-yeog-i eodiyeyo?',
                        'context_note' => null,
                    ],
                    [
                        'id' => 'ko-htl-1',
                        'category' => 'hotel',
                        'english' => 'Please take me to this hotel address.',
                        'local_text' => '이 호텔 주소로 가 주세요.',
                        'phonetic' => 'I hotel jusoro ga juseyo.',
                        'context_note' => null,
                    ],
                    [
                        'id' => 'ko-shp-1',
                        'category' => 'shopping',
                        'english' => 'How much is this?',
                        'local_text' => '이거 얼마예요?',
                        'phonetic' => 'Igeo eolmayeyo?',
                        'context_note' => null,
                    ],
                    [
                        'id' => 'ko-emg-1',
                        'category' => 'emergency',
                        'english' => 'Help! Please call 119.',
                        'local_text' => '도와주세요! 119를 불러 주세요.',
                        'phonetic' => 'Dowajuseyo! Il-il-gu-reul bulleo juseyo.',
                        'context_note' => 'Medical/fire emergency in South Korea is 119.',
                    ],
                ],
            ],
            'th' => [
                'language_code' => 'th',
                'language_name' => 'Thai',
                'native_name' => 'ภาษาไทย',
                'flag_emoji' => '🇹🇭',
                'country_code' => 'TH',
                'aliases' => ['thailand', 'th', 'bangkok', 'phuket', 'chiang mai'],
                'phrases' => [
                    [
                        'id' => 'th-ess-1',
                        'category' => 'essentials',
                        'english' => 'Hello / Thank you.',
                        'local_text' => 'สวัสดี / ขอบคุณ',
                        'phonetic' => 'Sawatdee / Khop khun (khrap/kha).',
                        'context_note' => null,
                    ],
                    [
                        'id' => 'th-din-1',
                        'category' => 'dining',
                        'english' => 'Not spicy, please.',
                        'local_text' => 'ไม่เผ็ดนะครับ/คะ',
                        'phonetic' => 'Mai phet na khrap/kha.',
                        'context_note' => null,
                    ],
                    [
                        'id' => 'th-emg-1',
                        'category' => 'emergency',
                        'english' => 'Help! Please call an ambulance.',
                        'local_text' => 'ช่วยด้วย! กรุณาเรียกรถพยาบาล',
                        'phonetic' => 'Chuay duay! Karuna riak rot phayaban.',
                        'context_note' => 'Thailand medical emergency hotline is 1669.',
                    ],
                ],
            ],
            'fr' => [
                'language_code' => 'fr',
                'language_name' => 'French',
                'native_name' => 'Français',
                'flag_emoji' => '🇫🇷',
                'country_code' => 'FR',
                'aliases' => ['france', 'fr', 'paris'],
                'phrases' => [
                    [
                        'id' => 'fr-ess-1',
                        'category' => 'essentials',
                        'english' => 'Hello, excuse me.',
                        'local_text' => 'Bonjour, excusez-moi.',
                        'phonetic' => 'Bon-zhoor, ex-koo-zay mwah.',
                        'context_note' => null,
                    ],
                    [
                        'id' => 'fr-din-1',
                        'category' => 'dining',
                        'english' => 'I have a severe food allergy.',
                        'local_text' => 'J’ai une allergie alimentaire grave.',
                        'phonetic' => 'Zhay oon ah-lair-zhee ah-lee-mahn-tair grahv.',
                        'context_note' => null,
                    ],
                    [
                        'id' => 'fr-emg-1',
                        'category' => 'emergency',
                        'english' => 'Help! Call an ambulance!',
                        'local_text' => 'Au secours ! Appelez une ambulance !',
                        'phonetic' => 'Oh suh-koor! Ah-play oon ahm-boo-lahns!',
                        'context_note' => 'European emergency number is 112 (SAMU medical is 15).',
                    ],
                ],
            ],
        ];
    }
}
