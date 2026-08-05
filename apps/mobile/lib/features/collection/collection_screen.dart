import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../scan/keepsake_model.dart';
import '../scan/keepsake_service.dart';

final _keepsakeServiceProvider = Provider<KeepsakeService>(
  (ref) => KeepsakeService(),
);

final _keepsakeListProvider = FutureProvider<List<Keepsake>>((ref) {
  return ref.watch(_keepsakeServiceProvider).list();
});

class CollectionScreen extends ConsumerWidget {
  const CollectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final keepsakes = ref.watch(_keepsakeListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Collection'),
        actions: [
          IconButton(
            icon: const Icon(Icons.camera_alt_outlined),
            tooltip: 'Scan',
            onPressed: () => context.go('/scan'),
          ),
        ],
      ),
      body: keepsakes.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 48),
                const SizedBox(height: 12),
                const Text('Could not load collection', textAlign: TextAlign.center),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () => ref.invalidate(_keepsakeListProvider),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (list) => list.isEmpty
            ? _EmptyState(onScan: () => context.go('/scan'))
            : _Grid(keepsakes: list),
      ),
    );
  }
}

class _Grid extends StatelessWidget {
  const _Grid({required this.keepsakes});

  final List<Keepsake> keepsakes;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.78,
      ),
      itemCount: keepsakes.length,
      itemBuilder: (context, index) => _KeepsakeCard(keepsake: keepsakes[index]),
    );
  }
}

class _KeepsakeCard extends StatelessWidget {
  const _KeepsakeCard({required this.keepsake});

  final Keepsake keepsake;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Image.network(
              keepsake.cutoutUrl,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stack) => const Center(
                child: Icon(Icons.pets, size: 48),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 6, 10, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  keepsake.name,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  keepsake.serialNumber,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                        letterSpacing: 1,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onScan});

  final VoidCallback onScan;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.pets, size: 64),
            const SizedBox(height: 16),
            Text(
              'No cats caught yet',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Go spot a cat and catch it!',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onScan,
              icon: const Icon(Icons.camera_alt_outlined),
              label: const Text('Scan for a Cat'),
            ),
          ],
        ),
      ),
    );
  }
}
