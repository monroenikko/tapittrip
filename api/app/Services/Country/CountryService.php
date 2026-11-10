<?php

declare(strict_types=1);

namespace App\Services\Country;

use App\Models\Country;
use Illuminate\Database\Eloquent\Collection;

final class CountryService
{
    /**
     * List all countries worldwide with primary currency and flag, with optional search term.
     *
     * @return Collection<int, Country>
     */
    public function search(?string $search = null): Collection
    {
        $query = Country::query()->orderBy('name');

        if ($search !== null && trim($search) !== '') {
            $term = strtolower(trim($search));
            $query->where(function ($q) use ($term, $search): void {
                $q->whereRaw('LOWER(name) LIKE ?', ["%{$term}%"])
                    ->orWhere('code', strtoupper($search))
                    ->orWhere('currency_code', strtoupper($search));
            });
        }

        return $query->get();
    }
}
