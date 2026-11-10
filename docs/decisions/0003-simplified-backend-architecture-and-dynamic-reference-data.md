# ADR 0003: Simplified Backend Architecture & Dynamic Reference Data

- **Status**: Accepted
- **Date**: 2026-11-10
- **Context**: The Laravel API was initially organized into strict split Domain and Application layers (`app/Domain/<Feature>` and `app/Application/<Feature>`), with individual single-method service classes for every action and large static constants (e.g., hundreds of country currency mappings, airport lounge directories, checklist templates) embedded in PHP classes.

## Decision

### 1. Simplified Standard Architecture
We adopt a cohesive, readable, and standard Laravel structure across `api/app/`:

```
api/app/
├── Services/{Feature}/        # Unified behavior services per feature (e.g., TripService, ItineraryService, ExpenseService)
├── Models/                    # Consolidated flat Eloquent models (Trip, Stay, Expense, Country, etc.)
├── DTOs/{Feature}/            # Strongly-typed Data Transfer Objects for requests and aggregated results
├── Http/Controllers/Api/V1/   # Thin controllers mapping HTTP requests to service calls
├── Http/Resources/Api/V1/     # Standardized JSON response resources
├── Policies/                  # Resource authorization policies (e.g., TripPolicy)
└── Traits/                    # Reusable framework behaviors
```

#### Key Principles:
1. **Application Service Pattern**: Each domain feature has a unified service class (e.g., `ExpenseService`, `ChecklistService`, `MediaService`) that handles transactions, business logic, and queries.
2. **Flat Models in `app/Models/`**: All Eloquent models live in `app/Models/`, simplifying relationships and eliminating verbose cross-domain model imports.
3. **Strongly Typed DTOs**: Input payloads and complex output summaries are encapsulated in typed DTOs under `app/DTOs/{Feature}/`.
4. **Thin Controllers**: Controllers validate requests via FormRequests, invoke service methods with DTOs, and return standard API resources without embedding business logic.

### 2. Updatable Reference Data in the Database
Data that can change, expand, or be updated in the future must not be hardcoded in static PHP class constants:

1. **Countries & Currencies**:
   - Stored in the `countries` database table with columns: `code`, `name`, `currency_code`, `flag_emoji`, `is_zero_decimal`, and `aliases` (`jsonb`).
   - Populated via `CountrySeeder` and database migrations.
   - Queried by `CountryCurrencyResolver` with `Cache::rememberForever` for sub-millisecond lookups and automatic cache clearing when `Country` records are updated.
   - Exposed publicly via `GET /api/v1/countries` so web and mobile clients load countries, currencies, and flags dynamically without hardcoded static lists.

2. **Airports & Lounge Catalogs**:
   - Catalogs and search aliases are maintained in structured seed data (`database/data/airports_catalog.json`) and database tables (`airports`, `airport_terminals`, `airport_lounges`) rather than 800+ lines of in-class PHP constants.

3. **Checklist Starter Templates**:
   - Starter template definitions are stored in seed data (`database/data/checklist_templates.json`), allowing easy expansion and customization without modifying core service classes.

4. **Weather City Coordinates Catalog**:
   - Coordinates and destination names for global cities are stored in `database/data/city_coordinates.json` and cached via `Cache::rememberForever`, removing hardcoded arrays from `WeatherService`.

## Consequences

- **Readability & Maintainability**: Reduced code sprawl and eliminated dozens of single-action classes.
- **Dynamic Updates**: Reference data (countries, currencies, city aliases) can be updated directly via migrations, seeders, or database updates without altering PHP source code.
- **Zero Breaking Changes**: Public API JSON response envelopes (`{"data": ...}`, `{"error": ...}`) and mobile client compatibility remain 100% intact.
- **High Performance**: In-memory caching preserves sub-millisecond execution times.

