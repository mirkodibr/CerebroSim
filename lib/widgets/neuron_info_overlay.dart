import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/neuron_model.dart';
import '../models/cell_type_descriptions.dart';

/// A floating overlay that displays detailed information about a selected neuron.
/// 
/// It uses "Smart Positioning" to avoid screen edges and animates values
/// when the neuron is in a firing state.
class NeuronInfoOverlay extends ConsumerWidget {
  final NeuronModel neuron;
  final Offset position;
  final VoidCallback onClose;

  const NeuronInfoOverlay({
    super.key,
    required this.neuron,
    required this.position,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final size = MediaQuery.of(context).size;
    final colorScheme = Theme.of(context).colorScheme;
    const cardWidth = 210.0;

    // Smart Positioning: flip to left if too close to right edge
    bool flipLeft = position.dx + cardWidth + 20 > size.width;
    double left = flipLeft ? position.dx - cardWidth - 10 : position.dx + 10;
    double top = (position.dy - 50).clamp(10.0, size.height - 250.0);

    return Positioned(
      left: left,
      top: top,
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: cardWidth,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colorScheme.surface.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colorScheme.outline.withValues(alpha: 0.24)),
            boxShadow: [
              BoxShadow(blurRadius: 10, color: colorScheme.onSurface.withValues(alpha: 0.54)),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    neuron.cellType,
                    style: TextStyle(
                      color: colorScheme.onSurface,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: neuron.isInhibitory 
                        ? colorScheme.error.withValues(alpha: 0.2) 
                        : colorScheme.tertiary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: neuron.isInhibitory ? colorScheme.error : colorScheme.tertiary,
                        width: 1,
                      ),
                    ),
                    child: Text(
                      neuron.isInhibitory ? 'INHIB' : 'EXCIT',
                      style: TextStyle(
                        color: neuron.isInhibitory ? colorScheme.error : colorScheme.tertiary,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: colorScheme.onSurface.withValues(alpha: 0.54), size: 16),
                    onPressed: onClose,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              Divider(color: colorScheme.outline.withValues(alpha: 0.1)),
              _buildValueRow(context, 'Membrane V', neuron.membranePotential, neuron.isFiring),
              _buildValueRow(context, 'Eligibility', neuron.eligibilityTrace, neuron.isFiring),
              _buildValueRow(context, 'Threshold', neuron.threshold, false),
              _buildValueRow(context, 'Decay Rate', neuron.decayRate, false),
              const SizedBox(height: 8),
              Text(
                kCellTypeDescriptions[neuron.cellType] ?? '',
                style: TextStyle(
                  color: colorScheme.onSurface.withValues(alpha: 0.7),
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildValueRow(BuildContext context, String label, double value, bool isFiring) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.54), fontSize: 11)),
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 150),
            style: TextStyle(
              color: isFiring ? colorScheme.error : colorScheme.onSurface,
              fontFamily: 'Courier',
              fontSize: 12,
              fontWeight: isFiring ? FontWeight.bold : FontWeight.normal,
            ),
            child: Text(value.toStringAsFixed(3)),
          ),
        ],
      ),
    );
  }
}
