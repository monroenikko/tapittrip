<?php

use App\Http\Controllers\Api\V1\AuthController;
use App\Http\Controllers\Api\V1\ChecklistController;
use App\Http\Controllers\Api\V1\ChecklistItemController;
use App\Http\Controllers\Api\V1\HealthController;
use App\Http\Controllers\Api\V1\ItineraryItemController;
use App\Http\Controllers\Api\V1\PlaceController;
use App\Http\Controllers\Api\V1\ProfileController;
use App\Http\Controllers\Api\V1\StayController;
use App\Http\Controllers\Api\V1\StayTransportController;
use App\Http\Controllers\Api\V1\TripController;
use App\Http\Controllers\Api\V1\TripDayController;
use App\Http\Controllers\Api\V1\TripTodayController;
use Illuminate\Support\Facades\Route;

Route::prefix('v1')->group(function (): void {
    Route::get('/health', HealthController::class)->name('health.show');

    Route::post('/auth/register', [AuthController::class, 'register'])->name('auth.register');
    Route::post('/auth/login', [AuthController::class, 'login'])->name('auth.login');
    Route::post('/auth/token', [AuthController::class, 'login'])->name('auth.token');

    Route::middleware('auth:sanctum')->group(function (): void {
        Route::post('/auth/logout', [AuthController::class, 'logout'])->name('auth.logout');
        Route::get('/me', [ProfileController::class, 'show'])->name('me.show');
        Route::delete('/me', [ProfileController::class, 'destroy'])->name('me.destroy');

        Route::apiResource('trips', TripController::class);
        Route::get('/trips/{trip}/today', [TripTodayController::class, 'show'])->name('trips.today.show');

        Route::get('/trips/{trip}/days', [TripDayController::class, 'index'])->name('trips.days.index');
        Route::post('/trips/{trip}/days', [TripDayController::class, 'store'])->name('trips.days.store');

        Route::get('/trips/{trip}/itinerary-items', [ItineraryItemController::class, 'index'])->name('trips.itinerary-items.index');
        Route::post('/trips/{trip}/itinerary-items', [ItineraryItemController::class, 'store'])->name('trips.itinerary-items.store');
        Route::post('/trips/{trip}/itinerary-items/reorder', [ItineraryItemController::class, 'reorder'])->name('trips.itinerary-items.reorder');
        Route::get('/itinerary-items/{item}', [ItineraryItemController::class, 'show'])->name('itinerary-items.show');
        Route::patch('/itinerary-items/{item}', [ItineraryItemController::class, 'update'])->name('itinerary-items.update');
        Route::delete('/itinerary-items/{item}', [ItineraryItemController::class, 'destroy'])->name('itinerary-items.destroy');

        Route::get('/places/search', [PlaceController::class, 'search'])->name('places.search');
        Route::post('/places', [PlaceController::class, 'store'])->name('places.store');
        Route::get('/places/{place}', [PlaceController::class, 'show'])->name('places.show');

        Route::get('/trips/{trip}/stays', [StayController::class, 'index'])->name('trips.stays.index');
        Route::post('/trips/{trip}/stays', [StayController::class, 'store'])->name('trips.stays.store');
        Route::get('/stays/{stay}', [StayController::class, 'show'])->name('stays.show');
        Route::patch('/stays/{stay}', [StayController::class, 'update'])->name('stays.update');
        Route::delete('/stays/{stay}', [StayController::class, 'destroy'])->name('stays.destroy');
        Route::post('/stays/{stay}/transport-options', [StayTransportController::class, 'compare'])->name('stays.transport-options.compare');

        Route::get('/trips/{trip}/checklists', [ChecklistController::class, 'index'])->name('trips.checklists.index');
        Route::post('/trips/{trip}/checklists', [ChecklistController::class, 'store'])->name('trips.checklists.store');
        Route::post('/trips/{trip}/checklists/apply-template', [ChecklistController::class, 'applyTemplate'])->name('trips.checklists.apply-template');
        Route::get('/checklists/{checklist}', [ChecklistController::class, 'show'])->name('checklists.show');
        Route::delete('/checklists/{checklist}', [ChecklistController::class, 'destroy'])->name('checklists.destroy');

        Route::post('/checklists/{checklist}/items', [ChecklistItemController::class, 'store'])->name('checklists.items.store');
        Route::patch('/checklist-items/{item}', [ChecklistItemController::class, 'update'])->name('checklist-items.update');
        Route::post('/checklist-items/{item}/toggle', [ChecklistItemController::class, 'toggle'])->name('checklist-items.toggle');
        Route::delete('/checklist-items/{item}', [ChecklistItemController::class, 'destroy'])->name('checklist-items.destroy');
    });
});
