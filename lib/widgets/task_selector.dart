import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/cerebellar_task.dart';
import '../providers/environment_provider.dart';
import '../providers/simulation_provider.dart';

/// A widget that allows users to switch between different [CerebellarTask] environments.
class TaskSelector extends ConsumerStatefulWidget {
  const TaskSelector({super.key});

  @override
  ConsumerState<TaskSelector> createState() => _TaskSelectorState();
}

class _TaskSelectorState extends ConsumerState<TaskSelector> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final task = ref.watch(environmentProvider);
    final isRunning = ref.watch(simulationProvider).isRunning;

    String configLabel = 'Config';
    switch (task) {
      case CerebellarTask.eyeblink: configLabel = 'Eyeblink Config'; break;
      case CerebellarTask.sineWave: configLabel = 'Sine Config'; break;
      case CerebellarTask.vor: configLabel = 'VOR Config'; break;
      case CerebellarTask.armReaching: configLabel = 'Arm Config'; break;
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
          child: SegmentedButton<CerebellarTask>(
            style: SegmentedButton.styleFrom(
              visualDensity: VisualDensity.compact,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              textStyle: const TextStyle(fontSize: 11),
            ),
            segments: const [
              ButtonSegment(value: CerebellarTask.eyeblink, label: Text('Eyeblink'), icon: Icon(Icons.remove_red_eye, size: 18)),
              ButtonSegment(value: CerebellarTask.sineWave, label: Text('Sine'), icon: Icon(Icons.waves, size: 18)),
              ButtonSegment(value: CerebellarTask.vor, label: Text('VOR'), icon: Icon(Icons.sync, size: 18)),
              ButtonSegment(value: CerebellarTask.armReaching, label: Text('Arm'), icon: Icon(Icons.gesture, size: 18)),
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
        InkWell(
          onTap: () => setState(() => _isExpanded = !_isExpanded),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 2.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(configLabel, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                Icon(_isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, size: 16),
              ],
            ),
          ),
        ),
        AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          constraints: BoxConstraints(
            maxHeight: _isExpanded ? 160.0 : 0.0,
          ),
          clipBehavior: Clip.hardEdge,
          child: _buildConfigPanel(task),
        ),
      ],
    );
  }

  Widget _buildConfigPanel(CerebellarTask task) {
    switch (task) {
      case CerebellarTask.eyeblink:
        return const EyeblinkConfigPanel();
      case CerebellarTask.sineWave:
        return const SineConfigPanel();
      case CerebellarTask.vor:
        return const VorConfigPanel();
      default:
        return const SizedBox.shrink();
    }
  }
}

class EyeblinkConfigPanel extends ConsumerWidget {
  const EyeblinkConfigPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(eyeblinkConfigProvider);
    final status = config.csDurationMs < 150 ? "Short CS = harder association" : "Standard Pavlovian timing";

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Text(status, style: const TextStyle(fontWeight: FontWeight.bold)),
            _buildSlider('CS window', config.csDurationMs, 50, 500, (v) {
              ref.read(eyeblinkConfigProvider.notifier).update(config.copyWith(csDurationMs: v));
            }, suffix: 'ms'),
            _buildSlider('Trial duration', config.trialDurationS, 0.5, 3.0, (v) {
              ref.read(eyeblinkConfigProvider.notifier).update(config.copyWith(trialDurationS: v));
            }, suffix: 's'),
          ],
        ),
      ),
    );
  }
}

class SineConfigPanel extends ConsumerWidget {
  const SineConfigPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(sineConfigProvider);
    final status = config.frequencyHz > 2.0 ? "High frequency = rapid adaptation required" : "Standard rhythmic tracking";

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Text(status, style: const TextStyle(fontWeight: FontWeight.bold)),
            _buildSlider('Frequency', config.frequencyHz, 0.25, 4.0, (v) {
              ref.read(sineConfigProvider.notifier).update(config.copyWith(frequencyHz: v));
            }, suffix: 'Hz'),
            _buildSlider('Amplitude', config.amplitude, 0.1, 2.0, (v) {
              ref.read(sineConfigProvider.notifier).update(config.copyWith(amplitude: v));
            }),
          ],
        ),
      ),
    );
  }
}

class VorConfigPanel extends ConsumerWidget {
  const VorConfigPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(vorConfigProvider);
    
    String status = 'Healthy VOR baseline';
    if (config.targetGain < 0.6) status = 'Simulating cerebellar ataxia';
    if (config.targetGain > 1.4) status = 'Simulating gain-up adaptation';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
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
            }, suffix: 'Hz'),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(double gain) {
    if (gain < 0.6) return Colors.redAccent;
    if (gain > 1.4) return Colors.blueAccent;
    return Colors.greenAccent;
  }
}

/// Helper for building a slider row with a label and its current value.
Widget _buildSlider(String label, double value, double min, double max, ValueChanged<double> onChanged, {String suffix = ''}) {
  return Row(
    children: [
      SizedBox(width: 80, child: Text(label, style: const TextStyle(fontSize: 11))),
      Expanded(
        child: Slider(
          value: value,
          min: min,
          max: max,
          onChanged: onChanged,
        ),
      ),
      SizedBox(
        width: 50, 
        child: Text(
          '${value >= 10 ? value.round() : value.toStringAsFixed(value < 1 ? 2 : 1)}$suffix', 
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)
        )
      ),
    ],
  );
}
