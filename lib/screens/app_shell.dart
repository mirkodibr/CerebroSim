import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:go_router/go_router.dart';
import '../providers/connectivity_provider.dart';
import '../providers/tutorial_provider.dart';
import '../providers/prefs_provider.dart';

/// The root navigation shell of the CerebroSim application.
/// 
/// This widget provides the primary navigation structure using a [BottomNavigationBar] 
/// and a [ShellRoute] child to maintain state between the different top-level screens.
/// It acts as a container for the core application features: simulation, experiment vault, 
/// and user profile.
class AppShell extends ConsumerWidget {
  /// The child widget to be displayed within the shell.
  final Widget child;

  /// Creates a new [AppShell] instance.
  const AppShell({super.key, required this.child});

  /// Updates the current tab by navigating to the corresponding route.
  void _onTabChange(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/shell/simulate');
        break;
      case 1:
        context.go('/shell/vault');
        break;
      case 2:
        context.go('/shell/profile');
        break;
    }
  }

  /// Calculates the current index based on the current route path.
  int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith('/shell/simulate')) return 0;
    if (location.startsWith('/shell/vault')) return 1;
    if (location.startsWith('/shell/profile')) return 2;
    return 0;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch connectivity and show/hide banner
    ref.listen<AsyncValue<List<ConnectivityResult>>>(connectivityProvider, (previous, next) {
      final results = next.value ?? [];
      final isOffline = results.isEmpty || results.every((r) => r == ConnectivityResult.none);
      
      if (isOffline) {
        ScaffoldMessenger.of(context).showMaterialBanner(
          MaterialBanner(
            content: const Text('No connection — simulation runs locally, cloud features unavailable.'),
            actions: [
              TextButton(
                onPressed: () => ScaffoldMessenger.of(context).hideCurrentMaterialBanner(),
                child: const Text('DISMISS'),
              ),
            ],
            backgroundColor: Theme.of(context).colorScheme.tertiaryContainer,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
      }
    });

    return Scaffold(
      body: () {
        // Auto-start tutorial once if onboarding is complete
        final onboarding = ref.watch(onboardingCompleteProvider);
        if (onboarding.value == true) {
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            final prefs = ref.read(prefsServiceProvider);
            final tutorialSeen = await prefs.hasTutorialBeenSeen();
            if (!tutorialSeen && ref.read(tutorialProvider) == null) {
              ref.read(tutorialProvider.notifier).startTutorial();
            }
          });
        }
        return child;
      }(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _calculateSelectedIndex(context),
        onTap: (index) => _onTabChange(context, index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.biotech),
            label: 'Simulate',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.science),
            label: 'Vault',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
