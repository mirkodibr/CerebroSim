import 'dart:typed_data';

/// A fixed-capacity ring buffer for simulation plot data.
/// 
/// This class uses [Float32List] to store data for three channels:
/// - criticPrediction
/// - actualSignal
/// - gainRatio
/// 
/// It avoids per-tick allocations by reusing the same memory.
class PlotRingBuffer {
  final int capacity;
  final Float32List criticPrediction;
  final Float32List actualSignal;
  final Float32List gainRatio;

  int _writeIndex = 0;
  int _filled = 0;

  PlotRingBuffer(this.capacity)
      : criticPrediction = Float32List(capacity),
        actualSignal = Float32List(capacity),
        gainRatio = Float32List(capacity);

  int get writeIndex => _writeIndex;
  int get filled => _filled;

  /// Pushes a new set of data points into the ring buffer.
  void push(double critic, double actual, double gain) {
    criticPrediction[_writeIndex] = critic;
    actualSignal[_writeIndex] = actual;
    gainRatio[_writeIndex] = gain;

    _writeIndex = (_writeIndex + 1) % capacity;
    if (_filled < capacity) {
      _filled++;
    }
  }

  /// Resets the buffer without reallocating memory.
  void clear() {
    _writeIndex = 0;
    _filled = 0;
  }

  /// Returns an iterable that yields data in chronological order.
  /// This is used for export or non-hot-path access.
  Iterable<PlotRingBufferEntry> get entries sync* {
    if (_filled == 0) return;

    final int start = _filled < capacity ? 0 : _writeIndex;
    for (int i = 0; i < _filled; i++) {
      final int index = (start + i) % capacity;
      yield PlotRingBufferEntry(
        criticPrediction[index],
        actualSignal[index],
        gainRatio[index],
      );
    }
  }
}

/// A simple DTO for entries yielded by the [PlotRingBuffer] iterator.
class PlotRingBufferEntry {
  final double criticPrediction;
  final double actualSignal;
  final double gainRatio;

  PlotRingBufferEntry(this.criticPrediction, this.actualSignal, this.gainRatio);
}
