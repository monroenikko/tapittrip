# Travel Documents Vault

- **Status**: Implemented
- **Milestone**: M4 / Release 1 Security & Privacy Hardening
- **Primary contracts**: [`docs/api/openapi.yaml`](../api/openapi.yaml) (`listTripDocuments`, `createTripDocument`, `updateTravelDocument`, `deleteTravelDocument`), [`MASTER_PLAN.md`](../../MASTER_PLAN.md) (Section 3 Release 1, Section 6, Section 11, Section 14C Visibility & Privacy Matrix)

## Traveler Flow

1. From **Today's Dashboard**, a traveler taps **Travel Documents Vault** (or navigates to `/trips/:tripId/documents`).
2. The vault lists all travel documents belonging to the user on that trip, plus any document summaries explicitly shared with the Trip Circle (`access_policy = circle_members`) by other accepted members.
3. Each document card displays:
   - Document type badge (`Passport Note`, `Visa Reference`, `Travel Insurance`, `Ticket / Voucher`, `Health Certificate`, or `Document`).
   - Visibility badge (`Private (Only You)` vs `Shared with Circle`).
   - Title, optional issuer/provider, and expiry date badge (`Expires on YYYY-MM-DD` or `Expired on YYYY-MM-DD`).
   - Owner-only reference number with a one-tap copy button (`Ref: ...`) and encrypted notes.
4. Tapping **Add Document** opens `AddTravelDocumentSheet`, where the traveler can save a document summary, toggle whether the summary is shared with Trip Circle members (`owner_only` by default), and store an encrypted reference number and private notes.

## Implementation & Security Behavior

- **Encryption at Rest**:
  - [`TravelDocument`](../../api/app/Models/TravelDocument.php) casts `reference_number` and `notes_private` using Laravel's `encrypted` cast so raw policy numbers, visa references, and emergency claim notes are never stored in plaintext in PostgreSQL (`travel_documents`).
- **Strict Visibility & Redaction (`MASTER_PLAN.md` Section 14C)**:
  - `access_policy` defaults to `owner_only`. Documents with `owner_only` are completely excluded from `GET /api/v1/trips/{trip}/documents` for other Circle members.
  - When `access_policy` is explicitly set to `circle_members`, other accepted Circle members can view the document summary (`display_name`, `document_type`, `issuer`, `expires_on`, `notes_private`), while [`TravelDocumentResource`](../../api/app/Http/Resources/Api/V1/TravelDocumentResource.php) strictly redacts `reference_number` (`null`) for non-owners.
  - Only the document owner (`owner_id`) can update (`PATCH /api/v1/documents/{document}`) or delete (`DELETE /api/v1/documents/{document}`) a document (`403 forbidden` otherwise).
- **Idempotency & Optimistic Concurrency**:
  - `POST /api/v1/trips/{trip}/documents` deduplicates retries by `(trip_id, owner_id, client_operation_id)`.
  - `PATCH /api/v1/documents/{document}` enforces `base_version` optimistic concurrency (`409 version_conflict`).
- **Offline Storage & Revocation Cleanup**:
  - [`TravelDocumentRepository`](../../client/lib/features/documents/data/travel_document_repository.dart) caches documents in `FlutterSecureStorage` under `cached_documents_{tripId}` for offline viewing.
  - A `403` response or Circle revocation (`TripCircleRepository.purgeAllTripCachesForStorage`) immediately deletes `cached_documents_{tripId}`.

## Verification

- Backend feature tests: [`api/tests/Feature/TravelDocumentTest.php`](../../api/tests/Feature/TravelDocumentTest.php)
- Mobile repository and widget tests: [`client/test/travel_document_test.dart`](../../client/test/travel_document_test.dart)

## Known Limitations & Direction

- The vault intentionally stores structured metadata, encrypted reference numbers, and private notes rather than raw biometric passport scans. File attachments continue to use the trip-scoped private media endpoint (`/api/v1/trips/{trip}/media`).
