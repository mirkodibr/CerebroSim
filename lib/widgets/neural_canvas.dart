import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/simulation_provider.dart';
import '../providers/prefs_provider.dart';
import '../services/neural_3d_projection.dart';
import '../models/neuron_model.dart';
import 'neuron_info_overlay.dart';
import 'neural_canvas_3d_painter.dart';
import 'simulation_hud.dart';
import 'simulation_status_bar.dart';
import 'explanation_card.dart';
import 'canvas_gesture_hint.dart';
import 'canvas_controls.dart';
import 'canvas_convergence_listener.dart';

/// An interactive 3D visualization of the cerebellar microcircuit.
class NeuralCanvas3D extends ConsumerStatefulWidget {
  const NeuralCanvas3D({super.key});

  @override
  ConsumerState<NeuralCanvas3D> createState() => NeuralCanvas3DState();
}

class NeuralCanvas3DState extends ConsumerState<NeuralCanvas3D> with TickerProviderStateMixin {
  late AnimationController _animationController;
  
  // State fields for 3D view
  double _rotX = 0.4;
  double _rotY = 0.6;
  double? _zoom;
  String? _selectedNeuronId;
  int _lastNeuronCount = 0;

  // For zoom tracking
  double _baseZoom = 120.0;
  static const double _defaultZoomMarker = -1.0;
  Timer? _hintTimer;

  @override
  void initState() {
    super.initState();
    _zoom = _defaultZoomMarker;
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();

    _checkAndShowHint();
  }

  Future<void> _checkAndShowHint() async {
    final prefs = ref.read(prefsServiceProvider);
    final hasSeen = await prefs.hasSeenCanvasHint();
    if (!hasSeen) {
      _hintTimer = Timer(const Duration(seconds: 1), () {
        if (mounted) {
          CanvasGestureHint.show(context);
          prefs.setCanvasHintSeen();
        }
      });
    }
  }

  @override
  void dispose() {
    _hintTimer?.cancel();
    CanvasGestureHint.dismiss();
    _animationController.dispose();
    super.dispose();
  }

  /// Resets the view to the default rotation and zoom.
  void resetView() {
    NeuralCanvas3DPainter.clearCache();
    setState(() {
      _rotX = 0.4;
      _rotY = 0.6;
      _zoom = 120.0;
      _selectedNeuronId = null;
    });
  }

  void _handleTapUp(TapUpDetails details) {
    CanvasGestureHint.dismiss();
    final RenderBox box = context.findRenderObject() as RenderBox;
    final Offset localPos = box.globalToLocal(details.globalPosition);
    final size = box.size;
    
    final state = ref.read(simulationProvider);
    final Map<String, List<NeuronModel>> grouped = {};
    for (final n in state.neurons.values) {
      grouped.putIfAbsent(n.cellType, () => []).add(n);
    }

    String? nearestId;
    double minDistance = 28.0;

    for (final n in state.neurons.values) {
      final pos3d = NeuralCanvas3DPainter.calculateProceduralPosition(n, grouped);
      final projected = Neural3DProjection.project(pos3d, 
          rotX: _rotX, rotY: _rotY, zoom: _zoom ?? 120.0,
          centerX: size.width / 2, centerY: size.height / 2);

      final screenPos = Offset(projected.x, projected.y);
      if ((localPos - screenPos).distance < minDistance) {
        minDistance = (localPos - screenPos).distance;
        nearestId = n.id;
      }
    }

    if (nearestId != null) HapticFeedback.lightImpact();
    setState(() {
      _selectedNeuronId = nearestId;
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(simulationProvider);
    final colorScheme = Theme.of(context).colorScheme;

    if (state.neurons.length != _lastNeuronCount) {
      NeuralCanvas3DPainter.clearCache();
      _lastNeuronCount = state.neurons.length;
    }

    if (_zoom == _defaultZoomMarker) {
      _zoom = (60.0 + (state.neurons.length * 3.5)).clamp(80.0, 220.0);
    }

    return CanvasConvergenceListener(
      builder: (context, celebrationValue) => Stack(
        children: [
          GestureDetector(
            onTapUp: _handleTapUp,
            onScaleStart: (_) {
              CanvasGestureHint.dismiss();
              _baseZoom = _zoom!;
            },
            onScaleUpdate: (details) {
              setState(() {
                if (details.pointerCount == 1) {
                  _rotY += details.focalPointDelta.dx * 0.008;
                  _rotX -= details.focalPointDelta.dy * 0.008;
                } else {
                  _zoom = (_baseZoom * details.scale).clamp(60.0, 280.0);
                }
              });
            },
            child: CustomPaint(
              size: Size.infinite,
              painter: NeuralCanvas3DPainter(
                state: state, rotX: _rotX, rotY: _rotY, zoom: _zoom!,
                selectedNeuronId: _selectedNeuronId,
                repaint: _animationController,
                colorScheme: colorScheme,
                celebrationValue: celebrationValue,
              ),
            ),
          ),
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              color: colorScheme.surface.withValues(alpha: 0.75),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: SimulationStatusBar(key: ValueKey(state.isRunning)),
              ),
            ),
          ),
          if (state.episodeCount > 0)
            const Positioned(top: 0, left: 8, right: 8, child: IgnorePointer(child: ExplanationCard())),
          
          Positioned(
            bottom: 48, right: 8,
            child: CanvasControls(
              onResetView: resetView,
              onShowHint: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Swipe to rotate, pinch to zoom, tap to inspect.'), duration: Duration(seconds: 2)),
              ),
            ),
          ),
          const SimulationHud(),
          if (_selectedNeuronId != null)
            _buildNeuronOverlay(state),
        ],
      ),
    );
  }

  Widget _buildNeuronOverlay(dynamic state) {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return const SizedBox.shrink();
    
    final neuron = state.neurons[_selectedNeuronId!];
    if (neuron == null) return const SizedBox.shrink();

    final Map<String, List<NeuronModel>> grouped = {};
    for (final n in state.neurons.values) {
      grouped.putIfAbsent(n.cellType, () => []).add(n);
    }

    final pos3d = NeuralCanvas3DPainter.calculateProceduralPosition(neuron, grouped);
    final projected = Neural3DProjection.project(pos3d, 
        rotX: _rotX, rotY: _rotY, zoom: _zoom!,
        centerX: box.size.width / 2, centerY: box.size.height / 2);

    return NeuronInfoOverlay(
      neuron: neuron,
      position: Offset(projected.x, projected.y),
      onClose: () => setState(() { _selectedNeuronId = null; }),
    );
  }
}
