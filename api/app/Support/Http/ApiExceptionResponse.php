<?php

declare(strict_types=1);

namespace App\Support\Http;

use App\Application\Identity\Exceptions\InvalidCredentials;
use Illuminate\Auth\AuthenticationException;
use Illuminate\Http\JsonResponse;
use Illuminate\Validation\ValidationException;
use Symfony\Component\HttpKernel\Exception\HttpExceptionInterface;
use Throwable;

final class ApiExceptionResponse
{
    public function __construct(
        private readonly ApiResponse $response,
    ) {}

    public function render(Throwable $exception): JsonResponse
    {
        return match (true) {
            $exception instanceof ValidationException => $this->response->error(
                code: 'validation_failed',
                message: 'The given data was invalid.',
                status: $exception->status,
                details: ['fields' => $exception->errors()],
            ),
            $exception instanceof InvalidCredentials => $this->response->error(
                code: 'invalid_credentials',
                message: 'The provided credentials are incorrect.',
                status: 422,
            ),
            $exception instanceof AuthenticationException => $this->response->error(
                code: 'unauthenticated',
                message: 'Authentication is required.',
                status: 401,
            ),
            $exception instanceof HttpExceptionInterface => $this->fromHttpException($exception),
            default => $this->response->error(
                code: 'internal_error',
                message: 'An unexpected error occurred.',
                status: 500,
            ),
        };
    }

    private function fromHttpException(HttpExceptionInterface $exception): JsonResponse
    {
        $status = $exception->getStatusCode();

        [$code, $message] = match ($status) {
            400 => ['bad_request', 'The request could not be processed.'],
            401 => ['unauthenticated', 'Authentication is required.'],
            403 => ['forbidden', 'You are not authorized to perform this action.'],
            404 => ['not_found', 'The requested resource was not found.'],
            405 => ['method_not_allowed', 'The HTTP method is not allowed for this endpoint.'],
            409 => ['conflict', 'The request conflicts with the current state.'],
            419 => ['authentication_timeout', 'The request could not be authenticated.'],
            422 => ['unprocessable_entity', 'The request could not be processed.'],
            429 => ['rate_limited', 'Too many requests. Please try again later.'],
            503 => ['service_unavailable', 'The service is temporarily unavailable.'],
            default => $status >= 500
                ? ['internal_error', 'An unexpected error occurred.']
                : ['request_failed', 'The request could not be completed.'],
        };

        return $this->response->error(
            code: $code,
            message: $message,
            status: $status,
            headers: $exception->getHeaders(),
        );
    }
}
