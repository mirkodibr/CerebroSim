import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/network_config.dart';

/// A provider that holds the currently selected network configuration.
class NetworkConfigNotifier extends Notifier<NetworkConfig> {
  @override
  NetworkConfig build() {
    return NetworkConfig.defaultConfig();
  }

  /// Updates the network configuration.
  void update(NetworkConfig c) => state = c;
}

/// A global provider for the [NetworkConfigNotifier].
final networkConfigProvider = NotifierProvider<NetworkConfigNotifier, NetworkConfig>(() {
  return NetworkConfigNotifier();
});
