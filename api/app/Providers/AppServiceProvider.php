<?php

namespace App\Providers;

use App\Application\Expenses\Contracts\ExchangeRateProviderInterface;
use App\Application\Expenses\Services\FakeExchangeRateProvider;
use App\Application\Expenses\Services\LiveExchangeRateProvider;
use App\Domain\Trips\Models\Trip;
use App\Domain\Trips\Policies\TripPolicy;
use Illuminate\Support\Facades\Gate;
use Illuminate\Support\ServiceProvider;

class AppServiceProvider extends ServiceProvider
{
    /**
     * Register any application services.
     */
    public function register(): void
    {
        $this->app->bind(ExchangeRateProviderInterface::class, function ($app) {
            if ($app->environment('testing')) {
                return new FakeExchangeRateProvider;
            }

            return new LiveExchangeRateProvider;
        });
    }

    /**
     * Bootstrap any application services.
     */
    public function boot(): void
    {
        Gate::policy(Trip::class, TripPolicy::class);
    }
}
