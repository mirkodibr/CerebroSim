import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/simulation_provider.dart';
import '../providers/environment_provider.dart';
import '../models/cerebellar_task.dart';

class SimulationHud extends ConsumerWidget {
  const SimulationHud({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(simulationProvider);
    final task = ref.watch(environmentProvider);
    final speedMultiplier = ref.watch(simulationProvider.notifier).speedMultiplier;
    final colorScheme = Theme.of(context).colorScheme;

    if (!state.isRunning && state.episodeCount == 0) {
      return const SizedBox.shrink();
    }

    return Positioned(
      top: 8,
      left: 8,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: colorScheme.surface.withValues(alpha: 0.75),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildStatItem(
              Icons.repeat,
              "Ep ${state.episodeCount}",
              colorScheme.onSurface,
            ),
            const SizedBox(width: 16),
            _buildStatItem(
              Icons.trending_down,
              "δ ${state.tdError.toStringAsFixed(3)}",
              colorScheme.onSurface,
            ),
            if (task == CerebellarTask.vor) ...[
              const SizedBox(width: 16),
              _buildStatItem(
                Icons.sync,
                "G ${state.rollingGainRatio.toStringAsFixed(2)}",
                colorScheme.onSurface,
              ),
            ],
            if (speedMultiplier > 1.0) ...[
              const SizedBox(width: 16),
              Text(
                "${speedMultiplier.toInt()}×",
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.tertiary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
