<?php

declare(strict_types=1);

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Services\Expenses\CurrencyExchangeRateService;
use App\Support\Http\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

final class CurrencyController extends Controller
{
    public function __construct(
        private readonly CurrencyExchangeRateService $rateService,
        private readonly ApiResponse $response,
    ) {}

    public function rate(Request $request): JsonResponse
    {
        $from = strtoupper(trim((string) $request->query('from', 'USD')));
        $to = strtoupper(trim((string) $request->query('to', 'PHP')));

        $rateData = $this->rateService->getRate($from, $to);

        if (! $rateData->available) {
            return $this->response->error(
                'exchange_rate_unavailable',
                "Exchange rate is currently unavailable for {$from} to {$to}.",
                503,
            );
        }

        return $this->response->success($rateData->toArray());
    }
}
