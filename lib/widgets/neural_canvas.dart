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

class NeuralCanvas3DState extends ConsumerState<NeuralCanvas3D> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _celebrationController;
  StreamSubscription? _convergenceSub;
  OverlayEntry? _hintEntry;
  
  // State fields for 3D view
  double _rotX = 0.4;
  double _rotY = 0.6;
  double? _zoom;
  String? _selectedNeuronId;
  Offset? _selectedNeuronPos;

  // For zoom tracking
  double _baseZoom = 120.0;
  static const double _defaultZoomMarker = -1.0;

  @override
  void initState() {
    super.initState();
    _zoom = _defaultZoomMarker;
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();

    _celebrationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _convergenceSub = ref.read(simulationProvider.notifier).convergenceEventStream.listen((_) {
      if (mounted) {
        _celebrationController.forward(from: 0.0);
      }
    });

    _checkAndShowHint();
  }

  Future<void> _checkAndShowHint() async {
    final prefs = ref.read(prefsServiceProvider);
    final hasSeen = await prefs.hasSeenCanvasHint();
    if (!hasSeen) {
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) _showGestureHint();
      });
    }
  }

  void _showGestureHint() {
    final colorScheme = Theme.of(context).colorScheme;
    
    _hintEntry = OverlayEntry(
      builder: (context) => Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: colorScheme.inverseSurface.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Swipe to rotate · Pinch to zoom · Tap to inspect',
              style: TextStyle(color: colorScheme.onInverseSurface, fontSize: 14),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_hintEntry!);

    // Auto-dismiss after 3s
    Future.delayed(const Duration(seconds: 3), () => _dismissHint());
  }

  void _dismissHint() {
    if (_hintEntry != null) {
      _hintEntry?.remove();
      _hintEntry = null;
      ref.read(prefsServiceProvider).setCanvasHintSeen();
    }
  }

  @override
  void dispose() {
    _hintEntry?.remove();
    _animationController.dispose();
    _celebrationController.dispose();
    _convergenceSub?.cancel();
    super.dispose();
  }

  /// Resets the view to the default rotation and zoom.
  void resetView() {
    setState(() {
      _rotX = 0.4;
      _rotY = 0.6;
      _zoom = 120.0;
      _selectedNeuronId = null;
      _selectedNeuronPos = null;
    });
  }

  /// Handles tap events to select a neuron in 3D space.
  void _handleTapUp(TapUpDetails details) {
    _dismissHint();
    final RenderBox box = context.findRenderObject() as RenderBox;
    final Offset localPos = box.globalToLocal(details.globalPosition);
    final Size size = box.size;
    final centerX = size.width / 2;
    final centerY = size.height / 2;

    final state = ref.read(simulationProvider);
    
    // Group neurons for procedural position calculation
    final Map<String, List<NeuronModel>> grouped = {};
    for (final n in state.neurons.values) {
      grouped.putIfAbsent(n.cellType, () => []).add(n);
    }

    String? nearestId;
    Offset? nearestPos;
    double minDistance = 28.0;

    for (final n in state.neurons.values) {
      final pos3d = NeuralCanvas3DPainter.calculateProceduralPosition(n, grouped);

      final projected = Neural3DProjection.project(
        pos3d,
        rotX: _rotX,
        rotY: _rotY,
        zoom: _zoom ?? 120.0,
        centerX: centerX,
        centerY: centerY,
      );

      final screenPos = Offset(projected.x, projected.y);
      final distance = (localPos - screenPos).distance;
      if (distance < minDistance) {
        minDistance = distance;
        nearestId = n.id;
        nearestPos = screenPos;
      }
    }

    if (nearestId != null) {
      HapticFeedback.lightImpact();
    }

    setState(() {
      _selectedNeuronId = nearestId;
      _selectedNeuronPos = nearestPos;
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(simulationProvider);

    // Auto-calculate zoom for initial view based on network size
    if (_zoom == _defaultZoomMarker) {
      _zoom = (60.0 + (state.neurons.length * 3.5)).clamp(80.0, 220.0);
    }

    // Re-calculate selected neuron position for overlay tracking
    Offset? overlayPos = _selectedNeuronPos;
    if (_selectedNeuronId != null) {
      final RenderBox? box = context.findRenderObject() as RenderBox?;
      if (box != null && box.hasSize) {
        final centerX = box.size.width / 2;
        final centerY = box.size.height / 2;
        
        final neuron = state.neurons[_selectedNeuronId!];
        if (neuron != null) {
          // Group neurons for procedural position calculation
          final Map<String, List<NeuronModel>> grouped = {};
          for (final n in state.neurons.values) {
            grouped.putIfAbsent(n.cellType, () => []).add(n);
          }

          final pos3d = NeuralCanvas3DPainter.calculateProceduralPosition(neuron, grouped);
          final projected = Neural3DProjection.project(
            pos3d,
            rotX: _rotX,
            rotY: _rotY,
            zoom: _zoom!,
            centerX: centerX,
            centerY: centerY,
          );
          overlayPos = Offset(projected.x, projected.y);
        }
      }
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Stack(
      children: [
        GestureDetector(
          onTapUp: _handleTapUp,
          onScaleStart: (details) {
            _dismissHint();
            _baseZoom = _zoom!;
          },
          onScaleUpdate: (details) {
            setState(() {
              if (details.pointerCount == 1) {
                _rotY += details.focalPointDelta.dx * 0.008;
                _rotX -= details.focalPointDelta.dy * 0.008;
              }
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
              zoom: _zoom!,
              selectedNeuronId: _selectedNeuronId,
              repaint: _animationController,
              colorScheme: colorScheme,
              celebrationValue: Curves.elasticOut.transform(_celebrationController.value),
            ),
          ),
        ),

        // Status Bar Overlay (Semi-transparent)
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            color: colorScheme.surface.withValues(alpha: 0.75),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: SimulationStatusBar(key: ValueKey(state.isRunning)),
            ),
          ),
        ),

        // Explanation Card Overlay (at top, ignored by gestures)
        if (state.episodeCount > 0)
          Positioned(
            top: 0,
            left: 8,
            right: 8,
            child: IgnorePointer(
              child: const ExplanationCard(),
            ),
          ),
        
        // Floating Controls anchored to canvas
        Positioned(
          bottom: 48, // Lifted to clear status bar
          right: 8,
          child: Column(
            children: [
              FloatingActionButton.small(
                heroTag: 'reset_view_canvas',
                onPressed: resetView,
                tooltip: 'Reset 3D View',
                child: const Icon(Icons.center_focus_strong),
              ),
              const SizedBox(height: 8),
              FloatingActionButton.small(
                heroTag: 'rotation_hint_canvas',
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Swipe to rotate, pinch to zoom, tap to inspect.'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                tooltip: 'Interaction Hint',
                child: const Icon(Icons.help_outline),
              ),
            ],
          ),
        ),

        const SimulationHud(),

        if (_selectedNeuronId != null) ...[
          () {
            final neuron = state.neurons[_selectedNeuronId!];
            if (neuron != null && overlayPos != null) {
              return NeuronInfoOverlay(
                neuron: neuron,
                position: overlayPos,
                onClose: () => setState(() {
                  _selectedNeuronId = null;
                  _selectedNeuronPos = null;
                }),
              );
            }
            return const SizedBox.shrink();
          }(),
        ],
      ],
    );
  }
}
