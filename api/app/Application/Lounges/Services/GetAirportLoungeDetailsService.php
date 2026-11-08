<?php

declare(strict_types=1);

namespace App\Application\Lounges\Services;

use App\Domain\Lounges\Models\AirportLounge;
use Symfony\Component\HttpKernel\Exception\NotFoundHttpException;

final class GetAirportLoungeDetailsService
{
    public function execute(string $loungeId): AirportLounge
    {
        $lounge = AirportLounge::with(['terminal', 'airport'])->find($loungeId);

        if ($lounge === null) {
            throw new NotFoundHttpException('Airport lounge not found');
        }

        return $lounge;
    }
}
