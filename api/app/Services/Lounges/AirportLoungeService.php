<?php

declare(strict_types=1);

namespace App\Services\Lounges;

use App\DTOs\Lounges\SearchAirportLoungesData;
use App\Models\Airport;
use App\Models\AirportLounge;
use Illuminate\Database\Eloquent\Collection;
use Symfony\Component\HttpKernel\Exception\NotFoundHttpException;

final class AirportLoungeService
{
    /**
     * List global airports matching an optional query string.
     *
     * @return array<int, array<string, mixed>>
     */
    public function listAirports(?string $query = null): array
    {
        return AirportLoungeDirectoryService::listGlobalAirports($query);
    }

    /**
     * Search lounges in an airport with filters for terminal, airside, and access methods.
     *
     * @return array{airport: Airport, lounges: Collection<int, AirportLounge>}
     */
    public function searchLounges(SearchAirportLoungesData $data): array
    {
        $iata = AirportLoungeDirectoryService::resolveIata($data->iataCode);
        $airport = Airport::with('terminals')->where('iata_code', $iata)->first();

        if ($airport === null) {
            $airport = AirportLoungeDirectoryService::autoProvision($iata);
        }

        if ($airport === null) {
            throw new NotFoundHttpException("Airport with IATA code '{$iata}' not found");
        }

        $query = AirportLounge::query()
            ->with(['terminal', 'airport'])
            ->where('airport_id', $airport->id);

        if ($data->terminalCode !== null && $data->terminalCode !== '') {
            $terminalCode = strtoupper(trim($data->terminalCode));
            $query->whereHas('terminal', static function ($q) use ($terminalCode): void {
                $q->where('code', $terminalCode);
            });
        }

        if ($data->isAirside !== null) {
            $query->where('is_airside', $data->isAirside);
        }

        if ($data->accessMethods !== null && $data->accessMethods !== []) {
            $query->where(function ($q) use ($data): void {
                foreach ($data->accessMethods as $method) {
                    $q->orWhereJsonContains('access_methods', $method);
                }
            });
        }

        $lounges = $query->orderBy('name', 'asc')->get();

        return [
            'airport' => $airport,
            'lounges' => $lounges,
        ];
    }

    /**
     * Get details for a single airport lounge by ID.
     */
    public function getLoungeDetails(string $loungeId): AirportLounge
    {
        $lounge = AirportLounge::with(['terminal', 'airport'])->find($loungeId);

        if ($lounge === null) {
            throw new NotFoundHttpException('Airport lounge not found');
        }

        return $lounge;
    }
}
