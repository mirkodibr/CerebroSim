import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/simulation_provider.dart';
import '../providers/environment_provider.dart';
import '../widgets/neural_canvas.dart';
import '../widgets/signal_plotter.dart';
import '../models/simulation_state.dart';
import '../models/neuron.dart';
import '../models/synapse.dart';

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
    // 1. Generate 10 Parallel Fiber neurons (PF)
    final neurons = <Neuron>[];
    final synapses = <Synapse>[];

    for (int i = 0; i < 10; i++) {
      neurons.add(Neuron(
        id: 'pf_$i',
        type: 'Granular',
        threshold: 1.0,
        currentPotential: 0.0,
        x: 100.0,
        y: 100.0 + (i * 60.0),
      ));
    }

    // 2. Add Basket Cells (BC - Lateral Inhibition)
    for (int i = 0; i < 5; i++) {
      neurons.add(Neuron(
        id: 'bc_$i',
        type: 'BC',
        threshold: 2.0,
        currentPotential: 0.0,
        x: 250.0,
        y: 150.0 + (i * 100.0),
      ));
    }

    // 3. Add Purkinje Cell (Actor)
    neurons.add(const Neuron(
      id: 'pc_1',
      type: 'Purkinje',
      threshold: 5.0,
      currentPotential: 0.0,
      x: 400.0,
      y: 370.0,
    ));

    // 4. Add Stellate Cell (Critic)
    neurons.add(const Neuron(
      id: 'sc_1',
      type: 'SC',
      threshold: 3.0,
      currentPotential: 0.0,
      x: 400.0,
      y: 150.0,
    ));

    // 5. Add DCN Cells (Output Actions)
    neurons.add(const Neuron(
      id: 'dcn_open',
      type: 'DCN',
      threshold: 2.0,
      currentPotential: 0.0,
      x: 700.0,
      y: 300.0,
      actionGroup: 'antiopen',
    ));
    neurons.add(const Neuron(
      id: 'dcn_close',
      type: 'DCN',
      threshold: 2.0,
      currentPotential: 0.0,
      x: 700.0,
      y: 440.0,
      actionGroup: 'anticlose',
    ));

    // 6. Connect PFs to BC, PC and SC
    for (int i = 0; i < 10; i++) {
      // PFs are excitatory (+)
      synapses.add(Synapse(
        sourceId: 'pf_$i',
        targetId: 'pc_1',
        weight: 0.5,
        learningRate: 0.05,
        targetType: 'PC',
      ));
      synapses.add(Synapse(
        sourceId: 'pf_$i',
        targetId: 'sc_1',
        weight: 0.2,
        learningRate: 0.02,
        targetType: 'SC',
      ));
      
      // PF to nearest BC
      synapses.add(Synapse(
        sourceId: 'pf_$i',
        targetId: 'bc_${(i / 2).floor()}',
        weight: 0.3,
        learningRate: 0.0,
        targetType: 'BC',
      ));
    }

    // 7. Inhibitory Synapses (Negative Weights)
    // BC to PC inhibition
    for (int i = 0; i < 5; i++) {
      synapses.add(const Synapse(
        sourceId: 'bc_$i',
        targetId: 'pc_1',
        weight: -1.0, // Inhibitory
        learningRate: 0.0,
        targetType: 'PC',
      ));
    }

    // PC to DCN inhibition
    synapses.add(const Synapse(
      sourceId: 'pc_1',
      targetId: 'dcn_close',
      weight: -2.0, // Inhibitory
      learningRate: 0.0,
      targetType: 'DCN',
    ));

    ref.read(simulationProvider.notifier).initialize(
      SimulationState(neurons: neurons, synapses: synapses),
    );
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
