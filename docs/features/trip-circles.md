# Trip Circles — Travel Together

- Milestone: `M10 (Trip Circles Slice 1 & Slice 2)`
- Status: `implemented` (Shareable Invite Links, Targeted Friend Code Invites, Circle Inbox, Member Roles, Two-Party Ownership Transfer & Shared Activity Feed UI)
- Owner: `engineering`
- Last verified: `2026-11-10`

## Purpose and traveler outcome

Enables trip organizers to invite friends, partners, and family into a single shared trip workspace (`trip_members`) via expiring, bounded-use invite links or privacy-safe Traveler Friend Codes (`TRP-XXXXXX`), review incoming invitations and organizer handovers inside an in-app Circle Inbox, manage member roles (`owner`, `editor`, `viewer`) and ownership transfer safely, and follow shared trip moments chronologically via the Circle Activity Feed.

## How it works

1. **Shareable Invite Links & Hashing (`POST /api/v1/trips/{trip}/invitations`)**:
   - Organizers select a proposed role (`viewer` or `editor`), max uses (`1–25`), and expiry (`1–30` days).
   - The API generates a CSPRNG token and stores only its SHA-256 hash (`token_hash`). The plaintext token is returned once on creation and omitted on all subsequent list queries.
2. **Targeted Direct Invitations via Friend Code (`POST /api/v1/trips/{trip}/invitations/direct`)**:
   - Every user receives an auto-assigned unique `friend_code` (`TRP-XXXXXX`, rotatable via `POST /me/friend-code/regenerate`) and an `accepts_direct_invites` opt-out toggle in Profile (`TC-2.1`).
   - Organizers can send direct invitations without public email search; missing codes, self-invites, disabled direct-invite preferences, and blocked organizers all return the same generic validation error to prevent enumeration (`TC-2.3`). Duplicate retries return the existing active pending invitation cleanly.
3. **Circle Inbox (`GET /me/invitations`, `POST /me/invitations/{invitation}/accept|decline`)**:
   - Pending direct invites appear only in the targeted recipient's Circle Inbox (`/invitations/inbox`) and grant zero trip membership or schedule visibility until accepted (`TC-1.6`, `TC-2.2`).
   - Declining supports optional sender blocking (`block_sender: true` -> `user_blocks`), and declined/revoked/expired invitations cannot be accepted later (`TC-2.4`).
   - Offline inbox reads use encrypted local cache with mutations disabled until reconnected.
4. **Safe Link Preview & Membership Admission (`GET /invitations/{token}`, `POST /invitations/{token}/accept`)**:
   - Opening or previewing an invitation link reveals only `trip_title`, `destination_country`, `proposed_role`, `inviter_name`, `expires_at`, and `status` (`TC-1.4`, `TC-1.9`) — excluding dates, itinerary stops, stays, expenses, and member emails.
   - Accepting locks the invitation (`lockForUpdate()`), enforces expiry/revocation/max uses atomically, restores soft-deleted memberships cleanly on rejoin, handles duplicate accepts idempotently, and emits a privacy-safe `member_joined` event.
5. **Two-Party Ownership Transfer & Account Deletion Guard (`TC-3.3`, `TC-3.4`)**:
   - Organizers can offer ownership transfer to an accepted companion (`POST /trips/{trip}/ownership-transfer`, choosing `former_owner_role` `editor` or `viewer`) and cancel pending offers (`DELETE /trips/{trip}/ownership-transfer/{transfer}`).
   - Recipients explicitly accept or decline in their Circle Inbox (`POST /me/ownership-transfers/{transfer}/accept|decline`); acceptance atomically locks and updates `trips.owner_id`, member roles, `version`, and records `ownership_transferred` activity so exactly one organizer exists under concurrent operations.
   - Account deletion (`DELETE /api/v1/me`) blocks organizers of shared trips (`422`) until ownership is transferred or shared trips are deleted, while cleaning up solo trips safely.
6. **Role, Sync & Cache Isolation (`TC-3.1`, `TC-3.2`)**:
   - Active accepted membership (`invitation_status = 'accepted'`) is enforced across trip endpoints, journal requests/controllers, and `SyncService`.
   - Downgraded or removed members cannot apply stale offline writes on `/sync/push`; rejected operations are retained with explanation in the mobile outbox rather than silently discarded. Removed members immediately lose access across endpoints and global `/sync/pull`, and local caches are purged on HTTP 403 (`TC-1.7`).
7. **Mobile UI**:
   - `TripCirclePage` provides an **Activity Feed** tab and **Members & Invites** tab supporting both Share Links and Friend Code direct invites, pending handover banner cancellation, member role updates, ownership transfer initiation, and leave/removal flows.
   - `CircleInboxPage` displays incoming invitations (with decline-and-block), ownership handover offers, offline state guards, and actionable empty state.
   - `ProfilePage` lets travelers view, copy, rotate, or disable their `Friend Code`; `JoinTripSheet` supports invite link/code lookup and joining.

## Architecture and contracts

- ADRs:
  - [`docs/decisions/0004-trip-circles-invitations-and-membership.md`](../decisions/0004-trip-circles-invitations-and-membership.md)
  - [`docs/decisions/0005-trip-circles-targeted-invites-and-ownership-transfer.md`](../decisions/0005-trip-circles-targeted-invites-and-ownership-transfer.md)
- OpenAPI: [`docs/api/openapi.yaml`](../api/openapi.yaml) (`listTripCircleMembers`, `updateTripCircleMemberRole`, `removeOrLeaveTripCircleMember`, `listTripInvitations`, `createTripInvitation`, `createDirectTripInvitation`, `revokeTripInvitation`, `previewTripInvitation`, `acceptTripInvitation`, `listIncomingInvitations`, `acceptDirectInvitation`, `declineDirectInvitation`, `getPendingOwnershipTransfer`, `initiateOwnershipTransfer`, `cancelOwnershipTransfer`, `listIncomingOwnershipTransfers`, `acceptOwnershipTransfer`, `declineOwnershipTransfer`, `regenerateFriendCode`, `getTripActivityFeed`)
- Migrations:
  - [`2026_11_10_030000_create_trip_invitations_table.php`](../../api/database/migrations/2026_11_10_030000_create_trip_invitations_table.php)
  - [`2026_11_10_040000_add_trip_circles_slice2_tables.php`](../../api/database/migrations/2026_11_10_040000_add_trip_circles_slice2_tables.php)

## Known limitations & next slices

- Multi-device conflict resolution UX enhancements (`TC-4`), organizer announcements (`TC-5`), managed child profiles (`TC-6`), and live location sharing (`TC-9`) remain deferred to subsequent approved slices.
- OS universal links (`tapittrip.com` or custom app-link hosts) are intentionally omitted until domain ownership is approved; shareable invite codes work directly in-app and respect `INVITE_LINK_BASE_URL` when configured.

## Testing and verification

- Backend Feature Tests: [`api/tests/Feature/TripCircleTest.php`](../../api/tests/Feature/TripCircleTest.php) — **9 tests passed (89 assertions)** covering organizer/editor/viewer/stranger isolation, SHA-256 token hashing, safe preview redaction, atomic concurrency/max-uses, idempotent retries, expired/revoked tokens, soft-delete rejoin, sole-owner leave block, and pending membership isolation.
- Mobile Tests: [`client/test/trip_circle_test.dart`](../../client/test/trip_circle_test.dart) — model parsing, URL token extraction, 403 cache cleanup, `TripCirclePage` organizer & viewer flows, and `JoinTripSheet` lookup & join.

