# Firestore Security & Data Integrity

## Architecture
The Research Vault utilizes a dual-write pattern to ensure that experiments are both privately archived and publicly shareable.

## Atomic Operations
All experiment saves MUST use `FirebaseFirestore.instance.batch()` to ensure atomicity. 
A single `saveSnapshot` call performs the following operations:
1.  Creates a new document in `users/{uid}/snapshots/`.
2.  Updates the `lastSnapshotAt` field in `users/{uid}/` for rate limiting.
3.  (Optional) Creates a new document in `public_snapshots/` if `isPublic` is true.

### Rollback Behavior
If any of the above operations fail (e.g., due to security rule violations or network errors), the ENTIRE batch is rolled back by Firestore. This prevents "partial saves" where an experiment might be public but missing from the user's private history, or vice versa.

## Security Rules
The `firestore.rules` file enforces:
- **Ownership:** Users can only read/write their own `users/{uid}` documents.
- **Validation:** snapshots must contain valid `synapticWeights`, `finalErrorRate` (0.0-1.0), and a `taskName` enum.
- **Rate Limiting:** Users are restricted to one snapshot every 60 seconds to prevent gallery flooding.
- **AI Rate Limiting:** AI interpretation is limited to 20 calls per user per day. Usage is tracked in `users/{uid}/usage/{YYYY-MM-DD}`.
- **Global Safety Cap:** A system-wide daily token cap is enforced to control total API costs.
- **Data Integrity:** `public_snapshots` are immutable after creation and can only be deleted by administrators.

## Manual Verification of Atomicity
To verify the rollback behavior:
1.  Temporarily modify `firestore.rules` to reject all writes to `public_snapshots`.
2.  Attempt to save a public experiment from the app.
3.  Observe that neither the private snapshot nor the public snapshot is created, confirming the batch rollback.
