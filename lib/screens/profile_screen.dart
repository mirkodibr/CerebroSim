import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../providers/theme_provider.dart';
import '../providers/auth_provider.dart';

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
          if (user != null && !user.emailVerified)
            Container(
              color: Theme.of(context).colorScheme.tertiaryContainer,
              child: ListTile(
                leading: Icon(
                  Icons.warning_amber_rounded,
                  color: Theme.of(context).colorScheme.tertiary,
                ),
                title: const Text('Email not verified'),
                subtitle: const Text('Check your inbox'),
                trailing: TextButton(
                  onPressed: () async {
                    await user.sendEmailVerification();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Verification email sent')),
                      );
                    }
                  },
                  child: const Text('Resend'),
                ),
              ),
            ),
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
            leading: const Icon(Icons.account_tree),
            title: const Text('Configure network'),
            subtitle: const Text('Adjust neural topology'),
            onTap: () {
              // Navigation will be implemented in Prompt 79
              // For now, we can show a placeholder or just leave it as is
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Sign Out', style: TextStyle(color: Colors.red)),
            onTap: () async {
              await ref.read(authProvider.notifier).signOut();
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            title: const Text('Delete account', style: TextStyle(color: Colors.red)),
            onTap: () => _showDeleteConfirmation(context, ref),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete account?'),
        content: const Text(
          'This permanently deletes all your experiments and cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await ref.read(authProvider.notifier).deleteAccount();
              } on FirebaseAuthException catch (e) {
                if (e.code == 'requires-recent-login') {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please sign out and sign back in before deleting your account.'),
                      ),
                    );
                  }
                } else {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: ${e.message}')),
                    );
                  }
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
            },
            child: const Text('DELETE', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
