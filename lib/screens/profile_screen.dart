import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../providers/theme_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/tutorial_provider.dart';
import '../providers/vault_provider.dart';
import '../providers/profile_provider.dart';
import '../models/user_profile.dart';
import '../widgets/snapshot_card.dart';

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
          // Profile card (bio, handle, edit)
          _ProfileCard(user: user),

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
          ListTile(
            leading: const Icon(Icons.help_outline),
            title: const Text('App Tutorial'),
            subtitle: const Text('Learn how to use CerebroSim'),
            onTap: () {
              ref.read(tutorialProvider.notifier).startTutorial();
              context.go('/shell/simulate');
            },
          ),
          const Divider(),
          // Public experiments portfolio
          _PublicPortfolio(uid: user?.uid),
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

/// Displays the user's Firestore profile with bio and edit capability.
class _ProfileCard extends ConsumerWidget {
  final User? user;
  const _ProfileCard({required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (user == null) return const SizedBox.shrink();
    final profile = ref.watch(myProfileProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return profile.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(16),
        child: LinearProgressIndicator(),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (p) {
        if (p == null) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Card(
            elevation: 0,
            color: colorScheme.surfaceContainerHighest,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        '@${p.handle}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                          fontFamily: 'monospace',
                        ),
                      ),
                      const Spacer(),
                      TextButton.icon(
                        icon: const Icon(Icons.edit, size: 14),
                        label: const Text('Edit'),
                        onPressed: () {
                          // Access parent's method via context — use a separate callback
                          _showEditProfileDialog(context, ref, p);
                        },
                      ),
                    ],
                  ),
                  if (p.displayName.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(p.displayName, style: const TextStyle(fontWeight: FontWeight.w600)),
                  ],
                  if (p.affiliation != null && p.affiliation!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      p.affiliation!,
                      style: TextStyle(fontSize: 12, color: colorScheme.onSurface.withValues(alpha: 0.6)),
                    ),
                  ],
                  if (p.bio.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(p.bio, style: TextStyle(fontSize: 13, color: colorScheme.onSurface.withValues(alpha: 0.8))),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showEditProfileDialog(BuildContext context, WidgetRef ref, UserProfile profile) {
    final displayNameCtrl = TextEditingController(text: profile.displayName);
    final bioCtrl = TextEditingController(text: profile.bio);
    final affiliationCtrl = TextEditingController(text: profile.affiliation ?? '');
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
          left: 24, right: 24, top: 24,
        ),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Edit Profile', style: Theme.of(ctx).textTheme.titleLarge),
              const SizedBox(height: 16),
              TextFormField(
                controller: displayNameCtrl,
                decoration: const InputDecoration(labelText: 'Display Name', border: OutlineInputBorder()),
                validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: bioCtrl,
                decoration: const InputDecoration(labelText: 'Bio (optional)', border: OutlineInputBorder()),
                maxLines: 3,
                maxLength: 200,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: affiliationCtrl,
                decoration: const InputDecoration(labelText: 'Affiliation (optional)', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () async {
                  if (!formKey.currentState!.validate()) return;
                  final updated = profile.copyWith(
                    displayName: displayNameCtrl.text.trim(),
                    bio: bioCtrl.text.trim(),
                    affiliation: affiliationCtrl.text.trim().isEmpty ? null : affiliationCtrl.text.trim(),
                  );
                  await saveProfile(updated);
                  ref.invalidate(myProfileProvider);
                  if (ctx.mounted) Navigator.pop(ctx);
                },
                child: const Text('Save'),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

/// Displays the user's public experiments as a portfolio.
class _PublicPortfolio extends ConsumerWidget {
  final String? uid;
  const _PublicPortfolio({required this.uid});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vault = ref.watch(vaultProvider);

    return vault.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (snaps) {
        final public = snaps.where((s) => s.isPublic).toList();
        if (public.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Text(
                'Public Portfolio (${public.length})',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey),
              ),
            ),
            ...public.take(5).map((snap) => SnapshotCard(
              snapshot: snap,
              onTap: () => context.push('/shell/vault/${snap.id}'),
              onReplay: snap.episodeHistory.isNotEmpty
                  ? () => context.push('/replay', extra: snap)
                  : null,
            )),
            if (public.length > 5)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  '+${public.length - 5} more in your Vault',
                  style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)),
                ),
              ),
          ],
        );
      },
    );
  }
}
