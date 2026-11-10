<?php

declare(strict_types=1);

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Resources\Api\V1\CountryResource;
use App\Models\Country;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;

final class CountryController extends Controller
{
    /**
     * List all countries worldwide with primary currency and flag.
     */
    public function index(Request $request): AnonymousResourceCollection
    {
        $query = Country::query()->orderBy('name');

        if ($search = $request->query('search')) {
            $term = strtolower(trim((string) $search));
            $query->where(function ($q) use ($term, $search): void {
                $q->whereRaw('LOWER(name) LIKE ?', ["%{$term}%"])
                    ->orWhere('code', strtoupper((string) $search))
                    ->orWhere('currency_code', strtoupper((string) $search));
            });
        }

        return CountryResource::collection($query->get());
    }
}
