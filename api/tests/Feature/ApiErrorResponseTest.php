<?php

declare(strict_types=1);

namespace Tests\Feature;

use Illuminate\Support\Facades\Route;
use RuntimeException;
use Tests\TestCase;

final class ApiErrorResponseTest extends TestCase
{
    public function test_unknown_api_route_uses_standard_not_found_envelope(): void
    {
        $this->getJson('/api/v1/unknown-endpoint')
            ->assertNotFound()
            ->assertExactJson([
                'error' => [
                    'code' => 'not_found',
                    'message' => 'The requested resource was not found.',
                ],
            ]);
    }

    public function test_method_not_allowed_response_preserves_framework_headers(): void
    {
        $this->postJson('/api/v1/health')
            ->assertMethodNotAllowed()
            ->assertHeader('Allow', 'GET, HEAD')
            ->assertExactJson([
                'error' => [
                    'code' => 'method_not_allowed',
                    'message' => 'The HTTP method is not allowed for this endpoint.',
                ],
            ]);
    }

    public function test_unexpected_api_error_does_not_leak_exception_details(): void
    {
        Route::get('/api/v1/test/unexpected-error', static function (): never {
            throw new RuntimeException('Internal diagnostic that must not be exposed.');
        });

        $this->getJson('/api/v1/test/unexpected-error')
            ->assertInternalServerError()
            ->assertExactJson([
                'error' => [
                    'code' => 'internal_error',
                    'message' => 'An unexpected error occurred.',
                ],
            ]);
    }
}
