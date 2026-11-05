<?php

use App\Support\Http\ApiExceptionResponse;
use App\Support\Http\ApiResponse;
use Illuminate\Foundation\Application;
use Illuminate\Foundation\Configuration\Exceptions;
use Illuminate\Foundation\Configuration\Middleware;
use Illuminate\Http\Request;

$apiExceptionResponse = new ApiExceptionResponse(new ApiResponse);

return Application::configure(basePath: dirname(__DIR__))
    ->withRouting(
        web: __DIR__.'/../routes/web.php',
        api: __DIR__.'/../routes/api.php',
        commands: __DIR__.'/../routes/console.php',
        health: '/up',
    )
    ->withMiddleware(function (Middleware $middleware): void {
        //
    })
    ->withExceptions(function (Exceptions $exceptions) use ($apiExceptionResponse): void {
        $exceptions->dontReportDuplicates();

        $exceptions->shouldRenderJsonWhen(
            fn (Request $request) => $request->is('api/*') || $request->expectsJson(),
        );

        $exceptions->render(
            fn (Throwable $exception, Request $request) => $request->is('api/*')
                ? $apiExceptionResponse->render($exception)
                : null,
        );
    })->create();
