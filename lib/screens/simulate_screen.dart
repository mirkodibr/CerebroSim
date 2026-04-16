import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/simulation_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/vault_provider.dart';
import '../providers/environment_provider.dart';
import '../providers/network_config_provider.dart';
import '../widgets/task_selector.dart';
import '../widgets/neural_canvas.dart';
import '../widgets/signal_plotter.dart';
import '../widgets/convergence_chart.dart';
import '../models/simulation_constants.dart';
import '../models/experiment_snapshot.dart';

/// The primary experimental workspace for CerebroSim.
/// 
/// This screen serves as the central hub for interacting with the cerebellar 
/// Reinforcement Learning (RL) simulation. It provides controls to start, stop, 
/// and reset episodes, as well as tools to select different tasks, visualize 
/// neural activity, and monitor real-time performance signals.
class SimulateScreen extends ConsumerStatefulWidget {
  /// Creates a new [SimulateScreen] instance.
  const SimulateScreen({super.key});

  @override
  ConsumerState<SimulateScreen> createState() => _SimulateScreenState();
}

class _SimulateScreenState extends ConsumerState<SimulateScreen> {
  /// Key to access the state of the 3D neural canvas (for resetting view).
  final GlobalKey<NeuralCanvas3DState> _canvasKey = GlobalKey<NeuralCanvas3DState>();

  /// Builds the simulation interface, including the task selector, neural canvas, 
  /// and signal plotter. It also integrates simulation control buttons in the AppBar.
  @override
  Widget build(BuildContext context) {
    /// Monitors the current state of the simulation (running status, progress, etc.).
    final state = ref.watch(simulationProvider);
    
    /// Provides access to simulation control methods.
    final notifier = ref.read(simulationProvider.notifier);

    /// Monitors the current network topology configuration.
    final networkConfig = ref.watch(networkConfigProvider);

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
            icon: Icon(state.isRunning ? Icons.pause : Icons.play_arrow),
            onPressed: () {
              if (state.isRunning) {
                notifier.pauseSimulation();
              } else {
                notifier.startSimulation();
              }
            },
            tooltip: state.isRunning ? 'Pause' : 'Start/Resume',
          ),
          if (state.isRunning || (state.episodeStep > 0 || state.episodeCount > 0))
            IconButton(
              icon: const Icon(Icons.stop),
              onPressed: () => notifier.stopSimulation(),
              tooltip: 'Stop',
            ),
          PopupMenuButton<double>(
            icon: const Icon(Icons.speed),
            tooltip: 'Simulation Speed',
            onSelected: (speed) => notifier.setSpeed(speed),
            itemBuilder: (context) => [
              const PopupMenuItem(value: SimulationConstants.kSpeedNormal, child: Text('1x Speed')),
              const PopupMenuItem(value: SimulationConstants.kSpeedFast, child: Text('5x Speed')),
              const PopupMenuItem(value: SimulationConstants.kSpeedVeryFast, child: Text('10x Speed')),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () => _showSaveDialog(context, ref),
            tooltip: 'Save Snapshot',
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              /// UI component for selecting between different cerebellar tasks (e.g., VOR, Eyeblink).
              const TaskSelector(),

              /// Summary of current network topology.
              InkWell(
                onTap: () => context.push('/network_config'),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Text(
                    'GC: ${networkConfig.gcCount} | BC: ${networkConfig.bcCount} | PC: ${networkConfig.pcCount} | SC: ${networkConfig.scCount}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.secondary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              
              /// Interactive 3D visualization of the neural network architecture and activity.
              Expanded(
                child: NeuralCanvas3D(key: _canvasKey),
              ),
              
              /// Real-time plotting component for monitoring simulation signals and performance.
              const SignalPlotter(),

              /// Chart showing performance convergence across multiple episodes.
              const SizedBox(
                height: 140,
                child: ConvergenceChart(),
              ),
              
              const SizedBox(height: 16),
            ],
          ),
          
          /// Floating reset and hint controls for the 3D canvas.
          Positioned(
            bottom: 250, // Positioned above the chart and plotter
            right: 16,
            child: Column(
              children: [
                FloatingActionButton.small(
                  heroTag: 'reset_view',
                  onPressed: () => _canvasKey.currentState?.resetView(),
                  tooltip: 'Reset 3D View',
                  child: const Icon(Icons.center_focus_strong),
                ),
                const SizedBox(height: 8),
                FloatingActionButton.small(
                  heroTag: 'rotation_hint',
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Swipe to rotate, pinch to zoom, tap to inspect.'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  tooltip: 'Interaction Hint',
                  child: const Icon(Icons.help_outline),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Displays a modal dialog to capture metadata and save the current simulation state.
  void _showSaveDialog(BuildContext context, WidgetRef ref) {
    final titleController = TextEditingController();
    bool isPublic = false;
    bool isSaving = false;
    final formKey = GlobalKey<FormState>();
    final colorScheme = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: colorScheme.surface,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
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
                Text('Save Experiment', style: TextStyle(color: colorScheme.onSurface, fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                TextFormField(
                  controller: titleController,
                  style: TextStyle(color: colorScheme.onSurface),
                  decoration: InputDecoration(
                    labelText: 'Experiment Title',
                    labelStyle: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.7)),
                    border: const OutlineInputBorder(),
                  ),
                  validator: (v) => (v == null || v.length < 3) ? 'Minimum 3 characters' : null,
                ),
                SwitchListTile(
                  title: Text('Share Publicly', style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.7))),
                  value: isPublic,
                  onChanged: isSaving ? null : (v) => setModalState(() => isPublic = v),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          if (formKey.currentState!.validate()) {
                            setModalState(() => isSaving = true);
                            try {
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
                                networkConfig: ref.read(networkConfigProvider),
                              );

                              await ref.read(vaultProvider.notifier).saveSnapshot(snapshot);
                              if (context.mounted) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Experiment saved!')),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Error: $e')),
                                );
                              }
                            } finally {
                              if (context.mounted) {
                                setModalState(() => isSaving = false);
                              }
                            }
                          }
                        },
                  child: isSaving
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: colorScheme.onPrimary,
                          ),
                        )
                      : const Text('Save Snapshot'),
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
