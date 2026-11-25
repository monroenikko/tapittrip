# ADR 0009: Trip Circles Temporary Opt-In Location Sharing & Meeting Assistance

- **Status**: Accepted
- **Date**: 2026-11-11
- **Extends**: [`0008-trip-circles-group-expense-splits-and-currency-snapshots.md`](0008-trip-circles-group-expense-splits-and-currency-snapshots.md)
- **Context**: `MASTER_PLAN.md` Section 14C Step 9 (`TC-9.1`–`TC-9.4`) defines optional, privacy-first temporary location sharing and meeting assistance among trip circle members.

## Decisions

### 1. Opt-In by Default & Explicit Consent (`TC-9.1`, `TC-9.3`)
- **Off by Default**: Location sharing is strictly disabled by default (`enabled: false`).
- **Explicit Consent & Lifecycle**:
  - Starts only after explicit per-person consent, audience selection (`circle` or `organizer_only`), and duration selection (`60`, `240`, `480`, `1440` minutes).
  - Child and managed traveler profiles (`TripTraveler`) cannot have location sharing enabled on their behalf; only consenting registered user accounts can share their own coordinates.
  - Denying permission leaves all regular trip features fully usable.
- This first mobile slice accepts an explicitly entered map pin; it does not request device GPS permission or run background location collection. The UI states that limit rather than inventing a current location.

### 2. Auto-Expiry, Stale Detection & Member Removal (`TC-9.2`)
- **Expiration**: Each active location share has an explicit `expires_at` timestamp based on selected duration. Once `expires_at` passes, the share is immediately expired and inactive.
- **Stale State Display**: Locations report `last_shared_at` and `is_stale` (when updates > 15 minutes old). The system never makes a "live" claim when a timestamp is old or the user is offline.
- **Revocation on Member Departure**: Stopping sharing, expiration, or circle departure/removal immediately ceases server-authorized sharing and prevents circle members from fetching coordinates.

### 3. Honest Meeting Assistance & Map Handoff (`TC-9.4`)
- No fabricated ETAs, route safety ratings, or synthetic GPS pings.
- Coordinates provide honest map-handoff capabilities (directions to current position or shared meeting point).
- Background/terminated-app limits are explicitly communicated in the UI.

## Data Model & API Surface
- Table `trip_location_shares`:
  - `id` (UUID PK), `trip_id` (FK trips), `user_id` (FK users), `enabled` (boolean), `duration_minutes` (integer), `expires_at` (timestampTz), `audience` (string), `latitude` (decimal 10,7), `longitude` (decimal 10,7), `last_shared_at` (timestampTz), `timestamps`.
  - A member-removal record is physically deleted. Manually stopping clears stored coordinates and expiry data, retaining only non-sensitive disabled settings.
  - Unique constraint on `['trip_id', 'user_id']`.
- Endpoints:
  - `GET /api/v1/trips/{trip}/location-share`: Current user's sharing settings and active state.
  - `POST /api/v1/trips/{trip}/location-share`: Enable sharing with an explicit `true` consent flag, one supported duration (`60`, `240`, `480`, or `1440` minutes), audience, and a complete coordinate pair.
  - `PATCH /api/v1/trips/{trip}/location-share`: Update sharing (toggle off/on, update coordinates).
  - `GET /api/v1/trips/{trip}/location-shares`: Active sharing coordinates of circle members visible to the requester.

