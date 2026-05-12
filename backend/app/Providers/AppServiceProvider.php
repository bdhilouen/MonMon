<?php

namespace App\Providers;

use Illuminate\Support\ServiceProvider;
use App\Services\AchievementService;

class AppServiceProvider extends ServiceProvider
{
    /**
     * Register any application services.
     */
    public function register(): void
    {
        $this->app->singleton(AchievementService::class, function ($app) {
            return new AchievementService();
        });
    }

    /**
     * Bootstrap any application services.
     */
    public function boot(): void
    {
        //
    }
}
