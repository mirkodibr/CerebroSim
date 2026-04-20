import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/simulation_provider.dart';
import '../providers/environment_provider.dart';
import '../providers/episode_history_provider.dart';
import '../providers/learning_rate_provider.dart';
import '../services/simulation_explainer.dart';

/// A widget that displays real-time human-readable explanations of the 
/// current simulation state.
class ExplanationCard extends ConsumerWidget {
  const ExplanationCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(simulationProvider);
    final history = ref.watch(episodeHistoryProvider);
    final task = ref.watch(environmentProvider);
    final learningRate = ref.watch(learningRateProvider);
    final colorScheme = Theme.of(context).colorScheme;

    final meanPunishment = history.isNotEmpty ? history.last.meanPunishment : 0.0;
    
    final explanation = SimulationExplainer.explain(
      episodeCount: state.episodeCount,
      meanPunishment: meanPunishment,
      tdError: state.tdError,
      learningRate: learningRate,
      task: task,
    );

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.secondary.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.psychology, size: 16, color: colorScheme.secondary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              explanation,
              key: ValueKey(explanation), // Needed for AnimatedSwitcher to detect changes
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSecondaryContainer,
                height: 1.4,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
