import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/vault_provider.dart';
import '../providers/simulation_provider.dart';
import '../widgets/snapshot_card.dart';
import '../models/experiment_snapshot.dart';

/// A repository for managing and exploring saved simulation states.
/// 
/// The [VaultScreen] provides a dual-tab interface:
/// 1. **My Experiments**: Displays snapshots saved locally by the current user.
/// 2. **Gallery**: Displays snapshots shared publicly by the CerebroSim community.
/// 
/// Users can browse these collections and load the synaptic weights from any 
/// snapshot back into the active simulation.
class VaultScreen extends ConsumerStatefulWidget {
  final Function(int)? onTabChange;
  final String? highlightedId;
  const VaultScreen({super.key, this.onTabChange, this.highlightedId});

  @override
  ConsumerState<VaultScreen> createState() => _VaultScreenState();
}

class _VaultScreenState extends ConsumerState<VaultScreen> with SingleTickerProviderStateMixin {
  String _filterTask = 'all';
  String _sortBy = 'date';
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Listen for data to auto-switch tabs if highlightedId is provided
    if (widget.highlightedId != null) {
      ref.listen(vaultProvider, (prev, next) {
        if (next.hasValue && next.value!.any((s) => s.id == widget.highlightedId)) {
          _tabController.animateTo(0);
        }
      });
      ref.listen(publicGalleryProvider, (prev, next) {
        if (next.hasValue && next.value!.any((s) => s.id == widget.highlightedId)) {
          _tabController.animateTo(1);
        }
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Research Vault'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'My Experiments'),
            Tab(text: 'Gallery'),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            tooltip: 'Sort by',
            onSelected: (value) => setState(() => _sortBy = value),
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'date', child: Text('Newest first')),
              const PopupMenuItem(value: 'performance', child: Text('Best performance')),
            ],
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildUserSnapshots(context, ref),
          _buildPublicGallery(context, ref),
        ],
      ),
    );
  }

  List<ExperimentSnapshot> _applyFilterAndSort(List<ExperimentSnapshot> snapshots) {
    var filtered = List<ExperimentSnapshot>.from(snapshots);
    if (_filterTask != 'all') {
      filtered = filtered.where((s) => s.taskName.toLowerCase() == _filterTask.toLowerCase()).toList();
    }

    if (_sortBy == 'date') {
      filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } else if (_sortBy == 'performance') {
      filtered.sort((a, b) => a.finalErrorRate.compareTo(b.finalErrorRate));
    }
    return filtered;
  }

  Widget _buildFilterChips(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _filterChip('All', 'all'),
          const SizedBox(width: 8),
          _filterChip('Eyeblink', 'eyeblink'),
          const SizedBox(width: 8),
          _filterChip('Sine', 'sineWave'),
          const SizedBox(width: 8),
          _filterChip('VOR', 'vor'),
        ],
      ),
    );
  }

  Widget _filterChip(String label, String value) {
    final isSelected = _filterTask == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() => _filterTask = value);
      },
      visualDensity: VisualDensity.compact,
    );
  }

  /// Builds the list of snapshots owned by the authenticated user.
  Widget _buildUserSnapshots(BuildContext context, WidgetRef ref) {
    final snapshots = ref.watch(vaultProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return snapshots.when(
      data: (list) {
        final processed = _applyFilterAndSort(list);
        return Column(
          children: [
            _buildFilterChips(context),
            Expanded(
              child: processed.isEmpty
                  ? Center(child: Text('No matching experiments.', style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.54))))
                  : ListView.builder(
                      itemCount: processed.length,
                      itemBuilder: (context, index) {
                        final snap = processed[index];
                        return SnapshotCard(
                          snapshot: snap,
                          onTap: () => _loadSnapshot(context, ref, snap),
                        );
                      },
                    ),
            ),
          ],
        );
      },
      loading: () => _buildShimmerList(context),
      error: (e, s) => Center(child: Text('Error: $e', style: TextStyle(color: colorScheme.error))),
    );
  }

  /// Builds the list of snapshots shared publicly by all users.
  Widget _buildPublicGallery(BuildContext context, WidgetRef ref) {
    final snapshots = ref.watch(publicGalleryProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return snapshots.when(
      data: (list) {
        final processed = _applyFilterAndSort(list);
        return Column(
          children: [
            _buildFilterChips(context),
            Expanded(
              child: processed.isEmpty
                  ? Center(child: Text('Gallery is empty.', style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.54))))
                  : ListView.builder(
                      itemCount: processed.length,
                      itemBuilder: (context, index) {
                        final snap = processed[index];
                        return SnapshotCard(
                          snapshot: snap,
                          onTap: () => _loadSnapshot(context, ref, snap),
                        );
                      },
                    ),
            ),
          ],
        );
      },
      loading: () => _buildShimmerList(context),
      error: (e, s) => Center(child: Text('Error: $e', style: TextStyle(color: colorScheme.error))),
    );
  }

  /// Renders a placeholder list while snapshot data is being fetched.
  Widget _buildShimmerList(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ListView.builder(
      itemCount: 5,
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Container(
          height: 100,
          decoration: BoxDecoration(
            color: colorScheme.onSurface.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ),
      ),
    );
  }

  /// Injects the synaptic weights from a [snapshot] into the active simulation.
  void _loadSnapshot(BuildContext context, WidgetRef ref, ExperimentSnapshot snapshot) {
    ref.read(simulationProvider.notifier).loadSnapshot(snapshot);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Loaded weights from "${snapshot.title}"')),
    );
    
    if (widget.onTabChange != null) {
      widget.onTabChange!(0);
    } else {
      context.go('/shell/simulate');
    }
  }
}
