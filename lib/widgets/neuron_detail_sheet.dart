import 'package:flutter/material.dart';
import '../models/neuron_model.dart';
import '../models/cell_type_descriptions.dart';

/// A modal bottom sheet that displays real-time state and anatomical details for a selected neuron.
///
/// It provides technical data such as membrane potential and eligibility traces,
/// as well as a descriptive overview of the neuron's role in the cerebellum.
class NeuronDetailSheet extends StatelessWidget {
  final NeuronModel neuron;

  const NeuronDetailSheet({super.key, required this.neuron});

  @override
  Widget build(BuildContext context) {
    final description = kCellTypeDescriptions[neuron.cellType] ?? 'No description available.';
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                neuron.cellType,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              Chip(
                label: Text(
                  neuron.isInhibitory ? 'Inhibitory' : 'Excitatory',
                  style: TextStyle(color: colorScheme.onTertiaryContainer),
                ),
                backgroundColor: neuron.isInhibitory 
                  ? colorScheme.error.withValues(alpha: 0.3) 
                  : colorScheme.tertiaryContainer,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildDataRow(context, 'Membrane Potential', neuron.membranePotential.toStringAsFixed(4)),
          _buildDataRow(context, 'Eligibility Trace', neuron.eligibilityTrace.toStringAsFixed(4)),
          _buildDataRow(context, 'Threshold', neuron.threshold.toStringAsFixed(2)),
          _buildDataRow(
            context, 
            'Status', 
            neuron.isFiring ? 'FIRING' : 'resting',
            valueColor: neuron.isFiring ? colorScheme.error : colorScheme.onSurface.withValues(alpha: 0.54),
          ),
          Divider(color: colorScheme.outline.withValues(alpha: 0.24), height: 32),
          Text(
            description,
            style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.7), fontStyle: FontStyle.italic),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  /// Builds a stylized row for displaying a labeled data point.
  Widget _buildDataRow(BuildContext context, String label, String value, {Color? valueColor}) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          ...[
            Text(label, style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.7))),
            Text(
              value,
              style: TextStyle(
                color: valueColor ?? colorScheme.onSurface,
                fontFamily: 'monospace',
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

