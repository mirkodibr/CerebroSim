import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/experiment_snapshot.dart';

/// Service for managing persistence and retrieval of [ExperimentSnapshot] data.
/// 
/// It interfaces with Google Cloud Firestore to store user experiments,
/// retrieve private history, and manage the public gallery of shared results.
class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Saves an [ExperimentSnapshot] to the Firestore database.
  /// 
  /// The snapshot is always saved to the user's private collection.
  /// If [snap.isPublic] is true, it is also saved to the 'public_snapshots'
  /// collection to make it visible to others in the gallery.
  /// Uses a [WriteBatch] to ensure atomicity of the operation.
  /// Throws a timeout error if the operation takes longer than 10 seconds.
  Future<void> saveSnapshot(ExperimentSnapshot snap) async {
    try {
      final batch = _db.batch();
      
      final userSnapRef = _db.collection('users').doc(snap.userId).collection('snapshots').doc();
      batch.set(userSnapRef, snap.toFirestore());

      if (snap.isPublic) {
        final publicSnapRef = _db.collection('public_snapshots').doc(userSnapRef.id);
        batch.set(publicSnapRef, snap.toFirestore());
      }

      await batch.commit().timeout(const Duration(seconds: 10));
    } on TimeoutException {
      throw 'Connection timed out. Please check your internet and try again.';
    } catch (e) {
      rethrow;
    }
  }

  /// Returns a [Stream] of [ExperimentSnapshot]s for a specific user.
  /// 
  /// The snapshots are ordered by [createdAt] in descending order (newest first).
  /// This provides real-time updates when the user's simulation history changes.
  Stream<List<ExperimentSnapshot>> watchUserSnapshots(String uid) {
    return _db
        .collection('users')
        .doc(uid)
        .collection('snapshots')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => ExperimentSnapshot.fromFirestore(doc)).toList());
  }

  /// Fetches a list of public snapshots for the community gallery.
  /// 
  /// Results are limited to the specified [limit] (default: 50) and 
  /// sorted by creation date (newest first).
  /// Throws a timeout error if the request exceeds 10 seconds.
  Future<List<ExperimentSnapshot>> fetchPublicGallery({int limit = 50}) async {
    try {
      final query = await _db
          .collection('public_snapshots')
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get()
          .timeout(const Duration(seconds: 10));

      return query.docs.map((doc) => ExperimentSnapshot.fromFirestore(doc)).toList();
    } on TimeoutException {
      throw 'Connection timed out while fetching gallery.';
    } catch (e) {
      rethrow;
    }
  }
}
