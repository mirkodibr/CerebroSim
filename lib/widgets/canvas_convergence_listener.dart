import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/simulation_provider.dart';
import '../providers/prefs_provider.dart';

/// Listens for convergence events from the simulation and triggers a visual
/// celebration — a brief glow pulse on the 3D canvas and a heavy haptic.
///
/// The celebration fires at most once per simulation run to avoid spamming
/// the user after the network first converges. It also respects the
/// `disableCelebrations` accessibility setting in [PrefsService].
class CanvasConvergenceListener extends ConsumerStatefulWidget {
  final Widget Function(BuildContext context, double celebrationValue) builder;

  const CanvasConvergenceListener({
    super.key,
    required this.builder,
  });

  @override
  ConsumerState<CanvasConvergenceListener> createState() =>
      _CanvasConvergenceListenerState();
}

class _CanvasConvergenceListenerState
    extends ConsumerState<CanvasConvergenceListener>
    with SingleTickerProviderStateMixin {
  late AnimationController _celebrationController;
  StreamSubscription<int>? _sub;

  // Rate-limiting: only celebrate once per simulation run.
  bool _celebratedThisRun = false;

  @override
  void initState() {
    super.initState();
    _celebrationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    Future.microtask(() async {
      final prefs = ref.read(prefsServiceProvider);
      final disabled = await prefs.isCelebrationDisabled();
      final disableMotion = MediaQuery.of(context).disableAnimations;

      if (disabled || disableMotion) return;

      _sub = ref
          .read(simulationControllerProvider)
          .convergenceEventStream
          .listen((episode) {
        if (!mounted) return;
        if (_celebratedThisRun) return; // once per run
        _celebratedThisRun = true;
        HapticFeedback.heavyImpact();
        _celebrationController.forward(from: 0.0);
      });
    });
  }

  /// Reset the celebration gate when the episode counter goes back to 0
  /// (i.e., the user hit Reset). We watch cold state for this.
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // When a reset happens episodeCount drops to 0 — re-enable celebration.
    ref.listenManual(
      coldSimulationProvider.select((c) => c.episodeCount),
      (prev, next) {
        if (next == 0 && prev != null && prev > 0) {
          _celebratedThisRun = false;
        }
      },
    );
  }

  @override
  void dispose() {
    _sub?.cancel();
    _celebrationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _celebrationController,
      builder: (context, child) {
        return widget.builder(context, _celebrationController.value);
      },
    );
  }
}
