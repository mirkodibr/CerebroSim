import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/simulation_provider.dart';

/// A persistent three-segment speed selector placed below the neural canvas.
///
/// Active segment is highlighted with the primary color. Triggers haptic
/// feedback on selection. Shows a warning icon when throttled.
class SpeedSegmentedControl extends ConsumerWidget {
  const SpeedSegmentedControl({super.key});

  static const _speeds = [1.0, 5.0, 10.0];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cold = ref.watch(coldSimulationProvider);
    final controller = ref.read(simulationControllerProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        border: Border.symmetric(
          horizontal: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.12),
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (int i = 0; i < _speeds.length; i++) ...[
            if (i > 0)
              Container(
                width: 1,
                height: 18,
                color: colorScheme.outline.withValues(alpha: 0.25),
              ),
            _SpeedChip(
              label: '${_speeds[i].toInt()}×',
              isSelected: cold.speedMultiplier == _speeds[i],
              showThrottleWarning: cold.isThrottled && cold.speedMultiplier == _speeds[i],
              colorScheme: colorScheme,
              onTap: () {
                HapticFeedback.selectionClick();
                controller.setSpeed(_speeds[i]);
              },
            ),
          ],
        ],
      ),
    );
  }
}

class _SpeedChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final bool showThrottleWarning;
  final ColorScheme colorScheme;
  final VoidCallback onTap;

  const _SpeedChip({
    required this.label,
    required this.isSelected,
    required this.showThrottleWarning,
    required this.colorScheme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minWidth: 64),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primary.withValues(alpha: 0.12)
              : Colors.transparent,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected
                    ? colorScheme.primary
                    : colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
            if (showThrottleWarning) ...[
              const SizedBox(width: 3),
              Icon(
                Icons.warning_amber_rounded,
                size: 12,
                color: colorScheme.error,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
