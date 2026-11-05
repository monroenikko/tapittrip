# Identity and Authentication

- Milestone: `M1`
- Status: `implemented` (Slice 1 backend foundation)
- Owner: `engineering`
- Last verified: `2026-11-05`

## Purpose and traveler outcome

Provides secure identity, API session token issuance, traveler profile management, and account deletion for travelers using TapItTrip.

## How it works

1. A traveler authenticates with credentials (`POST /api/v1/auth/login`, alias `POST /api/v1/auth/token`) and receives a personal access token (Bearer token) and profile data.
2. The authenticated client accesses the traveler's profile (`GET /api/v1/me`) to display their name, display name, preferred locale, and home timezone.
3. The traveler can log out (`POST /api/v1/auth/logout`), which invalidates the current access token.
4. The traveler can delete their account (`DELETE /api/v1/me`), which revokes all active tokens, removes sessions, and soft-deletes their user record.

## Architecture and data flow

- **Authentication Guard:** Laravel Sanctum using personal access tokens associated with UUID user identities.
- **Data model:** PostgreSQL `users` table with UUID primary key, `display_name`, `avatar_url`, `locale`, `home_timezone`, and `deleted_at` timestamp.
- **Application services:** `IssueAccessTokenService`, `RevokeCurrentAccessTokenService`, and `DeleteAccountService` live under `App\Application\Identity\Services` and own credential verification, token lifecycle, and transactional account deletion. Controllers only translate validated HTTP input and service results.
- **Resources:** `App\Http\Resources\Api\V1\UserResource` formats responses into clean API envelopes.
- **Response boundary:** `App\Support\Http\ApiResponse` is the single success/error envelope builder. `ApiExceptionResponse` maps validation, authentication, HTTP, and unexpected failures through centralized exception rendering.

## API contract

Documented in [`docs/api/openapi.yaml`](../api/openapi.yaml):
- `POST /api/v1/auth/login` (`login`) and legacy alias `POST /api/v1/auth/token` (`createAuthToken`)
- `POST /api/v1/auth/logout` (`logout`)
- `GET /api/v1/me` (`getProfile`)
- `DELETE /api/v1/me` (`deleteAccount`)

Successful JSON uses a top-level `data` member. Failures use a top-level `error` member with a stable machine-readable `code`, safe `message`, and optional structured `details`. Logout and account deletion return an empty `204` response.

## Security and privacy

- User IDs are UUIDv7/v4 strings; integer database identifiers are not exposed.
- Passwords are encrypted with bcrypt.
- Tokens are hashed at rest by Laravel Sanctum in `personal_access_tokens`.
- Tokens are strictly revocable and scoped to the user.
- Account deletion revokes all access tokens immediately.
- Exception messages, stack traces, SQL, credentials, tokens, and provider payloads are never copied into API error responses.

## Offline and conflict behavior

- Authentication and token issuance require network connectivity.
- Authenticated profile details are designed to be cached locally in secure client storage once mobile integration begins.

## Testing and acceptance evidence

- Feature test suite: [`api/tests/Feature/AuthTest.php`](../../api/tests/Feature/AuthTest.php)
  - `test_user_can_obtain_token_with_valid_credentials`
  - `test_user_cannot_obtain_token_with_invalid_credentials`
  - `test_token_request_validation_uses_standard_error_envelope`
  - `test_authenticated_user_can_view_profile`
  - `test_unauthenticated_request_to_me_is_rejected`
  - `test_authenticated_user_can_logout`
  - `test_authenticated_user_can_delete_account`
- Error-envelope suite: [`api/tests/Feature/ApiErrorResponseTest.php`](../../api/tests/Feature/ApiErrorResponseTest.php)
  - standard not-found and method-not-allowed responses
  - safe unexpected-error response without exception-detail leakage
- Verification commands:
  - `bash bin/test-postgres`
  - `./vendor/bin/sail pint --test`
  - `./vendor/bin/sail --profile tools run --rm --no-deps contracts`

## Operations and observability

- Migrations:
  - `2026_11_05_015033_create_personal_access_tokens_table.php`
  - `2026_11_05_020000_add_traveler_profile_to_users_table.php`
- Uses standard Laravel logs; sensitive tokens and passwords are redacted from log outputs.
- Duplicate reporting of the same exception instance is disabled in centralized exception configuration.

## Known limitations

- OAuth provider exchange (e.g. Google, Apple) with Socialite fakes will be layered on in future slices.
- Mobile client authentication UI is scheduled for Slice 3.

## Direction

- Proceed to Slice 2: Trips & Memberships CRUD API (`/api/v1/trips`) with `TripPolicy` and planning mode support.

