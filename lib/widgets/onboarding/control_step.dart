import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/learning_rate_provider.dart';
import '../signal_plotter.dart';

class ControlStep extends ConsumerStatefulWidget {
  final VoidCallback onNext;
  const ControlStep({super.key, required this.onNext});

  @override
  ConsumerState<ControlStep> createState() => _ControlStepState();
}

class _ControlStepState extends ConsumerState<ControlStep> {
  bool _interacted = false;

  @override
  Widget build(BuildContext context) {
    final lr = ref.watch(learningRateProvider);

    return Container(
      color: const Color(0xFF1E1E1E),
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Dynamic Controls',
            style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          const Text(
            'Adjust the learning rate to see how it affects the speed and stability of the network\'s adaptation.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
          const Spacer(),
          const SignalPlotter(),
          const SizedBox(height: 32),
          Row(
            children: [
              const Text('Learning Rate:', style: TextStyle(color: Colors.white)),
              Expanded(
                child: Slider(
                  value: lr,
                  min: 0.001,
                  max: 0.1,
                  onChanged: (v) {
                    setState(() => _interacted = true);
                    ref.read(learningRateProvider.notifier).value = v;
                  },
                ),
              ),
              Text(lr.toStringAsFixed(3), style: const TextStyle(color: Colors.cyan, fontWeight: FontWeight.bold)),
            ],
          ),
          const Spacer(),
          ElevatedButton(
            onPressed: _interacted ? widget.onNext : null,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              backgroundColor: Theme.of(context).colorScheme.primary,
            ),
            child: const Text('Next →', style: TextStyle(fontSize: 18, color: Colors.black)),
          ),
        ],
      ),
    );
  }
}
