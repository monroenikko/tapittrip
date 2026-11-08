<?php

declare(strict_types=1);

namespace App\Http\Controllers\Api\V1;

use App\Application\Expenses\Services\CurrencyExchangeRateService;
use App\Http\Controllers\Controller;
use App\Support\Http\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

final class CurrencyController extends Controller
{
    public function rate(
        Request $request,
        CurrencyExchangeRateService $rateService,
        ApiResponse $response,
    ): JsonResponse {
        $from = strtoupper(trim((string) $request->query('from', 'USD')));
        $to = strtoupper(trim((string) $request->query('to', 'PHP')));

        $rateData = $rateService->getRate($from, $to);

        return $response->success($rateData->toArray());
    }
}
