import 'package:flutter/material.dart';
import '../models/simulation_state.dart';
import '../models/neuron_model.dart';

class NeuralCanvasPainter extends CustomPainter {
  final SimulationState state;

  NeuralCanvasPainter({
    required this.state,
    required Listenable repaint,
  }) : super(repaint: repaint);

  static const Map<String, Offset> _fixedPositions = {
    'CF': Offset(0.15, 0.15),
    'GC': Offset(0.30, 0.80),
    'BC': Offset(0.55, 0.55),
    'PC': Offset(0.70, 0.50),
    'DCN': Offset(0.85, 0.75),
    'SC': Offset(0.45, 0.35), // Added SC position
  };

  static const Map<String, Color> _typeColors = {
    'GC': Color(0xFFEF9F27),
    'PC': Color(0xFF8A2BE2),
    'BC': Color(0xFFD85A30),
    'DCN': Color(0xFF1D9E75),
    'CF': Color(0xFFE24B4A),
    'SC': Color(0xFF00FFFF),
  };

  @override
  void paint(Canvas canvas, Size size) {
    _drawLayers(canvas, size);
    _drawSynapses(canvas, size);
    _drawNeurons(canvas, size);
  }

  void _drawLayers(Canvas canvas, Size size) {
    final h = size.height;
    final w = size.width;

    canvas.drawRect(Rect.fromLTWH(0, 0, w, h / 3), Paint()..color = const Color(0xFF0A1A2A));
    canvas.drawRect(Rect.fromLTWH(0, h / 3, w, h / 3), Paint()..color = const Color(0xFF0F0A1A));
    canvas.drawRect(Rect.fromLTWH(0, 2 * h / 3, w, h / 3), Paint()..color = const Color(0xFF0A1A0A));

    _drawLayerLabel(canvas, 'Molecular layer', 20, h / 6);
    _drawLayerLabel(canvas, 'Purkinje layer', 20, h / 2);
    _drawLayerLabel(canvas, 'Granular layer', 20, 5 * h / 6);
  }

  void _drawLayerLabel(Canvas canvas, String text, double x, double y) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(color: Colors.white38, fontSize: 14, fontWeight: FontWeight.bold),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(x, y - textPainter.height / 2));
  }

  void _drawSynapses(Canvas canvas, Size size) {
    for (final s in state.synapses) {
      final fromNeuron = state.neurons.firstWhere((n) => n.id == s.fromNeuronId, orElse: () => state.neurons.first);
      final toNeuron = state.neurons.firstWhere((n) => n.id == s.toNeuronId, orElse: () => state.neurons.first);

      final fromPos = getNeuronPos(fromNeuron, size);
      final toPos = getNeuronPos(toNeuron, size);

      final paint = Paint()
        ..strokeWidth = s.weight.abs().clamp(0.5, 3.0)
        ..style = PaintingStyle.stroke;

      if (s.isInhibitory) {
        paint.color = const Color(0xFFFF4444).withValues(alpha: 0.6);
        _drawDashedLine(canvas, fromPos, toPos, paint);
      } else {
        paint.color = const Color(0xFF00FFFF).withValues(alpha: 0.4);
        canvas.drawLine(fromPos, toPos, paint);
      }
    }
  }

  void _drawDashedLine(Canvas canvas, Offset p1, Offset p2, Paint paint) {
    const dashWidth = 5.0;
    const dashSpace = 3.0;
    double distance = (p2 - p1).distance;
    if (distance == 0) return;
    int count = (distance / (dashWidth + dashSpace)).floor();
    Offset direction = (p2 - p1) / distance;

    for (int i = 0; i < count; i++) {
      Offset start = p1 + direction * (i * (dashWidth + dashSpace));
      Offset end = start + direction * dashWidth;
      canvas.drawLine(start, end, paint);
    }
  }

  void _drawNeurons(Canvas canvas, Size size) {
    for (final n in state.neurons) {
      final pos = getNeuronPos(n, size);
      
      if (n.isFiring) {
        canvas.drawCircle(pos, 20.0, Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 2.0);
      }

      canvas.drawCircle(pos, 12.0, Paint()..color = _typeColors[n.cellType] ?? Colors.grey);

      final textPainter = TextPainter(
        text: TextSpan(text: n.cellType, style: const TextStyle(color: Colors.white, fontSize: 10)),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(pos.dx - textPainter.width / 2, pos.dy + 15));
    }
  }

  static Offset getNeuronPos(NeuronModel n, Size size) {
    final normPos = _fixedPositions[n.cellType] ?? Offset.zero;
    return Offset(normPos.dx * size.width, normPos.dy * size.height);
  }

  @override
  bool shouldRepaint(covariant NeuralCanvasPainter oldDelegate) {
    return true;
  }
}
