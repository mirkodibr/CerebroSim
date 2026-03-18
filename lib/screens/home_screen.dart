import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/simulation_provider.dart';
import '../providers/environment_provider.dart';
import '../widgets/neural_canvas.dart';
import '../widgets/signal_plotter.dart';
import '../services/network_initializer.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _resetToRLMock();
    });
  }

  void _resetToRLMock() {
    final initialState = NetworkInitializer.createRLMockNetwork();
    ref.read(simulationProvider.notifier).initialize(initialState);
  }

  @override
  Widget build(BuildContext context) {
    final simulationState = ref.watch(simulationProvider);
    final history = ref.watch(signalHistoryProvider);
    final isRunning = ref.watch(simulationProvider.notifier).isRunning;
    final envState = ref.watch(environmentProvider);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('CerebroSim RL Lab'),
            Text(
              '${envState.activeTask.name} | Ep: ${envState.episodeNumber} | ${envState.currentStep.toInt()}ms',
              style: const TextStyle(fontSize: 10, color: Colors.white70),
            ),
          ],
        ),
        actions: [
          PopupMenuButton<SignalTask>(
            icon: const Icon(Icons.settings_suggest),
            tooltip: 'Switch Task',
            onSelected: (task) {
              ref.read(environmentProvider.notifier).setTask(task);
              ref.read(signalHistoryProvider.notifier).reset();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: SignalTask.delayEyeblink, child: Text('Delay Eyeblink')),
              const PopupMenuItem(value: SignalTask.sineWave, child: Text('Sine Wave Tracking')),
              const PopupMenuItem(value: SignalTask.stepFunction, child: Text('Step Function')),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _resetToRLMock,
            tooltip: 'Reset Simulation',
          ),
          IconButton(
            icon: Icon(isRunning ? Icons.stop : Icons.play_arrow),
            onPressed: () {
              final notifier = ref.read(simulationProvider.notifier);
              if (notifier.isRunning) {
                notifier.stop();
              } else {
                notifier.start();
              }
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          InteractiveViewer(
            boundaryMargin: const EdgeInsets.all(double.infinity),
            minScale: 0.1,
            maxScale: 5.0,
            child: SizedBox(
              width: 2000,
              height: 2000,
              child: NeuralCanvas(state: simulationState),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 32,
            child: SignalPlotter(history: history),
          ),
        ],
      ),
    );
  }
}
