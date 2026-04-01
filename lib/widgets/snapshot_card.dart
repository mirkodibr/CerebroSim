import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/experiment_snapshot.dart';

class SnapshotCard extends StatelessWidget {
  final ExperimentSnapshot snapshot;
  final VoidCallback onTap;

  const SnapshotCard({super.key, required this.snapshot, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.white.withOpacity(0.05),
      child: ListTile(
        onTap: onTap,
        title: Text(snapshot.title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Chip(
                  label: Text(snapshot.taskName, style: const TextStyle(fontSize: 10)),
                  visualDensity: VisualDensity.compact,
                  backgroundColor: Colors.blue.withOpacity(0.3),
                ),
                const SizedBox(width: 8),
                if (snapshot.isPublic)
                  Chip(
                    label: const Text('PUBLIC', style: TextStyle(fontSize: 10)),
                    visualDensity: VisualDensity.compact,
                    backgroundColor: Colors.green.withOpacity(0.3),
                  ),
              ],
            ),
            Text(
              'Ep: ${snapshot.episodeCount} | Error: ${snapshot.finalErrorRate.toStringAsFixed(4)}',
              style: const TextStyle(fontSize: 12, color: Colors.white70),
            ),
            Text(
              DateFormat('MMM dd, yyyy HH:mm').format(snapshot.createdAt),
              style: const TextStyle(fontSize: 10, color: Colors.white38),
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.white38),
      ),
    );
  }
}
