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

/// A [ChangeNotifier] that triggers a refresh in [GoRouter] when auth or onboarding states change.
class RouterNotifier extends ChangeNotifier {
  final Ref _ref;

  RouterNotifier(this._ref) {
    // Re-run the redirect logic whenever these providers change
    _ref.listen<AsyncValue<User?>>(authProvider, (prev, next) => notifyListeners());
    _ref.listen<AsyncValue<bool>>(onboardingCompleteProvider, (prev, next) => notifyListeners());
  }
}

/// The provider for the application's [GoRouter] configuration.
/// 
/// It handles declarative routing and redirects based on the user's 
/// authentication status and onboarding progress.
final routerProvider = Provider<GoRouter>((ref) {
  final routerNotifier = RouterNotifier(ref);
  final authState = ref.watch(authProvider);
  final onboardingState = ref.watch(onboardingCompleteProvider);

  return GoRouter(
    initialLocation: '/shell/simulate',
    refreshListenable: routerNotifier,
    redirect: (context, state) {
      // If either auth or onboarding is still loading, don't redirect yet
      if (authState.isLoading || onboardingState.isLoading) return null;

      final user = authState.value;
      final onboardingComplete = onboardingState.value ?? false;

      final isLoggingIn = state.matchedLocation == '/login';
      final isRegistering = state.matchedLocation == '/register';
      final isOnboarding = state.matchedLocation == '/onboarding';

      // 1. If not logged in, redirect to /login (unless already there or registering)
      if (user == null) {
        if (isLoggingIn || isRegistering) return null;
        return '/login';
      }

      // 2. If logged in but onboarding not complete, redirect to /onboarding
      if (!onboardingComplete) {
        if (isOnboarding) return null;
        return '/onboarding';
      }

      // 3. If logged in and onboarding complete, redirect away from auth screens
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
                // Keep for backward compatibility with manual tab switching if needed
                if (index == 0) context.go('/shell/simulate');
                if (index == 2) context.go('/shell/profile');
              },
            ),
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
