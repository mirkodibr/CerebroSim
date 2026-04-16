import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../models/experiment_snapshot.dart';

/// A card widget that displays a summary of a saved experiment snapshot.
class SnapshotCard extends StatelessWidget {
  final ExperimentSnapshot snapshot;
  final VoidCallback onTap;
  final bool isHighlighted;

  const SnapshotCard({
    super.key, 
    required this.snapshot, 
    required this.onTap,
    this.isHighlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isWide = MediaQuery.of(context).size.width > 600;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 500),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isHighlighted 
                ? colorScheme.primaryContainer.withValues(alpha: 0.2) 
                : colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isHighlighted 
                  ? colorScheme.primary 
                  : colorScheme.outline.withValues(alpha: 0.1),
              width: isHighlighted ? 1.5 : 0.5,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            snapshot.title,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (snapshot.isPublic)
                          Container(
                            margin: const EdgeInsets.only(left: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: colorScheme.secondaryContainer,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'PUBLIC',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onSecondaryContainer,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        _buildChip(
                          context,
                          snapshot.taskName.toUpperCase(),
                          colorScheme.primaryContainer,
                          colorScheme.onPrimaryContainer,
                        ),
                        Text(
                          '${snapshot.episodeCount} ep · err: ${snapshot.finalErrorRate.toStringAsFixed(3)}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                        ),
                        Text(
                          '·',
                          style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.3)),
                        ),
                        Text(
                          DateFormat.yMMMd().format(snapshot.createdAt),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurface.withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ),
                    if (snapshot.networkConfig != null) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: [
                          _buildCompactTag(context, 'GC:${snapshot.networkConfig!.gcCount}'),
                          _buildCompactTag(context, 'BC:${snapshot.networkConfig!.bcCount}'),
                          _buildCompactTag(context, 'PC:${snapshot.networkConfig!.pcCount}'),
                          _buildCompactTag(context, 'SC:${snapshot.networkConfig!.scCount}'),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(Icons.share, size: 20, color: colorScheme.onSurface.withValues(alpha: 0.54)),
                    onPressed: () {
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
                    },
                  ),
                  if (isWide)
                    Icon(
                      Icons.chevron_right,
                      color: colorScheme.onSurface.withValues(alpha: 0.3),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChip(BuildContext context, String label, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildCompactTag(BuildContext context, String label) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: colorScheme.outline.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 9, color: colorScheme.onSurface.withValues(alpha: 0.5)),
      ),
    );
  }
}
