import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../providers/auth_provider.dart';
import '../providers/prefs_provider.dart';
import '../screens/login_screen.dart';
import '../screens/register_screen.dart';
import '../screens/onboarding_screen.dart';
import '../screens/app_shell.dart';
import '../screens/simulate_screen.dart';
import '../screens/vault_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/network_config_screen.dart';
import '../screens/replay_screen.dart';
import '../screens/leaderboard_screen.dart';
import '../screens/snapshot_view_screen.dart';

/*
Manual Test Steps for Onboarding Flow:
1. Fresh install -> expect /onboarding
2. Complete onboarding -> expect /shell/simulate
3. Sign out and sign back in -> expect /shell/simulate (not /onboarding again)
4. Clear app data -> expect /onboarding again
*/

/// A [ChangeNotifier] that triggers a refresh in [GoRouter] when auth or onboarding states change.
class RouterNotifier extends ChangeNotifier {
  final Ref _ref;

  RouterNotifier(this._ref) {
    // Re-run the redirect logic whenever these providers change
    _ref.listen<AsyncValue<User?>>(authProvider, (prev, next) {
      notifyListeners();
    });
    _ref.listen<AsyncValue<bool>>(onboardingCompleteProvider, (prev, next) {
      notifyListeners();
    });
  }
}

/// The provider for the application's [GoRouter] configuration.
/// 
/// It handles declarative routing and redirects based on the user's 
/// authentication status and onboarding progress.
final routerProvider = Provider<GoRouter>((ref) {
  final routerNotifier = RouterNotifier(ref);

  return GoRouter(
    initialLocation: '/shell/simulate',
    refreshListenable: routerNotifier,
    redirect: (context, state) {
      // Access current state via ref.read inside redirect triggered by refreshListenable
      final authState = ref.read(authProvider);
      final onboardingState = ref.read(onboardingCompleteProvider);

      // 1. If either auth or onboarding is still loading, don't redirect yet
      if (authState.isLoading || onboardingState.isLoading) {
        return null;
      }

      final user = authState.value;
      // 2. Explicitly handle null value for onboardingState (treat as false)
      final onboardingComplete = onboardingState.value ?? false;

      final isLoggingIn = state.matchedLocation == '/login';
      final isRegistering = state.matchedLocation == '/register';
      final isOnboarding = state.matchedLocation == '/onboarding';

      // 3. If not logged in, redirect to /login (unless already there or registering)
      if (user == null) {
        if (isLoggingIn || isRegistering) return null;
        return '/login';
      }

      // 4. Guard: If logged in but onboarding not complete, redirect to /onboarding
      // This runs AFTER the null user check as requested.
      if (!onboardingComplete) {
        if (isOnboarding) return null;
        return '/onboarding';
      }

      // 5. If logged in and onboarding complete, redirect away from auth/onboarding screens
      if (isLoggingIn || isRegistering || isOnboarding) {
        return '/shell/simulate';
      }

      // No redirect needed
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/network_config',
        builder: (context, state) => const NetworkConfigScreen(),
      ),
      GoRoute(
        path: '/replay',
        builder: (context, state) {
          final snapshot = state.extra as dynamic;
          return ReplayScreen(snapshot: snapshot);
        },
      ),
      GoRoute(
        path: '/view/:id',
        builder: (context, state) => SnapshotViewScreen(
          snapshotId: state.pathParameters['id']!,
        ),
      ),
      ShellRoute(
        builder: (context, state, child) {
          return AppShell(child: child);
        },
        routes: [
          GoRoute(
            path: '/shell/simulate',
            builder: (context, state) => const SimulateScreen(),
          ),
          GoRoute(
            path: '/shell/vault',
            builder: (context, state) => VaultScreen(
              onTabChange: (index) {
                if (index == 0) context.go('/shell/simulate');
                if (index == 2) context.go('/shell/leaderboard');
                if (index == 3) context.go('/shell/profile');
              },
            ),
          ),
          GoRoute(
            path: '/shell/vault/:id',
            builder: (context, state) => VaultScreen(
              highlightedId: state.pathParameters['id'],
              onTabChange: (index) {
                if (index == 0) context.go('/shell/simulate');
                if (index == 2) context.go('/shell/leaderboard');
                if (index == 3) context.go('/shell/profile');
              },
            ),
          ),
          GoRoute(
            path: '/shell/leaderboard',
            builder: (context, state) => const LeaderboardScreen(),
          ),
          GoRoute(
            path: '/shell/profile',
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),
    ],
  );
});
