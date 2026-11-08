# Multi-Currency Expenses & Group Budget Tracker

## Overview
TapItTrip provides international travelers with an integrated multi-currency expense tracker and budget management module. Travelers can track expenses during their journeys, convert foreign expenditures automatically into their trip's home/base currency using minor units (cents/sen), categorize expenditures across common travel categories, monitor budget utilization progress, and prepare for group expense splits.

## User Flow & Core Experience
1. **Setting a Trip Budget**:
   - From the trip itinerary, travelers open the overflow menu and select **"Expenses & Budget"** (`/trips/:tripId/expenses`).
   - Travelers can configure a target total trip budget and an optional daily target budget in their preferred base currency (e.g. USD, EUR, PHP, JPY).
   - Real-time spending progress is displayed via a progress bar indicating percentage utilized and remaining budget headroom.
2. **Logging Expenses**:
   - Tapping the floating action button (**"Log Expense"**) opens the logging bottom sheet.
   - Travelers select an expense category (Dining, Transport, Accommodation, Activities, Shopping, Other), input what they paid for, enter the amount, and choose the payment currency.
   - If spending in a foreign currency (e.g. paying ¥3,000 JPY on a USD-based trip), travelers can specify the exchange rate or let the system apply standard conversion, computing `base_amount_minor` deterministically.
   - Expenses can optionally link to an existing Itinerary Item or Stay.
3. **Filtering & Daily Insights**:
   - Filter chips at the top allow immediate filtering by category (Dining, Transport, etc.).
   - The summary endpoint provides daily breakdown trends and category distribution percentages.
4. **Offline Resilience**:
   - Expenses and budget configurations are cached locally using encrypted secure storage.
   - Travelers can review past expenditures and logged amounts even without an active internet connection.

## Data & Security Model
- **Integer Minor Units**: All monetary values (`total_budget_minor`, `amount_minor`, `base_amount_minor`, etc.) are strictly represented as integers in minor units (e.g. $10.50 = 1050 cents, ¥3000 = 3000 yen) to eliminate floating-point arithmetic errors.
- **Trip Membership Authorization**: Enforced on all expense and budget endpoints through `TripPolicy` (`$user->trips()->where('trips.id', $trip->id)->exists()`).
- **Encrypted Local Storage**: Cached summaries and expense lists are stored securely on device.

## API Contracts
Documented in `docs/api/openapi.yaml`:
- `GET /v1/trips/{trip}/budget`: Retrieve budget configuration.
- `PUT /v1/trips/{trip}/budget`: Set or update total and daily target budgets.
- `GET /v1/trips/{trip}/expenses`: List trip expenses with optional category and date filters.
- `POST /v1/trips/{trip}/expenses`: Record a new expense.
- `GET /v1/trips/{trip}/expenses/summary`: Aggregated spending analytics and budget tracking.
- `GET /v1/expenses/{expense}`: Retrieve single expense details.
- `PATCH /v1/expenses/{expense}`: Update an expense.
- `DELETE /v1/expenses/{expense}`: Remove an expense.

## Verification
- **Backend Tests**:
  - `TripBudgetTest.php` (5 tests covering creation, update, authorization, and validation).
  - `TripExpenseTest.php` (6 tests covering creation, foreign currency conversion, filtering, summary analytics, and deletion).
  - 108/108 PostgreSQL feature tests passing.
- **Mobile Tests**:
  - `expense_test.dart` (6 tests covering models, repository, `TripExpensesPage`, and `AddExpenseBottomSheet`).
  - 114/114 mobile unit and widget tests passing.
- **Code Standards**:
  - Laravel Pint: 0 style issues.
  - Flutter Analyze: 0 analyzer issues.
