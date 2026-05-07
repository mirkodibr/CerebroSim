import '../models/episode_record.dart';
import '../services/plot_ring_buffer.dart';

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

  /// Converts the [PlotRingBuffer] into a CSV string for export.
  ///
  /// Reads samples in chronological order without materialising a list copy.
  static String plotBufferToCsv(PlotRingBuffer ringBuffer) {
    final buffer = StringBuffer();
    buffer.writeln('tick,critic_prediction,actual_signal,gain_ratio');
    for (int i = 0; i < ringBuffer.filled; i++) {
      buffer.writeln('$i,'
          '${ringBuffer.getCritic(i).toStringAsFixed(6)},'
          '${ringBuffer.getActual(i).toStringAsFixed(6)},'
          '${ringBuffer.getGain(i).toStringAsFixed(6)}');
    }
    return buffer.toString();
  }
}
