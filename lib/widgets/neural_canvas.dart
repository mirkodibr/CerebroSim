import 'package:flutter/material.dart';
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

  @override
  void paint(Canvas canvas, Size size) {
    final synapsePaint = Paint()
      ..color = Colors.white24
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final neuronPaint = Paint()
      ..style = PaintingStyle.fill;

    // 1. Draw Synapses (Lines)
    for (final synapse in state.synapses) {
      final source = state.neurons.firstWhere((n) => n.id == synapse.sourceId);
      final target = state.neurons.firstWhere((n) => n.id == synapse.targetId);

      // Adjust color based on weight
      synapsePaint.color = CerebroTheme.neonCyan.withValues(
        alpha: (synapse.weight * 0.5).clamp(0.1, 0.8),
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
      
      // Spiking neurons glow bright neon cyan, others are dimmed
      neuronPaint.color = isSpiking 
          ? CerebroTheme.neonCyan 
          : Colors.grey.shade800;

      // Draw shadow/glow for spiking neurons
      if (isSpiking) {
        canvas.drawCircle(
          Offset(neuron.x, neuron.y),
          8.0,
          Paint()
            ..color = CerebroTheme.neonCyan.withValues(alpha: 0.3)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0),
        );
      }

      canvas.drawCircle(
        Offset(neuron.x, neuron.y),
        5.0,
        neuronPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _NeuralPainter oldDelegate) {
    return oldDelegate.state != state;
  }
}
