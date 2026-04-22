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
              Text(
                'Convergence Comparison',
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
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
              painter: _ComparisonPainter(
                snapA: snapshotA,
                snapB: snapshotB,
                colorA: const Color(0xFF00FFFF),
                colorB: Colors.amber,
                gridColor: colorScheme.outline.withValues(alpha: 0.2),
                labelStyle: theme.textTheme.labelSmall ?? const TextStyle(),
              ),
            ),
          ),
          const SizedBox(height: 24),
          _buildDetailRow(context, 'Total Episodes', 
            '${snapshotA.episodeCount}', '${snapshotB.episodeCount}'),
          _buildDetailRow(context, 'Final Error', 
            snapshotA.finalErrorRate.toStringAsFixed(4), snapshotB.finalErrorRate.toStringAsFixed(4)),
        ],
      ),
    );
  }

  Widget _buildLegend(BuildContext context) {
    return Row(
      children: [
        _LegendItem(label: snapshotA.title, color: const Color(0xFF00FFFF)),
        const SizedBox(width: 16),
        _LegendItem(label: snapshotB.title, color: Colors.amber),
      ],
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String valA, String valB) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label, style: theme.textTheme.bodySmall)),
          Text(valA, style: theme.textTheme.bodyMedium?.copyWith(color: const Color(0xFF00FFFF), fontWeight: FontWeight.bold)),
          const SizedBox(width: 24),
          Text(valB, style: theme.textTheme.bodyMedium?.copyWith(color: Colors.amber, fontWeight: FontWeight.bold)),
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
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _ComparisonPainter extends CustomPainter {
  final ExperimentSnapshot snapA;
  final ExperimentSnapshot snapB;
  final Color colorA;
  final Color colorB;
  final Color gridColor;
  final TextStyle labelStyle;

  _ComparisonPainter({
    required this.snapA,
    required this.snapB,
    required this.colorA,
    required this.colorB,
    required this.gridColor,
    required this.labelStyle,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.height <= 0 || size.width <= 0) return;

    const double leftMargin = 48.0;
    const double rightMargin = 48.0;
    const double topMargin = 32.0;
    const double bottomMargin = 16.0;

    final double maxVal = math.max(0.01, math.max(snapA.finalErrorRate, snapB.finalErrorRate) * 1.2);
    final double innerHeight = size.height - topMargin - bottomMargin;

    final paintGrid = Paint()..color = gridColor..strokeWidth = 1.0;
    final paintLine = Paint()
      ..color = colorA
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;
    final paintPointA = Paint()..color = colorA..style = PaintingStyle.fill;
    final paintPointB = Paint()..color = colorB..style = PaintingStyle.fill;

    // Draw horizontal grid lines
    for (int i = 0; i <= 4; i++) {
      final double val = maxVal * (i / 4);
      final double y = topMargin + (val / maxVal) * innerHeight;
      canvas.drawLine(Offset(leftMargin, y), Offset(size.width - rightMargin, y), paintGrid);

      // Y-axis labels
      final tp = TextPainter(
        text: TextSpan(
          text: val.toStringAsFixed(2),
          style: labelStyle.copyWith(color: Colors.grey, fontSize: 9),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(leftMargin - tp.width - 8, y - tp.height / 2));
    }

    final double x1 = leftMargin;
    final double x2 = size.width - rightMargin;
    
    // Higher error = lower on chart (Higher Y value)
    final double y1 = topMargin + (snapA.finalErrorRate / maxVal) * innerHeight;
    final double y2 = topMargin + (snapB.finalErrorRate / maxVal) * innerHeight;

    // Draw connecting line
    canvas.drawLine(Offset(x1, y1), Offset(x2, y2), paintLine);

    // Draw points
    canvas.drawCircle(Offset(x1, y1), 6, paintPointA);
    canvas.drawCircle(Offset(x2, y2), 6, paintPointB);

    // Draw value labels above dots
    _drawText(canvas, snapA.finalErrorRate.toStringAsFixed(3), x1, y1 - 20, colorA, true);
    _drawText(canvas, snapB.finalErrorRate.toStringAsFixed(3), x2, y2 - 20, colorB, true);

    // Draw header titles (truncated)
    _drawText(canvas, _truncate(snapA.title, 8), x1, 8, colorA, true);
    _drawText(canvas, _truncate(snapB.title, 8), x2, 8, colorB, true);
  }

  void _drawText(Canvas canvas, String text, double x, double y, Color color, bool center) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: labelStyle.copyWith(color: color, fontWeight: FontWeight.bold, fontSize: 10),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    
    final double xPos = center ? x - tp.width / 2 : x;
    tp.paint(canvas, Offset(xPos, y));
  }

  String _truncate(String text, int maxChars) {
    if (text.length <= maxChars) return text;
    return '${text.substring(0, maxChars)}…';
  }

  @override
  bool shouldRepaint(covariant _ComparisonPainter oldDelegate) {
    return oldDelegate.snapA != snapA || oldDelegate.snapB != snapB;
  }
}
