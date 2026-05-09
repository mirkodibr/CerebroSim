import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'snapshot_cache.dart';

/// Service responsible for handling user authentication via Firebase.
///
/// It supports email/password authentication and Google Sign-In, 
/// providing methods to sign in, register, and sign out users.
class AuthService {
  final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;
  final FirebaseFunctions _functions;

  /// Creates a new [AuthService].
  /// If no [auth] or [googleSignIn] is provided, it uses the default instances.
  AuthService({
    FirebaseAuth? auth,
    GoogleSignIn? googleSignIn,
    FirebaseFunctions? functions,
  }) : _auth = auth ?? FirebaseAuth.instance,
       _googleSignIn = googleSignIn ?? GoogleSignIn(),
       _functions = functions ?? FirebaseFunctions.instance;

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
      final uid = _auth.currentUser?.uid;
      await _googleSignIn.signOut();
      await _auth.signOut();
      if (uid != null) await SnapshotCache().clearCache(uid);
    } catch (e) {
      rethrow;
    }
  }

  /// Permanently deletes the user's account and all associated research data.
  ///
  /// Delegates all Firestore and Auth deletion to the `deleteUserAccount`
  /// Cloud Function, which uses the Admin SDK (no re-authentication required)
  /// and handles arbitrarily large snapshot collections via paginated batches.
  ///
  /// Throws a [FirebaseFunctionsException] on failure; the caller is
  /// responsible for surfacing an appropriate error message to the user.
  Future<void> deleteAccount() async {
    if (_auth.currentUser == null) return;

    final callable = _functions.httpsCallable('deleteUserAccount');
    await callable.call<void>(null);

    // Auth user is deleted server-side; sign out the Google session locally.
    await _googleSignIn.signOut();
  }
}
