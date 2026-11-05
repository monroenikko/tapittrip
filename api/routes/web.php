<?php

use Illuminate\Support\Facades\Route;

Route::get('/', function () {
    return view('welcome');
});

Route::get('/docs/openapi.yaml', function () {
    $path = file_exists('/var/www/docs/openapi.yaml')
        ? '/var/www/docs/openapi.yaml'
        : base_path('../docs/api/openapi.yaml');

    abort_unless(file_exists($path), 404, 'OpenAPI specification not found.');

    return response(file_get_contents($path), 200, [
        'Content-Type' => 'text/yaml; charset=utf-8',
        'Cache-Control' => 'no-cache, private',
    ]);
})->name('docs.openapi');

Route::get('/docs', function () {
    return view('docs.swagger');
})->name('docs.swagger');
