import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/experiment_snapshot.dart';
import '../models/episode_record.dart';
import '../providers/network_config_provider.dart';

/// Replays a saved experiment's learning trajectory episode by episode.
///
/// This is a pure visualization replay — it does not re-simulate.
class ReplayScreen extends ConsumerStatefulWidget {
  final ExperimentSnapshot snapshot;

  const ReplayScreen({super.key, required this.snapshot});

  @override
  ConsumerState<ReplayScreen> createState() => _ReplayScreenState();
}

class _ReplayScreenState extends ConsumerState<ReplayScreen> {
  int _currentIndex = 0;
  bool _isPlaying = false;
  Timer? _timer;

  List<EpisodeRecord> get _history => widget.snapshot.episodeHistory;
  bool get _isAtEnd => _currentIndex >= _history.length - 1;
  bool get _hasHistory => _history.isNotEmpty;

  // Episode index where meanPunishment first crosses convergence threshold.
  static const _convergenceThreshold = 0.2;
  int? get _convergenceIndex {
    for (int i = 0; i < _history.length; i++) {
      if (_history[i].meanPunishment < _convergenceThreshold) return i;
    }
    return null;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _play() {
    if (!_hasHistory || _isAtEnd) return;
    setState(() => _isPlaying = true);
    _timer = Timer.periodic(const Duration(milliseconds: 200), (_) {
      if (!mounted) return;
      if (_isAtEnd) {
        _timer?.cancel();
        setState(() => _isPlaying = false);
      } else {
        setState(() => _currentIndex++);
      }
    });
  }

  void _pause() {
    _timer?.cancel();
    setState(() => _isPlaying = false);
  }

  void _restart() {
    _pause();
    setState(() => _currentIndex = 0);
  }

  void _skipToEnd() {
    _pause();
    setState(() => _currentIndex = _history.isEmpty ? 0 : _history.length - 1);
  }

  void _forkToSimulate() {
    if (widget.snapshot.networkConfig != null) {
      ref.read(networkConfigProvider.notifier).update(widget.snapshot.networkConfig!);
    }
    context.go('/shell/simulate');
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final snap = widget.snapshot;
    final convIdx = _convergenceIndex;
    final justConverged = _hasHistory && convIdx != null && _currentIndex == convIdx;

    return Scaffold(
      appBar: AppBar(
        title: Text('Replay: ${snap.title.isEmpty ? 'Untitled' : snap.title}'),
        backgroundColor: colorScheme.surface,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: colorScheme.outline.withValues(alpha: 0.1)),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Metadata header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: [
                  _MetaChip(label: snap.taskName.toUpperCase(), colorScheme: colorScheme),
                  const SizedBox(width: 8),
                  _MetaChip(
                    label: '${_history.length} episodes',
                    colorScheme: colorScheme,
                  ),
                  const SizedBox(width: 8),
                  if (convIdx != null)
                    _MetaChip(
                      label: 'Converges @ ep ${_history[convIdx].episodeNumber}',
                      colorScheme: colorScheme,
                      highlight: true,
                    ),
                ],
              ),
            ),

            // Convergence banner on reaching convergence
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 400),
              crossFadeState: justConverged
                  ? CrossFadeState.showFirst
                  : CrossFadeState.showSecond,
              firstChild: Container(
                margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.emoji_events, color: colorScheme.onPrimaryContainer, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Convergence detected at episode ${_history[convIdx!].episodeNumber}!',
                        style: TextStyle(
                          color: colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              secondChild: const SizedBox(height: 0),
            ),

            const SizedBox(height: 12),

            // Replay chart
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _hasHistory
                    ? _ReplayChart(
                        history: _history,
                        visibleCount: _currentIndex + 1,
                        convergenceIndex: convIdx,
                        colorScheme: colorScheme,
                      )
                    : Center(
                        child: Text(
                          'No episode history saved in this snapshot.',
                          style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.5)),
                        ),
                      ),
              ),
            ),

            // Scrubber
            if (_hasHistory) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                child: Row(
                  children: [
                    Text(
                      'Ep ${_hasHistory ? _history[_currentIndex].episodeNumber : 0}',
                      style: TextStyle(fontSize: 11, color: colorScheme.onSurface.withValues(alpha: 0.6)),
                    ),
                    Expanded(
                      child: Slider(
                        value: _currentIndex.toDouble(),
                        min: 0,
                        max: (_history.length - 1).toDouble().clamp(1, double.infinity),
                        onChanged: (v) {
                          _pause();
                          setState(() => _currentIndex = v.round());
                        },
                      ),
                    ),
                    Text(
                      'Ep ${_history.last.episodeNumber}',
                      style: TextStyle(fontSize: 11, color: colorScheme.onSurface.withValues(alpha: 0.6)),
                    ),
                  ],
                ),
              ),
            ],

            // Controls
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.replay),
                    onPressed: _restart,
                    tooltip: 'Restart',
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
                    label: Text(_isPlaying ? 'Pause' : (_isAtEnd ? 'Replay' : 'Play')),
                    onPressed: _hasHistory
                        ? (_isPlaying ? _pause : (_isAtEnd ? _restart : _play))
                        : null,
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.skip_next),
                    onPressed: (_hasHistory && !_isAtEnd) ? _skipToEnd : null,
                    tooltip: 'Skip to end',
                  ),
                ],
              ),
            ),

            // CTA: fork config
            if (_isAtEnd && _hasHistory)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.science_outlined),
                  label: const Text('Try training with these settings'),
                  onPressed: _forkToSimulate,
                ),
              ),

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

/// Draws the convergence curve incrementally up to [visibleCount] episodes.
class _ReplayChart extends StatelessWidget {
  final List<EpisodeRecord> history;
  final int visibleCount;
  final int? convergenceIndex;
  final ColorScheme colorScheme;

  const _ReplayChart({
    required this.history,
    required this.visibleCount,
    required this.convergenceIndex,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _ReplayChartPainter(
        history: history,
        visibleCount: visibleCount,
        convergenceIndex: convergenceIndex,
        lineColor: colorScheme.primary,
        convergenceColor: colorScheme.tertiary,
        gridColor: colorScheme.outline.withValues(alpha: 0.1),
        labelColor: colorScheme.onSurface.withValues(alpha: 0.5),
      ),
    );
  }
}

class _ReplayChartPainter extends CustomPainter {
  final List<EpisodeRecord> history;
  final int visibleCount;
  final int? convergenceIndex;
  final Color lineColor;
  final Color convergenceColor;
  final Color gridColor;
  final Color labelColor;

  const _ReplayChartPainter({
    required this.history,
    required this.visibleCount,
    required this.convergenceIndex,
    required this.lineColor,
    required this.convergenceColor,
    required this.gridColor,
    required this.labelColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (history.isEmpty || visibleCount == 0) return;

    final count = visibleCount.clamp(0, history.length);
    const padding = EdgeInsets.fromLTRB(40, 16, 16, 32);
    final chartRect = Rect.fromLTWH(
      padding.left,
      padding.top,
      size.width - padding.left - padding.right,
      size.height - padding.top - padding.bottom,
    );

    // Draw grid lines
    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 0.5;
    for (double y = 0; y <= 1; y += 0.25) {
      final dy = chartRect.top + chartRect.height * (1 - y);
      canvas.drawLine(Offset(chartRect.left, dy), Offset(chartRect.right, dy), gridPaint);
    }

    // Convergence threshold line
    const threshold = 0.2;
    final threshY = chartRect.top + chartRect.height * (1 - threshold);
    canvas.drawLine(
      Offset(chartRect.left, threshY),
      Offset(chartRect.right, threshY),
      Paint()
        ..color = convergenceColor.withValues(alpha: 0.4)
        ..strokeWidth = 1
        ..style = PaintingStyle.stroke,
    );

    // Axis labels
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    for (double y = 0; y <= 1; y += 0.25) {
      final dy = chartRect.top + chartRect.height * (1 - y);
      textPainter.text = TextSpan(
        text: y.toStringAsFixed(2),
        style: TextStyle(fontSize: 9, color: labelColor),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(chartRect.left - textPainter.width - 4, dy - textPainter.height / 2));
    }

    // Draw convergence marker line
    if (convergenceIndex != null && convergenceIndex! < count) {
      final cx = chartRect.left + chartRect.width * (convergenceIndex! / (history.length - 1).clamp(1, double.infinity));
      canvas.drawLine(
        Offset(cx, chartRect.top),
        Offset(cx, chartRect.bottom),
        Paint()
          ..color = convergenceColor.withValues(alpha: 0.6)
          ..strokeWidth = 1.5,
      );
    }

    // Draw the curve
    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    final totalSpan = (history.length - 1).clamp(1, double.infinity).toDouble();

    for (int i = 0; i < count; i++) {
      final x = chartRect.left + chartRect.width * (i / totalSpan);
      final y = chartRect.top + chartRect.height * (1 - history[i].meanPunishment.clamp(0.0, 1.0));
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, linePaint);

    // Dot at current position
    if (count > 0) {
      final lastIdx = count - 1;
      final lx = chartRect.left + chartRect.width * (lastIdx / totalSpan);
      final ly = chartRect.top + chartRect.height * (1 - history[lastIdx].meanPunishment.clamp(0.0, 1.0));
      canvas.drawCircle(Offset(lx, ly), 4, Paint()..color = lineColor);
    }
  }

  @override
  bool shouldRepaint(covariant _ReplayChartPainter old) =>
      old.visibleCount != visibleCount || old.history.length != history.length;
}

class _MetaChip extends StatelessWidget {
  final String label;
  final ColorScheme colorScheme;
  final bool highlight;

  const _MetaChip({
    required this.label,
    required this.colorScheme,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: highlight ? colorScheme.primaryContainer : colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: highlight ? colorScheme.onPrimaryContainer : colorScheme.onSurface.withValues(alpha: 0.7),
        ),
      ),
    );
  }
}
