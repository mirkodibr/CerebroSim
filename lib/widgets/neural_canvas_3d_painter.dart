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
  final ColorScheme colorScheme;

  NeuralCanvas3DPainter({
    required this.state,
    required this.rotX,
    required this.rotY,
    required this.zoom,
    required this.colorScheme,
    this.selectedNeuronId,
    super.repaint,
  });

  /// Calculates a procedural 3D position for a neuron based on its cell type.
  static Offset3D calculateProceduralPosition(NeuronModel n, Map<String, List<NeuronModel>> grouped) {
    final sameType = grouped[n.cellType] ?? [];
    final index = sameType.indexWhere((element) => element.id == n.id);
    final count = sameType.length;

    double x = 0;
    double y = 0;
    double z = 0;

    switch (n.cellType) {
      case 'GC':
        y = -1.2;
        final side = math.sqrt(count).ceil();
        final row = index ~/ side;
        final col = index % side;
        x = (col - (side - 1) / 2) * 0.8;
        z = (row - (side - 1) / 2) * 0.8;
        break;
      case 'PC':
        y = 0.0;
        x = count > 1 ? (index - (count - 1) / 2) * 1.5 : 0.0;
        z = 0.0;
        break;
      case 'BC':
        y = 0.4;
        x = count > 1 ? (index - (count - 1) / 2) * 1.2 : 0.4;
        z = -0.5;
        break;
      case 'SC':
        y = 0.8;
        x = count > 1 ? (index - (count - 1) / 2) * 1.0 : -0.4;
        z = 0.5;
        break;
      case 'DCN':
        y = -2.0;
        x = count > 1 ? (index - (count - 1) / 2) * 1.0 : 0.0;
        z = 0.2;
        break;
      case 'CF':
        y = -1.8;
        x = -1.5;
        z = 0.0;
        break;
    }

    final random = math.Random(n.id.hashCode);
    x += (random.nextDouble() - 0.5) * 0.15;
    y += (random.nextDouble() - 0.5) * 0.15;
    z += (random.nextDouble() - 0.5) * 0.15;

    return Offset3D(x, y, z);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;

    _drawLayers(canvas, size);

    final Map<String, List<NeuronModel>> grouped = {};
    for (final n in state.neurons.values) {
      grouped.putIfAbsent(n.cellType, () => []).add(n);
    }

    final Map<String, ProjectedPoint> projectedNeurons = {};
    for (final n in state.neurons.values) {
      final pos3d = calculateProceduralPosition(n, grouped);
      projectedNeurons[n.id] = Neural3DProjection.project(
        pos3d,
        rotX: rotX,
        rotY: rotY,
        zoom: zoom,
        centerX: centerX,
        centerY: centerY,
      );
    }

    final List<_DepthItem> items = [];

    for (final n in state.neurons.values) {
      final p = projectedNeurons[n.id];
      if (p != null) {
        items.add(_NeuronItem(n, p, colorScheme, isSelected: n.id == selectedNeuronId));
      }
    }

    for (final s in state.synapses) {
      final pFrom = projectedNeurons[s.fromNeuronId];
      final pTo = projectedNeurons[s.toNeuronId];
      if (pFrom != null && pTo != null) {
        items.add(_SynapseItem(s, pFrom, pTo));
      }
    }

    items.sort((a, b) => b.depth.compareTo(a.depth));

    for (final item in items) {
      item.draw(canvas);
    }
  }

  void _drawLayers(Canvas canvas, Size size) {
    final h = size.height / 3;
    
    final molecularPaint = Paint()..color = colorScheme.primary.withValues(alpha: 0.1);
    final purkinjePaint = Paint()..color = colorScheme.secondary.withValues(alpha: 0.1);
    final granularPaint = Paint()..color = colorScheme.tertiary.withValues(alpha: 0.1);

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, h), molecularPaint);
    canvas.drawRect(Rect.fromLTWH(0, h, size.width, h), purkinjePaint);
    canvas.drawRect(Rect.fromLTWH(0, 2 * h, size.width, h), granularPaint);
  }

  @override
  bool shouldRepaint(covariant NeuralCanvas3DPainter oldDelegate) {
    return true;
  }
}

abstract class _DepthItem {
  double get depth;
  void draw(Canvas canvas);
}

class _NeuronItem extends _DepthItem {
  final NeuronModel neuron;
  final ProjectedPoint projected;
  final bool isSelected;
  final ColorScheme colorScheme;

  _NeuronItem(this.neuron, this.projected, this.colorScheme, {this.isSelected = false});

  @override
  double get depth => projected.zDepth;

  @override
  void draw(Canvas canvas) {
    final pos = Offset(projected.x, projected.y);
    final radius = 12.0 * projected.scale / 30.0;
    
    final paint = Paint()
      ..color = _getNeuronColor(neuron.cellType)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(pos, radius, paint);

    if (neuron.isFiring || isSelected) {
      canvas.drawCircle(
        pos,
        radius * 1.3,
        Paint()
          ..color = isSelected ? colorScheme.onSurface : colorScheme.onSurface.withValues(alpha: 0.5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0,
      );
    }

    final double sweepAngle = 2 * math.pi * neuron.membranePotential.clamp(0.0, 1.0);
    canvas.drawArc(
      Rect.fromCircle(center: pos, radius: radius * 0.85),
      -math.pi / 2,
      sweepAngle,
      false,
      Paint()
        ..color = colorScheme.onSurface.withValues(alpha: 0.6)
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
      case 'SC': return const Color(0xFF00FFFF);
      default: return colorScheme.outline;
    }
  }
}

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

  void _drawDashedLine(Canvas canvas, Offset p1, Offset p2, Paint paint) {
    const dashWidth = 6.0;
    const dashSpace = 4.0;
    final distance = (p2 - p1).distance;
    if (distance == 0) return;
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
