import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/simulation_provider.dart';
import '../providers/network_config_provider.dart';

class ThrottleBanner extends ConsumerWidget {
  const ThrottleBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isThrottled = ref.watch(coldSimulationProvider.select((s) => s.isThrottled));
    if (!isThrottled) return const SizedBox.shrink();

    final colorScheme = Theme.of(context).colorScheme;

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Material(
        color: colorScheme.errorContainer,
        child: InkWell(
          onTap: () => _showThrottleDetails(context, ref),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                Icon(Icons.speed, color: colorScheme.onErrorContainer, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Simulation throttled to maintain frame rate. Tap for details.',
                    style: TextStyle(
                      color: colorScheme.onErrorContainer,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: colorScheme.onErrorContainer, size: 20),
                  onPressed: () {
                    // Manual override to clear throttling flag for this session
                    ref.read(coldSimulationProvider.notifier).setState(
                      ref.read(coldSimulationProvider).copyWith(isThrottled: false)
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showThrottleDetails(BuildContext context, WidgetRef ref) {
    final config = ref.read(networkConfigProvider);
    final totalNeurons = config.gcCount + config.bcCount + config.pcCount + config.scCount + 2; // + DCN, CF
    final colorScheme = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,
      backgroundColor: colorScheme.surface,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Performance Throttling',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.error,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'The simulation engine is currently exceeding the frame budget on your device. To ensure the UI remains responsive, CerebroSim has automatically reduced the simulation speed.',
              ),
              const SizedBox(height: 16),
              _buildDetailItem(context, 'Network Size', '$totalNeurons neurons'),
              _buildDetailItem(context, 'Isolate Mode', kUseIsolate ? 'Enabled' : 'Disabled (Web)'),
              const SizedBox(height: 24),
              Text(
                'Recommended Actions:',
                style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.primary),
              ),
              const SizedBox(height: 8),
              const Text('• Reduce neuron counts in Network Config.'),
              const Text('• Switch to 1× simulation speed.'),
              if (!kUseIsolate) const Text('• Use a native mobile build for Isolate support.'),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Dismiss'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailItem(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(value, style: TextStyle(color: Theme.of(context).colorScheme.secondary)),
        ],
      ),
    );
  }
}
