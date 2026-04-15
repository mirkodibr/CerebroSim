import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/simulation_state.dart';
import '../models/neuron_model.dart';
import '../models/synapse_model.dart';
import '../services/neural_3d_projection.dart';

/// A custom painter that renders the cerebellar microcircuit in 3D.
/// 
/// It implements the Painter's Algorithm by sorting all elements by depth
/// before drawing. It also visualizes neural activity through dynamic arcs.
class NeuralCanvas3DPainter extends CustomPainter {
  final SimulationState state;
  final double rotX;
  final double rotY;
  final double zoom;
  final String? selectedNeuronId;

  NeuralCanvas3DPainter({
    required this.state,
    required this.rotX,
    required this.rotY,
    required this.zoom,
    this.selectedNeuronId,
    super.repaint,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;

    // 1. Draw Background Layers (40% opacity)
    _drawLayers(canvas, size);

    // 2. Project all neurons to determine 2D positions and depth
    final Map<String, ProjectedPoint> projectedNeurons = {};
    for (final n in state.neurons.values) {
      final pos3d = Neural3DProjection.kNeuronPositions[n.id];
      if (pos3d == null) continue;
      projectedNeurons[n.id] = Neural3DProjection.project(
        pos3d,
        rotX: rotX,
        rotY: rotY,
        zoom: zoom,
        centerX: centerX,
        centerY: centerY,
      );
    }

    // 3. Collect all drawable items for sorting
    final List<_DepthItem> items = [];

    // Add neurons
    for (final n in state.neurons.values) {
      final p = projectedNeurons[n.id];
      if (p != null) {
        items.add(_NeuronItem(n, p, isSelected: n.id == selectedNeuronId));
      }
    }

    // Add synapses
    for (final s in state.synapses) {
      final pFrom = projectedNeurons[s.fromNeuronId];
      final pTo = projectedNeurons[s.toNeuronId];
      if (pFrom != null && pTo != null) {
        items.add(_SynapseItem(s, pFrom, pTo));
      }
    }

    // 4. Painter's Algorithm: Sort by depth (furthest first)
    // In our projection, larger zDepth means further away from the camera.
    items.sort((a, b) => b.depth.compareTo(a.depth));

    // 5. Draw items in order
    for (final item in items) {
      item.draw(canvas);
    }
  }

  /// Draws the horizontal bands representing cerebellar layers.
  void _drawLayers(Canvas canvas, Size size) {
    final h = size.height / 3;
    final molecularPaint = Paint()..color = const Color(0xFF0A1A2A).withValues(alpha: 0.4);
    final purkinjePaint = Paint()..color = const Color(0xFF0F0A1A).withValues(alpha: 0.4);
    final granularPaint = Paint()..color = const Color(0xFF0A1A0A).withValues(alpha: 0.4);

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, h), molecularPaint);
    canvas.drawRect(Rect.fromLTWH(0, h, size.width, h), purkinjePaint);
    canvas.drawRect(Rect.fromLTWH(0, 2 * h, size.width, h), granularPaint);
  }

  @override
  bool shouldRepaint(covariant NeuralCanvas3DPainter oldDelegate) {
    // Repaint on every tick for smooth real-time activity visualization
    return true;
  }
}

/// Abstract base for depth-sortable drawable items.
abstract class _DepthItem {
  double get depth;
  void draw(Canvas canvas);
}

/// A drawable representation of a neuron in 3D space.
class _NeuronItem extends _DepthItem {
  final NeuronModel neuron;
  final ProjectedPoint projected;
  final bool isSelected;

  _NeuronItem(this.neuron, this.projected, {this.isSelected = false});

  @override
  double get depth => projected.zDepth;

  @override
  void draw(Canvas canvas) {
    final pos = Offset(projected.x, projected.y);
    // Base radius 12.0 scaled by perspective
    final radius = 12.0 * projected.scale / 30.0;
    
    final paint = Paint()
      ..color = _getNeuronColor(neuron.cellType)
      ..style = PaintingStyle.fill;

    // Draw core neuron body
    canvas.drawCircle(pos, radius, paint);

    // Selection/Firing indicator
    if (neuron.isFiring || isSelected) {
      canvas.drawCircle(
        pos,
        radius * 1.3,
        Paint()
          ..color = isSelected ? Colors.white : Colors.white.withValues(alpha: 0.5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0,
      );
    }

    // Live electrical activity arc (60% white)
    // Sweep angle is proportional to membrane potential (0 to 2*PI)
    final double sweepAngle = 2 * math.pi * neuron.membranePotential.clamp(0.0, 1.0);
    canvas.drawArc(
      Rect.fromCircle(center: pos, radius: radius * 0.85),
      -math.pi / 2,
      sweepAngle,
      false,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.6)
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 3.0 * (projected.scale / 30.0),
    );
  }

  Color _getNeuronColor(String type) {
    switch (type) {
      case 'GC': return const Color(0xFFEF9F27);
      case 'PC': return const Color(0xFF8A2BE2);
      case 'BC': return const Color(0xFFD85A30);
      case 'DCN': return const Color(0xFF1D9E75);
      case 'CF': return const Color(0xFFE24B4A);
      default: return Colors.grey;
    }
  }
}

/// A drawable representation of a synapse in 3D space.
class _SynapseItem extends _DepthItem {
  final SynapseModel synapse;
  final ProjectedPoint from;
  final ProjectedPoint to;

  _SynapseItem(this.synapse, this.from, this.to);

  @override
  double get depth => (from.zDepth + to.zDepth) / 2;

  @override
  void draw(Canvas canvas) {
    final baseColor = synapse.isInhibitory ? const Color(0xFFFF4444) : const Color(0xFF00FFFF);
    
    // Alpha-fading based on average scale (depth proxy)
    final avgScale = (from.scale + to.scale) / 2;
    final opacity = (avgScale / 60.0).clamp(0.1, 0.8);
    
    final paint = Paint()
      ..color = baseColor.withValues(alpha: opacity)
      ..strokeWidth = (synapse.weight.abs() * 3.0 + 0.5) * (avgScale / 30.0)
      ..style = PaintingStyle.stroke;

    if (synapse.isInhibitory) {
      _drawDashedLine(canvas, Offset(from.x, from.y), Offset(to.x, to.y), paint);
    } else {
      canvas.drawLine(Offset(from.x, from.y), Offset(to.x, to.y), paint);
    }
  }

  /// Helper to draw dashed lines for inhibitory synapses.
  void _drawDashedLine(Canvas canvas, Offset p1, Offset p2, Paint paint) {
    const dashWidth = 6.0;
    const dashSpace = 4.0;
    final distance = (p2 - p1).distance;
    final direction = (p2 - p1) / distance;
    double currentPos = 0.0;
    
    while (currentPos < distance) {
      final end = currentPos + dashWidth;
      canvas.drawLine(
        p1 + direction * currentPos,
        p1 + direction * (end > distance ? distance : end),
        paint,
      );
      currentPos += dashWidth + dashSpace;
    }
  }
}
