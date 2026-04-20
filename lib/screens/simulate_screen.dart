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
import '../models/simulation_state.dart';

/// The primary experimental workspace for CerebroSim.
class SimulateScreen extends ConsumerStatefulWidget {
  const SimulateScreen({super.key});

  @override
  ConsumerState<SimulateScreen> createState() => _SimulateScreenState();
}

class _SimulateScreenState extends ConsumerState<SimulateScreen> {
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(simulationProvider);
    final notifier = ref.read(simulationProvider.notifier);
    final networkConfig = ref.watch(networkConfigProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            snap: true,
            title: const Text('CerebroSim RL Lab'),
            backgroundColor: colorScheme.surface,
            elevation: 0,
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1.0),
              child: Divider(height: 1, color: colorScheme.outline.withValues(alpha: 0.1)),
            ),
            actions: [
              _buildSimControlGroup(context, state, notifier),
              PopupMenuButton<double>(
                icon: const Icon(Icons.speed, size: 20),
                tooltip: 'Simulation Speed',
                onSelected: (speed) => notifier.setSpeed(speed),
                itemBuilder: (context) => [
                  const PopupMenuItem(value: SimulationConstants.kSpeedNormal, child: Text('1x Speed')),
                  const PopupMenuItem(value: SimulationConstants.kSpeedFast, child: Text('5x Speed')),
                  const PopupMenuItem(value: SimulationConstants.kSpeedVeryFast, child: Text('10x Speed')),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.save, size: 20),
                onPressed: () => _showSaveDialog(context, ref),
                tooltip: 'Save Snapshot',
              ),
              const SizedBox(width: 8),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Column(
                children: [
                  const TaskSelector(),
                  InkWell(
                    onTap: () => context.push('/network_config'),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2.0, horizontal: 12.0),
                      child: Text(
                        'GC: ${networkConfig.gcCount} | BC: ${networkConfig.bcCount} | PC: ${networkConfig.pcCount} | SC: ${networkConfig.scCount}',
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.secondary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverFillRemaining(
            hasScrollBody: false,
            child: Column(
              children: [
                const Expanded(
                  flex: 7,
                  child: NeuralCanvas3D(),
                ),
                Divider(height: 1, color: colorScheme.outline.withValues(alpha: 0.1)),
                const SizedBox(
                  height: 120,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(12, 8, 12, 4),
                    child: SignalPlotter(),
                  ),
                ),
                const SizedBox(
                  height: 90,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(12, 4, 12, 4),
                    child: ConvergenceChart(),
                  ),
                ),
                const SizedBox(height: 8), // Minimal bottom breathing room
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimControlGroup(BuildContext context, SimulationState state, SimulationNotifier notifier) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.refresh, size: 18),
            onPressed: () => notifier.resetEpisode(),
            tooltip: 'Reset',
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: Icon(state.isRunning ? Icons.pause : Icons.play_arrow, size: 18),
            onPressed: () {
              if (state.isRunning) {
                notifier.pauseSimulation();
              } else {
                notifier.startSimulation();
              }
            },
            tooltip: state.isRunning ? 'Pause' : 'Start',
          ),
          if (state.isRunning || state.episodeStep > 0 || state.episodeCount > 0)
            IconButton(
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.stop, size: 18),
              onPressed: () => notifier.stopSimulation(),
              tooltip: 'Stop',
            ),
        ],
      ),
    );
  }

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
