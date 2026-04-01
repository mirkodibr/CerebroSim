import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../providers/theme_provider.dart';

/// A screen for managing user settings and application preferences.
/// 
/// This screen provides an interface for viewing the logged-in user's email, 
/// toggling between light and dark visual themes, and signing out of the application.
/// It integrates with [FirebaseAuth] for user status and [themeNotifierProvider]
/// for persistent theme management.
class ProfileScreen extends ConsumerWidget {
  /// Creates a new [ProfileScreen] instance.
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    /// Monitors the application's current theme mode.
    final themeMode = ref.watch(themeNotifierProvider);
    
    /// Retrieves the currently authenticated user from Firebase.
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: ListView(
        children: [
          if (user != null)
            ListTile(
              leading: const Icon(Icons.email),
              title: const Text('Email'),
              subtitle: Text(user.email ?? 'No email'),
            ),
          SwitchListTile(
            secondary: Icon(themeMode == ThemeMode.dark ? Icons.dark_mode : Icons.light_mode),
            title: const Text('Dark Mode'),
            value: themeMode == ThemeMode.dark,
            onChanged: (_) {
              ref.read(themeNotifierProvider.notifier).toggle();
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Sign Out', style: TextStyle(color: Colors.red)),
            onTap: () async {
              await FirebaseAuth.instance.signOut();
              // Note: Navigation to the login screen is typically handled by 
              // an auth listener in the application's root router.
            },
          ),
        ],
      ),
    );
  }
}
