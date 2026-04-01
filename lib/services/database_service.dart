import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/experiment_snapshot.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

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

  Stream<List<ExperimentSnapshot>> watchUserSnapshots(String uid) {
    return _db
        .collection('users')
        .doc(uid)
        .collection('snapshots')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => ExperimentSnapshot.fromFirestore(doc)).toList());
  }

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
