import 'dart:typed_data';

/// A fixed-capacity ring buffer for real-time simulation signal data.
///
/// Uses [Float32List]s for the three signal channels to avoid per-tick
/// heap allocations. All writes are O(1) and zero-allocation after
/// construction.
class PlotRingBuffer {
  final int capacity;
  final Float32List criticPrediction;
  final Float32List actualSignal;
  final Float32List gainRatio;

  int _writeIndex = 0;
  int _filled = 0;

  int get writeIndex => _writeIndex;
  int get filled => _filled;

  PlotRingBuffer({this.capacity = 200})
      : criticPrediction = Float32List(capacity),
        actualSignal = Float32List(capacity),
        gainRatio = Float32List(capacity);

  /// Writes one sample into the ring. O(1), zero allocation.
  void push(double critic, double actual, double gain) {
    criticPrediction[_writeIndex] = critic;
    actualSignal[_writeIndex] = actual;
    gainRatio[_writeIndex] = gain;
    _writeIndex = (_writeIndex + 1) % capacity;
    if (_filled < capacity) _filled++;
  }

  /// Resets read/write indices without reallocating the typed lists.
  void clear() {
    _writeIndex = 0;
    _filled = 0;
  }

  /// Index of the chronologically oldest sample in the underlying arrays.
  int get _startIndex => _filled < capacity ? 0 : _writeIndex;

  /// Returns the critic prediction at chronological position [i]
  /// (0 = oldest sample, [filled]-1 = newest).
  double getCritic(int i) => criticPrediction[(_startIndex + i) % capacity];

  /// Returns the actual signal at chronological position [i].
  double getActual(int i) => actualSignal[(_startIndex + i) % capacity];

  /// Returns the gain ratio at chronological position [i].
  double getGain(int i) => gainRatio[(_startIndex + i) % capacity];
}
