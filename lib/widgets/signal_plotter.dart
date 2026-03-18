import 'package:flutter/material.dart';
import '../providers/environment_provider.dart';

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
            'Actor-Critic Performance',
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

    final predictedPaint = Paint()
      ..color = Colors.purpleAccent.withValues(alpha: 0.8)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final actualPaint = Paint()
      ..color = Colors.redAccent.withValues(alpha: 0.8)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final predictedPath = Path();
    final actualPath = Path();

    const int maxPoints = 200;
    final double stepX = size.width / (maxPoints - 1);
    final double midY = size.height / 2;
    final double trackHeight = size.height / 2.5;

    for (int i = 0; i < history.length; i++) {
      final x = i * stepX;
      
      // Predicted Punishment (Critic output)
      final py = (midY / 2) - (history[i].input * trackHeight / 2);
      if (i == 0) {
        predictedPath.moveTo(x, py);
      } else {
        predictedPath.lineTo(x, py);
      }

      // Actual Punishment (Environment CF signal)
      final ay = (size.height * 0.75) - (history[i].output * trackHeight / 2);
       if (i == 0) {
        actualPath.moveTo(x, ay);
      } else {
        actualPath.lineTo(x, ay);
      }
    }

    canvas.drawPath(predictedPath, predictedPaint);
    canvas.drawPath(actualPath, actualPaint);

    _drawLabel(canvas, "Predicted", const Offset(0, 0), Colors.purpleAccent);
    _drawLabel(canvas, "Actual CF", Offset(0, midY), Colors.redAccent);
    
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
