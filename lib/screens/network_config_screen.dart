import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/network_config.dart';
import '../providers/network_config_provider.dart';
import '../providers/simulation_provider.dart';

/// Screen allowing the user to configure the counts of each neuron type in the network.
class NetworkConfigScreen extends ConsumerWidget {
  const NetworkConfigScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(networkConfigProvider);
    final colorScheme = Theme.of(context).colorScheme;

    int totalNeurons = config.gcCount + config.bcCount + config.pcCount + config.scCount + config.dcnCount;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Network topology'),
        actions: [
          IconButton(
            icon: const Icon(Icons.restore),
            onPressed: () {
              ref.read(networkConfigProvider.notifier).update(NetworkConfig.defaultConfig());
            },
            tooltip: 'Reset to defaults',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              children: [
                _buildCounter(
                  context,
                  ref,
                  config,
                  title: 'GC (Granule cells)',
                  subtitle: 'Receives and relays sensory signals',
                  count: config.gcCount,
                  min: 2,
                  max: 50,
                  onUpdate: (val) => ref.read(networkConfigProvider.notifier).update(config.copyWith(gcCount: val)),
                ),
                _buildCounter(
                  context,
                  ref,
                  config,
                  title: 'BC (Basket cells)',
                  subtitle: 'Suppresses neighbouring Purkinje cells to sharpen signals',
                  count: config.bcCount,
                  min: 1,
                  max: 20,
                  onUpdate: (val) => ref.read(networkConfigProvider.notifier).update(config.copyWith(bcCount: val)),
                ),
                _buildCounter(
                  context,
                  ref,
                  config,
                  title: 'PC (Purkinje cells)',
                  subtitle: 'Controls the degree of movement correction',
                  count: config.pcCount,
                  min: 1,
                  max: 10,
                  onUpdate: (val) => ref.read(networkConfigProvider.notifier).update(config.copyWith(pcCount: val)),
                ),
                _buildCounter(
                  context,
                  ref,
                  config,
                  title: 'SC (Stellate cells)',
                  subtitle: 'Provides feedforward inhibition to Purkinje cells',
                  count: config.scCount,
                  min: 0,
                  max: 10,
                  onUpdate: (val) => ref.read(networkConfigProvider.notifier).update(config.copyWith(scCount: val)),
                ),
                ListTile(
                  title: const Text('DCN (Output nuclei)'),
                  subtitle: const Text('Fixed — required for task environments'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const IconButton(icon: Icon(Icons.remove), onPressed: null),
                      SizedBox(
                        width: 40,
                        child: Text(
                          '${config.dcnCount}',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.54)),
                        ),
                      ),
                      const IconButton(icon: Icon(Icons.add), onPressed: null),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(24.0),
            color: colorScheme.surface,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Total neurons: $totalNeurons',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: totalNeurons > 30 ? colorScheme.error : colorScheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (totalNeurons > 30)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      'Large networks may affect performance at 10x speed.',
                      style: TextStyle(color: colorScheme.error, fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () {
                    ref.read(simulationProvider.notifier).resetEpisode(config: ref.read(networkConfigProvider));
                    context.go('/shell/simulate');
                  },
                  child: const Text('Apply & reset simulation'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCounter(
    BuildContext context, 
    WidgetRef ref, 
    NetworkConfig config, {
    required String title, 
    required String subtitle, 
    required int count, 
    required int min, 
    required int max, 
    required Function(int) onUpdate
  }) {
    return ListTile(
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.remove),
            onPressed: count > min ? () => onUpdate(count - 1) : null,
          ),
          SizedBox(
            width: 40,
            child: Text(
              '$count',
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: count < max ? () => onUpdate(count + 1) : null,
          ),
        ],
      ),
    );
  }
}
