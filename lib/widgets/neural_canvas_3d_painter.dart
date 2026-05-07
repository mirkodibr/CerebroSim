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
  /// A static cache of calculated positions to avoid expensive math.Random 
  /// allocations on every frame.
  static final Map<String, Offset3D> _positionCache = {};

  final HotSimState state;
  final double rotX;
  final double rotY;
  final double zoom;
  final String? selectedNeuronId;
  final ColorScheme colorScheme;
  final double celebrationValue;

  final Paint _molecularPaint = Paint()..style = PaintingStyle.fill;
  final Paint _purkinjePaint = Paint()..style = PaintingStyle.fill;
  final Paint _granularPaint = Paint()..style = PaintingStyle.fill;
  final TextPainter _layerTextPainter = TextPainter(textDirection: TextDirection.ltr);

  final List<_DepthItem> _depthItems = [];
  final Map<String, List<NeuronModel>> _groupedNeurons = {};
  final Map<String, ProjectedPoint> _projectedNeurons = {};

  NeuralCanvas3DPainter({
    required this.state,
    required this.rotX,
    required this.rotY,
    required this.zoom,
    required this.colorScheme,
    this.selectedNeuronId,
    this.celebrationValue = 0.0,
    super.repaint,
  }) {
    _molecularPaint.color = colorScheme.primary.withValues(alpha: 0.15);
    _purkinjePaint.color = colorScheme.secondary.withValues(alpha: 0.15);
    _granularPaint.color = colorScheme.tertiary.withValues(alpha: 0.15);
  }

  /// Clears the static position cache. Should be called when the network structure changes.
  static void clearCache() => _positionCache.clear();

  /// Retrieves a cached position for a neuron or calculates it if missing.
  static Offset3D _getCachedPosition(NeuronModel n, Map<String, List<NeuronModel>> grouped) {
    if (_positionCache.containsKey(n.id)) {
      return _positionCache[n.id]!;
    }
    final pos = calculateProceduralPosition(n, grouped);
    _positionCache[n.id] = pos;
    return pos;
  }

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
        x = (col - (side - 1) / 2) * 1.4;
        z = (row - (side - 1) / 2) * 1.4;
        break;
      case 'PC':
        y = 0.0;
        x = count > 1 ? (index - (count - 1) / 2) * 2.0 : 0.0;
        z = 0.0;
        break;
      case 'BC':
        y = 0.4;
        x = count > 1 ? (index - (count - 1) / 2) * 1.8 : 0.4;
        z = -0.5;
        break;
      case 'SC':
        y = 0.8;
        x = count > 1 ? (index - (count - 1) / 2) * 1.0 : -0.4;
        z = 0.5;
        break;
      case 'DCN':
        y = -2.0;
        x = count > 1 ? (index - (count - 1) / 2) * 1.6 : 0.0;
        z = 0.2;
        break;
      case 'CF':
        y = -1.8;
        x = -1.5;
        z = 0.0;
        break;
    }

    // Add a minimum separation guarantee for large networks
    if (count > 6) {
      final spreadFactor = (count / 6.0).clamp(1.0, 3.0);
      x *= spreadFactor;
      z *= spreadFactor;
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

    _groupedNeurons.clear();
    for (final n in state.neurons.values) {
      _groupedNeurons.putIfAbsent(n.cellType, () => []).add(n);
    }

    _projectedNeurons.clear();
    for (final n in state.neurons.values) {
      final pos3d = _getCachedPosition(n, _groupedNeurons);
      _projectedNeurons[n.id] = Neural3DProjection.project(
        pos3d,
        rotX: rotX,
        rotY: rotY,
        zoom: zoom,
        centerX: centerX,
        centerY: centerY,
      );
    }

    _depthItems.clear();

    for (final n in state.neurons.values) {
      final p = _projectedNeurons[n.id];
      if (p != null) {
        _depthItems.add(_NeuronItem(
          n, 
          p, 
          colorScheme, 
          isSelected: n.id == selectedNeuronId,
          celebrationValue: celebrationValue,
        ));
      }
    }

    for (final s in state.synapses) {
      final pFrom = _projectedNeurons[s.fromNeuronId];
      final pTo = _projectedNeurons[s.toNeuronId];
      if (pFrom != null && pTo != null) {
        _depthItems.add(_SynapseItem(s, pFrom, pTo));
      }
    }

    _depthItems.sort((a, b) => b.depth.compareTo(a.depth));

    for (final item in _depthItems) {
      item.draw(canvas);
    }
  }

  void _drawLayers(Canvas canvas, Size size) {
    final h = size.height / 3;
    
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, h), _molecularPaint);
    canvas.drawRect(Rect.fromLTWH(0, h, size.width, h), _purkinjePaint);
    canvas.drawRect(Rect.fromLTWH(0, 2 * h, size.width, h), _granularPaint);

    _drawLayerLabel(canvas, 'Molecular', h * 0.5, size.width);
    _drawLayerLabel(canvas, 'Purkinje', h * 1.5, size.width);
    _drawLayerLabel(canvas, 'Granular', h * 2.5, size.width);
  }

  void _drawLayerLabel(Canvas canvas, String text, double y, double width) {
    _layerTextPainter.text = TextSpan(
      text: text,
      style: TextStyle(
        fontSize: 9,
        color: colorScheme.onSurface.withValues(alpha: 0.3),
        fontWeight: FontWeight.bold,
      ),
    );
    _layerTextPainter.layout();
    _layerTextPainter.paint(canvas, Offset(width - 60, y - _layerTextPainter.height / 2));
  }


  @override
  bool shouldRepaint(covariant NeuralCanvas3DPainter oldDelegate) {
    return oldDelegate.state.episodeStep != state.episodeStep ||
        oldDelegate.rotX != rotX ||
        oldDelegate.rotY != rotY ||
        oldDelegate.zoom != zoom ||
        oldDelegate.selectedNeuronId != selectedNeuronId ||
        oldDelegate.celebrationValue != celebrationValue ||
        oldDelegate.colorScheme != colorScheme;
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
  final double celebrationValue;

  static final Paint _fillPaint = Paint()..style = PaintingStyle.fill;
  static final Paint _strokePaint = Paint()..style = PaintingStyle.stroke;
  static final Paint _glowPaint = Paint()..style = PaintingStyle.fill;
  static final Paint _arcPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round;

  _NeuronItem(this.neuron, this.projected, this.colorScheme, {this.isSelected = false, this.celebrationValue = 0.0});

  @override
  double get depth => projected.zDepth;

  @override
  void draw(Canvas canvas) {
    final pos = Offset(projected.x, projected.y);
    final radius = 16.0 * projected.scale / 30.0;
    final neuronColor = _getNeuronColor(neuron.cellType);
    
    // Convergence celebration glow
    if (celebrationValue > 0) {
      final celebrateRadius = radius * (1.0 + celebrationValue);
      _glowPaint.color = neuronColor.withValues(alpha: 0.1 * celebrationValue);
      _glowPaint.maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
      canvas.drawCircle(pos, celebrateRadius * 2.5, _glowPaint);
    }

    if (neuron.isFiring) {
      _fillPaint.color = neuronColor.withValues(alpha: 0.25);
      canvas.drawCircle(pos, radius * 2.2, _fillPaint);
    }

    _fillPaint.color = neuronColor;
    canvas.drawCircle(pos, radius, _fillPaint);

    if (neuron.isFiring || isSelected) {
      _strokePaint.color = isSelected ? colorScheme.onSurface : colorScheme.onSurface.withValues(alpha: 0.5);
      _strokePaint.strokeWidth = 2.0;
      canvas.drawCircle(pos, radius * 1.3, _strokePaint);
    }

    final double sweepAngle = 2 * math.pi * neuron.membranePotential.clamp(0.0, 1.0);
    _arcPaint.color = neuronColor.withValues(alpha: 0.9);
    _arcPaint.strokeWidth = 4.0 * (projected.scale / 30.0);
    canvas.drawArc(
      Rect.fromCircle(center: pos, radius: radius * 0.85),
      -math.pi / 2,
      sweepAngle,
      false,
      _arcPaint,
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

  static final Paint _synapsePaint = Paint()..style = PaintingStyle.stroke;

  _SynapseItem(this.synapse, this.from, this.to);

  @override
  double get depth => (from.zDepth + to.zDepth) / 2;

  @override
  void draw(Canvas canvas) {
    final baseColor = synapse.isInhibitory ? const Color(0xFFFF4444) : const Color(0xFF00FFFF);
    final avgScale = (from.scale + to.scale) / 2;
    final opacity = (avgScale / 40.0).clamp(0.2, 0.9);
    
    _synapsePaint.color = baseColor.withValues(alpha: opacity);
    _synapsePaint.strokeWidth = (synapse.weight.abs() * 3.0 + 0.8) * (avgScale / 30.0);

    if (synapse.isInhibitory) {
      _drawDashedLine(canvas, Offset(from.x, from.y), Offset(to.x, to.y), _synapsePaint);
    } else {
      canvas.drawLine(Offset(from.x, from.y), Offset(to.x, to.y), _synapsePaint);
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

