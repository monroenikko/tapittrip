<?php

declare(strict_types=1);

namespace App\Application\Lounges\Services;

use App\Application\Lounges\Data\SearchAirportLoungesData;
use App\Domain\Lounges\Models\Airport;
use App\Domain\Lounges\Models\AirportLounge;
use Illuminate\Database\Eloquent\Collection;
use Symfony\Component\HttpKernel\Exception\NotFoundHttpException;

final class SearchAirportLoungesService
{
    /**
     * @return array{airport: Airport, lounges: Collection<int, AirportLounge>}
     */
    public function execute(SearchAirportLoungesData $data): array
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
}
