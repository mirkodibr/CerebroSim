import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'plot_buffer_provider.dart';

typedef LegendReadout = ({double critic, double actual, double gain});

/// Notifier that exposes the latest ring-buffer values at a 5 Hz update rate.
///
/// The underlying painter still reads at 60 Hz; this provider only updates
/// the legend text 5× per second so values remain human-readable.
class LegendReadoutNotifier extends Notifier<LegendReadout> {
  Timer? _timer;

  @override
  LegendReadout build() {
    ref.onDispose(() => _timer?.cancel());
    _timer = Timer.periodic(const Duration(milliseconds: 200), (_) => _update());
    return (critic: 0.0, actual: 0.0, gain: 0.0);
  }

  void _update() {
    final buf = ref.read(plotRingBufferProvider);
    if (buf.filled == 0) return;
    final idx = (buf.writeIndex - 1 + buf.capacity) % buf.capacity;
    state = (
      critic: buf.criticPrediction[idx].toDouble(),
      actual: buf.actualSignal[idx].toDouble(),
      gain: buf.gainRatio[idx].toDouble(),
    );
  }
}

final legendReadoutProvider =
    NotifierProvider<LegendReadoutNotifier, LegendReadout>(
  LegendReadoutNotifier.new,
);
