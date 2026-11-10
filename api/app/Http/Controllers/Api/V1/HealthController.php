<?php

declare(strict_types=1);

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Support\Http\ApiResponse;
use Illuminate\Http\JsonResponse;

final class HealthController extends Controller
{
    public function __construct(
        private readonly ApiResponse $response,
    ) {}

    public function __invoke(): JsonResponse
    {
        return $this->response->success([
            'status' => 'ok',
        ]);
    }
}
