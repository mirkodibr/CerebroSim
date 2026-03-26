import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

class AuthNotifier extends AsyncNotifier<User?> {
  StreamSubscription<User?>? _subscription;

  @override
  FutureOr<User?> build() {
    _subscription?.cancel();
    _subscription = FirebaseAuth.instance.authStateChanges().listen((user) {
      state = AsyncData(user);
    });
    
    ref.onDispose(() => _subscription?.cancel());
    
    return FirebaseAuth.instance.currentUser;
  }

  Future<void> signIn(String email, String password) async {
    state = const AsyncLoading();
    try {
      await ref.read(authServiceProvider).signInWithEmail(email, password);
    } on FirebaseAuthException catch (e, s) {
      state = AsyncError(e, s);
    }
  }

  Future<void> register(String email, String password) async {
    state = const AsyncLoading();
    try {
      await ref.read(authServiceProvider).registerWithEmail(email, password);
    } on FirebaseAuthException catch (e, s) {
      state = AsyncError(e, s);
    }
  }

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

  Future<void> signOut() async {
    state = const AsyncLoading();
    try {
      await ref.read(authServiceProvider).signOut();
    } catch (e, s) {
      state = AsyncError(e, s);
    }
  }
}

final authProvider = AsyncNotifierProvider<AuthNotifier, User?>(() {
  return AuthNotifier();
});
