# Checklists & Packing Management

- Milestone: `M4`
- Status: `implemented`
- Owner: `engineering`
- Last verified: `2026-11-06`

## Purpose and traveler outcome

Travelers often worry about leaving behind vital travel documents, prescription medicine, power adapters, or clothing. Checklists & Packing Management enables travelers to create customized packing lists, bootstrap from pre-built starter packs (International Essentials, Tech Gear, Clothing, Toiletries), and check off items in real-time with instant optimistic feedback, offline caching, and category filtering.

## How it works

1. **Accessing Checklists**: Inside any trip view, the traveler taps the **Checklists** tab.
2. **Starter Packs**: If no checklist exists, a clean empty state offers one-tap starter pack templates:
   - *Trip Packing Essentials*: 31-item comprehensive pack across all categories.
   - *International Essentials*: 10 items (Passport, travel cards, universal adapter, medications).
   - *Electronics & Tech*: 7 items (chargers, power bank, noise-cancelling headphones, cables).
   - *Clothing & Apparel*: 7 items (tops, shorts, walking shoes, rain jacket).
   - *Toiletries & Health*: 7 items (TSA liquids, dental care, sun protection, first aid).
3. **Item Checkoff**: Tapping any item instantly toggles its packed status with tactile visual feedback (checkbox check, strikethrough typography, progress bar increment).
4. **Category Filtering**: Horizontal chips filter items by category (All, Documents, Clothing, Electronics, Toiletries, Health, Gear, Other) showing live item counts.
5. **Adding & Editing**: Travelers can add items with quantity steppers (- / +) and optional notes, edit item details, or delete items.

## Architecture and data flow

- **Mobile Client**:
  - `ChecklistRepository`: Loads from and saves to `FlutterSecureStorage` cache (`cached_checklists_${tripId}`), falling back to offline cache on network interruptions.
  - `ChecklistListNotifier`: Riverpod `AsyncNotifier` managing state with optimistic updates for instant checkoff and background server reconciliation.
  - UI: `ChecklistsView`, `ChecklistProgressCard`, `ChecklistCategoryTabs`, `ChecklistItemTile`, `AddChecklistItemBottomSheet`, `ChecklistTemplateDialog`.
- **Backend API**:
  - Modular monolith Application Services under `app/Application/Checklists/Services/`:
    - `GetTripChecklistsService`, `CreateChecklistService`, `ApplyChecklistTemplateService`, `CreateChecklistItemService`, `ToggleChecklistItemService`, `UpdateChecklistItemService`, `DeleteChecklistItemService`, `DeleteChecklistService`.
  - Eloquent Models: `Checklist` and `ChecklistItem` with UUID primary keys and foreign keys cascading on delete.
  - Database migrations: `2026_11_06_060000_create_checklists_table.php` and `2026_11_06_060100_create_checklist_items_table.php`.

## API contract

- Documented in `docs/api/openapi.yaml`:
  - `GET /api/v1/trips/{trip}/checklists` (`getTripChecklists`)
  - `POST /api/v1/trips/{trip}/checklists` (`createTripChecklist`)
  - `POST /api/v1/trips/{trip}/checklists/apply-template` (`applyChecklistTemplate`)
  - `GET /api/v1/checklists/{checklist}` (`getChecklist`)
  - `DELETE /api/v1/checklists/{checklist}` (`deleteChecklist`)
  - `POST /api/v1/checklists/{checklist}/items` (`createChecklistItem`)
  - `PATCH /api/v1/checklist-items/{item}` (`updateChecklistItem`)
  - `POST /api/v1/checklist-items/{item}/toggle` (`toggleChecklistItem`)
  - `DELETE /api/v1/checklist-items/{item}` (`deleteChecklistItem`)

## Security and privacy

- Enforces strict trip membership authorization via `TripPolicy` (`Gate::authorize('view', $trip)` and `Gate::authorize('update', $trip)`).
- Cross-trip denial tested: unauthorized users cannot list, view, toggle, or modify checklists or items belonging to other travelers.

## Offline and conflict behavior

- Mobile client reads from local secure storage cache before network response.
- Item toggling applies optimistically in memory and local storage, ensuring responsiveness even in airplane cabins or underground subways.
- When the network reconnects, background sync reconciles item version numbers.

## Testing and acceptance evidence

- **Backend Tests**: `api/tests/Feature/ChecklistTest.php` (5 tests, 53 assertions). Full PostgreSQL suite: 62/62 tests passing.
- **Mobile Tests**: `client/test/checklist_test.dart` (8 tests). Full Flutter suite: 65/65 tests passing.
