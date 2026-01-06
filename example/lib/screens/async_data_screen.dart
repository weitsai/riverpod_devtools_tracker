import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../l10n/app_localizations.dart';

import '../providers/async_data_provider.dart';

class AsyncDataScreen extends ConsumerWidget {
  const AsyncDataScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final asyncData = ref.watch(asyncDataProvider);
    final refreshableData = ref.watch(refreshableDataProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.asyncScreenTitle),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            l10n.futureProviderExample,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: asyncData.when(
                data:
                    (data) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.check_circle, color: Colors.green),
                            const SizedBox(width: 8),
                            Text(l10n.loadingSuccess),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(data),
                      ],
                    ),
                loading:
                    () => Row(
                      children: [
                        const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        const SizedBox(width: 12),
                        Text(l10n.loading),
                      ],
                    ),
                error:
                    (error, stack) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.error, color: Colors.red),
                            const SizedBox(width: 8),
                            Text(l10n.loadingFailed),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          error.toString(),
                          style: const TextStyle(color: Colors.red),
                        ),
                      ],
                    ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () => _reloadFutureProvider(ref),
            icon: const Icon(Icons.refresh),
            label: Text(l10n.reloadInvalidate),
          ),
          const SizedBox(height: 32),
          Text(
            l10n.stateNotifierAsyncExample,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: refreshableData.when(
                data:
                    (data) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.check_circle, color: Colors.green),
                            const SizedBox(width: 8),
                            Text(l10n.loadingSuccess),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(data),
                      ],
                    ),
                loading:
                    () => Row(
                      children: [
                        const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        const SizedBox(width: 12),
                        Text(l10n.loading),
                      ],
                    ),
                error:
                    (error, stack) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.error, color: Colors.red),
                            const SizedBox(width: 8),
                            Text(l10n.loadingFailed),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          error.toString(),
                          style: const TextStyle(color: Colors.red),
                        ),
                      ],
                    ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () => _refreshData(ref),
            icon: const Icon(Icons.refresh),
            label: Text(l10n.refreshData),
          ),
        ],
      ),
    );
  }

  // Trigger FutureProvider reload
  void _reloadFutureProvider(WidgetRef ref) {
    ref.invalidate(asyncDataProvider);
  }

  // Trigger StateNotifier refresh
  void _refreshData(WidgetRef ref) {
    ref.read(refreshableDataProvider.notifier).refresh();
  }
}
