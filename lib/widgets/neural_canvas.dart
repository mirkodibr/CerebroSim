import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/simulation_provider.dart';
import '../providers/prefs_provider.dart';
import '../models/simulation_state.dart';
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

  // Active tap ripples (max 5)
  final List<_TapRipple> _ripples = [];

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
    
    final hotState = ref.read(hotSimulationProvider);
    final Map<String, List<NeuronModel>> grouped = {};
    for (final n in hotState.neurons.values) {
      grouped.putIfAbsent(n.cellType, () => []).add(n);
    }

    String? nearestId;
    double minDistance = 28.0;

    for (final n in hotState.neurons.values) {
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

    if (nearestId != null) {
      HapticFeedback.selectionClick();
      final neuron = ref.read(hotSimulationProvider).neurons[nearestId];
      final rippleColor = neuron != null ? _neuronColor(neuron.cellType) : Colors.white;

      // Prune expired ripples before adding a new one.
      final now = DateTime.now();
      _ripples.removeWhere((r) => now.difference(r.startTime).inMilliseconds > 350);
      if (_ripples.length >= 5) _ripples.removeAt(0);
      _ripples.add(_TapRipple(position: localPos, color: rippleColor, startTime: now));
    }
    setState(() {
      _selectedNeuronId = nearestId;
    });
  }

  static Color _neuronColor(String type) {
    switch (type) {
      case 'GC': return const Color(0xFFEF9F27);
      case 'PC': return const Color(0xFF8A2BE2);
      case 'BC': return const Color(0xFFD85A30);
      case 'DCN': return const Color(0xFF1D9E75);
      case 'CF': return const Color(0xFFE24B4A);
      case 'SC': return const Color(0xFF00FFFF);
      default: return Colors.white;
    }
  }

  @override
  Widget build(BuildContext context) {
    final hotState = ref.watch(hotSimulationProvider);
    final coldState = ref.watch(coldSimulationProvider);
    final colorScheme = Theme.of(context).colorScheme;

    if (hotState.neurons.length != _lastNeuronCount) {
      NeuralCanvas3DPainter.clearCache();
      _lastNeuronCount = hotState.neurons.length;
    }

    if (_zoom == _defaultZoomMarker) {
      _zoom = (60.0 + (hotState.neurons.length * 3.5)).clamp(80.0, 220.0);
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
                state: hotState, rotX: _rotX, rotY: _rotY, zoom: _zoom!,
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
                child: SimulationStatusBar(key: ValueKey(coldState.isRunning)),
              ),
            ),
          ),
          if (coldState.episodeCount > 0)
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
          // Ripple overlay — redrawn by the animation controller
          if (_ripples.isNotEmpty)
            IgnorePointer(
              child: AnimatedBuilder(
                animation: _animationController,
                builder: (_, __) => CustomPaint(
                  size: Size.infinite,
                  painter: _RipplePainter(ripples: List.unmodifiable(_ripples)),
                ),
              ),
            ),
          if (_selectedNeuronId != null)
            _buildNeuronOverlay(hotState),
        ],
      ),
    );
  }

  Widget _buildNeuronOverlay(HotSimState hotState) {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return const SizedBox.shrink();
    
    final neuron = hotState.neurons[_selectedNeuronId!];
    if (neuron == null) return const SizedBox.shrink();

    final Map<String, List<NeuronModel>> grouped = {};
    for (final n in hotState.neurons.values) {
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

// ──────────────────────────────────────────────────────────────────────────────
// Ripple support (P4.8)
// ──────────────────────────────────────────────────────────────────────────────

class _TapRipple {
  final Offset position;
  final Color color;
  final DateTime startTime;
  const _TapRipple({required this.position, required this.color, required this.startTime});
}

class _RipplePainter extends CustomPainter {
  final List<_TapRipple> ripples;
  final Paint _paint = Paint()..style = PaintingStyle.stroke..strokeWidth = 2.0;

  _RipplePainter({required this.ripples});

  @override
  void paint(Canvas canvas, Size size) {
    final now = DateTime.now();
    for (final ripple in ripples) {
      final double elapsed = now.difference(ripple.startTime).inMilliseconds / 350.0;
      if (elapsed > 1.0) continue;
      final double radius = elapsed * 80.0;
      final double alpha = (1.0 - elapsed) * 0.8;
      _paint.color = ripple.color.withValues(alpha: alpha);
      canvas.drawCircle(ripple.position, radius, _paint);
    }
  }

  @override
  bool shouldRepaint(covariant _RipplePainter old) => true;
}
