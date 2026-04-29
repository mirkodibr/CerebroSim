import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/experiment_snapshot.dart';
import '../models/episode_record.dart';

class ComparisonChart extends StatelessWidget {
  final ExperimentSnapshot snapshotA;
  final ExperimentSnapshot snapshotB;
  final List<EpisodeRecord> currentHistory;

  const ComparisonChart({
    super.key,
    required this.snapshotA,
    required this.snapshotB,
    required this.currentHistory,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    final isSameTask = snapshotA.taskName == snapshotB.taskName;
    final taskSubtitle = isSameTask 
        ? 'Same task — comparing hyperparameters'
        : 'Different tasks — comparing transfer';

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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'A vs B: ${snapshotA.taskName} vs ${snapshotB.taskName}',
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    if (isSameTask)
                      Text(
                        taskSubtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.6)
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: colorScheme.errorContainer,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          taskSubtitle,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onErrorContainer,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildLegend(context),
          const SizedBox(height: 24),
          SizedBox(
            height: 240,
            width: double.infinity,
            child: CustomPaint(
              painter: ConvergenceComparisonPainter(
                snapA: snapshotA,
                snapB: snapshotB,
                colorA: const Color(0xFF00FFFF),
                colorB: Colors.amber,
                colorScheme: colorScheme,
                labelStyle: theme.textTheme.labelSmall ?? const TextStyle(),
              ),
            ),
          ),
          const SizedBox(height: 32),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildStatTile(
                  context,
                  label: 'Episodes',
                  valA: '${snapshotA.episodeCount}',
                  valB: '${snapshotB.episodeCount}',
                  icon: Icons.repeat,
                ),
                _buildStatTile(
                  context,
                  label: 'Final Error',
                  valA: snapshotA.finalErrorRate.toStringAsFixed(4),
                  valB: snapshotB.finalErrorRate.toStringAsFixed(4),
                  icon: Icons.trending_down,
                ),
                _buildStatTile(
                  context,
                  label: 'Best Epoch',
                  valA: _getBestEpoch(snapshotA),
                  valB: _getBestEpoch(snapshotB),
                  icon: Icons.star,
                ),
                _buildStatTile(
                  context,
                  label: 'Convergence',
                  valA: _getConvergence(snapshotA),
                  valB: _getConvergence(snapshotB),
                  icon: Icons.done_all,
                  colorA: snapshotA.finalErrorRate < 0.2 ? Colors.green : Colors.red,
                  colorB: snapshotB.finalErrorRate < 0.2 ? Colors.green : Colors.red,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getBestEpoch(ExperimentSnapshot snap) {
    if (snap.episodeHistory.isEmpty) return 'N/A';
    int bestEp = 0;
    double minErr = double.infinity;
    for (final rec in snap.episodeHistory) {
      if (rec.meanPunishment < minErr) {
        minErr = rec.meanPunishment;
        bestEp = rec.episodeNumber;
      }
    }
    return '$bestEp';
  }

  String _getConvergence(ExperimentSnapshot snap) {
    return snap.finalErrorRate < 0.2 ? 'Yes (<0.2)' : 'No';
  }

  Widget _buildLegend(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _LegendItem(label: snapshotA.title, color: const Color(0xFF00FFFF))),
        const SizedBox(width: 16),
        Expanded(child: _LegendItem(label: snapshotB.title, color: Colors.amber)),
      ],
    );
  }

  Widget _buildStatTile(
    BuildContext context, {
    required String label,
    required String valA,
    required String valB,
    required IconData icon,
    Color? colorA,
    Color? colorB,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: colorScheme.onSurfaceVariant),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                valA,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: colorA ?? const Color(0xFF00FFFF),
                ),
              ),
              Text(
                valB,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: colorB ?? Colors.amber,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final String label;
  final Color color;

  const _LegendItem({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class ConvergenceComparisonPainter extends CustomPainter {
  final ExperimentSnapshot snapA;
  final ExperimentSnapshot snapB;
  final Color colorA;
  final Color colorB;
  final ColorScheme colorScheme;
  final TextStyle labelStyle;

  ConvergenceComparisonPainter({
    required this.snapA,
    required this.snapB,
    required this.colorA,
    required this.colorB,
    required this.colorScheme,
    required this.labelStyle,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const double leftMargin = 44.0;
    const double bottomMargin = 20.0;
    final double chartWidth = size.width - leftMargin;
    final double chartHeight = size.height - bottomMargin;

    if (chartWidth <= 0 || chartHeight <= 0) return;

    double maxPunishment = 0.0;
    
    // Find global maxY
    for (final rec in snapA.episodeHistory) {
      if (rec.meanPunishment > maxPunishment) maxPunishment = rec.meanPunishment;
    }
    for (final rec in snapB.episodeHistory) {
      if (rec.meanPunishment > maxPunishment) maxPunishment = rec.meanPunishment;
    }
    
    if (snapA.episodeHistory.isEmpty) maxPunishment = math.max(maxPunishment, snapA.finalErrorRate);
    if (snapB.episodeHistory.isEmpty) maxPunishment = math.max(maxPunishment, snapB.finalErrorRate);

    double maxY = math.max(1.0, maxPunishment * 1.1);

    final Paint gridPaint = Paint()
      ..color = colorScheme.onSurface.withValues(alpha: 0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Draw Gridlines and Y-axis labels (0, 25%, 50%, 75%, 100%)
    final List<double> gridFractions = [0.0, 0.25, 0.5, 0.75, 1.0];
    for (final frac in gridFractions) {
      final double val = maxY * frac;
      final double y = chartHeight - (frac * chartHeight);
      
      canvas.drawLine(Offset(leftMargin, y), Offset(size.width, y), gridPaint);

      final TextPainter tp = TextPainter(
        text: TextSpan(
          text: val.toStringAsFixed(2),
          style: labelStyle.copyWith(color: colorScheme.onSurface.withValues(alpha: 0.5), fontSize: 10),
        ),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.right,
      )..layout(maxWidth: leftMargin - 4);
      tp.paint(canvas, Offset(leftMargin - tp.width - 8, y - tp.height / 2));
    }

    // X-axis labels
    _drawXLabel(canvas, '0%', leftMargin, size.height - 14);
    _drawXLabel(canvas, '50%', leftMargin + chartWidth / 2, size.height - 14, alignCenter: true);
    _drawXLabel(canvas, '100%', size.width, size.height - 14, alignRight: true);

    // Draw curves
    _drawCurve(canvas, snapA, colorA, leftMargin, chartWidth, chartHeight, maxY);
    _drawCurve(canvas, snapB, colorB, leftMargin, chartWidth, chartHeight, maxY);
  }

  void _drawCurve(Canvas canvas, ExperimentSnapshot snap, Color color, double left, double width, double height, double maxY) {
    if (snap.episodeHistory.isEmpty) {
      // Fallback for single data point
      final double y = height - ((snap.finalErrorRate / maxY).clamp(0.0, 1.0) * height);
      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;
      canvas.drawLine(Offset(left, y), Offset(left + width, y), paint);
      
      final tp = TextPainter(
        text: TextSpan(
          text: '(single data point)',
          style: labelStyle.copyWith(color: color, fontSize: 10),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(left + width / 2 - tp.width / 2, y - tp.height - 4));
      return;
    }

    final int count = snap.episodeHistory.length;
    if (count == 1) {
      // Same logic for single history entry
      final double y = height - ((snap.episodeHistory.first.meanPunishment / maxY).clamp(0.0, 1.0) * height);
      final paint = Paint()..color = color..strokeWidth = 2.0;
      canvas.drawLine(Offset(left, y), Offset(left + width, y), paint);
      return;
    }

    final Path strokePath = Path();
    final Path fillPath = Path();
    
    fillPath.moveTo(left, height);

    for (int i = 0; i < count; i++) {
      final record = snap.episodeHistory[i];
      // Normalize X from 0 to 1 based on index
      final double fracX = i / (count - 1);
      final double x = left + (fracX * width);
      final double y = height - ((record.meanPunishment / maxY).clamp(0.0, 1.0) * height);

      if (i == 0) {
        strokePath.moveTo(x, y);
        fillPath.lineTo(x, y);
      } else {
        strokePath.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }
    
    fillPath.lineTo(left + width, height);
    fillPath.close();

    final Paint fillPaint = Paint()
      ..color = color.withValues(alpha: 0.15)
      ..style = PaintingStyle.fill;
      
    final Paint strokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(strokePath, strokePaint);
  }

  void _drawXLabel(Canvas canvas, String text, double x, double y, {bool alignCenter = false, bool alignRight = false}) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: labelStyle.copyWith(fontSize: 10, color: colorScheme.onSurface.withValues(alpha: 0.5))),
      textDirection: TextDirection.ltr,
    )..layout();
    
    double dx = x;
    if (alignCenter) dx = x - tp.width / 2;
    if (alignRight) dx = x - tp.width;
    
    tp.paint(canvas, Offset(dx, y));
  }

  @override
  bool shouldRepaint(covariant ConvergenceComparisonPainter oldDelegate) {
    return oldDelegate.snapA != snapA || oldDelegate.snapB != snapB;
  }
}
