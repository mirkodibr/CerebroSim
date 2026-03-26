import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../providers/theme_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeNotifierProvider);
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
              // Navigation will be handled by AuthRouteGuard in main.dart later
            },
          ),
        ],
      ),
    );
  }
}
