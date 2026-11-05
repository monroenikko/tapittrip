<?php

declare(strict_types=1);

namespace App\Http\Controllers\Api\V1;

use App\Application\Identity\Services\DeleteAccountService;
use App\Http\Controllers\Controller;
use App\Http\Resources\Api\V1\UserResource;
use App\Support\Http\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Response;

final class ProfileController extends Controller
{
    public function show(Request $request, ApiResponse $response): JsonResponse
    {
        return $response->success(new UserResource($request->user()));
    }

    public function destroy(
        Request $request,
        DeleteAccountService $deleteAccountService,
        ApiResponse $response,
    ): Response {
        $deleteAccountService->handle($request->user());

        return $response->noContent();
    }
}
