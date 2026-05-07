import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/plot_ring_buffer.dart';
import '../models/plot_point.dart';

/// Holds the single [PlotRingBuffer] instance for the lifetime of the app.
/// Consumers read signal data from here; they never materialise a List.
final plotRingBufferProvider = Provider<PlotRingBuffer>((ref) {
  return PlotRingBuffer();
});

/// A [Notifier] whose state is a monotonically-increasing tick counter.
///
/// Each [push] writes one sample into the shared [PlotRingBuffer] and
/// increments the counter so painter subscribers know to repaint —
/// without ever allocating a copy of the data.
class PlotBufferNotifier extends Notifier<int> {
  static const int _maxSize = 200; // kept as a constant for test assertions

  @override
  int build() => 0;

  /// Writes one sample directly into the ring buffer. O(1), zero allocation.
  void push(double critic, double actual, double gain) {
    ref.read(plotRingBufferProvider).push(critic, actual, gain);
    state = state + 1;
  }

  /// Convenience wrapper accepting a [PlotPoint] for any serialization call
  /// sites that still construct one. The [PlotPoint] itself is NOT placed
  /// in the ring buffer — only its scalar fields are forwarded.
  void addPoint(PlotPoint point) {
    push(point.criticPrediction, point.actualSignal, point.gainRatio);
  }

  /// Clears the ring buffer and resets the tick counter.
  void clear() {
    ref.read(plotRingBufferProvider).clear();
    state = 0;
  }
}

/// Provider for the [PlotBufferNotifier].
final plotBufferProvider =
    NotifierProvider<PlotBufferNotifier, int>(() => PlotBufferNotifier());
