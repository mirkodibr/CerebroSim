import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_profile.dart';
import 'auth_provider.dart';

final _db = FirebaseFirestore.instance;

/// Fetches the profile for the currently signed-in user.
/// Creates a placeholder profile on first access if none exists.
final myProfileProvider = FutureProvider<UserProfile?>((ref) async {
  final user = ref.watch(authProvider).value;
  if (user == null) return null;
  return _getOrCreateProfile(user.uid, user.email ?? '');
});

/// Fetches a public profile by UID.
final userProfileProvider = FutureProvider.family<UserProfile?, String>((ref, uid) async {
  final doc = await _db.collection('profiles').doc(uid).get();
  if (!doc.exists) return null;
  return UserProfile.fromFirestore(doc);
});

Future<UserProfile> _getOrCreateProfile(String uid, String email) async {
  final doc = await _db.collection('profiles').doc(uid).get();
  if (doc.exists) return UserProfile.fromFirestore(doc);

  // Auto-create placeholder profile on first access.
  final profile = UserProfile(
    uid: uid,
    handle: UserProfile.handleFromEmail(email),
    displayName: email.split('@').first,
    createdAt: DateTime.now(),
  );
  await _db.collection('profiles').doc(uid).set(profile.toFirestore());
  return profile;
}

/// Saves profile edits for the current user.
Future<void> saveProfile(UserProfile profile) async {
  await _db.collection('profiles').doc(profile.uid).set(
    profile.toFirestore(),
    SetOptions(merge: true),
  );
}
