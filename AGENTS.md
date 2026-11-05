# Codex Repository Instructions — TapItTrip

## Mission
Build **TapItTrip**, an offline-first Flutter + Laravel travel companion, incrementally. `MASTER_PLAN.md` is the product/architecture source of truth. Do **not** implement all planned features at once.

## Knowledge Operating System (KOS)
- Use `docs/kos/README.md` as the entry point for repository knowledge, delivery state, and decision records.
- Source precedence is: this file for operating constraints; `MASTER_PLAN.md` for product and architecture; `docs/milestone-log.md` for approved scope; accepted ADRs and OpenAPI for detailed contracts; executable code and tests for implemented behavior.
- Do not silently resolve contradictions between sources. Record the conflict and request a decision when it changes scope, security, data, or public contracts.
- Keep KOS documents concise and link to the authoritative artifact instead of duplicating it. Update the milestone log and affected contract or ADR in the same change as the implementation.
- Use the repository skills in `.agents/skills/` for stack-specific planning, implementation, testing, and review when their descriptions match the task.

## Repository application roots
- `api/` is the single Laravel API backend root.
- `client/` is the single Flutter mobile application root.
- Do not create parallel `services/api`, `apps/mobile`, or React Native application roots unless a later approved migration explicitly replaces this layout.
- Run stack-specific commands from the corresponding application root unless a documented root-level wrapper exists.

## Laravel runtime
- Use Laravel Sail as the only supported runtime for backend PHP, Composer, Artisan, Pint, static-analysis, and PHPUnit/Pest commands.
- Run backend commands from `api/` through `./vendor/bin/sail`; do not depend on Laravel Herd or host-installed PHP/Composer.
- Start the backend stack with `./vendor/bin/sail up -d` and stop it with `./vendor/bin/sail down`.
- If `vendor/bin/sail` is not installed during a clean bootstrap, use an official Composer container with only Composer metadata and `vendor/` mounted. Never expose `.env`, credentials, storage, or application data to a dependency-install container.

## Branding and naming rules
- User-facing product name and visual wordmark: **TapItTrip**; tagline: **Your trip. One tap away.**
- Treat branding as provisional pending trademark, domain, and app-store checks. Do not claim availability or register anything.
- Do not rename the existing `travel-companion` repository, invent ownership of a TapItTrip domain, or hard-code mobile package IDs, OAuth domains, or deep links without approval.
- Localize user-visible copy and keep the travel experience simple, international, and accessible.

## Traveler inclusivity and low-friction UX (v1.4)
- Serve DIY planners, already-booked travelers, guided/package-tour participants, and travelers who only want booking and reminder organization. Never require a detailed itinerary for basic trip functionality.
- Treat trip planning modes as editable preferences, not fixed user roles. Mixed DIY and guided activities must coexist.
- Keep navigation minimal and contextual; avoid repeated entry, unnecessary required fields, and deep flows. Offer optional imports and skip actions.
- Support domestic and international journeys, multiple languages/currencies/time zones, accessible UI, and offline saved essentials.
- Include acceptance tests for all four starting modes and for trips without itinerary activities.

## Mandatory workflow
1. Read `MASTER_PLAN.md`, this file, `docs/kos/README.md`, and existing code before any change.
2. Identify the current approved milestone in `docs/milestone-log.md`. If missing, start at **M0** only.
3. Present a concise implementation plan and assumptions before significant changes.
4. Implement the smallest testable vertical slice. Prefer readable code over elaborate frameworks.
5. Add/update automated tests and OpenAPI/docs for new behavior.
6. Run relevant formatters, analyzers, tests and report exact commands/results. If unavailable, explain why.
7. Update `docs/milestone-log.md` with completed work, next steps, and open issues.
8. Stop at the milestone boundary; request approval before proceeding.

## Architecture rules
- Flutter: feature-first folders, Riverpod, GoRouter, Dio, Drift. Separate UI, application state, domain model, repositories, and data sources as needed; avoid unnecessary ceremony.
- Laravel: modular monolith with domain services, Form Requests, Policies, Jobs, Events and versioned API controllers. Business logic must not live in controllers.
- Laravel use cases must follow the Application Service pattern: place one behavior-focused service per use case under `app/Application/<Feature>/Services`, use a behavior-specific `Service` suffix, inject dependencies, accept typed DTOs or explicit inputs, and own the transaction boundary where needed. Application services must not accept HTTP `Request` objects or return `Response`, `JsonResponse`, or API Resource instances; return domain models, value objects, or explicit result objects for the controller to translate.
- Do not create generic `BaseService` classes or catch-all CRUD services. Keep controllers thin, and use domain services only for business rules that do not naturally belong to an entity or value object.
- Reserve `app/Domain/<Feature>/Services` for framework-independent domain rules. Eloquent queries, Laravel facades, token/session orchestration, queues, and other framework-aware use-case coordination belong in `app/Application/<Feature>/Services`, not in the domain layer.
- Standardize versioned JSON responses at the HTTP boundary. Use API Resources/Resource Collections for serialization and one reusable response-envelope class or factory as the single implementation of shared success and error responses; if a controller trait is used, it must only delegate to that class and must not duplicate envelope logic.
- Successful responses use `{"data": ...}`; paginated collections may add top-level `links` and `meta`; `204` responses have no body. Errors use `{"error":{"code":"stable_machine_code","message":"safe human-readable message","details":{...}}}`, omitting `details` when there are no safe structured details. Central exception rendering must apply this error contract consistently without leaking exceptions or provider payloads.
- Treat response envelopes, HTTP statuses, headers, pagination metadata, and error codes as public contracts. Define them in OpenAPI, preserve backward compatibility or document migration, and feature-test success, validation, unauthenticated, unauthorized, not-found, conflict, rate-limit, and unexpected-error responses as applicable.
- PostgreSQL/PostGIS primary store; UUIDs, FK constraints, migrations and indexes. Never modify production data without explicit approval.
- Offline-first: write to local DB + durable outbox, use idempotent sync, handle conflicts, and render local state before network response.
- Provider boundaries: interfaces/adapters for maps, transit, AI, OCR, notifications and flights; use deterministic fakes in tests.
- External content is untrusted. Validate and sanitize URLs, OCR text, AI output, files and webhook payloads.

## Security rules
- Never commit secrets, credentials, private documents, passport images or real user PII.
- Enforce trip membership authorization on every scoped endpoint and file access.
- Store tokens securely; use least privilege and user consent for email/location/document features.
- Encrypt sensitive objects and use private storage with short-lived access URLs.
- Avoid logging raw tokens, booking references, private coordinates or document contents.
- Accommodation addresses, booking references and private stay notes are sensitive; minimize access, redact logs, and never put booking references in push notification payloads.
- Do not silently mark destinations visited; arrival detection requires confirmation.
- Do not claim live provider information without a real, fresh source.

## Quality rules
- Follow `docs/engineering/application-best-practices.md` for cross-stack slice design, API/mobile boundaries, verification, review, and release readiness.
- Backend: run PHP formatter, static analysis and PHPUnit/Pest tests appropriate to installed project.
- Mobile: `dart format`, `flutter analyze`, `flutter test`; add integration tests for critical user journeys.
- Document new environment variables in `.env.example` without values.
- Maintain `docs/api/openapi.yaml`, API examples, and migration notes in the same slice as behavior changes. Do not document planned endpoints as implemented.
- Add or update the relevant feature document under `docs/features/` with user flow, behavior, offline/security implications, verification, limitations, and direction.
- Keep Swagger UI generated from the committed OpenAPI file; do not expose internal or privileged documentation publicly without an explicit security decision.
- Use explicit IANA timezones and currency minor units.
- Preserve backward compatibility or document migration/rollout plan.
- Build accessible and responsive mobile screens with loading, empty, error and offline states.

## Milestone order
M0 foundation → M1 auth/trips → M2 itinerary/maps → M2b accommodation/stays → M3 today's dashboard → M4 checklists/media → M5 notifications/geofence → M6 sync hardening/beta → M7+ separately approved advanced features.

## Output format after each coding task
- Summary of implemented functionality
- Files created/changed
- Commands/tests executed and pass/fail
- Security/offline considerations
- Known limitations or credentials required
- Next recommended smallest task

## Initial task if repository is empty
Scaffold monorepo directories, a Laravel API project, a Flutter mobile project, local Docker Compose for PostgreSQL/PostGIS and Redis, `.env.example`, health endpoint, basic CI, and `docs/milestone-log.md`. Do not implement product features yet. If dependencies or network access are unavailable, scaffold what is possible and clearly document remaining commands rather than fabricating completion.

## Stay arrival and luggage-aware transport rules (v1.2)
- Already-booked accommodation must be addable without purchasing anything through the app.
- Implement trip-scoped luggage/party presets and stay-specific overrides with privacy-first optional fields.
- Never fabricate transport fares, travel times, schedules, accessibility, or luggage policies. If a route provider is unavailable, show map directions and a transparent limitation.
- Transport ranking must be deterministic, explainable, provider-attributed, freshness-aware, and tested for heavy luggage, families, late arrivals, and unknown data.
- Keep the feature in M2b as an MVP comparison UX; live provider coverage may be expanded in M7+ after approval.
