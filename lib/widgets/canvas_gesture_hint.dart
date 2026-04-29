import 'package:flutter/material.dart';

/// A semi-transparent overlay hint indicating how to interact with the 3D canvas.
class CanvasGestureHint extends StatefulWidget {
  const CanvasGestureHint({super.key});

  static OverlayEntry? _currentEntry;

  /// Shows the gesture hint overlay if it is not already shown.
  static void show(BuildContext context) {
    if (_currentEntry != null) return;
    
    _currentEntry = OverlayEntry(
      builder: (context) => const CanvasGestureHint(),
    );
    Overlay.of(context).insert(_currentEntry!);
  }

  /// Dismisses the gesture hint overlay if it is currently shown.
  static void dismiss() {
    _currentEntry?.remove();
    _currentEntry = null;
  }

  @override
  State<CanvasGestureHint> createState() => _CanvasGestureHintState();
}

class _CanvasGestureHintState extends State<CanvasGestureHint> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        CanvasGestureHint.dismiss();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: CanvasGestureHint.dismiss,
      onPanDown: (_) => CanvasGestureHint.dismiss(),
      child: Container(
        color: Colors.transparent, // Capture taps across the screen
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: colorScheme.inverseSurface.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Swipe to rotate · Pinch to zoom · Tap to inspect',
              style: TextStyle(color: colorScheme.onInverseSurface),
            ),
          ),
        ),
      ),
    );
  }
}
