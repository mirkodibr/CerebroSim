import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/simulation_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/vault_provider.dart';
import '../providers/environment_provider.dart';
import '../providers/episode_history_provider.dart';
import '../providers/network_config_provider.dart';
import '../widgets/task_selector.dart';
import '../widgets/neural_canvas.dart';
import '../widgets/signal_plotter.dart';
import '../widgets/convergence_chart.dart';
import '../widgets/simulation_status_bar.dart';
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
  int _speedIndex = 0;
  final List<double> _speeds = [
    SimulationConstants.kSpeedNormal,
    SimulationConstants.kSpeedFast,
    SimulationConstants.kSpeedVeryFast,
  ];

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(simulationProvider);
    final notifier = ref.read(simulationProvider.notifier);
    final networkConfig = ref.watch(networkConfigProvider);
    final vaultSnapshots = ref.watch(vaultProvider).value ?? [];
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
              const SizedBox(width: 8),
              Badge(
                label: Text(vaultSnapshots.length.toString()),
                isLabelVisible: vaultSnapshots.isNotEmpty,
                child: IconButton(
                  icon: const Icon(Icons.bookmark_add_outlined, size: 22),
                  onPressed: () => _showSaveDialog(context, ref),
                  tooltip: 'Save Snapshot',
                ),
              ),
              const SizedBox(width: 12),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 0),
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
          const SliverToBoxAdapter(
            child: Column(
              children: [
                SimulationStatusBar(),
                Divider(height: 1),
              ],
            ),
          ),
          SliverFillRemaining(
            hasScrollBody: false,
            child: Column(
              children: [
                const Expanded(
                  flex: 8,
                  child: NeuralCanvas3D(),
                ),
                Divider(height: 1, color: colorScheme.outline.withValues(alpha: 0.1)),
                const SizedBox(
                  height: 110,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(12, 8, 12, 4),
                    child: SignalPlotter(),
                  ),
                ),
                const SizedBox(
                  height: 80,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(12, 4, 12, 4),
                    child: ConvergenceChart(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimControlGroup(BuildContext context, SimulationState state, SimulationNotifier notifier) {
    final colorScheme = Theme.of(context).colorScheme;
    final isExpanded = state.isRunning || state.episodeCount > 0;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Play/Pause Toggle
        IconButton(
          icon: Icon(
            state.isRunning ? Icons.pause_circle_filled : Icons.play_circle_filled,
            size: 28,
            color: state.isRunning ? colorScheme.tertiary : colorScheme.primary,
          ),
          onPressed: () {
            if (state.isRunning) {
              notifier.pauseSimulation();
            } else {
              notifier.startSimulation();
            }
          },
          tooltip: state.isRunning ? 'Pause' : 'Start simulation',
        ),

        // Stop/Reset
        if (isExpanded)
          IconButton(
            icon: Icon(Icons.stop_circle_outlined, size: 24, color: colorScheme.error),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Reset Simulation?'),
                  content: const Text('This clears all episode history and synaptic weights.'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: TextButton.styleFrom(foregroundColor: colorScheme.error),
                      child: const Text('Reset'),
                    ),
                  ],
                ),
              );
              if (confirm == true) {
                notifier.resetEpisode();
              }
            },
            tooltip: 'Reset simulation',
          ),

        // Speed Selector
        TextButton(
          onPressed: () {
            setState(() {
              _speedIndex = (_speedIndex + 1) % _speeds.length;
            });
            notifier.setSpeed(_speeds[_speedIndex]);
          },
          style: TextButton.styleFrom(
            minimumSize: const Size(40, 36),
            padding: EdgeInsets.zero,
            foregroundColor: _speedIndex > 0 ? colorScheme.tertiary : colorScheme.onSurface,
          ),
          child: Text(
            '${_speeds[_speedIndex].toInt()}×',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
          ),
        ),
      ],
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
                                episodeHistory: ref.read(episodeHistoryProvider),
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
