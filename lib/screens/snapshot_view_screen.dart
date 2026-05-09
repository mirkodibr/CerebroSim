import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/experiment_snapshot.dart';
import '../providers/auth_provider.dart';
import '../providers/vault_provider.dart';

/// Fetches a single public snapshot by ID from `public_snapshots/{id}`.
///
/// Readable without authentication (public Firestore rules).
final publicSnapshotProvider = FutureProvider.family<ExperimentSnapshot?, String>((ref, id) async {
  final doc = await FirebaseFirestore.instance
      .collection('public_snapshots')
      .doc(id)
      .get();
  if (!doc.exists) return null;
  return ExperimentSnapshot.fromFirestore(doc);
});

/// Web-friendly preview of a shared public experiment.
///
/// Accessible at `/view/:id` without requiring sign-in.
/// Anonymous users can watch the replay but cannot fork to their vault.
class SnapshotViewScreen extends ConsumerWidget {
  final String snapshotId;

  const SnapshotViewScreen({super.key, required this.snapshotId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshotAsync = ref.watch(publicSnapshotProvider(snapshotId));
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Shared Experiment'),
        backgroundColor: colorScheme.surface,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: colorScheme.outline.withValues(alpha: 0.1)),
        ),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.open_in_new, size: 16),
            label: const Text('Open in App'),
            onPressed: () => context.go('/shell/vault/$snapshotId'),
          ),
        ],
      ),
      body: snapshotAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _ErrorView(colorScheme: colorScheme),
        data: (snapshot) {
          if (snapshot == null) return _NotFoundView(colorScheme: colorScheme);
          return _SnapshotPreview(snapshot: snapshot);
        },
      ),
    );
  }
}

class _SnapshotPreview extends ConsumerWidget {
  final ExperimentSnapshot snapshot;

  const _SnapshotPreview({required this.snapshot});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final user = ref.watch(authProvider).value;
    final isSignedIn = user != null;

    return Column(
      children: [
        // Author + metadata banner
        Container(
          width: double.infinity,
          color: colorScheme.surfaceContainerHighest,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: colorScheme.primaryContainer,
                child: Text(
                  snapshot.userEmail.isNotEmpty ? snapshot.userEmail[0].toUpperCase() : '?',
                  style: TextStyle(fontSize: 12, color: colorScheme.onPrimaryContainer),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      snapshot.title.isEmpty ? 'Untitled Experiment' : snapshot.title,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'by ${snapshot.userEmail} · ${snapshot.taskName.toUpperCase()} · '
                      '${snapshot.episodeCount} episodes · '
                      'err ${snapshot.finalErrorRate.toStringAsFixed(3)}',
                      style: TextStyle(
                        fontSize: 11,
                        color: colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Notes (if any)
        if (snapshot.notes != null && snapshot.notes!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Text(
              snapshot.notes!,
              style: TextStyle(
                fontStyle: FontStyle.italic,
                color: colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),

        // Replay CTA
        if (snapshot.episodeHistory.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: OutlinedButton.icon(
              icon: const Icon(Icons.play_circle_outline),
              label: Text('Watch Learning Replay (${snapshot.episodeHistory.length} episodes)'),
              onPressed: () => context.push('/replay', extra: snapshot),
            ),
          ),

        const Spacer(),

        // CTA
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: isSignedIn
                ? _ForkButton(snapshot: snapshot)
                : _SignInCta(colorScheme: colorScheme),
          ),
        ),
      ],
    );
  }
}

class _ForkButton extends ConsumerWidget {
  final ExperimentSnapshot snapshot;

  const _ForkButton({required this.snapshot});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FilledButton.icon(
      icon: const Icon(Icons.fork_right),
      label: const Text('Fork to My Vault'),
      onPressed: () async {
        final user = ref.read(authProvider).value;
        if (user == null) return;
        final forked = snapshot.copyWith(
          userId: user.uid,
          userEmail: user.email ?? 'anon',
          title: 'Fork of ${snapshot.title}',
          isPublic: false,
          id: '',
        );
        await ref.read(vaultProvider.notifier).saveSnapshot(forked);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Forked to your vault!')),
          );
          context.go('/shell/vault');
        }
      },
    );
  }
}

class _SignInCta extends StatelessWidget {
  final ColorScheme colorScheme;

  const _SignInCta({required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colorScheme.primary.withValues(alpha: 0.2)),
          ),
          child: Column(
            children: [
              Text(
                'Sign in to fork this experiment to your vault',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: () => context.go('/login'),
                child: const Text('Sign In / Register'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _NotFoundView extends StatelessWidget {
  final ColorScheme colorScheme;
  const _NotFoundView({required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off, size: 64, color: colorScheme.outline),
          const SizedBox(height: 16),
          const Text('Experiment not found or not public.'),
          const SizedBox(height: 8),
          TextButton(onPressed: () => context.go('/shell/vault'), child: const Text('Browse Gallery')),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final ColorScheme colorScheme;
  const _ErrorView({required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.cloud_off, size: 64, color: colorScheme.outline),
          const SizedBox(height: 16),
          const Text('Unable to load experiment.'),
          const SizedBox(height: 8),
          TextButton(onPressed: () => context.go('/shell/simulate'), child: const Text('Go to Simulator')),
        ],
      ),
    );
  }
}
