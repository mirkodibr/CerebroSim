import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../models/experiment_snapshot.dart';
import 'interpretation_sheet.dart';

/// A card widget that displays a summary of a saved experiment snapshot.
class SnapshotCard extends StatelessWidget {
  final ExperimentSnapshot snapshot;
  final VoidCallback onTap;
  final bool isHighlighted;
  final bool showCompareAction;

  const SnapshotCard({
    super.key, 
    required this.snapshot, 
    required this.onTap,
    this.isHighlighted = false,
    this.showCompareAction = false,
  });

  // Parse taskName string back to enum for display:
  String _taskDisplayName(String taskName) {
    if (taskName.isEmpty) return 'UNKNOWN TASK';
    switch (taskName) {
      case 'eyeblink': return 'EYEBLINK';
      case 'sineWave': return 'SINE WAVE';
      case 'vor': return 'VOR';
      case 'armReaching': return 'ARM';
      default: return taskName.toUpperCase();
    }
  }

  IconData _taskIcon(String taskName) {
    switch (taskName) {
      case 'eyeblink': return Icons.visibility;
      case 'sineWave': return Icons.waves;
      case 'vor': return Icons.rotate_90_degrees_cw;
      case 'armReaching': return Icons.back_hand;
      default: return Icons.science;
    }
  }

  Color _performanceColor(BuildContext context) {
    if (snapshot.finalErrorRate < 0.2) return Colors.green;
    if (snapshot.finalErrorRate < 0.5) return Colors.orange;
    return Theme.of(context).colorScheme.error;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isWide = MediaQuery.of(context).size.width > 600;
    final perfColor = _performanceColor(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isHighlighted 
                      ? colorScheme.primaryContainer.withValues(alpha: 0.2) 
                      : colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isHighlighted ? colorScheme.primary : colorScheme.outline.withValues(alpha: 0.1),
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
                              Icon(_taskIcon(snapshot.taskName), size: 14, color: colorScheme.primary),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  snapshot.title.isEmpty ? 'Untitled Experiment' : snapshot.title,
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
                                _taskDisplayName(snapshot.taskName),
                                colorScheme.primaryContainer,
                                colorScheme.onPrimaryContainer,
                              ),
                              _PerformanceBar(
                                errorRate: snapshot.finalErrorRate,
                                color: perfColor,
                              ),
                              _MiniSparkline(
                                values: snapshot.synapticWeights.take(20).toList(),
                                color: colorScheme.secondary.withValues(alpha: 0.5),
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
                          if (snapshot.notes != null && snapshot.notes!.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              snapshot.notes!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontStyle: FontStyle.italic,
                                color: colorScheme.onSurface.withValues(alpha: 0.6),
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (showCompareAction)
                          IconButton(
                            icon: Icon(Icons.compare_arrows, size: 20, color: colorScheme.primary),
                            onPressed: onTap,
                            tooltip: 'Select for comparison',
                          ),
                        IconButton(
                          icon: Icon(Icons.psychology, size: 20, color: colorScheme.secondary),
                          onPressed: () {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (context) => InterpretationSheet(snapshot: snapshot),
                            );
                          },
                          tooltip: 'AI Interpretation',
                        ),
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
              // Thick colored left border overlay
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: Container(
                  width: 4,
                  decoration: BoxDecoration(
                    color: perfColor,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      bottomLeft: Radius.circular(16),
                    ),
                  ),
                ),
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

class _PerformanceBar extends StatelessWidget {
  final double errorRate;
  final Color color;

  const _PerformanceBar({required this.errorRate, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 80,
          height: 4,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(2),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: (1.0 - errorRate).clamp(0.05, 1.0),
            child: Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          errorRate.toStringAsFixed(3),
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _MiniSparkline extends StatelessWidget {
  final List<double> values;
  final Color color;

  const _MiniSparkline({required this.values, required this.color});

  @override
  Widget build(BuildContext context) {
    if (values.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      width: 60,
      height: 24,
      child: CustomPaint(
        painter: _SparklinePainter(values: values, color: color),
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  final List<double> values;
  final Color color;

  final Paint _paint = Paint()
    ..strokeWidth = 1.5
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round;
  final Path _path = Path();

  _SparklinePainter({required this.values, required this.color}) {
    _paint.color = color;
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;

    _path.reset();
    final xStep = size.width / (values.length - 1);
    
    // Simple normalization for visualization
    double minVal = values[0];
    double maxVal = values[0];
    for (final v in values) {
      if (v < minVal) minVal = v;
      if (v > maxVal) maxVal = v;
    }
    final range = (maxVal - minVal).clamp(0.0001, double.infinity);

    for (int i = 0; i < values.length; i++) {
      final x = i * xStep;
      final y = size.height - ((values[i] - minVal) / range * size.height);
      if (i == 0) {
        _path.moveTo(x, y);
      } else {
        _path.lineTo(x, y);
      }
    }
    canvas.drawPath(_path, _paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

