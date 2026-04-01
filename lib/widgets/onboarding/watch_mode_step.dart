import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/simulation_provider.dart';
import '../neural_canvas.dart';

class WatchModeStep extends ConsumerStatefulWidget {
  final VoidCallback onNext;
  const WatchModeStep({super.key, required this.onNext});

  @override
  ConsumerState<WatchModeStep> createState() => _WatchModeStepState();
}

class _WatchModeStepState extends ConsumerState<WatchModeStep> {
  Timer? _autoAdvanceTimer;

  @override
  void initState() {
    super.initState();
    // Start simulation automatically
    Future.microtask(() {
      ref.read(simulationProvider.notifier).startSimulation();
    });
    
    _autoAdvanceTimer = Timer(const Duration(seconds: 30), () {
      if (mounted) widget.onNext();
    });
  }

  @override
  void dispose() {
    _autoAdvanceTimer?.cancel();
    // Stop simulation when leaving step
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
