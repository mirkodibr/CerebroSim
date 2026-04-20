import 'dart:collection';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/plot_point.dart';

/// A [Notifier] that manages a sliding buffer of [PlotPoint]s for real-time visualization.
///
/// It maintains a maximum of 200 points to ensure smooth performance while
/// providing enough history for the user to observe trends in the simulation.
class PlotBufferNotifier extends Notifier<List<PlotPoint>> {
  static const int _maxSize = 200;

  @override
  List<PlotPoint> build() => [];

  /// Adds a new [point] to the buffer and removes the oldest point if the
  /// limit is exceeded.
  void addPoint(PlotPoint point) {
    final queue = Queue<PlotPoint>.from(state);
    if (queue.length >= _maxSize) queue.removeFirst();
    queue.addLast(point);
    state = queue.toList(growable: false);
  }

  /// Clears the entire buffer.
  void clear() {
    state = [];
  }
}

/// Provider for the [PlotBufferNotifier].
final plotBufferProvider = NotifierProvider<PlotBufferNotifier, List<PlotPoint>>(() {
  return PlotBufferNotifier();
});
