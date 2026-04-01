import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Service responsible for handling user authentication via Firebase.
///
/// It supports email/password authentication and Google Sign-In, 
/// providing methods to sign in, register, and sign out users.
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

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
}
