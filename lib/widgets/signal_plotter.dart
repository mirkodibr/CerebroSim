import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/plot_point.dart';
import '../models/cerebellar_task.dart';
import '../providers/environment_provider.dart';
import '../providers/plot_buffer_provider.dart';

/// A widget that displays a real-time line chart of simulation signals.
///
/// It visualizes the relationship between the cerebellar 'Critic' prediction,
/// the 'Actual' climbing fiber signal, and (for VOR tasks) the resulting 'Gain'.
class SignalPlotter extends ConsumerWidget {
  const SignalPlotter({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final task = ref.watch(environmentProvider);
    final buffer = ref.watch(plotBufferProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      height: 180,
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: colorScheme.scrim.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          _buildLegend(context, task),
          Expanded(
            child: CustomPaint(
              size: Size.infinite,
              painter: SignalPlotterPainter(
                buffer: buffer, 
                isVor: task == CerebellarTask.vor,
                colorScheme: colorScheme,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds a color-coded legend indicating which signal each line represents.
  Widget _buildLegend(BuildContext context, CerebellarTask task) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _legendItem(context, 'Critic', const Color(0xFF00FFFF)),
        const SizedBox(width: 16),
        _legendItem(context, 'Actual', const Color(0xFFEF9F27)),
        if (task == CerebellarTask.vor) ...[
          const SizedBox(width: 16),
          _legendItem(context, 'Gain', const Color(0xFF8A2BE2)),
        ],
      ],
    );
  }

  /// Helper for creating a single labeled legend item.
  Widget _legendItem(BuildContext context, String label, Color color) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.7), fontSize: 10)),
      ],
    );
  }
}

/// A [CustomPainter] that draws the signal paths on the canvas.
///
/// It maps normalized signal values (-1.0 to 1.0) to the vertical space of the
/// widget, where 0.0 is the vertical center.
class SignalPlotterPainter extends CustomPainter {
  final List<PlotPoint> buffer;
  final bool isVor;
  final ColorScheme colorScheme;

  late final TextPainter _labelTop = _makeLabel("1");
  late final TextPainter _labelBottom = _makeLabel("-1");

  SignalPlotterPainter({
    required this.buffer,
    required this.isVor,
    required this.colorScheme,
  });

  TextPainter _makeLabel(String text) => TextPainter(
        text: TextSpan(
            text: text,
            style: TextStyle(
                color: colorScheme.onSurface.withValues(alpha: 0.3),
                fontSize: 9)),
        textDirection: TextDirection.ltr,
      )..layout();

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Draw Reference Grid
    _drawReferenceLines(canvas, size);

    if (buffer.isEmpty) return;

    final paintCritic = Paint()
      ..color = const Color(0xFF00FFFF)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    final paintActual = Paint()
      ..color = const Color(0xFFEF9F27)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    final paintGain = Paint()
      ..color = const Color(0xFF8A2BE2)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final pathCritic = Path();
    final pathActual = Path();
    final pathGain = Path();

    final double stepX =
        size.width / (buffer.length > 1 ? buffer.length - 1 : 1);

    for (int i = 0; i < buffer.length; i++) {
      final x = i * stepX;

      /// Maps a value between -1 and 1 to a Y coordinate on the canvas.
      /// 1.0 maps to top, -1.0 maps to bottom, 0.0 maps to center.
      double mapY(double val) => size.height / 2 - (val * size.height / 2);

      if (i == 0) {
        pathCritic.moveTo(x, mapY(buffer[i].criticPrediction));
        pathActual.moveTo(x, mapY(buffer[i].actualSignal));
        pathGain.moveTo(x, mapY(buffer[i].gainRatio));
      } else {
        pathCritic.lineTo(x, mapY(buffer[i].criticPrediction));
        pathActual.lineTo(x, mapY(buffer[i].actualSignal));
        pathGain.lineTo(x, mapY(buffer[i].gainRatio));
      }
    }

    canvas.drawPath(pathCritic, paintCritic);
    canvas.drawPath(pathActual, paintActual);
    if (isVor) {
      canvas.drawPath(pathGain, paintGain);
    }

    // 2. Draw "Now" Indicator
    final nowPaint = Paint()
      ..color = colorScheme.secondary.withValues(alpha: 0.5)
      ..strokeWidth = 1.0;
    canvas.drawLine(
        Offset(size.width - 1, 0), Offset(size.width - 1, size.height), nowPaint);
  }

  void _drawReferenceLines(Canvas canvas, Size size) {
    final centerPaint = Paint()
      ..color = colorScheme.outline.withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    // Center horizontal line (y=0)
    _drawDashedLine(canvas, Offset(0, size.height / 2),
        Offset(size.width, size.height / 2), centerPaint);

    // Y-axis markers at +1 and -1
    _labelTop.paint(canvas, const Offset(2, 0));
    _labelBottom.paint(canvas, Offset(2, size.height - 12));
  }

  void _drawDashedLine(Canvas canvas, Offset p1, Offset p2, Paint paint) {
    const dashWidth = 4.0;
    const dashSpace = 4.0;
    double currentX = p1.dx;
    while (currentX < p2.dx) {
      canvas.drawLine(
          Offset(currentX, p1.dy), Offset(currentX + dashWidth, p1.dy), paint);
      currentX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant SignalPlotterPainter oldDelegate) {
    return oldDelegate.buffer != buffer;
  }
}
