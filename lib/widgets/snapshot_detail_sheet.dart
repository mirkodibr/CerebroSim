import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../models/experiment_snapshot.dart';
import '../providers/simulation_provider.dart';

class SnapshotDetailSheet extends ConsumerWidget {
  final ExperimentSnapshot snapshot;

  const SnapshotDetailSheet({super.key, required this.snapshot});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  snapshot.title,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Created on ${DateFormat.yMMMMd().add_jm().format(snapshot.createdAt)}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 16),
          _buildMetadataGrid(context),
          if (snapshot.notes != null && snapshot.notes!.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text(
              'Notes',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.secondary,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.outline.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                snapshot.notes!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  height: 1.5,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _handleShare(snapshot),
                  icon: const Icon(Icons.share, size: 18),
                  label: const Text('Share'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    ref.read(simulationProvider.notifier).loadSnapshot(snapshot);
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Simulation state restored!')),
                    );
                  },
                  icon: const Icon(Icons.play_circle_outline, size: 18),
                  label: const Text('Load to Lab'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetadataGrid(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 12,
      children: [
        _buildInfoItem(context, 'Task', snapshot.taskName.toUpperCase()),
        _buildInfoItem(context, 'Episodes', snapshot.episodeCount.toString()),
        _buildInfoItem(context, 'Final Error', snapshot.finalErrorRate.toStringAsFixed(4)),
        if (snapshot.finalVorGain != null)
          _buildInfoItem(context, 'Gain Ratio', snapshot.finalVorGain!.toStringAsFixed(3)),
        if (snapshot.networkConfig != null)
          _buildInfoItem(context, 'GC Count', snapshot.networkConfig!.gcCount.toString()),
      ],
    );
  }

  Widget _buildInfoItem(BuildContext context, String label, String value) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  void _handleShare(ExperimentSnapshot snapshot) {
    if (snapshot.isPublic) {
      Share.share(
        'Check out my CerebroSim experiment: ${snapshot.title}\n'
        'Task: ${snapshot.taskName} | Error rate: ${snapshot.finalErrorRate.toStringAsFixed(3)}\n'
        'cerebrosim://snapshot/${snapshot.id}'
      );
    } else {
      final json = snapshot.toJson();
      final bytes = utf8.encode(json);
      Share.shareXFiles(
        [XFile.fromData(bytes, name: '${snapshot.title}.json', mimeType: 'application/json')],
        text: 'CerebroSim Experiment Export: ${snapshot.title}',
      );
    }
  }
}
