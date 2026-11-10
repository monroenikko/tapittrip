<?php

declare(strict_types=1);

namespace App\Http\Controllers\Api\V1;

use App\DTOs\Identity\UpdateProfileData;
use App\Http\Controllers\Controller;
use App\Http\Requests\Api\V1\Profile\UpdateProfileRequest;
use App\Http\Resources\Api\V1\UserResource;
use App\Services\Identity\ProfileService;
use App\Support\Http\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Response;

final class ProfileController extends Controller
{
    public function __construct(
        private readonly ProfileService $profileService,
        private readonly ApiResponse $response,
    ) {}

    public function show(Request $request): JsonResponse
    {
        return $this->response->success(new UserResource($request->user()));
    }

    public function update(UpdateProfileRequest $request): JsonResponse
    {
        $user = $this->profileService->update(
            $request->user(),
            UpdateProfileData::fromArray($request->validated()),
        );

        return $this->response->success(new UserResource($user));
    }

    public function destroy(Request $request): Response
    {
        $this->profileService->deleteAccount($request->user());

        return $this->response->noContent();
    }
}
