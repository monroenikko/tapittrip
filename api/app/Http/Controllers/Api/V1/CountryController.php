<?php

declare(strict_types=1);

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Resources\Api\V1\CountryResource;
use App\Services\Country\CountryService;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;

final class CountryController extends Controller
{
    public function __construct(
        private readonly CountryService $countryService,
    ) {}

    /**
     * List all countries worldwide with primary currency and flag.
     */
    public function index(Request $request): AnonymousResourceCollection
    {
        $search = $request->query('search');
        $countries = $this->countryService->search(is_string($search) ? $search : null);

        return CountryResource::collection($countries);
    }
}
