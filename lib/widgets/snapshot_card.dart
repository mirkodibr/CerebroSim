import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/experiment_snapshot.dart';

/// A card widget that displays a summary of a saved experiment snapshot.
///
/// It shows the snapshot's title, the associated [CerebellarTask], public status,
/// final error rates, and the creation timestamp. Tapping the card triggers
/// the [onTap] callback, typically used to load or view the snapshot.
class SnapshotCard extends StatelessWidget {
  final ExperimentSnapshot snapshot;
  final VoidCallback onTap;

  const SnapshotCard({super.key, required this.snapshot, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: colorScheme.onSurface.withValues(alpha: 0.05),
      child: ListTile(
        onTap: onTap,
        title: Text(snapshot.title, style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Chip(
                  label: Text(snapshot.taskName, style: TextStyle(fontSize: 10, color: colorScheme.onPrimaryContainer)),
                  visualDensity: VisualDensity.compact,
                  backgroundColor: colorScheme.primaryContainer,
                ),
                const SizedBox(width: 8),
                if (snapshot.isPublic)
                  Chip(
                    label: Text('PUBLIC', style: TextStyle(fontSize: 10, color: colorScheme.onSecondaryContainer)),
                    visualDensity: VisualDensity.compact,
                    backgroundColor: colorScheme.secondaryContainer,
                  ),
              ],
            ),
            if (snapshot.networkConfig != null)
              Padding(
                padding: const EdgeInsets.only(top: 4.0, bottom: 4.0),
                child: Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: [
                    _buildCompactTag(context, 'GC:${snapshot.networkConfig!.gcCount}'),
                    _buildCompactTag(context, 'BC:${snapshot.networkConfig!.bcCount}'),
                    _buildCompactTag(context, 'PC:${snapshot.networkConfig!.pcCount}'),
                    _buildCompactTag(context, 'SC:${snapshot.networkConfig!.scCount}'),
                  ],
                ),
              ),
            Text(
              'Ep: ${snapshot.episodeCount} | Error: ${snapshot.finalErrorRate.toStringAsFixed(4)}',
              style: TextStyle(fontSize: 12, color: colorScheme.onSurface.withValues(alpha: 0.7)),
            ),
            Text(
              DateFormat('MMM dd, yyyy HH:mm').format(snapshot.createdAt),
              style: TextStyle(fontSize: 10, color: colorScheme.onSurface.withValues(alpha: 0.38)),
            ),
          ],
        ),
        trailing: Icon(Icons.chevron_right, color: colorScheme.onSurface.withValues(alpha: 0.38)),
      ),
    );
  }

  Widget _buildCompactTag(BuildContext context, String label) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: colorScheme.outline.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 9, color: colorScheme.onSurface.withValues(alpha: 0.6)),
      ),
    );
  }
}
