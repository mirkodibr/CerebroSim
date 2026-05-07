import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import '../providers/simulation_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/vault_provider.dart';
import '../providers/environment_provider.dart';
import '../providers/episode_history_provider.dart';
import '../providers/plot_buffer_provider.dart';
import '../providers/network_config_provider.dart';
import '../widgets/task_selector.dart';
import '../widgets/neural_canvas.dart';
import '../widgets/signal_plotter.dart';
import '../widgets/convergence_chart.dart';
import '../models/experiment_snapshot.dart';
import '../models/simulation_state.dart';
import '../services/export_service.dart';
import '../widgets/tutorial_overlay.dart';

/// The primary experimental workspace for CerebroSim.
class SimulateScreen extends ConsumerStatefulWidget {
  const SimulateScreen({super.key});

  @override
  ConsumerState<SimulateScreen> createState() => _SimulateScreenState();
}

class _SimulateScreenState extends ConsumerState<SimulateScreen> {
  StreamSubscription? _convergenceSub;
  bool _chartsExpanded = false;

  @override
  void initState() {
    super.initState();
    _convergenceSub = ref.read(simulationControllerProvider).convergenceEventStream.listen((ep) {
      if (mounted) {
        _showConvergenceSnackBar(context, ep);
      }
    });
  }

  @override
  void dispose() {
    _convergenceSub?.cancel();
    super.dispose();
  }

  void _showConvergenceSnackBar(BuildContext context, int episode) {
    final colorScheme = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: colorScheme.primaryContainer,
        duration: const Duration(seconds: 4),
        content: Row(
          children: [
            Icon(Icons.emoji_events, color: colorScheme.onPrimaryContainer),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                "Convergence detected at episode $episode! The cerebellum has learned.",
                style: TextStyle(color: colorScheme.onPrimaryContainer, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final coldState = ref.watch(coldSimulationProvider);
    final controller = ref.read(simulationControllerProvider);
    final networkConfig = ref.watch(networkConfigProvider);
    final vaultSnapshots = ref.watch(vaultProvider).value ?? [];
    final colorScheme = Theme.of(context).colorScheme;

    final isDesktop = defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux;

    Widget content = Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            snap: true,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('CerebroSim RL Lab'),
                InkWell(
                  onTap: () => context.push('/network_config'),
                  child: Text(
                    'GC: ${networkConfig.gcCount} | BC: ${networkConfig.bcCount} | PC: ${networkConfig.pcCount} | SC: ${networkConfig.scCount}',
                    style: TextStyle(
                      fontSize: 10,
                      color: colorScheme.secondary.withValues(alpha: 0.8),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: colorScheme.surface,
            elevation: 0,
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1.0),
              child: Divider(
                  height: 1, color: colorScheme.outline.withValues(alpha: 0.1)),
            ),
            actions: [
              _buildSimControlGroup(context, coldState, controller),
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(Icons.download_outlined, size: 22),
                onPressed: () => _showExportOptions(context, ref),
                tooltip: 'Export data',
              ),
              const SizedBox(width: 4),
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
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.only(top: 4, bottom: 4),
              child: TaskSelector(),
            ),
          ),
          SliverFillRemaining(
            hasScrollBody: false,
            child: Column(
              mainAxisSize: MainAxisSize.max,
              children: [
                const Expanded(
                  child: NeuralCanvas3D(),
                ),
                _buildChartsDrawer(colorScheme),
              ],
            ),
          ),
        ],
      ),
    );

    if (isDesktop) {
      return Focus(
        autofocus: true,
        onKeyEvent: (node, event) {
          if (event is! KeyDownEvent) return KeyEventResult.ignored;
          switch (event.logicalKey) {
            case LogicalKeyboardKey.space:
              coldState.isRunning
                  ? controller.pauseSimulation()
                  : controller.startSimulation();
              return KeyEventResult.handled;
            case LogicalKeyboardKey.keyR:
              controller.resetEpisode();
              return KeyEventResult.handled;
            case LogicalKeyboardKey.digit1:
              controller.setSpeed(1.0);
              return KeyEventResult.handled;
            case LogicalKeyboardKey.digit5:
              controller.setSpeed(5.0);
              return KeyEventResult.handled;
            case LogicalKeyboardKey.digit0:
              controller.setSpeed(10.0);
              return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: content,
      );
    }

    return Stack(
      children: [
        content,
        const TutorialOverlay(),
      ],
    );
  }

  Widget _buildChartsDrawer(ColorScheme colorScheme) {
    return SafeArea(
      top: false,
      left: false,
      right: false,
      bottom: true,
      child: GestureDetector(
        onTap: () => setState(() => _chartsExpanded = !_chartsExpanded),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          height: _chartsExpanded ? 280 : 35,
          decoration: BoxDecoration(
            color: _chartsExpanded ? colorScheme.surface : colorScheme.surfaceContainerHighest,
            border: Border(
              top: BorderSide(color: colorScheme.outline.withValues(alpha: 0.1)),
            ),
          ),
          child: Column(
            children: [
              Container(
                height: 34,
                alignment: Alignment.center,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.show_chart, size: 14, color: colorScheme.secondary),
                    const SizedBox(width: 8),
                    Text(
                      _chartsExpanded ? 'Charts  ▼' : 'Charts  ▲',
                      style: TextStyle(
                        fontSize: 12, 
                        color: colorScheme.secondary, 
                        fontWeight: FontWeight.bold
                      ),
                    ),
                  ],
                ),
              ),
              if (_chartsExpanded) ...[
                const SizedBox(
                  height: 120,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(8, 4, 8, 0),
                    child: SignalPlotter(),
                  ),
                ),
                const SizedBox(
                  height: 110,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(8, 4, 8, 4),
                    child: ConvergenceChart(),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSimControlGroup(
      BuildContext context, ColdSimState state, SimulationController controller) {
    final colorScheme = Theme.of(context).colorScheme;
    final isExpanded = state.isRunning || state.episodeCount > 0;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Play/Pause Toggle
        IconButton(
          icon: Icon(
            state.isRunning
                ? Icons.pause_circle_filled
                : Icons.play_circle_filled,
            size: 28,
            color: state.isRunning ? colorScheme.tertiary : colorScheme.primary,
          ),
          onPressed: () {
            if (state.isRunning) {
              controller.pauseSimulation();
            } else {
              controller.startSimulation();
            }
          },
          tooltip: state.isRunning ? 'Pause' : 'Start simulation',
        ),

        // Stop/Reset
        if (isExpanded)
          IconButton(
            icon: Icon(Icons.stop_circle_outlined,
                size: 24, color: colorScheme.error),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Reset Simulation?'),
                  content: const Text(
                      'This clears all episode history and synaptic weights.'),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel')),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: TextButton.styleFrom(
                          foregroundColor: colorScheme.error),
                      child: const Text('Reset'),
                    ),
                  ],
                ),
              );
              if (confirm == true) {
                controller.resetEpisode();
              }
            },
            tooltip: 'Reset simulation',
          ),

        // Speed Selector
        TextButton(
          onPressed: () {
            final currentSpeed = state.speedMultiplier;
            double nextSpeed;
            if (currentSpeed < 5.0) {
              nextSpeed = 5.0;
            } else if (currentSpeed < 10.0) {
              nextSpeed = 10.0;
            } else {
              nextSpeed = 1.0;
            }
            controller.setSpeed(nextSpeed);
          },
          style: TextButton.styleFrom(
            minimumSize: const Size(40, 36),
            padding: EdgeInsets.zero,
            foregroundColor:
                state.speedMultiplier > 1.0 ? colorScheme.tertiary : colorScheme.onSurface,
          ),
          child: Text(
            '${state.speedMultiplier.toInt()}×',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  void _showExportOptions(BuildContext context, WidgetRef ref) {
    final history = ref.read(episodeHistoryProvider);
    final ringBuffer = ref.read(plotRingBufferProvider);
    final colorScheme = Theme.of(context).colorScheme;

    if (history.isEmpty && ringBuffer.filled == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Run simulation first to export data.')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: colorScheme.surface,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text('Export Data',
                  style: Theme.of(context).textTheme.titleMedium),
            ),
            if (history.isNotEmpty)
              ListTile(
                leading: const Icon(Icons.history),
                title: const Text('Export episode history (.csv)'),
                onTap: () {
                  Navigator.pop(context);
                  final csv = ExportService.episodesToCsv(history);
                  final bytes = utf8.encode(csv);
                  Share.shareXFiles(
                    [
                      XFile.fromData(bytes,
                          name: 'episode_history.csv', mimeType: 'text/csv')
                    ],
                    text: 'CerebroSim Episode History',
                  );
                },
              ),
            if (ringBuffer.filled > 0)
              ListTile(
                leading: const Icon(Icons.show_chart),
                title: const Text('Export signal data (.csv)'),
                onTap: () {
                  Navigator.pop(context);
                  final plotPoints = ringBuffer.entries.map((e) => PlotPoint(
                    criticPrediction: e.criticPrediction,
                    actualSignal: e.actualSignal,
                    gainRatio: e.gainRatio,
                  )).toList();
                  final csv = ExportService.plotBufferToCsv(plotPoints);
                  final bytes = utf8.encode(csv);
                  Share.shareXFiles(
                    [
                      XFile.fromData(bytes,
                          name: 'signal_data.csv', mimeType: 'text/csv')
                    ],
                    text: 'CerebroSim Signal Data',
                  );
                },
              ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showSaveDialog(BuildContext context, WidgetRef ref) {
    final titleController = TextEditingController();
    final notesController = TextEditingController();
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
                Text('Save Experiment',
                    style: TextStyle(
                        color: colorScheme.onSurface,
                        fontSize: 20,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                TextFormField(
                  controller: titleController,
                  style: TextStyle(color: colorScheme.onSurface),
                  decoration: InputDecoration(
                    labelText: 'Experiment Title',
                    labelStyle: TextStyle(
                        color: colorScheme.onSurface.withValues(alpha: 0.7)),
                    border: const OutlineInputBorder(),
                  ),
                  validator: (v) => (v == null || v.length < 3)
                      ? 'Minimum 3 characters'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: notesController,
                  style: TextStyle(color: colorScheme.onSurface),
                  maxLines: 3,
                  maxLength: 300,
                  decoration: InputDecoration(
                    labelText: 'Notes (optional)',
                    labelStyle: TextStyle(
                        color: colorScheme.onSurface.withValues(alpha: 0.7)),
                    border: const OutlineInputBorder(),
                  ),
                ),
                SwitchListTile(
                  title: Text('Share Publicly',
                      style: TextStyle(
                          color: colorScheme.onSurface.withValues(alpha: 0.7))),
                  value: isPublic,
                  onChanged: isSaving
                      ? null
                      : (v) => setModalState(() => isPublic = v),
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

                              final snapshot =
                                  ExperimentSnapshot.fromSimulation(
                                userId: user.uid,
                                userEmail: user.email ?? 'anon',
                                taskName: task.name,
                                title: titleController.text,
                                notes: notesController.text,
                                isPublic: isPublic,
                                state: simState,
                                episodeHistory:
                                    ref.read(episodeHistoryProvider),
                                networkConfig: ref.read(networkConfigProvider),
                              );

                              await ref.read(vaultProvider.notifier)
                                  .saveSnapshot(snapshot);
                              if (context.mounted) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text('Experiment saved!')),
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
