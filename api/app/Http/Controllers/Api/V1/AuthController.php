<?php

declare(strict_types=1);

namespace App\Http\Controllers\Api\V1;

use App\DTOs\Identity\LoginUserData;
use App\DTOs\Identity\RegisterUserData;
use App\Http\Controllers\Controller;
use App\Http\Requests\Api\V1\Auth\ExchangeOAuthRequest;
use App\Http\Requests\Api\V1\Auth\LoginRequest;
use App\Http\Requests\Api\V1\Auth\RegisterRequest;
use App\Http\Resources\Api\V1\UserResource;
use App\Services\Identity\AuthService;
use App\Support\Http\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Response;

final class AuthController extends Controller
{
    public function __construct(
        private readonly AuthService $authService,
        private readonly ApiResponse $response,
    ) {}

    public function register(RegisterRequest $request): JsonResponse
    {
        $result = $this->authService->register(
            RegisterUserData::fromArray($request->validated())
        );

        return $this->response->success([
            'token' => $result->plainTextToken,
            'token_type' => 'Bearer',
            'user' => new UserResource($result->user),
        ], 201);
    }

    public function login(LoginRequest $request): JsonResponse
    {
        $result = $this->authService->login(
            LoginUserData::fromArray($request->validated())
        );

        return $this->response->success([
            'token' => $result->plainTextToken,
            'token_type' => 'Bearer',
            'user' => new UserResource($result->user),
        ]);
    }

    public function exchangeOAuth(ExchangeOAuthRequest $request, string $provider): JsonResponse
    {
        $exchanged = $this->authService->exchangeOAuth($provider, $request->validated());

        return $this->response->success([
            'token' => $exchanged['result']->plainTextToken,
            'token_type' => 'Bearer',
            'is_new_user' => $exchanged['is_new_user'],
            'user' => new UserResource($exchanged['result']->user),
        ], $exchanged['is_new_user'] ? 201 : 200);
    }

    public function logout(Request $request): Response
    {
        $this->authService->logout($request->user());

        return $this->response->noContent();
    }
}
