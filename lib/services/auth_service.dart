import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Service responsible for handling user authentication via Firebase.
///
/// It supports email/password authentication and Google Sign-In, 
/// providing methods to sign in, register, and sign out users.
class AuthService {
  final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;
  final FirebaseFirestore _db;

  /// Creates a new [AuthService]. 
  /// If no [auth], [googleSignIn], or [db] is provided, it uses the default instances.
  AuthService({
    FirebaseAuth? auth,
    GoogleSignIn? googleSignIn,
    FirebaseFirestore? db,
  }) : _auth = auth ?? FirebaseAuth.instance,
       _googleSignIn = googleSignIn ?? GoogleSignIn(),
       _db = db ?? FirebaseFirestore.instance;

  /// Signs in a user using their [email] and [password].
  ///
  /// Throws a [FirebaseAuthException] if the credentials are invalid 
  /// or if there is a network error.
  Future<UserCredential> signInWithEmail(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Registers a new user with the provided [email] and [password].
  ///
  /// Creates a new user account in Firebase and returns the [UserCredential].
  /// Throws an error if the email is already in use or the password is weak.
  Future<UserCredential> registerWithEmail(String email, String password) async {
    try {
      return await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Initiates the Google Sign-In flow.
  ///
  /// Returns the [UserCredential] if successful.
  /// Throws a [FirebaseAuthException] with code 'sign-in-cancelled' if the 
  /// user cancels the operation.
  Future<UserCredential> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw FirebaseAuthException(code: 'sign-in-cancelled');
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      return await _auth.signInWithCredential(credential);
    } catch (e) {
      rethrow;
    }
  }

  /// Signs out the current user from both Firebase and Google.
  ///
  /// This ensures that the next sign-in attempt requires credentials.
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
    } catch (e) {
      rethrow;
    }
  }

  /// Permanently deletes the user's account and all associated research data.
  /// 
  /// This performs a batch deletion of the user's Firestore documents 
  /// before deleting the Firebase Auth user.
  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final uid = user.uid;

    try {
      // 1. Delete all Firestore snapshots in a batch
      final snapshots = await _db.collection('users').doc(uid).collection('snapshots').get();
      
      final batch = _db.batch();
      for (var doc in snapshots.docs) {
        batch.delete(doc.reference);
        // If it was public, delete from public_snapshots too
        if (doc.data()['isPublic'] == true) {
          batch.delete(_db.collection('public_snapshots').doc(doc.id));
        }
      }
      
      // Delete the user document itself
      batch.delete(_db.collection('users').doc(uid));

      await batch.commit();

      // 2. Delete the Firebase user
      // This may throw 'requires-recent-login'
      await user.delete();

      // 3. Clear Google session
      await _googleSignIn.signOut();
    } catch (e) {
      rethrow;
    }
  }
}
