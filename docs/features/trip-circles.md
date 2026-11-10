# Trip Circles — Travel Together

- Milestone: `M10 (Trip Circles Slices 1–4)`
- Status: `implemented` (Shareable Invite Links, Targeted Friend Code Invites, Circle Inbox, Ownership Transfer, Conflict Resolution, Announcements, Managed Traveler Profiles & Collaborative Checklist Assignments)
- Owner: `engineering`
- Last verified: `2026-11-10`

## Purpose and traveler outcome

Enables trip organizers to invite friends, partners, and family into a single shared trip workspace (`trip_members`) via expiring, bounded-use invite links or privacy-safe Traveler Friend Codes (`TRP-XXXXXX`), review incoming invitations and organizer handovers inside an in-app Circle Inbox, manage member roles (`owner`, `editor`, `viewer`) and ownership transfer safely, follow shared trip moments chronologically via the Circle Activity Feed, add minimal managed traveler profiles (children/dependents without accounts), and collaborate on packing checklists with clear responsibility and offline resilience.

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
7. **Managed Traveler Profiles (`TC-6.3`, `GET/POST /api/v1/trips/{trip}/travelers`, `PATCH/DELETE /api/v1/travelers/{traveler}`)**:
   - Organizers and editors can add lightweight companion/dependent profiles (`child`, `infant`, `adult`, `companion`) without user accounts, credentials, location sharing, or document sharing.
   - Optional `restricted_notes` are encrypted at rest via Laravel `encrypted` casting and returned (`restricted_notes`, `can_edit`, `can_delete`) solely to the `managing_user_id`; all other members receive `restricted_notes: null` and `403` on direct edit/delete attempts. Removing the managing adult clears dependent checklist assignments and soft-deletes their managed travelers atomically.
8. **Collaborative Checklist Assignments & Offline Completion (`TC-6.1`, `TC-6.2`)**:
   - Checklist items accept an exclusive assignee (`assigned_user_id` for accepted trip members or `assigned_traveler_id` for single-trip managed travelers, never both), completion attribution (`completed_by_user_id`, `completed_by_name`), and `base_version` optimistic concurrency (`409 version_conflict`).
   - `viewer` members can toggle pack status strictly on items assigned to them (`assigned_user_id === viewer->id`, via `POST /checklist-items/{item}/toggle` or `is_packed`-only `sync/push` updates) without gaining edit/delete access or altering itinerary/visit state.
   - Mobile `ChecklistsView`, `AddChecklistItemBottomSheet`, `ChecklistItemTile`, and `ManagedTravelersSection` provide assignee dropdowns/filters, manager-scoped private traveler notes, viewer completion-only guards, durable `OutboxStorage` offline queues across app restart, and `403` cache purging (`cached_checklists_{tripId}`, `cached_travelers_{tripId}`).

## Architecture and contracts

- ADRs:
  - [`docs/decisions/0004-trip-circles-invitations-and-membership.md`](../decisions/0004-trip-circles-invitations-and-membership.md)
  - [`docs/decisions/0005-trip-circles-targeted-invites-and-ownership-transfer.md`](../decisions/0005-trip-circles-targeted-invites-and-ownership-transfer.md)
  - [`docs/decisions/0006-trip-circles-sync-conflicts-and-announcements.md`](../decisions/0006-trip-circles-sync-conflicts-and-announcements.md)
  - [`docs/decisions/0007-trip-circles-managed-travelers-and-checklists.md`](../decisions/0007-trip-circles-managed-travelers-and-checklists.md)
- OpenAPI: [`docs/api/openapi.yaml`](../api/openapi.yaml) (`listTripCircleMembers`, `updateTripCircleMemberRole`, `removeOrLeaveTripCircleMember`, `listTripInvitations`, `createTripInvitation`, `createDirectTripInvitation`, `revokeTripInvitation`, `previewTripInvitation`, `acceptTripInvitation`, `listIncomingInvitations`, `acceptDirectInvitation`, `declineDirectInvitation`, `getPendingOwnershipTransfer`, `initiateOwnershipTransfer`, `cancelOwnershipTransfer`, `listIncomingOwnershipTransfers`, `acceptOwnershipTransfer`, `declineOwnershipTransfer`, `regenerateFriendCode`, `getTripActivityFeed`, `listTripAnnouncements`, `createTripAnnouncement`, `updateTripAnnouncement`, `deleteTripAnnouncement`, `listTripTravelers`, `createTripTraveler`, `updateTripTraveler`, `deleteTripTraveler`, `listUserNotifications`, `markUserNotificationRead`, checklist assignee/attribution fields, and `409 version_conflict` on itinerary/reorder/stays/announcements/checklists/travelers)
- Migrations:
  - [`2026_11_10_030000_create_trip_invitations_table.php`](../../api/database/migrations/2026_11_10_030000_create_trip_invitations_table.php)
  - [`2026_11_10_040000_add_trip_circles_slice2_tables.php`](../../api/database/migrations/2026_11_10_040000_add_trip_circles_slice2_tables.php)
  - [`2026_11_10_050000_add_trip_circles_slice3_tables.php`](../../api/database/migrations/2026_11_10_050000_add_trip_circles_slice3_tables.php)
  - [`2026_11_10_060000_add_trip_circles_slice4_tables.php`](../../api/database/migrations/2026_11_10_060000_add_trip_circles_slice4_tables.php)

## Known limitations & next slices

- Shared group expense splits/balances (`TC-7` / Slice 5) and live opt-in location sharing (`TC-9`) remain deferred to future approved slices.
- OS universal links (`tapittrip.com` or custom app-link hosts) are intentionally omitted until domain ownership is approved; shareable invite codes work directly in-app and respect `INVITE_LINK_BASE_URL` when configured.

## Testing and verification

- Backend Feature Tests:
  - [`api/tests/Feature/TripCircleTest.php`](../../api/tests/Feature/TripCircleTest.php) — invite links, friend codes, ownership handovers, account orphan guard, and sync/journal role isolation.
  - [`api/tests/Feature/TripCollaborationSlice3Test.php`](../../api/tests/Feature/TripCollaborationSlice3Test.php) — `TC-4` & `TC-5`: multi-editor propagation, idempotent itinerary/stay offline sync + cross-trip isolation, `409 version_conflict` on itinerary/reorder/stays, non-owner stay redaction (`booking_reference`, `phone`, `friends_family` private address), organizer announcements without push devices + edit/retry deduplication, `destination` vs `home` quiet-hours evaluation, automatic reminder rescheduling/cancellation, and removed-member notification cancellation.
  - [`api/tests/Feature/TripCollaborationSlice4Test.php`](../../api/tests/Feature/TripCollaborationSlice4Test.php) — `TC-6`: exclusive checklist assignments to accepted members and managed travelers, automatic unassignment and cleanup when members or travelers are removed, `viewer` completion-only authorization + offline sync isolation + `409 version_conflict` checks, and `trip_travelers` encrypted/redacted `restricted_notes` lifecycle.
- Mobile Tests:
  - [`client/test/trip_circle_test.dart`](../../client/test/trip_circle_test.dart) — model parsing, URL token extraction, 403 cache cleanup, `TripCirclePage`, `CircleInboxPage`, and `JoinTripSheet`.
  - [`client/test/trip_circle_slice3_test.dart`](../../client/test/trip_circle_slice3_test.dart) — offline outbox queueing, `409` conflict recording, multi-conflict selector sheet & `ConflictResolutionDialog`, full per-trip cache + reminder purge isolation, redacted `StayCard`, `CircleAnnouncementsSection`, `CircleNoticesSection`, and `NotificationPreferencesPage` announcement/timezone controls.
  - [`client/test/trip_circle_slice4_test.dart`](../../client/test/trip_circle_slice4_test.dart) — `TC-6` checklist assignment picker & filters, `viewer` completion-only UI & API guard, offline checklist completion restart persistence in `OutboxStorage`/cache, `409` conflict & `403` cache purge, and `ManagedTravelersSection` privacy redaction & creation flow.

