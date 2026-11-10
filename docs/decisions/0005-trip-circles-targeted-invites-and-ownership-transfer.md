# ADR 0005: Trip Circles Targeted Invitations, Ownership Transfer & Account Orphan Guard

- **Status**: Accepted
- **Date**: 2026-11-10
- **Extends**: [`0004-trip-circles-invitations-and-membership.md`](0004-trip-circles-invitations-and-membership.md)
- **Context**: `MASTER_PLAN.md` Section 14C Steps 2–3 (`TC-2`, `TC-3`) require organizer-initiated targeted invitations without a public email directory, explicit in-app recipient inbox accept/decline/block controls, strict viewer/editor/removed enforcement across HTTP and sync, explicit two-party ownership transfer, and protection against orphaning shared trips on account deletion.

## Decisions

### 1. Privacy-Preserving Friend Codes (`TC-2.1`, `TC-2.3`)
- **Non-Searchable Identifier**: Each user receives a server-generated unique uppercase `friend_code` (`TRP-XXXXXX` using an unambiguous 32-character alphabet `23456789ABCDEFGHJKLMNPQRSTUVWXYZ`) stored on `users.friend_code` and exposed only to the account owner (`GET /api/v1/me`, auth payloads).
- **Opt-Out & Rotation**: Users can regenerate their friend code (`POST /api/v1/me/friend-code/regenerate`) and toggle `users.accepts_direct_invites` (`PATCH /api/v1/me`, default `true`). Targeted invitations never query by email address.
- **Abuse & Block Controls (`user_blocks`)**: Recipients declining a direct invitation may pass `block_sender: true`, creating a `(blocker_id, blocked_id)` row in `user_blocks`.
- **Uniform Anti-Enumeration Failure**: Unknown friend codes, self-targeting, recipients with `accepts_direct_invites = false`, and blocked organizers all return the exact same `422` validation error (`friend_code: "Unable to deliver invitation to that identifier. Please check the friend code and try again."`), revealing neither account existence nor block status (`TC-2.3`). Already-accepted trip members return a trip-scoped error since the organizer already has visibility into current circle members.

### 2. Targeted Direct Invitations & Recipient Inbox (`TC-2.2`, `TC-2.4`)
- **Unified `trip_invitations` Lifecycle**:
  - `invite_type` distinguishes `'link'` (token-bearing) from `'direct'` (account-targeted).
  - `token_hash` is nullable (unique when non-null for `'link'`; `null` for `'direct'`). `target_user_id` and `responded_at` track the recipient and response timestamp.
  - Direct invitations start with `status = 'pending'`, are never returned by or redeemable through public `/invitations/{token}` routes, and do **not** create `trip_members` records until accepted (`TC-1.6`).
- **Idempotent Retries**: Resending a direct invitation for an already-pending `(trip_id, target_user_id)` invite updates/returns the existing active pending invitation cleanly without creating duplicate invites or notifications.
- **Recipient Isolation**: Only `target_user_id` sees the invitation in `GET /api/v1/me/invitations` and can call `POST /api/v1/me/invitations/{invitation}/accept` or `/decline` (`403` for any other authenticated user). Declined, revoked, or expired invitations cannot later grant membership (`422`).
- **Offline Semantics**: Acceptance and declination require server confirmation; offline clients cache the last-known inbox for read-only visibility and disable accept/decline mutations until online.

### 3. Explicit Two-Party Ownership Transfer (`TC-3.3`)
- **Dedicated `trip_ownership_transfers` Table**: Stores `trip_id`, `from_user_id`, `to_user_id`, `former_owner_role` (`'editor'` or `'viewer'`), `status` (`'pending'`, `'accepted'`, `'declined'`, `'cancelled'`, `'expired'`), `expires_at`, and `responded_at`.
- **Eligibility**: Only the active organizer (`owner`) can initiate (`POST /api/v1/trips/{trip}/ownership-transfer`) or cancel (`DELETE /api/v1/trips/{trip}/ownership-transfer/{transfer}`) a handover, and only for an accepted non-owner circle member (`invitation_status = 'accepted'`, non-deleted). Retrying for the same target & former role is idempotent.
- **Atomic Acceptance**: The target companion explicitly confirms (`POST /api/v1/me/ownership-transfers/{transfer}/accept`) or declines (`.../decline`). Acceptance acquires `lockForUpdate()` on the transfer, trip, and active member rows, re-verifies `from_user_id === trip.owner_id` and target membership, updates `trips.owner_id`, promotes target `TripMember.role` to `'owner'`, assigns former owner `TripMember.role = former_owner_role`, increments `trips.version`, cancels stale pending transfers on the trip, and emits a safe `ownership_transferred` activity feed event.

### 4. Account Deletion Orphan Guard & Sync Rejection Visibility (`TC-3.1`, `TC-3.2`, `TC-3.4`)
- **Orphan Protection (`DELETE /api/v1/me`)**: Inside an atomic transaction locking owned `trips` rows, if the user still owns any active trip with at least one other accepted `TripMember`, account deletion is blocked (`422`) until ownership is transferred or those shared trips are deleted. If the user owns only solo trips (no other accepted members), solo trips and outgoing/incoming pending invites/transfers and companion memberships are soft-deleted alongside tokens and the user account.
- **Sync Hardening**: Removed members cannot pull previously touched trip operations even via unscoped `GET /api/v1/sync/pull`, and downgraded/removed writes rejected by `SyncService::push()` are retained in the mobile client's `OutboxStorage` with `status = 'rejected'` and the server's explanation rather than being silently deleted (`TC-3.2`). Journal requests/controllers enforce `$trip->hasMember()` (`invitation_status = 'accepted'`).

## Consequences
- Existing link-based invitations (`TC-1`) remain backward-compatible because `'link'` defaults remain intact.
- Two-party handover guarantees a single organizer invariant under concurrent leave, removal, transfer, and account deletion requests.

