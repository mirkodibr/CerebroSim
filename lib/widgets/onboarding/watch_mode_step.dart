import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/simulation_provider.dart';
import '../neural_canvas.dart';

/// An onboarding step that allows users to observe the neural network in action.
///
/// It automatically starts the simulation upon entry and provides a passive
/// viewing experience (via [AbsorbPointer] on the canvas) to help users
/// visualize the firing patterns and adaptation process.
class WatchModeStep extends ConsumerStatefulWidget {
  /// Callback triggered when the user advances to the next step.
  final VoidCallback onNext;
  const WatchModeStep({super.key, required this.onNext});

  @override
  ConsumerState<WatchModeStep> createState() => _WatchModeStepState();
}

class _WatchModeStepState extends ConsumerState<WatchModeStep> {
  /// A timer that automatically advances the onboarding after a fixed duration.
  Timer? _autoAdvanceTimer;

  @override
  void initState() {
    super.initState();
    // Automatically start the simulation to demonstrate activity.
    Future.microtask(() {
      ref.read(simulationProvider.notifier).startSimulation();
    });
    
    // Set a 30-second timeout for automatic progression.
    _autoAdvanceTimer = Timer(const Duration(seconds: 30), () {
      if (mounted) widget.onNext();
    });
  }

  @override
  void dispose() {
    _autoAdvanceTimer?.cancel();
    // Ensure the simulation is stopped when navigating away from this step.
    ref.read(simulationProvider.notifier).stopSimulation();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const AbsorbPointer(
          child: NeuralCanvas(),
        ),
        Container(
          color: Colors.black45,
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Neural Observation',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text(
                'Your cerebellum learns by trying and failing. Watch the network attempt to predict the error signal.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: widget.onNext,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  backgroundColor: Theme.of(context).colorScheme.primary,
                ),
                child: const Text('I see it →', style: TextStyle(fontSize: 18, color: Colors.black)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

