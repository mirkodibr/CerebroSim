import 'package:flutter/material.dart';
import '../models/neuron_model.dart';
import '../models/cell_type_descriptions.dart';

class NeuronDetailSheet extends StatelessWidget {
  final NeuronModel neuron;

  const NeuronDetailSheet({super.key, required this.neuron});

  @override
  Widget build(BuildContext context) {
    final description = kCellTypeDescriptions[neuron.cellType] ?? 'No description available.';

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
                  color: Colors.white,
                ),
              ),
              Chip(
                label: Text(
                  neuron.isInhibitory ? 'Inhibitory' : 'Excitatory',
                  style: const TextStyle(color: Colors.white),
                ),
                backgroundColor: neuron.isInhibitory ? Colors.red.withOpacity(0.3) : Colors.cyan.withOpacity(0.3),
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
            valueColor: neuron.isFiring ? Colors.red : Colors.grey,
          ),
          const Divider(color: Colors.white24, height: 32),
          Text(
            description,
            style: const TextStyle(color: Colors.white70, fontStyle: FontStyle.italic),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildDataRow(BuildContext context, String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          ...[
            Text(label, style: const TextStyle(color: Colors.white70)),
            Text(
              value,
              style: TextStyle(
                color: valueColor ?? Colors.white,
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
