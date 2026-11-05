<?php

use App\Http\Controllers\Api\V1\AuthController;
use App\Http\Controllers\Api\V1\HealthController;
use App\Http\Controllers\Api\V1\ProfileController;
use Illuminate\Support\Facades\Route;

Route::prefix('v1')->group(function (): void {
    Route::get('/health', HealthController::class)->name('health.show');

    Route::post('/auth/token', [AuthController::class, 'token'])->name('auth.token');

    Route::middleware('auth:sanctum')->group(function (): void {
        Route::post('/auth/logout', [AuthController::class, 'logout'])->name('auth.logout');
        Route::get('/me', [ProfileController::class, 'show'])->name('me.show');
        Route::delete('/me', [ProfileController::class, 'destroy'])->name('me.destroy');
    });
});
