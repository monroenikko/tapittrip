<?php

declare(strict_types=1);

namespace App\Http\Controllers\Api\V1;

use App\Application\Lounges\Data\SearchAirportLoungesData;
use App\Application\Lounges\Services\AirportLoungeDirectoryService;
use App\Application\Lounges\Services\GetAirportLoungeDetailsService;
use App\Application\Lounges\Services\SearchAirportLoungesService;
use App\Http\Controllers\Controller;
use App\Http\Requests\Api\V1\Lounges\SearchAirportLoungesRequest;
use App\Http\Resources\Api\V1\AirportLoungeResource;
use App\Http\Resources\Api\V1\AirportResource;
use App\Support\Http\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

final class AirportLoungeController extends Controller
{
    /**
     * List and search worldwide airports and their terminals.
     */
    public function airports(
        Request $request,
        ApiResponse $response,
    ): JsonResponse {
        $q = $request->query('q');
        $airports = AirportLoungeDirectoryService::listGlobalAirports($q ? (string) $q : null);

        return $response->success($airports);
    }

    /**
     * Search and filter lounges for an airport by IATA code.
     */
    public function index(
        string $iata,
        SearchAirportLoungesRequest $request,
        SearchAirportLoungesService $service,
        ApiResponse $response,
    ): JsonResponse {
        $validated = $request->validated();
        $data = new SearchAirportLoungesData(
            iataCode: $iata,
            terminalCode: isset($validated['terminal']) ? (string) $validated['terminal'] : null,
            isAirside: isset($validated['is_airside']) ? (bool) $validated['is_airside'] : null,
            accessMethods: isset($validated['access_methods']) && is_array($validated['access_methods'])
                ? $validated['access_methods']
                : null,
        );

        $result = $service->execute($data);

        return $response->success([
            'airport' => new AirportResource($result['airport']),
            'lounges' => AirportLoungeResource::collection($result['lounges']),
        ]);
    }

    /**
     * Get detailed information for an airport lounge.
     */
    public function show(
        string $lounge,
        GetAirportLoungeDetailsService $service,
        ApiResponse $response,
    ): JsonResponse {
        $loungeModel = $service->execute($lounge);

        return $response->success(new AirportLoungeResource($loungeModel));
    }
}
