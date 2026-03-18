import 'package:flutter/material.dart';
import '../models/neuron.dart';
import '../models/simulation_state.dart';
import '../theme.dart';

class NeuralCanvas extends StatelessWidget {
  final SimulationState state;

  const NeuralCanvas({
    super.key,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.infinite,
      painter: _NeuralPainter(state: state),
    );
  }
}

class _NeuralPainter extends CustomPainter {
  final SimulationState state;

  _NeuralPainter({required this.state});

  Color _getNeuronColor(String type) {
    switch (type) {
      case 'Purkinje':
        return CerebroTheme.neonCyan; // Actor
      case 'SC':
        return Colors.purpleAccent; // Critic (Stellate Cell)
      case 'DCN':
        return Colors.orangeAccent; // Output (Deep Cerebellar Nuclei)
      case 'BC':
        return Colors.redAccent; // Inhibitor (Basket Cell)
      case 'Granular':
        return Colors.tealAccent; // Input (Parallel Fiber)
      default:
        return Colors.grey.shade600;
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final synapsePaint = Paint()
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final neuronPaint = Paint()
      ..style = PaintingStyle.fill;

    // 1. Draw Synapses (Lines)
    for (final synapse in state.synapses) {
      // Find source and target safely
      final source = state.neurons.firstWhere((n) => n.id == synapse.sourceId, 
          orElse: () => Neuron(id: '', type: '', threshold: 0, currentPotential: 0));
      final target = state.neurons.firstWhere((n) => n.id == synapse.targetId,
          orElse: () => Neuron(id: '', type: '', threshold: 0, currentPotential: 0));

      if (source.id.isEmpty || target.id.isEmpty) continue;

      // Color synapse by target type
      final targetColor = _getNeuronColor(target.type);
      synapsePaint.color = targetColor.withValues(
        alpha: (synapse.weight * 0.4).clamp(0.05, 0.6),
      );
      
      canvas.drawLine(
        Offset(source.x, source.y),
        Offset(target.x, target.y),
        synapsePaint,
      );
    }

    // 2. Draw Neurons (Circles)
    for (final neuron in state.neurons) {
      final isSpiking = neuron.currentPotential >= neuron.threshold && neuron.threshold > 0;
      final baseColor = _getNeuronColor(neuron.type);
      
      // Spiking neurons glow with their cell-type color, others are dimmed
      neuronPaint.color = isSpiking 
          ? baseColor 
          : baseColor.withValues(alpha: 0.2);

      // Draw shadow/glow for spiking neurons
      if (isSpiking) {
        canvas.drawCircle(
          Offset(neuron.x, neuron.y),
          8.0,
          Paint()
            ..color = baseColor.withValues(alpha: 0.4)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0),
        );
      }

      // Draw the main neuron body
      canvas.drawCircle(
        Offset(neuron.x, neuron.y),
        5.0,
        neuronPaint,
      );

      // Add a small label for cell types (optional, subtle)
      if (neuron.type == 'DCN') {
        _drawSmallLabel(canvas, neuron.actionGroup ?? 'DCN', Offset(neuron.x + 8, neuron.y - 8), baseColor);
      }
    }
  }

  void _drawSmallLabel(Canvas canvas, String text, Offset offset, Color color) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(color: color.withValues(alpha: 0.7), fontSize: 8, fontWeight: FontWeight.bold),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant _NeuralPainter oldDelegate) {
    return oldDelegate.state != state;
  }
}
