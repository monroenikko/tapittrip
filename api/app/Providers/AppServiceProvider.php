<?php

namespace App\Providers;

use App\Contracts\ExchangeRateProviderInterface;
use App\Models\Trip;
use App\Policies\TripPolicy;
use App\Services\Expenses\FakeExchangeRateProvider;
use App\Services\Expenses\LiveExchangeRateProvider;
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
