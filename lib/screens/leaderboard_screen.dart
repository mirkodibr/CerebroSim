import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/leaderboard_entry.dart';
import '../providers/leaderboard_provider.dart';

/// Per-task leaderboards showing the fastest-converging public experiments.
///
/// Rankings are computed nightly by the `recomputeLeaderboards` Cloud Function
/// from the `public_snapshots` collection. Weekly resets keep it competitive.
class LeaderboardScreen extends ConsumerStatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  ConsumerState<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends ConsumerState<LeaderboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _tasks = leaderboardTasks;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tasks.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _taskLabel(String task) {
    switch (task) {
      case 'eyeblink': return 'Eyeblink';
      case 'sineWave': return 'Sine Wave';
      case 'vor': return 'VOR';
      case 'armReaching': return 'Arm';
      default: return task;
    }
  }

  IconData _taskIcon(String task) {
    switch (task) {
      case 'eyeblink': return Icons.visibility;
      case 'sineWave': return Icons.waves;
      case 'vor': return Icons.rotate_90_degrees_cw;
      case 'armReaching': return Icons.back_hand;
      default: return Icons.science;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Leaderboards'),
        backgroundColor: colorScheme.surface,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: _tasks.map((t) => Tab(
            icon: Icon(_taskIcon(t), size: 16),
            text: _taskLabel(t),
          )).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: _tasks.map((task) => _LeaderboardTab(task: task)).toList(),
      ),
    );
  }
}

class _LeaderboardTab extends ConsumerWidget {
  final String task;
  const _LeaderboardTab({required this.task});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leaderboard = ref.watch(leaderboardProvider(task));
    final colorScheme = Theme.of(context).colorScheme;

    return leaderboard.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off, size: 48, color: colorScheme.outline),
            const SizedBox(height: 12),
            Text(
              'Leaderboard unavailable',
              style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.6)),
            ),
            const SizedBox(height: 4),
            Text(
              'Rankings are computed nightly.',
              style: TextStyle(fontSize: 12, color: colorScheme.onSurface.withValues(alpha: 0.4)),
            ),
          ],
        ),
      ),
      data: (entries) {
        if (entries.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.emoji_events_outlined, size: 64, color: colorScheme.outline),
                const SizedBox(height: 16),
                Text(
                  'No entries yet this week.',
                  style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.6)),
                ),
                const SizedBox(height: 8),
                Text(
                  'Save a public experiment to compete!',
                  style: TextStyle(fontSize: 12, color: colorScheme.onSurface.withValues(alpha: 0.4)),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: entries.length,
          itemBuilder: (context, i) => _LeaderboardRow(entry: entries[i]),
        );
      },
    );
  }
}

class _LeaderboardRow extends StatelessWidget {
  final LeaderboardEntry entry;

  const _LeaderboardRow({required this.entry});

  Color _rankColor(BuildContext context, int rank) {
    if (rank == 1) return const Color(0xFFFFD700); // gold
    if (rank == 2) return const Color(0xFFC0C0C0); // silver
    if (rank == 3) return const Color(0xFFCD7F32); // bronze
    return Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final rankColor = _rankColor(context, entry.rank);
    final isTopThree = entry.rank <= 3;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: entry.snapshotId.isNotEmpty
              ? () => context.push('/shell/vault/${entry.snapshotId}')
              : null,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isTopThree
                  ? rankColor.withValues(alpha: 0.08)
                  : colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isTopThree
                    ? rankColor.withValues(alpha: 0.3)
                    : colorScheme.outline.withValues(alpha: 0.1),
              ),
            ),
            child: Row(
              children: [
                // Rank badge
                SizedBox(
                  width: 36,
                  child: Text(
                    isTopThree ? ['🥇', '🥈', '🥉'][entry.rank - 1] : '#${entry.rank}',
                    style: TextStyle(
                      fontSize: isTopThree ? 20 : 13,
                      fontWeight: FontWeight.bold,
                      color: rankColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(width: 12),

                // Title + author
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.title.isEmpty ? 'Untitled' : entry.title,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        entry.userEmail,
                        style: TextStyle(
                          fontSize: 11,
                          color: colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 12),

                // Stats
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Score: ${entry.score.toStringAsFixed(3)}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${entry.episodeCount} ep · ${entry.networkSize}N',
                      style: TextStyle(
                        fontSize: 10,
                        color: colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),

                if (entry.snapshotId.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Icon(Icons.chevron_right, size: 16, color: colorScheme.onSurface.withValues(alpha: 0.3)),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
