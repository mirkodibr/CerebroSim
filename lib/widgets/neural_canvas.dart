import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/simulation_state.dart';
import '../providers/simulation_provider.dart';
import '../services/neural_3d_projection.dart';
import 'neuron_detail_sheet.dart';
import 'neural_canvas_3d_painter.dart';

/// An interactive 3D visualization of the cerebellar microcircuit.
/// 
/// This widget allows users to rotate and zoom into the neural model using
/// touch gestures. It leverages [Neural3DProjection] for math and 
/// [NeuralCanvas3DPainter] for rendering depth-sorted neurons and synapses.
class NeuralCanvas3D extends ConsumerStatefulWidget {
  const NeuralCanvas3D({super.key});

  @override
  ConsumerState<NeuralCanvas3D> createState() => NeuralCanvas3DState();
}

class NeuralCanvas3DState extends ConsumerState<NeuralCanvas3D> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  
  // State fields for 3D view
  double _rotX = 0.4;
  double _rotY = 0.6;
  double _zoom = 120.0;
  String? _selectedNeuronId;

  // For zoom tracking
  double _baseZoom = 120.0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  /// Resets the view to the default rotation and zoom.
  void resetView() {
    setState(() {
      _rotX = 0.4;
      _rotY = 0.6;
      _zoom = 120.0;
    });
  }

  /// Handles tap events to select a neuron in 3D space.
  void _handleTapUp(TapUpDetails details) {
    final RenderBox box = context.findRenderObject() as RenderBox;
    final Offset localPos = box.globalToLocal(details.globalPosition);
    final Size size = box.size;
    final centerX = size.width / 2;
    final centerY = size.height / 2;

    final state = ref.read(simulationProvider);
    String? nearestId;
    double minDistance = 28.0;

    for (final n in state.neurons) {
      final pos3d = Neural3DProjection.kNeuronPositions[n.id];
      if (pos3d == null) continue;

      final projected = Neural3DProjection.project(
        pos3d,
        rotX: _rotX,
        rotY: _rotY,
        zoom: _zoom,
        centerX: centerX,
        centerY: centerY,
      );

      final distance = (localPos - Offset(projected.x, projected.y)).distance;
      if (distance < minDistance) {
        minDistance = distance;
        nearestId = n.id;
      }
    }

    setState(() {
      _selectedNeuronId = nearestId;
    });

    if (nearestId != null) {
      final neuron = state.neurons.firstWhere((n) => n.id == nearestId);
      showModalBottomSheet(
        context: context,
        backgroundColor: const Color(0xFF1E1E1E),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) => NeuronDetailSheet(neuron: neuron),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(simulationProvider);

    return GestureDetector(
      onTapUp: _handleTapUp,
      onScaleStart: (details) {
        _baseZoom = _zoom;
      },
      onScaleUpdate: (details) {
        setState(() {
          // Implement rotation logic: delta.dx * 0.008
          if (details.pointerCount == 1) {
            _rotY += details.focalPointDelta.dx * 0.008;
            _rotX -= details.focalPointDelta.dy * 0.008;
          }
          
          // Implement pinch-to-zoom logic: clamp 60–280
          if (details.pointerCount > 1) {
            _zoom = (_baseZoom * details.scale).clamp(60.0, 280.0);
          }
        });
      },
      child: CustomPaint(
        size: Size.infinite,
        painter: NeuralCanvas3DPainter(
          state: state,
          rotX: _rotX,
          rotY: _rotY,
          zoom: _zoom,
          selectedNeuronId: _selectedNeuronId,
          repaint: _animationController,
        ),
      ),
    );
  }
}

