import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/cerebellar_task.dart';
import '../providers/environment_provider.dart';
import '../providers/plot_buffer_provider.dart';
import '../services/plot_ring_buffer.dart';

/// A widget that displays a real-time line chart of simulation signals.
class SignalPlotter extends ConsumerWidget {
  const SignalPlotter({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final task = ref.watch(environmentProvider);
    // Watch the tick to trigger repaints
    final tick = ref.watch(plotBufferProvider);
    final ringBuffer = ref.read(plotRingBufferProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
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
                    buffer: ringBuffer,
                    tick: tick,
                    isVor: task == CerebellarTask.vor,
                    colorScheme: colorScheme,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

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

class SignalPlotterPainter extends CustomPainter {
  final PlotRingBuffer buffer;
  final int tick;
  final bool isVor;
  final ColorScheme colorScheme;

  late final TextPainter _labelTop = _makeLabel("1");
  late final TextPainter _labelBottom = _makeLabel("-1");

  SignalPlotterPainter({
    required this.buffer,
    required this.tick,
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
    _drawReferenceLines(canvas, size);

    final int filled = buffer.filled;
    if (filled == 0) return;

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

    final double stepX = size.width / (filled > 1 ? filled - 1 : 1);
    final int start = filled < buffer.capacity ? 0 : buffer.writeIndex;

    for (int i = 0; i < filled; i++) {
      final int index = (start + i) % buffer.capacity;
      final x = i * stepX;

      double mapY(double val) => size.height / 2 - (val * size.height / 2);

      if (i == 0) {
        pathCritic.moveTo(x, mapY(buffer.criticPrediction[index]));
        pathActual.moveTo(x, mapY(buffer.actualSignal[index]));
        pathGain.moveTo(x, mapY(buffer.gainRatio[index]));
      } else {
        pathCritic.lineTo(x, mapY(buffer.criticPrediction[index]));
        pathActual.lineTo(x, mapY(buffer.actualSignal[index]));
        pathGain.lineTo(x, mapY(buffer.gainRatio[index]));
      }
    }

    canvas.drawPath(pathCritic, paintCritic);
    canvas.drawPath(pathActual, paintActual);
    if (isVor) {
      canvas.drawPath(pathGain, paintGain);
    }

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

    _drawDashedLine(canvas, Offset(0, size.height / 2),
        Offset(size.width, size.height / 2), centerPaint);

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
    return oldDelegate.tick != tick || oldDelegate.isVor != isVor;
  }
}
