import 'package:cloud_firestore/cloud_firestore.dart';

/// A public user profile stored in `profiles/{uid}`.
///
/// Created automatically on first sign-in with a placeholder handle
/// derived from the user's email. Users can claim a custom handle later.
class UserProfile {
  final String uid;
  final String handle;
  final String displayName;
  final String bio;
  final String? avatarUrl;
  final String? affiliation;
  final List<String> links;
  final DateTime createdAt;

  const UserProfile({
    required this.uid,
    required this.handle,
    required this.displayName,
    this.bio = '',
    this.avatarUrl,
    this.affiliation,
    this.links = const [],
    required this.createdAt,
  });

  factory UserProfile.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserProfile(
      uid: data['uid'] as String? ?? doc.id,
      handle: data['handle'] as String? ?? doc.id,
      displayName: data['displayName'] as String? ?? '',
      bio: data['bio'] as String? ?? '',
      avatarUrl: data['avatarUrl'] as String?,
      affiliation: data['affiliation'] as String?,
      links: List<String>.from(data['links'] as List<dynamic>? ?? []),
      createdAt: data['createdAt'] is Timestamp
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'uid': uid,
        'handle': handle,
        'displayName': displayName,
        'bio': bio,
        if (avatarUrl != null) 'avatarUrl': avatarUrl,
        if (affiliation != null) 'affiliation': affiliation,
        'links': links,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  UserProfile copyWith({
    String? handle,
    String? displayName,
    String? bio,
    String? avatarUrl,
    String? affiliation,
    List<String>? links,
  }) {
    return UserProfile(
      uid: uid,
      handle: handle ?? this.handle,
      displayName: displayName ?? this.displayName,
      bio: bio ?? this.bio,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      affiliation: affiliation ?? this.affiliation,
      links: links ?? this.links,
      createdAt: createdAt,
    );
  }

  /// Generates a placeholder handle from an email address.
  static String handleFromEmail(String email) {
    final local = email.split('@').first.replaceAll(RegExp(r'[^a-z0-9]'), '').toLowerCase();
    return local.length >= 3 ? local : '${local}user';
  }
}
