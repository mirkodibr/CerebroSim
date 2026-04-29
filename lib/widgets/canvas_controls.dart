import 'package:flutter/material.dart';

/// Floating controls for the neural canvas, such as resetting the view.
class CanvasControls extends StatelessWidget {
  final VoidCallback onResetView;
  final VoidCallback onShowHint;

  const CanvasControls({
    super.key,
    required this.onResetView,
    required this.onShowHint,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FloatingActionButton.small(
          heroTag: 'canvas_hint',
          onPressed: onShowHint,
          backgroundColor: colorScheme.surfaceContainerHighest,
          child: Icon(Icons.help_outline, color: colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 8),
        FloatingActionButton.small(
          heroTag: 'canvas_reset',
          onPressed: onResetView,
          backgroundColor: colorScheme.surfaceContainerHighest,
          child: Icon(Icons.center_focus_strong, color: colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }
}
