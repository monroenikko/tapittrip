<?php

declare(strict_types=1);

namespace App\Http\Controllers\Api\V1;

use App\Application\Identity\Services\IssueAccessTokenService;
use App\Application\Identity\Services\RevokeCurrentAccessTokenService;
use App\Http\Controllers\Controller;
use App\Http\Requests\Api\V1\Auth\LoginRequest;
use App\Http\Resources\Api\V1\UserResource;
use App\Support\Http\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Response;

final class AuthController extends Controller
{
    public function login(
        LoginRequest $request,
        IssueAccessTokenService $issueAccessTokenService,
        ApiResponse $response,
    ): JsonResponse {
        $validated = $request->validated();
        $result = $issueAccessTokenService->handle(
            email: $validated['email'],
            password: $validated['password'],
            deviceName: $validated['device_name'] ?? null,
        );

        return $response->success([
            'token' => $result->plainTextToken,
            'token_type' => 'Bearer',
            'user' => new UserResource($result->user),
        ]);
    }

    public function logout(
        Request $request,
        RevokeCurrentAccessTokenService $revokeCurrentAccessTokenService,
        ApiResponse $response,
    ): Response {
        $revokeCurrentAccessTokenService->handle($request->user());

        return $response->noContent();
    }
}
