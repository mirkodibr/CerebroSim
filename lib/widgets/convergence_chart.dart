import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/episode_record.dart';
import '../providers/episode_history_provider.dart';

/// Controls whether ConvergenceChart uses dual y-axes (left = punishment, right = TD error).
class UseDualAxisNotifier extends Notifier<bool> {
  @override
  bool build() => true;

  void toggle() => state = !state;
}

final useDualAxisProvider = NotifierProvider<UseDualAxisNotifier, bool>(
  UseDualAxisNotifier.new,
);

/// A widget that visualizes the convergence of the simulation over multiple episodes.
///
/// Supports dual y-axis mode (default) where mean punishment uses the left axis (0–1)
/// and TD error uses the right axis (–1 to +1), preserving the sign information.
/// Tap/pan to scrub; long-press to pin a crosshair marker.
class ConvergenceChart extends ConsumerStatefulWidget {
  const ConvergenceChart({super.key});

  @override
  ConsumerState<ConvergenceChart> createState() => _ConvergenceChartState();
}

class _ConvergenceChartState extends ConsumerState<ConvergenceChart> {
  double? _scrubT; // normalized x position 0..1
  final List<_PinnedMarker> _pinned = [];

  static const double _left = 36.0;
  static const double _rightDual = 38.0;

  double _chartWidth(double totalWidth, bool useDual) =>
      totalWidth - _left - (useDual ? _rightDual : 0.0);

  void _onScrub(Offset local, double totalWidth, bool useDual) {
    final cw = _chartWidth(totalWidth, useDual);
    final t = ((local.dx - _left) / cw).clamp(0.0, 1.0);
    setState(() => _scrubT = t);
  }

  void _onPin(List<EpisodeRecord> history) {
    if (_scrubT == null || history.isEmpty) return;
    HapticFeedback.selectionClick();
    final idx = (_scrubT! * (history.length - 1)).round().clamp(0, history.length - 1);
    setState(() => _pinned.add(_PinnedMarker(t: _scrubT!, record: history[idx])));
  }

  void _clearScrub() => setState(() => _scrubT = null);

  @override
  Widget build(BuildContext context) {
    final history = ref.watch(episodeHistoryProvider);
    final useDual = ref.watch(useDualAxisProvider);
    final theme = Theme.of(context);

    if (history.length < 2) {
      return Center(
        child: Text(
          'Run episodes to see convergence',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return GestureDetector(
            onTapDown: (d) => _onScrub(d.localPosition, constraints.maxWidth, useDual),
            onPanUpdate: (d) => _onScrub(d.localPosition, constraints.maxWidth, useDual),
            onPanEnd: (_) => _clearScrub(),
            onTapUp: (_) => _clearScrub(),
            onLongPress: () => _onPin(history),
            child: Stack(
              children: [
                CustomPaint(
                  size: Size.infinite,
                  painter: ConvergenceChartPainter(
                    history: history,
                    labelStyle: theme.textTheme.labelSmall ?? const TextStyle(),
                    colorScheme: theme.colorScheme,
                    useDualAxis: useDual,
                  ),
                ),
                if (_scrubT != null || _pinned.isNotEmpty)
                  CustomPaint(
                    size: Size.infinite,
                    painter: _CrosshairPainter(
                      history: history,
                      scrubT: _scrubT,
                      pinned: _pinned,
                      labelStyle: theme.textTheme.labelSmall ?? const TextStyle(),
                      colorScheme: theme.colorScheme,
                      useDualAxis: useDual,
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _PinnedMarker {
  final double t;
  final EpisodeRecord record;
  const _PinnedMarker({required this.t, required this.record});
}

class _CrosshairPainter extends CustomPainter {
  final List<EpisodeRecord> history;
  final double? scrubT;
  final List<_PinnedMarker> pinned;
  final TextStyle labelStyle;
  final ColorScheme colorScheme;
  final bool useDualAxis;

  final Paint _linePaint = Paint()..strokeWidth = 1.0..style = PaintingStyle.stroke;
  final TextPainter _tp = TextPainter(textDirection: TextDirection.ltr);

  _CrosshairPainter({
    required this.history,
    required this.scrubT,
    required this.pinned,
    required this.labelStyle,
    required this.colorScheme,
    required this.useDualAxis,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const double left = 36.0;
    const double rightDual = 38.0;
    const double bottom = 20.0;
    final double chartW = size.width - left - (useDualAxis ? rightDual : 0.0);
    final double chartH = size.height - bottom;
    final int n = history.length;

    void drawAt(double t, Color lineColor) {
      final double x = left + t * chartW;
      _linePaint.color = lineColor;
      canvas.drawLine(Offset(x, 0), Offset(x, chartH), _linePaint);

      final idx = (t * (n - 1)).round().clamp(0, n - 1);
      final rec = history[idx];
      final String tdStr = useDualAxis
          ? rec.finalTdError.toStringAsFixed(3)
          : rec.finalTdError.abs().toStringAsFixed(3);

      final lines = ['Ep ${rec.episodeNumber}', 'P: ${rec.meanPunishment.toStringAsFixed(3)}', 'TD: $tdStr'];
      double ty = 4.0;
      for (final line in lines) {
        _tp.text = TextSpan(
          text: line,
          style: labelStyle.copyWith(
            fontSize: 9,
            color: colorScheme.onSurface,
            backgroundColor: colorScheme.scrim.withValues(alpha: 0.65),
          ),
        );
        _tp.layout();
        final double tx = (x + 4).clamp(left, size.width - _tp.width - 4);
        _tp.paint(canvas, Offset(tx, ty));
        ty += _tp.height + 1;
      }
    }

    for (final p in pinned) {
      drawAt(p.t, colorScheme.primary.withValues(alpha: 0.7));
    }
    if (scrubT != null) {
      drawAt(scrubT!, colorScheme.onSurface.withValues(alpha: 0.55));
    }
  }

  @override
  bool shouldRepaint(covariant _CrosshairPainter old) => true;
}

/// Painter for the convergence chart lines and axes.
class ConvergenceChartPainter extends CustomPainter {
  final List<EpisodeRecord> history;
  final TextStyle labelStyle;
  final ColorScheme colorScheme;
  final bool useDualAxis;

  static const List<double> kGridValues = [0.0, 0.25, 0.5, 0.75, 1.0];
  static const List<double> kRightAxisValues = [-1.0, -0.5, 0.0, 0.5, 1.0];

  final Paint _gridPaint = Paint()..style = PaintingStyle.stroke..strokeWidth = 0.5;
  final Paint _axisPaint = Paint()..strokeWidth = 1.0;
  final Paint _centerLinePaint = Paint()..style = PaintingStyle.stroke..strokeWidth = 0.8;
  final Paint _punishmentPaint = Paint()
    ..color = const Color(0xFFE24B4A)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.0
    ..strokeCap = StrokeCap.round;
  final Paint _tdErrorPaint = Paint()
    ..color = const Color(0xFF00FFFF)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.0
    ..strokeCap = StrokeCap.round;

  final Path _punishmentPath = Path();
  final Path _tdErrorPath = Path();
  final TextPainter _textPainter = TextPainter(textDirection: TextDirection.ltr);

  ConvergenceChartPainter({
    required this.history,
    required this.labelStyle,
    required this.colorScheme,
    this.useDualAxis = true,
  }) {
    _gridPaint.color = colorScheme.onSurface.withValues(alpha: 0.1);
    _axisPaint.color = colorScheme.outline.withValues(alpha: 0.3);
    _centerLinePaint.color = const Color(0xFF00FFFF).withValues(alpha: 0.25);
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (history.isEmpty) return;

    const double leftMargin = 36.0;
    const double rightMargin = 38.0;
    const double bottomMargin = 20.0;
    final double effectiveRight = useDualAxis ? rightMargin : 0.0;
    final double chartWidth = size.width - leftMargin - effectiveRight;
    final double chartHeight = size.height - bottomMargin;
    final double chartRight = leftMargin + chartWidth;

    // Left y-axis: punishment 0..1
    for (final val in kGridValues) {
      final double y = chartHeight - (val * chartHeight);
      _drawDashedLine(canvas, Offset(leftMargin, y), Offset(chartRight, y), _gridPaint);
      _textPainter.text = TextSpan(
        text: val.toStringAsFixed(2),
        style: labelStyle.copyWith(
          color: colorScheme.onSurface.withValues(alpha: 0.45),
          fontSize: 9,
        ),
      );
      _textPainter.layout(maxWidth: 34);
      _textPainter.paint(canvas, Offset(0, y - _textPainter.height / 2));
    }

    // Right y-axis: TD error -1..1
    if (useDualAxis) {
      for (final val in kRightAxisValues) {
        // val=-1 → y=chartHeight, val=0 → y=chartHeight/2, val=1 → y=0
        final double y = chartHeight * (0.5 - val * 0.5);
        _textPainter.text = TextSpan(
          text: val == 0.0 ? '0' : val.toStringAsFixed(1),
          style: labelStyle.copyWith(
            color: const Color(0xFF00FFFF).withValues(alpha: 0.45),
            fontSize: 9,
          ),
        );
        _textPainter.layout(maxWidth: 36);
        _textPainter.paint(canvas, Offset(chartRight + 2, y - _textPainter.height / 2));
      }

      // Dashed zero line for the TD error (right) axis
      _drawDashedLine(
        canvas,
        Offset(leftMargin, chartHeight * 0.5),
        Offset(chartRight, chartHeight * 0.5),
        _centerLinePaint,
      );
    }

    // X-axis episode labels
    final firstEp = history.first.episodeNumber;
    final lastEp = history.last.episodeNumber;
    _drawXLabel(canvas, firstEp.toString(), leftMargin, size.height - tpHeight('0'));
    _drawXLabel(canvas, lastEp.toString(), chartRight - 20, size.height - tpHeight('0'));

    // Axes
    canvas.drawLine(Offset(leftMargin, chartHeight), Offset(chartRight, chartHeight), _axisPaint);
    canvas.drawLine(Offset(leftMargin, 0), Offset(leftMargin, chartHeight), _axisPaint);
    if (useDualAxis) {
      canvas.drawLine(Offset(chartRight, 0), Offset(chartRight, chartHeight), _axisPaint);
    }

    // Data lines
    final int count = history.length;
    final double dx = chartWidth / (count - 1).clamp(1, count);

    _punishmentPath.reset();
    _tdErrorPath.reset();

    for (int i = 0; i < count; i++) {
      final record = history[i];
      final double x = leftMargin + (i * dx);
      final double yPunishment = chartHeight - (record.meanPunishment.clamp(0.0, 1.0) * chartHeight);
      final double yTdError = useDualAxis
          ? chartHeight * (0.5 - record.finalTdError.clamp(-1.0, 1.0) * 0.5)
          : chartHeight - (record.finalTdError.abs().clamp(0.0, 1.0) * chartHeight);

      if (i == 0) {
        _punishmentPath.moveTo(x, yPunishment);
        _tdErrorPath.moveTo(x, yTdError);
      } else {
        _punishmentPath.lineTo(x, yPunishment);
        _tdErrorPath.lineTo(x, yTdError);
      }
    }

    canvas.drawPath(_punishmentPath, _punishmentPaint);
    canvas.drawPath(_tdErrorPath, _tdErrorPaint);
    _drawLegend(canvas, leftMargin);
  }

  void _drawDashedLine(Canvas canvas, Offset p1, Offset p2, Paint paint) {
    const dashWidth = 4.0;
    const dashSpace = 4.0;
    double x = p1.dx;
    while (x < p2.dx) {
      canvas.drawLine(Offset(x, p1.dy), Offset(x + dashWidth, p1.dy), paint);
      x += dashWidth + dashSpace;
    }
  }

  double tpHeight(String text) {
    _textPainter.text = TextSpan(text: text, style: labelStyle);
    _textPainter.layout();
    return _textPainter.height;
  }

  void _drawXLabel(Canvas canvas, String text, double x, double y) {
    _textPainter.text = TextSpan(
      text: text,
      style: labelStyle.copyWith(fontSize: 10, color: colorScheme.onSurface.withValues(alpha: 0.45)),
    );
    _textPainter.layout();
    _textPainter.paint(canvas, Offset(x, y));
  }

  void _drawLegend(Canvas canvas, double left) {
    final last = history.last;

    final String punishLabel = useDualAxis
        ? '● Punishment (L): ${last.meanPunishment.toStringAsFixed(3)}'
        : 'Punishment: ${last.meanPunishment.toStringAsFixed(3)}';
    _textPainter.text = TextSpan(
      text: punishLabel,
      style: labelStyle.copyWith(
        color: _punishmentPaint.color,
        fontWeight: FontWeight.bold,
        fontSize: 9,
      ),
    );
    _textPainter.layout();
    _textPainter.paint(canvas, Offset(left + 4, 4));
    final double ph = _textPainter.height;

    final String tdLabel = useDualAxis
        ? '● TD Error (R): ${last.finalTdError.toStringAsFixed(3)}'
        : '|TD error|: ${last.finalTdError.abs().toStringAsFixed(3)}';
    _textPainter.text = TextSpan(
      text: tdLabel,
      style: labelStyle.copyWith(
        color: _tdErrorPaint.color,
        fontWeight: FontWeight.bold,
        fontSize: 9,
      ),
    );
    _textPainter.layout();
    _textPainter.paint(canvas, Offset(left + 4, ph + 6));
  }

  @override
  bool shouldRepaint(covariant ConvergenceChartPainter oldDelegate) {
    return oldDelegate.history.length != history.length ||
        (history.isNotEmpty && !identical(oldDelegate.history.last, history.last)) ||
        oldDelegate.colorScheme != colorScheme ||
        oldDelegate.useDualAxis != useDualAxis;
  }
}
