<?php

declare(strict_types=1);

namespace App\Http\Controllers\Api\V1;

use App\DTOs\Lounges\SearchAirportLoungesData;
use App\Http\Controllers\Controller;
use App\Http\Requests\Api\V1\Lounges\SearchAirportLoungesRequest;
use App\Http\Resources\Api\V1\AirportLoungeResource;
use App\Http\Resources\Api\V1\AirportResource;
use App\Services\Lounges\AirportLoungeService;
use App\Support\Http\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

final class AirportLoungeController extends Controller
{
    public function __construct(
        private readonly AirportLoungeService $loungeService,
        private readonly ApiResponse $response,
    ) {}

    /**
     * List and search worldwide airports and their terminals.
     */
    public function airports(Request $request): JsonResponse
    {
        $q = $request->query('q');
        $airports = $this->loungeService->listAirports($q ? (string) $q : null);

        return $this->response->success($airports);
    }

    /**
     * Search and filter lounges for an airport by IATA code.
     */
    public function index(
        string $iata,
        SearchAirportLoungesRequest $request,
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

        $result = $this->loungeService->searchLounges($data);

        return $this->response->success([
            'airport' => new AirportResource($result['airport']),
            'lounges' => AirportLoungeResource::collection($result['lounges']),
        ]);
    }

    /**
     * Get detailed information for an airport lounge.
     */
    public function show(string $lounge): JsonResponse
    {
        $loungeModel = $this->loungeService->getLoungeDetails($lounge);

        return $this->response->success(new AirportLoungeResource($loungeModel));
    }
}
