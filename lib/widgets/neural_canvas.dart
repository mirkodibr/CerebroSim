import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/simulation_state.dart';
import '../models/neuron_model.dart';
import '../providers/simulation_provider.dart';
import 'neuron_detail_sheet.dart';
import 'neural_canvas_painter.dart';

/// A widget that provides an interactive, zoomable canvas for visualizing the neural network.
///
/// It uses [InteractiveViewer] to allow panning and zooming, and [CustomPaint]
/// with [NeuralCanvasPainter] to render the cerebellar layers, neurons, and synapses.
class NeuralCanvas extends ConsumerStatefulWidget {
  const NeuralCanvas({super.key});

  @override
  ConsumerState<NeuralCanvas> createState() => _NeuralCanvasState();
}

class _NeuralCanvasState extends ConsumerState<NeuralCanvas> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  final double _canvasWidth = 800;
  final double _canvasHeight = 600;

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

  /// Handles tap events on the canvas to detect if a neuron was selected.
  ///
  /// Converts the global tap position to local canvas coordinates and finds
  /// the nearest neuron within a fixed threshold (20 pixels). If a neuron is
  /// found, it displays a [NeuronDetailSheet] in a modal bottom sheet.
  void _handleTap(TapDownDetails details, SimulationState state) {
    final RenderBox box = context.findRenderObject() as RenderBox;
    final Offset localPos = box.globalToLocal(details.globalPosition);
    
    NeuronModel? nearest;
    double minDistance = 20.0;

    for (final n in state.neurons) {
      final pos = NeuralCanvasPainter.getNeuronPos(n, Size(_canvasWidth, _canvasHeight));
      final distance = (localPos - pos).distance;
      if (distance < minDistance) {
        minDistance = distance;
        nearest = n;
      }
    }

    if (nearest != null) {
      showModalBottomSheet(
        context: context,
        backgroundColor: const Color(0xFF1E1E1E),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) => NeuronDetailSheet(neuron: nearest!),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(simulationProvider);

    return InteractiveViewer(
      minScale: 0.5,
      maxScale: 3.0,
      boundaryMargin: const EdgeInsets.all(200),
      child: Center(
        child: GestureDetector(
          onTapDown: (details) => _handleTap(details, state),
          child: SizedBox(
            width: _canvasWidth,
            height: _canvasHeight,
            child: CustomPaint(
              painter: NeuralCanvasPainter(
                state: state,
                repaint: _animationController,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
