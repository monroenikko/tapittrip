# ADR 0004: Trip Circles Invitations, Membership Lifecycle & Activity Visibility

- **Status**: Accepted
- **Date**: 2026-11-10
- **Context**: `MASTER_PLAN.md` Section 14C defines Trip Circles as a shared collaborative view over existing trip aggregates (`trips`, `trip_members`, itineraries, stays, expenses, journal entries, and activity feed). Step 0 (`TC-0.2`) requires an accepted architectural decision before creating invitation tables or collaboration flows.

## Decisions

### 1. Invitation Token Generation, Storage, & Safe Links
- **Token Entropy & Hashing**: Shareable invitation links use CSPRNG tokens (48 hex characters / 24 random bytes). The API hashes tokens at rest with SHA-256 (`token_hash`, unique 64-char column) and **never** persists raw tokens in PostgreSQL or logs.
- **One-Time Exposure**: The plaintext invite token and shareable link (`INVITE_LINK_BASE_URL` or app fallback `/invite/{token}`) are returned **once** inside the organizer's `POST /api/v1/trips/{trip}/invitations` response. Subsequent `GET /invitations` listings omit `token_hash` and raw tokens.
- **No Unapproved Domain Assumptions**: URL host generation uses `config('app.invite_base_url')` (`INVITE_LINK_BASE_URL`), defaulting cleanly without claiming ownership of an external web domain or mobile universal-link host. Travelers can paste either the full share URL or raw token in-app.

### 2. Invitation Constraints & Concurrency (`TC-1.4`, `TC-1.5`)
- **Proposed Roles**: Organizers can issue invitations scoped to `viewer` (default) or `editor`. Only the trip organizer (`owner`) can create, inspect, or revoke invitations.
- **Expiry & Bounded Usage**: Invitations expire after `expires_in_days` (default 7 days, bounded 1–30 days) and support `max_uses` (default `1`, bounded 1–25).
- **Atomic Redemption**: `POST /api/v1/invitations/{token}/accept` wraps checks inside a DB transaction using row locking (`lockForUpdate()`). Redemption verifies `status === 'active'`, `expires_at` in the future, and `use_count < max_uses`.
- **Safe Preview (`GET /api/v1/invitations/{token}`)**: Rate-limited preview returns **only** `trip_title`, `destination_country`, `proposed_role`, `inviter_name`, `expires_at`, and `status`. Itinerary stops, trip dates, stay addresses, expenses, emails, and member lists are strictly excluded (`TC-1.9`), and previewing never confers membership (`TC-1.4`).

### 3. Active Membership Enforcement & Soft-Delete Rejoin (`TC-1.6`, `TC-1.7`)
- **Active Status Guard**: `Trip::hasMember()`, `Trip::memberRole()`, `User::trips()`, and `SyncService` enforce `invitation_status = 'accepted'` consistently so pending, declined, or soft-deleted memberships cannot grant access.
- **Soft-Deleted Member Rejoin**: Because `(trip_id, user_id)` has a unique index on `trip_members` and models enforce universal soft deletes (`ADR 0003`), re-accepting an invitation for a previously removed or departed traveler restores the existing soft-deleted `TripMember` record atomically with the newly accepted role and `invitation_status = 'accepted'`.
- **Idempotency**: An already-accepted member redeeming an invite link receives an idempotent success (`already_member = true`) without escalating/downgrading their current role or consuming an invitation use.
- **Removed Member Cache Cleanup**: When a mobile client receives HTTP 403 on trip/circle/feed fetches after removal or revocation, it purges local secure caches for that trip and refreshes its trip roster.

### 4. Role Management & Account Leaving (`TC-3.1`, `TC-3.4`)
- **Organizer Privileges**: Only the `owner` can change companion roles (`viewer` ↔ `editor`) or remove another member. Companions receive HTTP 403 on role/member/invitation mutations.
- **Leaving vs. Sole Owner**: Non-owner companions can remove themselves (`DELETE /api/v1/trips/{trip}/members/{member}`). The sole `owner` cannot leave without deleting the trip or completing a future ownership transfer (returns `422` validation error).

### 5. Deferred Scope (Follow-up Slices)
- **Slice 2 (`TC-2`)**: Targeted in-app friend-code/username invitations and pending invitation inbox.
- **Slice 3 (`TC-3.3`)**: Explicit two-party ownership transfer and account deletion trip-orphan guard.
- **Audit Events**: Joining a trip circle records a privacy-safe `member_joined` summary via `ActivityService` for the trip activity feed (`TC-8.2`).

## Consequences
- Existing single-user trip ownership and membership checks remain 100% compatible because trip creators are automatically inserted as accepted `owner` members on creation.
- Invite redemption is strictly server-confirmed and atomic; offline invitation creation or acceptance is disallowed (`TC-1.8`).

