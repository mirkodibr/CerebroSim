import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'profile_screen.dart';
import 'simulate_screen.dart';
import 'vault_screen.dart';

/// The root navigation shell of the CerebroSim application.
/// 
/// This widget provides the primary navigation structure using a [BottomNavigationBar] 
/// and an [IndexedStack] to maintain state between the different top-level screens.
/// It acts as a container for the core application features: simulation, experiment vault, 
/// and user profile.
class AppShell extends ConsumerStatefulWidget {
  /// Creates a new [AppShell] instance.
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

/// The state for [AppShell], managing the current navigation index and screen transitions.
class _AppShellState extends ConsumerState<AppShell> {
  /// The current index of the selected tab in the navigation bar.
  int _currentIndex = 0;

  /// Updates the current tab index and triggers a rebuild to show the selected screen.
  /// 
  /// [index] is the zero-based index of the new tab selection.
  void _onTabChange(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    /// The list of top-level screens accessible via the navigation bar.
    /// Order must match the [BottomNavigationBar] items.
    final List<Widget> screens = [
      const SimulateScreen(),
      VaultScreen(onTabChange: _onTabChange),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabChange,
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
