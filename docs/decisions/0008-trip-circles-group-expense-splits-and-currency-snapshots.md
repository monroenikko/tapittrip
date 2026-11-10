# ADR 0008: Trip Circles Group Expense Splits, Multi-Currency Rate Snapshots & Balance Privacy

- **Status**: Accepted
- **Date**: 2026-11-10
- **Extends**: [`0006-trip-circles-sync-conflicts-and-announcements.md`](0006-trip-circles-sync-conflicts-and-announcements.md)
- **Context**: `MASTER_PLAN.md` Section 14C Step 7 (`TC-7.1`–`TC-7.3`) requires auditable group expense splitting (`single`, `equal`, `selected`, `custom`), strict participant membership validation, exact integer minor-unit rounding with zero phantom balance drift, attributed exchange-rate snapshots without fabricated offline rates, strict privacy isolation of personal expenses, and offline sync/retry idempotency without claiming money was transferred.

## Decisions

### 1. Personal vs Shared Visibility & Participant Validation (`TC-7.1`, `TC-7.3`)
- **Explicit Visibility**: `expenses.visibility` (`'private'` | `'shared'`) and `created_by_user_id` separate personal trip spending from shared group ledger entries.
  - `'single'` (`Just me`) expenses default to `visibility = 'private'` and remain invisible (`403` on direct read/update/delete, omitted from list/summary/settlements/sync pull) to every other trip member unless explicitly shared (`visibility = 'shared'`).
  - `'equal'`, `'selected'`, and `'custom'` expenses default to `'shared'` and are visible to accepted trip members, while creator personal `private` totals stay scoped strictly to `$actor`.
  - Companion `email` addresses are omitted from shared expense, split, balance, and settlement payloads.
- **Exact Splits & Rounding (`ExpenseSplitCalculator`)**:
  - Accepted split modes are `'single'`, `'equal'` (all accepted members at entry time), `'selected'` (`participant_ids`), and `'custom'` (explicit `splits` with positive `amount_minor` per participant).
  - `payer_id`, `participant_ids`, `splits.*.user_id`, `itinerary_item_id`, and `stay_id` must belong to the target trip and reference active accepted members (`422` otherwise, no duplicate split participants, exact sum invariant `sum(splits.*.amount_minor) === amount_minor`).
  - Both original-currency remainders and base-currency proportional conversions distribute remaining minor units deterministically via largest-remainder allocation so `sum(splits.*.base_amount_minor) === expense.base_amount_minor` whenever converted.

### 2. Attributed Multi-Currency Snapshots & Settlement Ledger (`TC-7.2`, `TC-7.3`)
- **No Fabricated Rates**:
  - `LiveExchangeRateProvider` does not fall back to `FakeExchangeRateProvider` on HTTP errors in non-testing environments, and mobile `CurrencyRepository` removes hardcoded offline rate tables, returning an explicit unavailable state when neither network nor previously cached dated snapshots exist.
  - Foreign expenses record `rate_source` (`'identity'`, `'open_exchange_rates'`, `'cached_snapshot'`, `'user_manual'`, `'fake'`, or `'unavailable'`), `rate_captured_at`, and `conversion_status` (`'converted'` | `'unavailable'`). When unavailable, `exchange_rate` and `base_amount_minor` remain `null` and the expense is flagged in `unconverted_expenses` instead of inventing `1.0`.
- **Immutable Snapshots & Foreign Settlement Conversion**:
  - Changing trip budgets later does not silently rewrite previously snapped `base_amount_minor` balances.
  - `expense_settlements` stores `exchange_rate`, `base_amount_minor`, `rate_source`, `rate_captured_at`, `created_by_user_id`, and `client_operation_id` so settlement records in foreign currencies convert cleanly using a snapshot instead of adding incompatible integer currencies, while duplicate submission retries deduplicate cleanly.
- **Member Departure & Honest Transfer Language**:
  - Historical shared splits, expenses, and settlements of departed members remain auditable (`is_departed: true` on balances) while blocking departed users from new splits or mutations.
  - Settlements strictly record balance adjustments; API summaries and mobile dialogs explicitly disclaim actual money transfer.

### 3. Optimistic Concurrency & Offline Expense Sync (`TC-7.3`)
- `expenses` and `expense_settlements` enforce per-trip unique `client_operation_id` deduplication, `PATCH/DELETE` support `base_version` (`409 version_conflict`), and `SyncService` handles `'expense'` (`create`/`update`/`delete`) with private-expense `pull()` redaction.

## Consequences
- Existing USD/same-currency and explicit-rate flows (`TripExpenseTest`, `GroupSettlementTest`) remain backward-compatible while eliminating fabricated FX fallbacks and private expense leaks.
