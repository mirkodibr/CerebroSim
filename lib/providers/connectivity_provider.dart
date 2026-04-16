import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A provider that exposes the current connectivity status.
///
/// It listens to changes in the network state (Wi-Fi, Mobile, None)
/// and allows the UI to react accordingly, such as by showing offline banners.
final connectivityProvider = StreamProvider<List<ConnectivityResult>>((ref) {
  return Connectivity().onConnectivityChanged;
});
