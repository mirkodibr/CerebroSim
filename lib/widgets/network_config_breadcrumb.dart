import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/network_config_provider.dart';

/// A compact breadcrumb row showing the current network composition as
/// color-coded pill chips that match the neuron colors in the 3D canvas.
///
/// Tapping any chip shows the full cell-type name in a tooltip.
/// Tapping the row navigates to the network configuration screen.
class NetworkConfigBreadcrumb extends ConsumerWidget {
  const NetworkConfigBreadcrumb({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(networkConfigProvider);

    return Tooltip(
      message: 'Network composition — tap to configure',
      child: InkWell(
        onTap: () => context.push('/network_config'),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _CellChip(count: config.gcCount, color: const Color(0xFFFFD700), label: 'Granule Cells'),
              const SizedBox(width: 4),
              _CellChip(count: config.bcCount, color: const Color(0xFF5B8EFF), label: 'Basket Cells'),
              const SizedBox(width: 4),
              _CellChip(count: config.pcCount, color: const Color(0xFF8A2BE2), label: 'Purkinje Cells'),
              const SizedBox(width: 4),
              _CellChip(count: config.scCount, color: const Color(0xFF4CAF50), label: 'Stellate Cells'),
            ],
          ),
        ),
      ),
    );
  }
}

class _CellChip extends StatelessWidget {
  final int count;
  final Color color;
  final String label;

  const _CellChip({
    required this.count,
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: '$label: $count',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.35), width: 0.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 3),
            Text(
              '$count',
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
