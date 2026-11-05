# Laravel Application Service and API Patterns

Apply these patterns inside the root `api/` project. Adapt namespaces to the generated Laravel version, but preserve responsibility and dependency direction.

## Default request flow

```text
Route
  -> Form Request (authorize coarse access, validate, normalize)
  -> Versioned Controller (translate HTTP only)
  -> Policy (resource/trip membership authorization)
  -> Application Service or Action (one use case, transaction boundary)
  -> Domain Model / Domain Service / Provider Port
  -> API Resource (stable response mapping)
```

The controller must not contain business decisions, persistence orchestration, provider calls, or multi-step transactions. The application service must not receive the framework `Request` object or return an HTTP response.

## Service pattern

Use “service” only when the class has a clear role:

### Application service or action

Orchestrates one user/system use case such as `CreateTrip`, `UpdateStay`, or `PushSyncOperations`.

- Accept a small typed command/DTO or explicit scalar/value-object inputs.
- Enforce use-case ordering and transaction boundaries.
- Call domain models/services and provider ports.
- Return a model or explicit result object, not a JSON response.
- Name by behavior. Prefer `CreateTrip` or `CreateTripService` over `TripService`.

```php
final class CreateTrip
{
    public function __construct(
        private Clock $clock,
    ) {}

    public function handle(User $owner, CreateTripData $data): Trip
    {
        return DB::transaction(function () use ($owner, $data): Trip {
            return Trip::query()->create([
                'id' => (string) Str::uuid(),
                'owner_id' => $owner->getKey(),
                'name' => $data->name,
                'timezone' => $data->timezone,
                'starts_at' => $data->startsAt,
                'created_at' => $this->clock->now(),
            ]);
        });
    }
}
```

Treat this as a shape, not copy-ready code: use the installed project's UUID, timestamp, mass-assignment, and DTO conventions.

### Domain service

Use only for a business rule that does not naturally belong to one entity/value object, such as deterministic transport ranking or conflict resolution.

- Keep it framework-independent when practical.
- Make inputs and outputs explicit and deterministic.
- Do not query the database, read the request, or format HTTP responses.

### Infrastructure/provider service

Wrap maps, transit, AI, OCR, notifications, flights, storage, clock, and other external capabilities behind a small application/domain-facing interface.

- Bind the interface to the adapter in the service container.
- Translate provider payloads/errors at the adapter boundary.
- Include source and freshness metadata where the domain needs it.
- Supply deterministic fakes for tests.

### Repository

Do not wrap Eloquent in a repository merely to rename `find`, `create`, or `save`. Add a repository/port when it creates a real boundary: a complex aggregate store, multiple persistence implementations, offline-sync sequencing, or isolation from an external SDK. Keep query objects/scopes for reusable read queries when that is simpler.

## Feature-oriented structure

Prefer a domain/feature structure that keeps a capability together:

```text
api/app/
  Domain/Trips/
    Actions/CreateTrip.php
    Data/CreateTripData.php
    Models/Trip.php
    Policies/TripPolicy.php
    Rules/
    Services/                    # only genuine domain services
  Http/Controllers/Api/V1/Trips/
    TripController.php
  Http/Requests/Api/V1/Trips/
    StoreTripRequest.php
  Http/Resources/Api/V1/Trips/
    TripResource.php
  Providers/
    Maps/Contracts/MapsProvider.php
    Maps/Adapters/...
```

Follow existing Laravel autoloading and framework conventions after scaffolding. Do not reorganize generated/runtime files without a concrete benefit.

## API creation pattern

For each operation, implement in this order:

1. Define the traveler outcome and OpenAPI operation, including authentication, inputs, response, errors, idempotency, and examples.
2. Add the versioned route and select only required resource actions.
3. Add a Form Request using `validated()`/`safe()` data; normalize carefully and reject unknown or unsafe input according to the contract.
4. Add or update the Policy. Authorize nested resources against the parent trip and prevent cross-trip binding mistakes.
5. Add the application action/service and its transaction/idempotency boundary.
6. Persist with explicit constraints, indexes, casts, fillable/guarded strategy, and UTC/timezone/currency rules.
7. Return an API Resource and documented status/headers; do not expose Eloquent models directly.
8. Add unit tests for domain rules and feature tests for the complete HTTP contract.
9. Update OpenAPI, feature documentation, migrations/rollout notes, and the milestone log.

Example controller shape:

```php
final class TripController
{
    public function store(
        StoreTripRequest $request,
        CreateTrip $createTrip,
    ): JsonResponse {
        $trip = $createTrip->handle(
            $request->user(),
            CreateTripData::from($request->validated()),
        );

        return (new TripResource($trip))
            ->response()
            ->setStatusCode(201);
    }
}
```

## API invariants

- Use `/api/v1` and stable `operationId` values.
- Authenticate first and authorize every trip-scoped read/write server-side.
- Use route model scoping or explicit parent checks; never trust matching UUID shape as membership.
- Use predictable error envelopes with stable codes; never leak exceptions or provider payloads.
- Paginate collections and constrain filters/sorts. Prevent N+1 queries and unbounded includes.
- Require an idempotency key or operation UUID where retries can duplicate data or side effects.
- Use optimistic versions/conflict responses where offline clients may edit the same record.
- Dispatch jobs/events after commit when they depend on committed records; make handlers idempotent.
- Rate-limit abuse-prone, authentication, upload, import, and provider-backed operations.
- Serialize only approved fields; encrypted storage does not make a field safe to expose.

## Testing seams

- Application service tests: use-case ordering, transaction outcomes, domain errors, and idempotent retry behavior.
- Domain service tests: table-driven deterministic rules and edge cases without Laravel HTTP.
- API feature tests: validation, unauthenticated/unauthorized/cross-trip access, success resource, not found, conflict, pagination, rate limits, and database effects.
- Provider contract tests: adapter translation with recorded synthetic fixtures or controlled sandboxes; default tests use fakes.

Prefer real Laravel/container/database behavior in feature tests over mocking controllers or Eloquent internals.

## Avoid

- `TripService`/`BaseService` classes that grow unrelated CRUD methods.
- Controllers calling `Model::create($request->all())`.
- Passing Request, Response, Resource, or authenticated globals into domain services.
- A repository per model without a boundary benefit.
- Service-to-service cycles, hidden service-locator lookups, or business logic in observers.
- Generic catch-all exceptions that erase conflict, validation, or provider failure meaning.
- Returning raw models, exposing encrypted/private attributes, or trusting client-side authorization.

## Official references

- [Laravel service container](https://laravel.com/docs/container)
- [Laravel controllers and API resources](https://laravel.com/docs/controllers)
- [Laravel validation and Form Requests](https://laravel.com/docs/validation#form-request-validation)
- [Laravel authorization policies](https://laravel.com/docs/authorization#creating-policies)
- [Laravel API resources](https://laravel.com/docs/eloquent-resources)

