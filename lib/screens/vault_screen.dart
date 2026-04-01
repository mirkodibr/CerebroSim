import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/vault_provider.dart';
import '../providers/simulation_provider.dart';
import '../widgets/snapshot_card.dart';
import '../models/experiment_snapshot.dart';

class VaultScreen extends ConsumerWidget {
  final Function(int) onTabChange;
  const VaultScreen({super.key, required this.onTabChange});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Research Vault'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'My Experiments'),
              Tab(text: 'Gallery'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildUserSnapshots(context, ref),
            _buildPublicGallery(context, ref),
          ],
        ),
      ),
    );
  }

  Widget _buildUserSnapshots(BuildContext context, WidgetRef ref) {
    final snapshots = ref.watch(vaultProvider);

    return snapshots.when(
      data: (list) => list.isEmpty
          ? const Center(child: Text('No experiments saved yet.', style: TextStyle(color: Colors.white54)))
          : ListView.builder(
              itemCount: list.length,
              itemBuilder: (context, index) => SnapshotCard(
                snapshot: list[index],
                onTap: () => _loadSnapshot(context, ref, list[index]),
              ),
            ),
      loading: () => _buildShimmerList(),
      error: (e, s) => Center(child: Text('Error: $e', style: const TextStyle(color: Colors.red))),
    );
  }

  Widget _buildPublicGallery(BuildContext context, WidgetRef ref) {
    final snapshots = ref.watch(publicGalleryProvider);

    return snapshots.when(
      data: (list) => list.isEmpty
          ? const Center(child: Text('Gallery is empty.', style: TextStyle(color: Colors.white54)))
          : ListView.builder(
              itemCount: list.length,
              itemBuilder: (context, index) => SnapshotCard(
                snapshot: list[index],
                onTap: () => _loadSnapshot(context, ref, list[index]),
              ),
            ),
      loading: () => _buildShimmerList(),
      error: (e, s) => Center(child: Text('Error: $e', style: const TextStyle(color: Colors.red))),
    );
  }

  Widget _buildShimmerList() {
    return ListView.builder(
      itemCount: 5,
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Container(
          height: 100,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ),
      ),
    );
  }

  void _loadSnapshot(BuildContext context, WidgetRef ref, ExperimentSnapshot snapshot) {
    ref.read(simulationProvider.notifier).loadSnapshot(snapshot.synapticWeights);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Loaded weights from "${snapshot.title}"')),
    );
    onTabChange(0); // Switch to Simulate tab
  }
}
