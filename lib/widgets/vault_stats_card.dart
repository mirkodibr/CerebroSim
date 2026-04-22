import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/experiment_snapshot.dart';

class VaultStatsCard extends StatelessWidget {
  final List<ExperimentSnapshot> snapshots;

  const VaultStatsCard({super.key, required this.snapshots});

  @override
  Widget build(BuildContext context) {
    if (snapshots.length < 3) return const SizedBox.shrink();

    final colorScheme = Theme.of(context).colorScheme;

    // Calculations
    final totalExperiments = snapshots.length;
    
    final bestErrorRate = snapshots.map((s) => s.finalErrorRate).reduce(math.min);
    
    final taskCounts = <String, int>{};
    for (final s in snapshots) {
      taskCounts[s.taskName] = (taskCounts[s.taskName] ?? 0) + 1;
    }
    final mostUsedTask = taskCounts.entries.isEmpty 
        ? 'N/A' 
        : taskCounts.entries.reduce((a, b) => a.value > b.value ? a : b).key;

    final convergedExp = snapshots.where((s) => s.finalErrorRate < 0.3).toList();
    final avgEpisodesToConvergence = convergedExp.isEmpty 
        ? 0 
        : (convergedExp.map((s) => s.episodeCount).reduce((a, b) => a + b) / convergedExp.length).round();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _StatTile(
            label: 'Total Exp',
            value: totalExperiments.toString(),
            icon: Icons.science,
            color: colorScheme.primary,
          ),
          _StatTile(
            label: 'Best Error',
            value: bestErrorRate.toStringAsFixed(3),
            icon: Icons.trending_down,
            color: Colors.green,
          ),
          _StatTile(
            label: 'Top Task',
            value: _formatTaskName(mostUsedTask),
            icon: Icons.star,
            color: Colors.orange,
          ),
          _StatTile(
            label: 'Avg Conv',
            value: '$avgEpisodesToConvergence ep',
            icon: Icons.speed,
            color: colorScheme.secondary,
          ),
        ],
      ),
    );
  }

  String _formatTaskName(String task) {
    switch (task.toLowerCase()) {
      case 'eyeblink': return 'EYE';
      case 'sinewave': return 'SINE';
      case 'vor': return 'VOR';
      case 'armreaching': return 'ARM';
      default: return task.toUpperCase();
    }
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: 120,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: colorScheme.onPrimaryContainer.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}
