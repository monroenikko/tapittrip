<?php

declare(strict_types=1);

use App\Models\Country;
use App\Services\Expenses\CountryCurrencyResolver;
use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        DB::table('countries')
            ->whereIn('currency_code', CountryCurrencyResolver::ZERO_DECIMAL_CURRENCIES)
            ->update(['is_zero_decimal' => true]);

        Cache::forget(Country::CACHE_KEY);
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        DB::table('countries')
            ->whereNotIn('currency_code', ['JPY', 'KRW', 'VND'])
            ->whereIn('currency_code', CountryCurrencyResolver::ZERO_DECIMAL_CURRENCIES)
            ->update(['is_zero_decimal' => false]);

        Cache::forget(Country::CACHE_KEY);
    }
};
