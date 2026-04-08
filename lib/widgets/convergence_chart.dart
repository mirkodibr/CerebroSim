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
            color: theme.colorScheme.onSurface.withOpacity(0.5),
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
        ),
      ),
    );
  }
}

/// Painter for the convergence chart lines and axes.
class ConvergenceChartPainter extends CustomPainter {
  final List<EpisodeRecord> history;
  final TextStyle labelStyle;

  ConvergenceChartPainter({
    required this.history,
    required this.labelStyle,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double width = size.width;
    final double height = size.height;

    final Paint axisPaint = Paint()
      ..color = Colors.grey.withOpacity(0.3)
      ..strokeWidth = 1.0;

    // Draw axes
    canvas.drawLine(Offset(0, height), Offset(width, height), axisPaint);
    canvas.drawLine(Offset(0, 0), Offset(0, height), axisPaint);

    if (history.isEmpty) return;

    final int count = history.length;
    final double dx = width / (count - 1).clamp(1, count);

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

    // Find max values for normalization
    double maxPunishment = 0.1;
    double maxTdError = 0.1;
    for (var record in history) {
      if (record.meanPunishment > maxPunishment) maxPunishment = record.meanPunishment;
      if (record.finalTdError.abs() > maxTdError) maxTdError = record.finalTdError.abs();
    }
    
    // Add some padding to max
    maxPunishment *= 1.2;
    maxTdError *= 1.2;

    for (int i = 0; i < count; i++) {
      final record = history[i];
      final double x = i * dx;
      
      // Normalize Y (inverted for canvas coordinates)
      final double yPunishment = height - (record.meanPunishment / maxPunishment * height).clamp(0, height);
      final double yTdError = height - (record.finalTdError.abs() / maxTdError * height).clamp(0, height);

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

    // Draw Legend
    _drawLegend(canvas, width, punishmentPaint.color, tdErrorPaint.color);
  }

  void _drawLegend(Canvas canvas, double width, Color punishmentColor, Color tdErrorColor) {
    final TextPainter tpPunishment = TextPainter(
      text: TextSpan(text: 'Mean Punishment', style: labelStyle.copyWith(color: punishmentColor)),
      textDirection: TextDirection.ltr,
    )..layout();

    final TextPainter tpTdError = TextPainter(
      text: TextSpan(text: 'Final |TD Error|', style: labelStyle.copyWith(color: tdErrorColor)),
      textDirection: TextDirection.ltr,
    )..layout();

    tpPunishment.paint(canvas, Offset(width - tpPunishment.width - 8, 4));
    tpTdError.paint(canvas, Offset(width - tpTdError.width - 8, tpPunishment.height + 8));
  }

  @override
  bool shouldRepaint(covariant ConvergenceChartPainter oldDelegate) {
    return oldDelegate.history != history;
  }
}
