import 'package:flutter/material.dart';
import '../providers/signal_provider.dart';

class SignalPlotter extends StatelessWidget {
  final List<HistoryPoint> history;

  const SignalPlotter({super.key, required this.history});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 150,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Signal Analysis',
            style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: ClipRect(
              child: CustomPaint(
                painter: _SignalPainter(history),
                size: Size.infinite,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SignalPainter extends CustomPainter {
  final List<HistoryPoint> history;

  _SignalPainter(this.history);

  @override
  void paint(Canvas canvas, Size size) {
    if (history.isEmpty) return;

    final inputPaint = Paint()
      ..color = Colors.cyanAccent.withValues(alpha: 0.8)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final outputPaint = Paint()
      ..color = Colors.orangeAccent.withValues(alpha: 0.8)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final inputPath = Path();
    final outputPath = Path();

    // Max 200 points as defined in SignalHistoryNotifier
    const int maxPoints = 200;
    final double stepX = size.width / (maxPoints - 1);
    final double midY = size.height / 2;
    final double trackHeight = size.height / 2.5;

    for (int i = 0; i < history.length; i++) {
      final x = i * stepX;
      
      // Input plot (Target) - centered in top half
      final inputY = (midY / 2) - (history[i].input * trackHeight / 2);
      if (i == 0) {
        inputPath.moveTo(x, inputY);
      } else {
        // Use step-like line for binary signals
        inputPath.lineTo(x, inputY);
      }

      // Output plot (Actual) - centered in bottom half
      final outputY = (size.height * 0.75) - (history[i].output * trackHeight / 2);
       if (i == 0) {
        outputPath.moveTo(x, outputY);
      } else {
        outputPath.lineTo(x, outputY);
      }
    }

    canvas.drawPath(inputPath, inputPaint);
    canvas.drawPath(outputPath, outputPaint);

    // Legend/Labels
    _drawLabel(canvas, "Target", const Offset(0, 0), Colors.cyanAccent);
    _drawLabel(canvas, "Actual", Offset(0, midY), Colors.orangeAccent);
    
    // Draw a divider
    final dividerPaint = Paint()
      ..color = Colors.white10
      ..strokeWidth = 1;
    canvas.drawLine(Offset(0, midY), Offset(size.width, midY), dividerPaint);
  }

  void _drawLabel(Canvas canvas, String text, Offset offset, Color color) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(color: color.withValues(alpha: 0.6), fontSize: 9, fontWeight: FontWeight.bold),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant _SignalPainter oldDelegate) => true;
}
