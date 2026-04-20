import '../models/cerebellar_task.dart';

/// A rule-based engine that generates human-readable explanations of the 
/// simulation's current state and progress.
class SimulationExplainer {
  /// Generates a concise explanation based on simulation metrics and the active task.
  static String explain({
    required int episodeCount,
    required double meanPunishment,
    required double tdError,
    required double learningRate,
    required CerebellarTask task,
  }) {
    if (episodeCount == 0) {
      return _introText(task);
    }
    
    if (episodeCount < 5) {
      return 'Early learning: The network is making large errors '
          '(punishment: ${meanPunishment.toStringAsFixed(2)}). '
          'Purkinje cells are heavily suppressing DCN output.';
    }
    
    if (meanPunishment > 0.7) {
      return 'High error rate detected. Consider reducing learning '
          'rate below ${learningRate.toStringAsFixed(3)} or checking '
          'that DCN baseline drive is sufficient.';
    }
    
    if (meanPunishment < 0.2 && episodeCount > 10) {
      return 'Convergence detected after $episodeCount episodes! '
          'Parallel fiber weights have stabilized. The climbing fiber '
          'signal is minimal — the cerebellum has learned the task.';
    }
    
    if (tdError.abs() < 0.05) {
      return 'TD error near zero: the critic\'s prediction matches '
          'actual punishment. Weight updates are slowing (Δw ≈ 0).';
    }
    
    return 'Learning in progress: episode $episodeCount, '
        'mean punishment ${meanPunishment.toStringAsFixed(2)}, '
        '|δ| = ${tdError.abs().toStringAsFixed(3)}.';
  }

  /// Returns the introductory text for each task, explaining the biological context.
  static String _introText(CerebellarTask task) {
    switch (task) {
      case CerebellarTask.eyeblink:
        return 'Eyeblink conditioning: A tone (CS) will be followed by '
            'an airpuff (US). The network must learn to blink before '
            'the airpuff using eligibility traces to bridge the delay.';
      case CerebellarTask.sineWave:
        return 'Sine wave tracking: The DCN must produce outputs that '
            'follow a sinusoidal target. Punishment occurs when the '
            'output direction opposes the wave slope.';
      case CerebellarTask.vor:
        return 'VOR adaptation: The eyes must counter-rotate to '
            'stabilize gaze during head movement. Image slip is '
            'the error signal driving plasticity.';
      case CerebellarTask.armReaching:
        return '2D arm reaching: Four DCNs control X/Y velocity. '
            'The network must drive the arm to a randomized target '
            'by minimizing Euclidean distance.';
    }
  }
}
