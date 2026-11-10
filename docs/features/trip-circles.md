# Trip Circles — Travel Together

- Milestone: `M10 (Trip Circles Slice 1)`
- Status: `implemented` (Private Invite Links, Member Role Management & Shared Activity Feed UI)
- Owner: `engineering`
- Last verified: `2026-11-10`

## Purpose and traveler outcome

Enables trip organizers to invite friends, partners, and family into a single shared trip workspace (`trip_members`) via expiring, bounded-use invite links, manage member roles (`owner`, `editor`, `viewer`), and follow shared trip moments chronologically via the Circle Activity Feed.

## How it works

1. **Invitation Generation & Hashing (`POST /api/v1/trips/{trip}/invitations`)**:
   - Organizers select a proposed role (`viewer` or `editor`), max uses (`1–25`), and expiry (`1–30` days).
   - The API generates a CSPRNG token and stores only its SHA-256 hash (`token_hash`). The plaintext token is returned once on creation and omitted on all subsequent list queries.
2. **Safe Preview & Membership Admission (`GET /invitations/{token}`, `POST /invitations/{token}/accept`)**:
   - Opening or previewing an invitation link reveals only `trip_title`, `destination_country`, `proposed_role`, `inviter_name`, `expires_at`, and `status` (`TC-1.4`, `TC-1.9`) — excluding dates, itinerary stops, stays, expenses, and member emails.
   - Accepting requires authentication (`auth:sanctum`), locks the invitation row (`lockForUpdate()`), enforces expiry/revocation/max uses atomically, restores soft-deleted memberships cleanly on rejoin, handles duplicate accepts idempotently, and emits a privacy-safe `member_joined` event on the shared activity feed.
3. **Member Roles, Removal & Leaving (`GET/PATCH/DELETE /trips/{trip}/members`)**:
   - Only active accepted members (`invitation_status = 'accepted'`) can read trip resources or feed events (`TC-1.6`).
   - Only organizers (`owner`) can change member roles (`viewer` ↔ `editor`) or remove companions. Non-owners can leave voluntarily; sole organizers cannot leave without deleting the trip (`TC-3.4`).
   - On HTTP 403 revocation, the mobile client purges local trip circle, feed, journal, recap, and itinerary caches immediately (`TC-1.7`).
4. **Mobile UI**:
   - `TripCirclePage` provides an **Activity Feed** tab (chronological moments & joins) and a **Members & Invites** tab (organizer invite link generator, copy button, active invite revocation, role switcher, leave/remove flows).
   - `JoinTripSheet` lets travelers paste an invite URL or token from the Trips screen, preview trip metadata, and join in one tap.

## Architecture and contracts

- ADR: [`docs/decisions/0004-trip-circles-invitations-and-membership.md`](../decisions/0004-trip-circles-invitations-and-membership.md)
- OpenAPI: [`docs/api/openapi.yaml`](../api/openapi.yaml) (`listTripCircleMembers`, `updateTripCircleMemberRole`, `removeOrLeaveTripCircleMember`, `listTripInvitations`, `createTripInvitation`, `revokeTripInvitation`, `previewTripInvitation`, `acceptTripInvitation`, `getTripActivityFeed`)
- Migration: [`2026_11_10_030000_create_trip_invitations_table.php`](../../api/database/migrations/2026_11_10_030000_create_trip_invitations_table.php)

## Known limitations & next slices

- Targeted friend-code / username invitations (`TC-2`), two-party ownership transfer (`TC-3.3`), organizer announcements (`TC-5`), and managed child profiles (`TC-6`) remain deferred to subsequent approved slices.
- OS universal links (`tapittrip.com` or custom app-link hosts) are intentionally omitted until domain ownership is approved; shareable invite codes work directly in-app and respect `INVITE_LINK_BASE_URL` when configured.

## Testing and verification

- Backend Feature Tests: [`api/tests/Feature/TripCircleTest.php`](../../api/tests/Feature/TripCircleTest.php) — **9 tests passed (89 assertions)** covering organizer/editor/viewer/stranger isolation, SHA-256 token hashing, safe preview redaction, atomic concurrency/max-uses, idempotent retries, expired/revoked tokens, soft-delete rejoin, sole-owner leave block, and pending membership isolation.
- Mobile Tests: [`client/test/trip_circle_test.dart`](../../client/test/trip_circle_test.dart) — model parsing, URL token extraction, 403 cache cleanup, `TripCirclePage` organizer & viewer flows, and `JoinTripSheet` lookup & join.

