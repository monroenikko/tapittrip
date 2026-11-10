<?php

declare(strict_types=1);

namespace Database\Seeders;

use App\Models\Country;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\File;

final class CountrySeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        $path = database_path('data/countries.json');
        if (! File::exists($path)) {
            return;
        }

        /** @var list<array{code: string, name: string, currency_code: string, flag_emoji: string, is_zero_decimal: bool, aliases: list<string>}> $countries */
        $countries = json_decode(File::get($path), true, 512, JSON_THROW_ON_ERROR);

        foreach ($countries as $country) {
            Country::query()->updateOrCreate(
                ['code' => $country['code']],
                [
                    'name' => $country['name'],
                    'currency_code' => $country['currency_code'],
                    'flag_emoji' => $country['flag_emoji'],
                    'is_zero_decimal' => $country['is_zero_decimal'] ?? false,
                    'aliases' => $country['aliases'] ?? [],
                ],
            );
        }
    }
}

