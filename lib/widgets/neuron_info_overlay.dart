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
            color: const Color(0xFF1E1E1E).withOpacity(0.95),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white24),
            boxShadow: const [
              BoxShadow(blurRadius: 10, color: Colors.black54),
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
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: neuron.isInhibitory ? Colors.red.withOpacity(0.2) : Colors.cyan.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: neuron.isInhibitory ? Colors.red : Colors.cyan,
                        width: 1,
                      ),
                    ),
                    child: Text(
                      neuron.isInhibitory ? 'INHIB' : 'EXCIT',
                      style: TextStyle(
                        color: neuron.isInhibitory ? Colors.red : Colors.cyan,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white54, size: 16),
                    onPressed: onClose,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const Divider(color: Colors.white12),
              _buildValueRow('Membrane V', neuron.membranePotential, neuron.isFiring),
              _buildValueRow('Eligibility', neuron.eligibilityTrace, neuron.isFiring),
              _buildValueRow('Threshold', neuron.threshold, false),
              _buildValueRow('Decay Rate', neuron.decayRate, false),
              const SizedBox(height: 8),
              Text(
                kCellTypeDescriptions[neuron.cellType] ?? '',
                style: const TextStyle(
                  color: Colors.white70,
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

  Widget _buildValueRow(String label, double value, bool isFiring) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 11)),
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 150),
            style: TextStyle(
              color: isFiring ? Colors.red : Colors.white,
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
