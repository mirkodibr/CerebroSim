# Firestore Security Rules: Production Audit

## 1. Identified Collections
*   **`users/{uid}/snapshots/`**: Contains private research history and simulation snapshots for individual users.
*   **`public_snapshots/`**: A global collection for snapshots shared with the community.

## 2. Security Vulnerability Assessment
*   **Initial State (Test Mode)**: Most Firebase projects start with "Test Mode" rules that allow any unauthenticated user to read/write all data (`allow read, write: if true;`). This is a critical vulnerability that would allow data theft or corruption.
*   **Production Transition**: We have transitioned to granular, identity-based rules to ensure data integrity and privacy.

## 3. Implemented Logic (Production Rules)

### Private Research History
*   **Collection**: `/users/{userId}/snapshots/{snapshotId}`
*   **Logic**: A user can only access this collection if they are authenticated AND their `uid` matches the `{userId}` in the path.
*   **Benefit**: Ensures that one researcher cannot view or modify the experiments of another.

### Public Community Gallery
*   **Collection**: `/public_snapshots/{snapshotId}`
*   **Read Access**: Any authenticated user can browse the public gallery.
*   **Create Access**: Any authenticated user can share a snapshot, but the rule verifies that the `userId` field in the document matches the sender's `uid`.
*   **Delete Access**: Only the original uploader (the owner) can remove their snapshot from the public gallery.
*   **Update Access**: Disabled. Public snapshots are considered immutable records of a specific simulation state.

## 4. Validation Plan
*   [x] Attempt to read another user's private snapshot: **Expect Permission Denied**.
*   [x] Attempt to write to `public_snapshots` without authentication: **Expect Permission Denied**.
*   [x] Attempt to delete a public snapshot owned by someone else: **Expect Permission Denied**.
