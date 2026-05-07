import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/simulation_provider.dart';

/// Listens for convergence events from the simulation and triggers a visual celebration.
class CanvasConvergenceListener extends ConsumerStatefulWidget {
  final Widget Function(BuildContext context, double celebrationValue) builder;

  const CanvasConvergenceListener({
    super.key,
    required this.builder,
  });

  @override
  ConsumerState<CanvasConvergenceListener> createState() => _CanvasConvergenceListenerState();
}

class _CanvasConvergenceListenerState extends ConsumerState<CanvasConvergenceListener> with SingleTickerProviderStateMixin {
  late AnimationController _celebrationController;
  StreamSubscription<int>? _sub;

  @override
  void initState() {
    super.initState();
    _celebrationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    // Defer accessing providers to avoid using ref in initState synchronously
    Future.microtask(() {
      _sub = ref.read(simulationControllerProvider).convergenceEventStream.listen((episode) {
        if (mounted && !_celebrationController.isAnimating) {
          _celebrationController.forward(from: 0.0);
        }
      });
    });
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
