import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../neural_canvas.dart';
import '../task_selector.dart';

/// An onboarding step that encourages users to explore the interactive components.
///
/// It provides access to the [TaskSelector] and [NeuralCanvas], allowing
/// users to experiment with switching tasks and inspecting individual neurons
/// before concluding the onboarding process.
class ExploreStep extends ConsumerWidget {
  /// Callback triggered when the user finishes exploring and starts the full research experience.
  final VoidCallback onComplete;
  const ExploreStep({super.key, required this.onComplete});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      color: const Color(0xFF1E1E1E),
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Explore the Network',
            style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          const Text(
            'Tap any cell to learn what it does. You can also switch between different training tasks.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
          const SizedBox(height: 24),
          const TaskSelector(),
          const Expanded(
            child: NeuralCanvas(),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: onComplete,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              backgroundColor: Theme.of(context).colorScheme.primary,
            ),
            child: const Text('Start Researching →', style: TextStyle(fontSize: 18, color: Colors.black)),
          ),
        ],
      ),
    );
  }
}

