import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/cerebellar_task.dart';
import '../providers/environment_provider.dart';
import '../providers/simulation_provider.dart';

/// A widget that allows users to switch between different [CerebellarTask] environments.
///
/// It uses a [SegmentedButton] to select the task. If a simulation is currently
/// running, it prompts the user for confirmation before resetting the state.
/// For the VOR task, it also reveals a [VorConfigPanel] for parameter tuning.
class TaskSelector extends ConsumerWidget {
  const TaskSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final task = ref.watch(environmentProvider);
    final isRunning = ref.watch(simulationProvider).isRunning;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: SegmentedButton<CerebellarTask>(
            segments: const [
              ButtonSegment(value: CerebellarTask.eyeblink, label: Text('Eyeblink'), icon: Icon(Icons.remove_red_eye)),
              ButtonSegment(value: CerebellarTask.sineWave, label: Text('Sine'), icon: Icon(Icons.waves)),
              ButtonSegment(value: CerebellarTask.vor, label: Text('VOR'), icon: Icon(Icons.sync)),
            ],
            selected: {task},
            onSelectionChanged: (newSelection) async {
              final newTask = newSelection.first;
              if (isRunning) {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Reset Simulation?'),
                    content: const Text('Switching tasks will reset the current simulation state.'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                      TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Reset')),
                    ],
                  ),
                );
                if (confirm != true) return;
              }
              ref.read(environmentProvider.notifier).selectTask(newTask);
            },
          ),
        ),
        if (task == CerebellarTask.vor) const VorConfigPanel(),
      ],
    );
  }
}

/// A configuration panel for the Vestibulo-Ocular Reflex (VOR) task.
///
/// It provides sliders to adjust the target gain, signal amplitude, and
/// frequency of the simulation, allowing users to model healthy or pathological states.
class VorConfigPanel extends ConsumerWidget {
  const VorConfigPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(vorConfigProvider);
    
    String status = 'Healthy VOR baseline';
    if (config.targetGain < 0.6) status = 'Simulating cerebellar ataxia';
    if (config.targetGain > 1.4) status = 'Simulating gain-up adaptation';

    return Card(
      margin: const EdgeInsets.all(8.0),
      color: Colors.white.withValues(alpha: 0.05),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Text(status, style: TextStyle(color: _getStatusColor(config.targetGain), fontWeight: FontWeight.bold)),
            _buildSlider('Target Gain', config.targetGain, 0.1, 2.0, (v) {
              ref.read(vorConfigProvider.notifier).update(config.copyWith(targetGain: v));
            }),
            _buildSlider('Amplitude', config.amplitude, 10.0, 60.0, (v) {
              ref.read(vorConfigProvider.notifier).update(config.copyWith(amplitude: v));
            }),
            _buildSlider('Frequency', config.frequency, 0.5, 3.0, (v) {
              ref.read(vorConfigProvider.notifier).update(config.copyWith(frequency: v));
            }),
          ],
        ),
      ),
    );
  }

  /// Maps the current gain value to a descriptive semantic color.
  Color _getStatusColor(double gain) {
    if (gain < 0.6) return Colors.redAccent;
    if (gain > 1.4) return Colors.blueAccent;
    return Colors.greenAccent;
  }

  /// Helper for building a slider row with a label and its current value.
  Widget _buildSlider(String label, double value, double min, double max, ValueChanged<double> onChanged) {
    return Row(
      children: [
        SizedBox(width: 80, child: Text(label, style: const TextStyle(fontSize: 12))),
        Expanded(
          child: Slider(
            value: value,
            min: min,
            max: max,
            onChanged: onChanged,
          ),
        ),
        SizedBox(width: 40, child: Text(value.toStringAsFixed(1), style: const TextStyle(fontSize: 12))),
      ],
    );
  }
}

