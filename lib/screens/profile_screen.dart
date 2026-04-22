import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: ListView(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 32),
            alignment: Alignment.center,
            child: Column(children: [
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [colorScheme.primary, colorScheme.secondary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: CircleAvatar(
                  radius: 38,
                  backgroundColor: colorScheme.surface,
                  child: CircleAvatar(
                    radius: 35,
                    backgroundColor: colorScheme.primaryContainer,
                    child: Text(
                      user?.email?.substring(0, 1).toUpperCase() ?? '?',
                      style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onPrimaryContainer),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(user?.email ?? '',
                  style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface)),
            ]),
          ),
          if (user != null && !user.emailVerified)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Card(
                elevation: 0,
                color: colorScheme.tertiaryContainer,
                child: ListTile(
                  leading: Icon(
                    Icons.mark_email_unread,
                    color: colorScheme.tertiary,
                  ),
                  title: Text(
                    'Email not verified',
                    style: TextStyle(color: colorScheme.onTertiaryContainer, fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    'Check your inbox to secure your account',
                    style: TextStyle(color: colorScheme.onTertiaryContainer.withValues(alpha: 0.8)),
                  ),
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
            ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text('Settings', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
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
              context.push('/network_config');
            },
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text('Account', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
          ),
          ListTile(
            leading: Icon(Icons.logout, color: colorScheme.onSurface),
            title: const Text('Sign Out'),
            subtitle: Text("You'll need to sign back in", 
              style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.5), fontSize: 12)),
            onTap: () async {
              await ref.read(authProvider.notifier).signOut();
            },
          ),
          const Divider(),
          ListTile(
            leading: Icon(Icons.delete_forever, color: colorScheme.error),
            title: Text('Delete account', style: TextStyle(color: colorScheme.error)),
            onTap: () => _showDeleteConfirmation(context, ref),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('App version'),
            trailing: const Text('1.0.0+1', style: TextStyle(color: Colors.grey)),
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
