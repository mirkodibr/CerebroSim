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

## App Check Enforcement
App Check protects CerebroSim from unauthorized API access by ensuring only the official app can call Cloud Functions and access Firestore.

### Console Configuration
1.  **Register App Check:** In the Firebase Console, go to App Check > Apps.
2.  **Configure Providers:**
    - **Android:** Register your SHA-256 fingerprint with the **Play Integrity** provider.
    - **iOS:** Configure the **DeviceCheck** or **App Attest** provider.
    - **Web:** Register your domain and configure the **reCAPTCHA v3** provider.
3.  **Enable Enforcement:**
    - **Cloud Functions:** Enforcement is enabled in code via `enforceAppCheck: true`.
    - **Firestore:** In the App Check console, go to the "APIs" tab and click "Enforce" for Cloud Firestore.

### Local Development
In debug mode (`kDebugMode`), the app uses the App Check **Debug Provider**. 
- On Android/iOS, look for the "App Check debug token" in the console output and register it in the Firebase Console under App Check > Apps > [Your App] > Manage debug tokens.
- For Web, use the reCAPTCHA debug token configuration.

## Manual Verification of Atomicity
To verify the rollback behavior:
1.  Temporarily modify `firestore.rules` to reject all writes to `public_snapshots`.
2.  Attempt to save a public experiment from the app.
3.  Observe that neither the private snapshot nor the public snapshot is created, confirming the batch rollback.
