<?php

declare(strict_types=1);

namespace App\Support\Http;

use Illuminate\Http\JsonResponse;
use Illuminate\Http\Response;

final class ApiResponse
{
    /**
     * @param  array<string, string>  $headers
     */
    public function success(mixed $data, int $status = 200, array $headers = []): JsonResponse
    {
        return response()->json([
            'data' => $data,
        ], $status, $headers);
    }

    /**
     * @param  array<string, mixed>  $details
     * @param  array<string, string>  $headers
     */
    public function error(
        string $code,
        string $message,
        int $status,
        array $details = [],
        array $headers = [],
    ): JsonResponse {
        $error = [
            'code' => $code,
            'message' => $message,
        ];

        if ($details !== []) {
            $error['details'] = $details;
        }

        return response()->json([
            'error' => $error,
        ], $status, $headers);
    }

    /**
     * @param  array<string, string>  $headers
     */
    public function noContent(array $headers = []): Response
    {
        return response()->noContent(headers: $headers);
    }
}
