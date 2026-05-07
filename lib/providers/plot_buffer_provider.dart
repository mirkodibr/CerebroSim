import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/plot_ring_buffer.dart';

/// Provider for the [PlotRingBuffer] instance.
final plotRingBufferProvider = Provider<PlotRingBuffer>((ref) {
  return PlotRingBuffer(200);
});

/// A [Notifier] that manages a tick counter for real-time visualization.
///
/// It holds a reference to a [PlotRingBuffer] and increments its state (a tick counter)
/// whenever a new point is added, triggering repaints in the UI.
class PlotBufferNotifier extends Notifier<int> {
  late final PlotRingBuffer _buffer;

  @override
  int build() {
    _buffer = ref.read(plotRingBufferProvider);
    return 0;
  }

  /// Pushes a new point to the underlying ring buffer and increments the tick counter.
  void addPoint(double critic, double actual, double gain) {
    _buffer.push(critic, actual, gain);
    state++;
  }

  /// Clears the ring buffer and resets the tick counter.
  void clear() {
    _buffer.clear();
    state = 0;
  }
}

/// Provider for the [PlotBufferNotifier]. 
/// The state is a monotonically increasing integer representing the "tick".
final plotBufferProvider = NotifierProvider<PlotBufferNotifier, int>(() {
  return PlotBufferNotifier();
});
