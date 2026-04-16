import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/episode_record.dart';
import '../providers/episode_history_provider.dart';

/// A widget that visualizes the convergence of the simulation over multiple episodes.
///
/// It displays a line chart showing how the mean punishment and final TD error
/// evolve as the network learns.
class ConvergenceChart extends ConsumerWidget {
  const ConvergenceChart({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(episodeHistoryProvider);
    final theme = Theme.of(context);

    if (history.length < 2) {
      return Center(
        child: Text(
          'Run episodes to see convergence',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: CustomPaint(
        size: Size.infinite,
        painter: ConvergenceChartPainter(
          history: history,
          labelStyle: theme.textTheme.labelSmall ?? const TextStyle(),
          colorScheme: theme.colorScheme,
        ),
      ),
    );
  }
}

/// Painter for the convergence chart lines and axes.
class ConvergenceChartPainter extends CustomPainter {
  final List<EpisodeRecord> history;
  final TextStyle labelStyle;
  final ColorScheme colorScheme;

  ConvergenceChartPainter({
    required this.history,
    required this.labelStyle,
    required this.colorScheme,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (history.isEmpty) return;

    const double leftMargin = 40.0;
    const double bottomMargin = 20.0;
    final double chartWidth = size.width - leftMargin;
    final double chartHeight = size.height - bottomMargin;

    final Paint gridPaint = Paint()
      ..color = colorScheme.onSurface.withValues(alpha: 0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    final Paint axisPaint = Paint()
      ..color = colorScheme.outline.withValues(alpha: 0.3)
      ..strokeWidth = 1.0;

    // Draw Gridlines and Y-axis labels
    final List<double> gridValues = [0.0, 0.25, 0.5, 0.75, 1.0];
    for (final val in gridValues) {
      final double y = chartHeight - (val * chartHeight);
      
      // Dashed gridline
      _drawDashedLine(canvas, Offset(leftMargin, y), Offset(size.width, y), gridPaint);

      // Y-axis label
      final TextPainter tp = TextPainter(
        text: TextSpan(
          text: val.toStringAsFixed(2),
          style: labelStyle.copyWith(color: colorScheme.onSurface.withValues(alpha: 0.5), fontSize: 10),
        ),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.right,
      )..layout(maxWidth: 36);
      tp.paint(canvas, Offset(0, y - tp.height / 2));
    }

    // Draw X-axis labels
    final firstEp = history.first.episodeNumber;
    final lastEp = history.last.episodeNumber;
    
    _drawXLabel(canvas, firstEp.toString(), leftMargin, size.height - tpHeight('0'));
    _drawXLabel(canvas, lastEp.toString(), size.width - 20, size.height - tpHeight('0'));

    // Draw axes
    canvas.drawLine(Offset(leftMargin, chartHeight), Offset(size.width, chartHeight), axisPaint);
    canvas.drawLine(Offset(leftMargin, 0), Offset(leftMargin, chartHeight), axisPaint);

    final int count = history.length;
    final double dx = chartWidth / (count - 1).clamp(1, count);

    // Paints for the two metrics
    final Paint punishmentPaint = Paint()
      ..color = const Color(0xFFE24B4A) // Red
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final Paint tdErrorPaint = Paint()
      ..color = const Color(0xFF00FFFF) // Cyan
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final Path punishmentPath = Path();
    final Path tdErrorPath = Path();

    for (int i = 0; i < count; i++) {
      final record = history[i];
      final double x = leftMargin + (i * dx);
      
      // Normalize Y (hardcoded 1.0 scale as per prompt)
      final double yPunishment = chartHeight - (record.meanPunishment.clamp(0.0, 1.0) * chartHeight);
      final double yTdError = chartHeight - (record.finalTdError.abs().clamp(0.0, 1.0) * chartHeight);

      if (i == 0) {
        punishmentPath.moveTo(x, yPunishment);
        tdErrorPath.moveTo(x, yTdError);
      } else {
        punishmentPath.lineTo(x, yPunishment);
        tdErrorPath.lineTo(x, yTdError);
      }
    }

    canvas.drawPath(punishmentPath, punishmentPaint);
    canvas.drawPath(tdErrorPath, tdErrorPaint);

    // Draw Legend with current values
    _drawLegend(canvas, leftMargin, chartWidth, punishmentPaint.color, tdErrorPaint.color);
  }

  void _drawDashedLine(Canvas canvas, Offset p1, Offset p2, Paint paint) {
    const dashWidth = 4.0;
    const dashSpace = 4.0;
    double currentX = p1.dx;
    while (currentX < p2.dx) {
      canvas.drawLine(Offset(currentX, p1.dy), Offset(currentX + dashWidth, p1.dy), paint);
      currentX += dashWidth + dashSpace;
    }
  }

  double tpHeight(String text) {
    return (TextPainter(
      text: TextSpan(text: text, style: labelStyle),
      textDirection: TextDirection.ltr,
    )..layout()).height;
  }

  void _drawXLabel(Canvas canvas, String text, double x, double y) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: labelStyle.copyWith(fontSize: 10, color: colorScheme.onSurface.withValues(alpha: 0.5))),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(x, y));
  }

  void _drawLegend(Canvas canvas, double left, double width, Color punishmentColor, Color tdErrorColor) {
    final last = history.last;
    final TextPainter tpPunishment = TextPainter(
      text: TextSpan(
        text: 'Punishment: ${last.meanPunishment.toStringAsFixed(3)}', 
        style: labelStyle.copyWith(color: punishmentColor, fontWeight: FontWeight.bold)
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final TextPainter tpTdError = TextPainter(
      text: TextSpan(
        text: '|TD error|: ${last.finalTdError.abs().toStringAsFixed(3)}', 
        style: labelStyle.copyWith(color: tdErrorColor, fontWeight: FontWeight.bold)
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    tpPunishment.paint(canvas, Offset(left + width - tpPunishment.width - 8, 4));
    tpTdError.paint(canvas, Offset(left + width - tpTdError.width - 8, tpPunishment.height + 8));
  }

  @override
  bool shouldRepaint(covariant ConvergenceChartPainter oldDelegate) {
    return oldDelegate.history != history;
  }
}
