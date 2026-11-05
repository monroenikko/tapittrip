<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Support\Http\ApiResponse;
use Illuminate\Http\JsonResponse;

class HealthController extends Controller
{
    public function __invoke(ApiResponse $response): JsonResponse
    {
        return $response->success([
            'status' => 'ok',
        ]);
    }
}
