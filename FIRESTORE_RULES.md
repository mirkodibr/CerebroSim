rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // User-specific snapshots
    match /users/{userId}/snapshots/{snapshotId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Public gallery
    match /public_snapshots/{snapshotId} {
      allow read: if request.auth != null;
      // Writing to public gallery should ideally be handled via a Cloud Function for security,
      // but for this lab simulation we allow clients to write their own public entries.
      // A rule could check that the userId in the document matches request.auth.uid.
      allow create: if request.auth != null && request.resource.data.userId == request.auth.uid;
      allow update, delete: if false; // Immutable public records
    }
  }
}
