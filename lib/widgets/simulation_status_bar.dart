import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/simulation_provider.dart';
import '../providers/environment_provider.dart';

class SimulationStatusBar extends ConsumerWidget {
  const SimulationStatusBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(simulationProvider);
    final colorScheme = Theme.of(context).colorScheme;
    
    // Get environment name safely
    final envName = ref.read(environmentProvider.notifier).activeEnv.taskName;

    Color dotColor;
    String statusText;

    if (state.isRunning) {
      dotColor = Colors.green;
      statusText = "● Running";
    } else if (state.episodeCount > 0) {
      dotColor = Colors.orange;
      statusText = "● Paused";
    } else {
      dotColor = colorScheme.outline;
      statusText = "● Idle";
    }

    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      color: colorScheme.surface,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Status indicator
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                statusText,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          
          // Episode count
          if (state.episodeCount > 0)
            Text(
              "${state.episodeCount} episodes",
              style: TextStyle(
                fontSize: 11,
                color: colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),

          // Task name
          Text(
            envName,
            style: TextStyle(
              fontSize: 11,
              color: colorScheme.secondary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
