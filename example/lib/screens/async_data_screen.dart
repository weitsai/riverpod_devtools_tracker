import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/async_data_provider.dart';

class AsyncDataScreen extends ConsumerWidget {
  const AsyncDataScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncData = ref.watch(asyncDataProvider);
    final refreshableData = ref.watch(refreshableDataProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('非同步資料範例'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'FutureProvider 範例',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: asyncData.when(
                data: (data) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green),
                        SizedBox(width: 8),
                        Text('載入成功'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(data),
                  ],
                ),
                loading: () => const Row(
                  children: [
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 12),
                    Text('載入中...'),
                  ],
                ),
                error: (error, stack) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.error, color: Colors.red),
                        SizedBox(width: 8),
                        Text('載入失敗'),
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
            label: const Text('重新載入 (invalidate)'),
          ),
          const SizedBox(height: 32),
          const Text(
            'StateNotifier + AsyncValue 範例',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: refreshableData.when(
                data: (data) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green),
                        SizedBox(width: 8),
                        Text('載入成功'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(data),
                  ],
                ),
                loading: () => const Row(
                  children: [
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 12),
                    Text('載入中...'),
                  ],
                ),
                error: (error, stack) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.error, color: Colors.red),
                        SizedBox(width: 8),
                        Text('載入失敗'),
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
            label: const Text('刷新資料'),
          ),
        ],
      ),
    );
  }

  // 觸發 FutureProvider 重新載入
  void _reloadFutureProvider(WidgetRef ref) {
    ref.invalidate(asyncDataProvider);
  }

  // 觸發 StateNotifier 刷新
  void _refreshData(WidgetRef ref) {
    ref.read(refreshableDataProvider.notifier).refresh();
  }
}
