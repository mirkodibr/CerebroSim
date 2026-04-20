import '../models/episode_record.dart';
import '../models/plot_point.dart';

/// A service that provides data export capabilities for simulation results.
class ExportService {
  /// Converts a list of [EpisodeRecord] objects into a CSV-formatted string.
  /// 
  /// The CSV includes the episode number, mean punishment (performance), 
  /// and the final Temporal Difference (TD) error for each episode.
  static String episodesToCsv(List<EpisodeRecord> records) {
    final buffer = StringBuffer();
    buffer.writeln('episode,mean_punishment,final_td_error');
    for (final r in records) {
      buffer.writeln('${r.episodeNumber},'
          '${r.meanPunishment.toStringAsFixed(6)},'
          '${r.finalTdError.toStringAsFixed(6)}');
    }
    return buffer.toString();
  }

  /// Converts a list of [PlotPoint] objects from the real-time buffer into a CSV string.
  /// 
  /// This captures the detailed temporal signals: tick index, critic prediction, 
  /// actual environmental signal, and the calculated gain ratio.
  static String plotBufferToCsv(List<PlotPoint> points) {
    final buffer = StringBuffer();
    buffer.writeln('tick,critic_prediction,actual_signal,gain_ratio');
    for (int i = 0; i < points.length; i++) {
      final p = points[i];
      buffer.writeln('$i,'
          '${p.criticPrediction.toStringAsFixed(6)},'
          '${p.actualSignal.toStringAsFixed(6)},'
          '${p.gainRatio.toStringAsFixed(6)}');
    }
    return buffer.toString();
  }
}
