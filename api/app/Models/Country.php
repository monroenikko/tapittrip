<?php

declare(strict_types=1);

namespace App\Models;

use Database\Factories\CountryFactory;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Facades\Cache;

#[Fillable([
    'code',
    'name',
    'currency_code',
    'flag_emoji',
    'is_zero_decimal',
    'aliases',
])]
final class Country extends Model
{
    /** @use HasFactory<CountryFactory> */
    use HasFactory, HasUuids;

    public const CACHE_KEY = 'countries_lookup_map';

    protected static function booted(): void
    {
        self::saved(fn () => Cache::forget(self::CACHE_KEY));
        self::deleted(fn () => Cache::forget(self::CACHE_KEY));
    }

    /**
     * Create a new factory instance for the model.
     */
    protected static function newFactory(): CountryFactory
    {
        return CountryFactory::new();
    }

    /**
     * Get the attributes that should be cast.
     *
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'is_zero_decimal' => 'boolean',
            'aliases' => 'array',
        ];
    }
}
