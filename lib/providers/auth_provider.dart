import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';

/// A provider that exposes an instance of [AuthService].
/// This service handles the low-level authentication logic with Firebase.
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

/// A notifier that manages the authentication state of the application.
/// It uses [FirebaseAuth] to listen to authentication changes and provides
/// methods for signing in, registering, and signing out.
class AuthNotifier extends AsyncNotifier<User?> {
  StreamSubscription<User?>? _subscription;

  /// Initializes the notifier by listening to [FirebaseAuth] state changes.
  /// Returns the current user if available.
  @override
  FutureOr<User?> build() {
    _subscription?.cancel();
    _subscription = FirebaseAuth.instance.authStateChanges().listen((user) {
      state = AsyncData(user);
    });
    
    ref.onDispose(() => _subscription?.cancel());
    
    return FirebaseAuth.instance.currentUser;
  }

  /// Signs in a user using an email and password via the [AuthService].
  /// Updates the state to [AsyncLoading] during the process and [AsyncError] on failure.
  Future<void> signIn(String email, String password) async {
    state = const AsyncLoading();
    try {
      await ref.read(authServiceProvider).signInWithEmail(email, password);
    } on FirebaseAuthException catch (e, s) {
      state = AsyncError(e, s);
    }
  }

  /// Registers a new user using an email and password via the [AuthService].
  /// Updates the state to [AsyncLoading] during the process and [AsyncError] on failure.
  Future<void> register(String email, String password) async {
    state = const AsyncLoading();
    try {
      await ref.read(authServiceProvider).registerWithEmail(email, password);
    } on FirebaseAuthException catch (e, s) {
      state = AsyncError(e, s);
    }
  }

  /// Signs in a user using Google authentication via the [AuthService].
  /// Updates the state to [AsyncLoading] during the process and [AsyncError] on failure,
  /// unless the sign-in was cancelled by the user.
  Future<void> signInWithGoogle() async {
    state = const AsyncLoading();
    try {
      await ref.read(authServiceProvider).signInWithGoogle();
    } on FirebaseAuthException catch (e, s) {
      if (e.code != 'sign-in-cancelled') {
        state = AsyncError(e, s);
      } else {
        // Restore previous state if cancelled
        state = AsyncData(FirebaseAuth.instance.currentUser);
      }
    }
  }

  /// Signs out the current user via the [AuthService].
  /// Updates the state to [AsyncLoading] during the process and [AsyncError] on failure.
  Future<void> signOut() async {
    state = const AsyncLoading();
    try {
      await ref.read(authServiceProvider).signOut();
    } catch (e, s) {
      state = AsyncError(e, s);
    }
  }
}

/// A global provider for the [AuthNotifier], allowing widgets to observe and
/// interact with the current user's authentication state.
final authProvider = AsyncNotifierProvider<AuthNotifier, User?>(() {
  return AuthNotifier();
});
