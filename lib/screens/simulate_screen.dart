import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/simulation_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/vault_provider.dart';
import '../providers/environment_provider.dart';
import '../widgets/task_selector.dart';
import '../widgets/neural_canvas.dart';
import '../widgets/signal_plotter.dart';
import '../models/experiment_snapshot.dart';

/// The primary experimental workspace for CerebroSim.
/// 
/// This screen serves as the central hub for interacting with the cerebellar 
/// Reinforcement Learning (RL) simulation. It provides controls to start, stop, 
/// and reset episodes, as well as tools to select different tasks, visualize 
/// neural activity, and monitor real-time performance signals.
class SimulateScreen extends ConsumerWidget {
  /// Creates a new [SimulateScreen] instance.
  const SimulateScreen({super.key});

  /// Builds the simulation interface, including the task selector, neural canvas, 
  /// and signal plotter. It also integrates simulation control buttons in the AppBar.
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    /// Monitors the current state of the simulation (running status, progress, etc.).
    final state = ref.watch(simulationProvider);
    
    /// Provides access to simulation control methods.
    final notifier = ref.read(simulationProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('CerebroSim RL Lab'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => notifier.resetEpisode(),
            tooltip: 'Reset Simulation',
          ),
          IconButton(
            icon: Icon(state.isRunning ? Icons.stop : Icons.play_arrow),
            onPressed: () {
              if (state.isRunning) {
                notifier.stopSimulation();
              } else {
                notifier.startSimulation();
              }
            },
            tooltip: state.isRunning ? 'Stop' : 'Start',
          ),
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () => _showSaveDialog(context, ref),
            tooltip: 'Save Snapshot',
          ),
        ],
      ),
      body: Column(
        children: [
          /// UI component for selecting between different cerebellar tasks (e.g., VOR, Eyeblink).
          const TaskSelector(),
          
          /// Interactive 2D visualization of the neural network architecture and activity.
          const Expanded(
            child: NeuralCanvas(),
          ),
          
          /// Real-time plotting component for monitoring simulation signals and performance.
          const SignalPlotter(),
          
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  /// Displays a modal dialog to capture metadata and save the current simulation state.
  /// 
  /// The dialog collects a title and visibility preference (public/private).
  /// Upon confirmation, it constructs an [ExperimentSnapshot] from the current
  /// [simulationProvider] and [environmentProvider] states and persists it
  /// using the [vaultProvider].
  void _showSaveDialog(BuildContext context, WidgetRef ref) {
    final titleController = TextEditingController();
    bool isPublic = false;
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E1E1E),
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 24,
            right: 24,
            top: 24,
          ),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Save Experiment', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                TextFormField(
                  controller: titleController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Experiment Title',
                    labelStyle: TextStyle(color: Colors.white70),
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => (v == null || v.length < 3) ? 'Minimum 3 characters' : null,
                ),
                SwitchListTile(
                  title: const Text('Share Publicly', style: TextStyle(color: Colors.white70)),
                  value: isPublic,
                  onChanged: (v) => setState(() => isPublic = v),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      final user = ref.read(authProvider).value;
                      if (user == null) return;

                      final task = ref.read(environmentProvider);
                      final simState = ref.read(simulationProvider);

                      final snapshot = ExperimentSnapshot.fromSimulation(
                        userId: user.uid,
                        userEmail: user.email ?? 'anon',
                        taskName: task.name,
                        title: titleController.text,
                        isPublic: isPublic,
                        state: simState,
                      );

                      await ref.read(vaultProvider.notifier).saveSnapshot(snapshot);
                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Experiment saved!')),
                        );
                      }
                    }
                  },
                  child: const Text('Save Snapshot'),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
