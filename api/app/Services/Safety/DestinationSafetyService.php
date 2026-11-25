<?php

declare(strict_types=1);

namespace App\Services\Safety;

use App\DTOs\Safety\DestinationSafetyProfileData;
use App\Models\Country;
use App\Models\Trip;

final class DestinationSafetyService
{
    public const DISCLAIMER = 'Emergency numbers and official government/airline portals are provided for reference only and do not constitute definitive visa, immigration, or medical advice. Verify entry rules directly with official authorities before travel.';

    /**
     * List all curated destination safety profiles, optionally filtered by query.
     *
     * @return array<int, DestinationSafetyProfileData>
     */
    public function listCuratedProfiles(?string $query = null): array
    {
        $profiles = array_map(
            fn (array $row): DestinationSafetyProfileData => $this->hydrateProfile($row),
            array_values($this->curatedDirectory())
        );

        if ($query === null || trim($query) === '') {
            return $profiles;
        }

        $term = strtolower(trim($query));

        return array_values(array_filter(
            $profiles,
            static fn (DestinationSafetyProfileData $p): bool => str_contains(strtolower($p->countryName), $term)
                || str_contains(strtolower($p->countryCode), $term)
        ));
    }

    /**
     * Resolve a safety profile for a specific trip (using optional country override or trip destination_country).
     */
    public function getForTrip(Trip $trip, ?string $countryOverride = null): DestinationSafetyProfileData
    {
        $target = $countryOverride !== null && trim($countryOverride) !== ''
            ? trim($countryOverride)
            : (string) ($trip->destination_country ?? 'PH');

        if ($target === '') {
            $target = 'PH';
        }

        return $this->getByCountry($target);
    }

    /**
     * Resolve a safety profile by ISO-2 country code or country name.
     * Never fabricates emergency numbers for uncurated countries.
     */
    public function getByCountry(string $countryIdentifier): DestinationSafetyProfileData
    {
        $normalized = trim($countryIdentifier);
        $upper = strtoupper($normalized);
        $lower = strtolower($normalized);
        $directory = $this->curatedDirectory();

        if (isset($directory[$upper])) {
            return $this->hydrateProfile($directory[$upper]);
        }

        foreach ($directory as $code => $entry) {
            if (strtolower($entry['country_name']) === $lower) {
                return $this->hydrateProfile($entry);
            }
            foreach ($entry['aliases'] as $alias) {
                if (strtolower($alias) === $lower) {
                    return $this->hydrateProfile($entry);
                }
            }
        }

        // Check database Country table for known ISO-2 code or name match
        $dbCountry = Country::query()
            ->where('code', $upper)
            ->orWhereRaw('LOWER(name) = ?', [$lower])
            ->first();

        if ($dbCountry !== null && isset($directory[strtoupper($dbCountry->code)])) {
            return $this->hydrateProfile($directory[strtoupper($dbCountry->code)]);
        }

        $fallbackCode = $dbCountry !== null
            ? strtoupper($dbCountry->code)
            : (strlen($upper) === 2 ? $upper : 'UN');
        $fallbackName = $dbCountry !== null
            ? $dbCountry->name
            : ($normalized !== '' ? $normalized : 'Unknown Destination');
        $fallbackFlag = $dbCountry !== null && $dbCountry->flag_emoji !== null
            ? $dbCountry->flag_emoji
            : '🌍';

        return new DestinationSafetyProfileData(
            countryCode: $fallbackCode,
            countryName: $fallbackName,
            flagEmoji: $fallbackFlag,
            isCurated: false,
            emergencyNumbers: [
                'police' => null,
                'ambulance' => null,
                'fire' => null,
                'general_emergency' => null,
                'tourist_hotline' => null,
            ],
            officialResources: [],
            emergencyPhrases: [
                [
                    'category' => 'medical',
                    'english' => 'I need a doctor / hospital.',
                    'local_text' => 'I need a doctor / hospital.',
                    'phonetic' => 'I need a doctor / hospital.',
                ],
                [
                    'category' => 'emergency',
                    'english' => 'Please call the police.',
                    'local_text' => 'Please call the police.',
                    'phonetic' => 'Please call the police.',
                ],
            ],
            lastVerifiedAt: '2026-11-01',
            disclaimer: self::DISCLAIMER,
        );
    }

    /**
     * @param  array<string, mixed>  $row
     */
    private function hydrateProfile(array $row): DestinationSafetyProfileData
    {
        return new DestinationSafetyProfileData(
            countryCode: (string) $row['country_code'],
            countryName: (string) $row['country_name'],
            flagEmoji: (string) $row['flag_emoji'],
            isCurated: true,
            emergencyNumbers: $row['emergency_numbers'],
            officialResources: $row['official_resources'],
            emergencyPhrases: $row['emergency_phrases'],
            lastVerifiedAt: (string) $row['last_verified_at'],
            disclaimer: self::DISCLAIMER,
        );
    }

    /**
     * @return array<string, array<string, mixed>>
     */
    private function curatedDirectory(): array
    {
        return [
            'JP' => [
                'country_code' => 'JP',
                'country_name' => 'Japan',
                'flag_emoji' => '🇯🇵',
                'aliases' => ['nippon', 'tokyo', 'osaka', 'kyoto'],
                'last_verified_at' => '2026-11-01',
                'emergency_numbers' => [
                    'police' => '110',
                    'ambulance' => '119',
                    'fire' => '119',
                    'general_emergency' => '110 / 119',
                    'tourist_hotline' => '050-3816-2787 (JNTO 24h)',
                ],
                'official_resources' => [
                    [
                        'title' => 'Visit Japan Web (Immigration & Customs QR)',
                        'publisher' => 'Digital Agency, Government of Japan',
                        'category' => 'entry_requirements',
                        'url' => 'https://services.digital.go.jp/en/visit-japan-web/',
                        'last_verified_at' => '2026-11-01',
                    ],
                    [
                        'title' => 'JNTO Safety Tips for Travelers in Japan',
                        'publisher' => 'Japan National Tourism Organization',
                        'category' => 'safety_advisory',
                        'url' => 'https://www.jnto.go.jp/safety-tips/eng/index.html',
                        'last_verified_at' => '2026-11-01',
                    ],
                ],
                'emergency_phrases' => [
                    [
                        'category' => 'emergency',
                        'english' => 'Help! Please call an ambulance.',
                        'local_text' => '助けて！救急車を呼んでください。',
                        'phonetic' => 'Tasukete! Kyuukyuusha o yonde kudasai.',
                    ],
                    [
                        'category' => 'emergency',
                        'english' => 'Please call the police.',
                        'local_text' => '警察を呼んでください。',
                        'phonetic' => 'Keisatsu o yonde kudasai.',
                    ],
                    [
                        'category' => 'medical',
                        'english' => 'Where is the nearest hospital?',
                        'local_text' => '一番近い病院はどこですか？',
                        'phonetic' => 'Ichiban chikai byouin wa doko desu ka?',
                    ],
                    [
                        'category' => 'consular',
                        'english' => 'I lost my passport.',
                        'local_text' => 'パスポートをなくしました。',
                        'phonetic' => 'Pasupooto o nakushimashita.',
                    ],
                ],
            ],
            'PH' => [
                'country_code' => 'PH',
                'country_name' => 'Philippines',
                'flag_emoji' => '🇵🇭',
                'aliases' => ['the philippines', 'manila', 'cebu', 'palawan'],
                'last_verified_at' => '2026-11-01',
                'emergency_numbers' => [
                    'police' => '911',
                    'ambulance' => '911',
                    'fire' => '911',
                    'general_emergency' => '911',
                    'tourist_hotline' => '+63 2 1383 (DOT Tourist Assistance)',
                ],
                'official_resources' => [
                    [
                        'title' => 'Philippine eTravel Portal',
                        'publisher' => 'Republic of the Philippines',
                        'category' => 'entry_requirements',
                        'url' => 'https://etravel.gov.ph/',
                        'last_verified_at' => '2026-11-01',
                    ],
                    [
                        'title' => 'Bureau of Immigration Advisory',
                        'publisher' => 'Bureau of Immigration Philippines',
                        'category' => 'immigration',
                        'url' => 'https://immigration.gov.ph/',
                        'last_verified_at' => '2026-11-01',
                    ],
                ],
                'emergency_phrases' => [
                    [
                        'category' => 'emergency',
                        'english' => 'Help! We need an ambulance.',
                        'local_text' => 'Tulong! Kailangan namin ng ambulansya.',
                        'phonetic' => 'Too-long! Kah-ee-lahng-ahn nah-min nahng ahm-boo-lahn-syah.',
                    ],
                    [
                        'category' => 'emergency',
                        'english' => 'Please call the police.',
                        'local_text' => 'Pakitawag po ang pulis.',
                        'phonetic' => 'Pah-kee-tah-wahg poh ahng poo-lees.',
                    ],
                    [
                        'category' => 'medical',
                        'english' => 'Where is the nearest hospital?',
                        'local_text' => 'Saan po ang pinakamalapit na ospital?',
                        'phonetic' => 'Sah-ahn poh ahng pee-nah-kah-mah-lah-peet nah os-pee-tahl?',
                    ],
                ],
            ],
            'KR' => [
                'country_code' => 'KR',
                'country_name' => 'South Korea',
                'flag_emoji' => '🇰🇷',
                'aliases' => ['republic of korea', 'korea', 'seoul', 'busan'],
                'last_verified_at' => '2026-11-01',
                'emergency_numbers' => [
                    'police' => '112',
                    'ambulance' => '119',
                    'fire' => '119',
                    'general_emergency' => '112 / 119',
                    'tourist_hotline' => '1330 (KTO Travel Helpline)',
                ],
                'official_resources' => [
                    [
                        'title' => 'K-ETA & Korea Entry Guidance',
                        'publisher' => 'Ministry of Justice, Republic of Korea',
                        'category' => 'entry_requirements',
                        'url' => 'https://www.k-eta.go.kr/',
                        'last_verified_at' => '2026-11-01',
                    ],
                    [
                        'title' => 'Q-CODE Quarantine Information System',
                        'publisher' => 'KDCA Republic of Korea',
                        'category' => 'health_declaration',
                        'url' => 'https://qcode.kdca.go.kr/',
                        'last_verified_at' => '2026-11-01',
                    ],
                ],
                'emergency_phrases' => [
                    [
                        'category' => 'emergency',
                        'english' => 'Help! Please call 119.',
                        'local_text' => '도와주세요! 119를 불러 주세요.',
                        'phonetic' => 'Dowajuseyo! Il-il-gu-reul bulleo juseyo.',
                    ],
                    [
                        'category' => 'medical',
                        'english' => 'Where is the nearest hospital?',
                        'local_text' => '가장 가까운 병원이 어디예요?',
                        'phonetic' => 'Gajang gakkaun byeongwon-i eodiyeyo?',
                    ],
                    [
                        'category' => 'consular',
                        'english' => 'I lost my passport.',
                        'local_text' => '여권을 잃어버렸어요.',
                        'phonetic' => 'Yeogwon-eul ilheobeoryeosseoyo.',
                    ],
                ],
            ],
            'SG' => [
                'country_code' => 'SG',
                'country_name' => 'Singapore',
                'flag_emoji' => '🇸🇬',
                'aliases' => ['republic of singapore'],
                'last_verified_at' => '2026-11-01',
                'emergency_numbers' => [
                    'police' => '999',
                    'ambulance' => '995',
                    'fire' => '995',
                    'general_emergency' => '999 / 995',
                    'tourist_hotline' => '1800-736-2000 (STB Tourist Line)',
                ],
                'official_resources' => [
                    [
                        'title' => 'SG Arrival Card (SGAC)',
                        'publisher' => 'Immigration & Checkpoints Authority (ICA)',
                        'category' => 'entry_requirements',
                        'url' => 'https://eservices.ica.gov.sg/sgarrivalcard/',
                        'last_verified_at' => '2026-11-01',
                    ],
                ],
                'emergency_phrases' => [
                    [
                        'category' => 'emergency',
                        'english' => 'Please call an ambulance (995).',
                        'local_text' => 'Please call an ambulance (995).',
                        'phonetic' => 'Please call an ambulance (995).',
                    ],
                    [
                        'category' => 'medical',
                        'english' => 'Where is the nearest 24-hour clinic?',
                        'local_text' => 'Where is the nearest 24-hour clinic?',
                        'phonetic' => 'Where is the nearest 24-hour clinic?',
                    ],
                ],
            ],
            'TH' => [
                'country_code' => 'TH',
                'country_name' => 'Thailand',
                'flag_emoji' => '🇹🇭',
                'aliases' => ['bangkok', 'phuket', 'chiang mai'],
                'last_verified_at' => '2026-11-01',
                'emergency_numbers' => [
                    'police' => '191',
                    'ambulance' => '1669',
                    'fire' => '199',
                    'general_emergency' => '191 / 1669',
                    'tourist_hotline' => '1155 (Tourist Police)',
                ],
                'official_resources' => [
                    [
                        'title' => 'Thai Official e-Visa Portal',
                        'publisher' => 'Ministry of Foreign Affairs, Kingdom of Thailand',
                        'category' => 'entry_requirements',
                        'url' => 'https://www.thaievisa.go.th/',
                        'last_verified_at' => '2026-11-01',
                    ],
                ],
                'emergency_phrases' => [
                    [
                        'category' => 'emergency',
                        'english' => 'Help! Please call an ambulance.',
                        'local_text' => 'ช่วยด้วย! กรุณาเรียกรถพยาบาล',
                        'phonetic' => 'Chuay duay! Karuna riak rot phayaban.',
                    ],
                    [
                        'category' => 'medical',
                        'english' => 'I need to go to the hospital.',
                        'local_text' => 'ฉันต้องไปโรงพยาบาล',
                        'phonetic' => 'Chan tong pai rong phayaban.',
                    ],
                ],
            ],
            'US' => [
                'country_code' => 'US',
                'country_name' => 'United States',
                'flag_emoji' => '🇺🇸',
                'aliases' => ['usa', 'united states of america'],
                'last_verified_at' => '2026-11-01',
                'emergency_numbers' => [
                    'police' => '911',
                    'ambulance' => '911',
                    'fire' => '911',
                    'general_emergency' => '911',
                    'tourist_hotline' => null,
                ],
                'official_resources' => [
                    [
                        'title' => 'Official ESTA Application Portal',
                        'publisher' => 'U.S. Customs and Border Protection',
                        'category' => 'entry_requirements',
                        'url' => 'https://esta.cbp.dhs.gov/',
                        'last_verified_at' => '2026-11-01',
                    ],
                ],
                'emergency_phrases' => [
                    [
                        'category' => 'emergency',
                        'english' => 'Please call 911 immediately.',
                        'local_text' => 'Please call 911 immediately.',
                        'phonetic' => 'Please call 911 immediately.',
                    ],
                ],
            ],
            'GB' => [
                'country_code' => 'GB',
                'country_name' => 'United Kingdom',
                'flag_emoji' => '🇬🇧',
                'aliases' => ['uk', 'great britain', 'england', 'london'],
                'last_verified_at' => '2026-11-01',
                'emergency_numbers' => [
                    'police' => '999',
                    'ambulance' => '999',
                    'fire' => '999',
                    'general_emergency' => '999 / 112',
                    'tourist_hotline' => '111 (NHS Non-Emergency Medical)',
                ],
                'official_resources' => [
                    [
                        'title' => 'UK Electronic Travel Authorisation (ETA)',
                        'publisher' => 'GOV.UK',
                        'category' => 'entry_requirements',
                        'url' => 'https://www.gov.uk/guidance/apply-for-an-electronic-travel-authorisation-eta',
                        'last_verified_at' => '2026-11-01',
                    ],
                ],
                'emergency_phrases' => [
                    [
                        'category' => 'emergency',
                        'english' => 'Please call 999 for an ambulance.',
                        'local_text' => 'Please call 999 for an ambulance.',
                        'phonetic' => 'Please call 999 for an ambulance.',
                    ],
                ],
            ],
            'FR' => [
                'country_code' => 'FR',
                'country_name' => 'France',
                'flag_emoji' => '🇫🇷',
                'aliases' => ['paris'],
                'last_verified_at' => '2026-11-01',
                'emergency_numbers' => [
                    'police' => '17',
                    'ambulance' => '15',
                    'fire' => '18',
                    'general_emergency' => '112',
                    'tourist_hotline' => null,
                ],
                'official_resources' => [
                    [
                        'title' => 'France-Visas Official Portal',
                        'publisher' => 'French Government',
                        'category' => 'entry_requirements',
                        'url' => 'https://france-visas.gouv.fr/',
                        'last_verified_at' => '2026-11-01',
                    ],
                ],
                'emergency_phrases' => [
                    [
                        'category' => 'emergency',
                        'english' => 'Help! Call an ambulance!',
                        'local_text' => 'Au secours ! Appelez une ambulance !',
                        'phonetic' => 'Oh suh-koor! Ah-play oon ahm-boo-lahns!',
                    ],
                    [
                        'category' => 'medical',
                        'english' => 'Where is the nearest pharmacy?',
                        'local_text' => 'Où est la pharmacie la plus proche ?',
                        'phonetic' => 'Oo eh lah far-mah-see lah ploo prosh?',
                    ],
                ],
            ],
            'AU' => [
                'country_code' => 'AU',
                'country_name' => 'Australia',
                'flag_emoji' => '🇦🇺',
                'aliases' => ['sydney', 'melbourne'],
                'last_verified_at' => '2026-11-01',
                'emergency_numbers' => [
                    'police' => '000',
                    'ambulance' => '000',
                    'fire' => '000',
                    'general_emergency' => '000 / 112',
                    'tourist_hotline' => '131 444 (Police Non-Emergency)',
                ],
                'official_resources' => [
                    [
                        'title' => 'Australian Department of Home Affairs Immigration',
                        'publisher' => 'Australian Government',
                        'category' => 'entry_requirements',
                        'url' => 'https://immi.homeaffairs.gov.au/',
                        'last_verified_at' => '2026-11-01',
                    ],
                ],
                'emergency_phrases' => [
                    [
                        'category' => 'emergency',
                        'english' => 'Please dial 000 for emergency assistance.',
                        'local_text' => 'Please dial 000 for emergency assistance.',
                        'phonetic' => 'Please dial 000 for emergency assistance.',
                    ],
                ],
            ],
        ];
    }
}
