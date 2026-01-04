import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/counter_provider.dart';

class CounterScreen extends ConsumerWidget {
  const CounterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(counterProvider);
    final doubleCount = ref.watch(counterDoubleProvider);
    final isEven = ref.watch(isEvenProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('計數器範例'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              '當前計數:',
              style: TextStyle(fontSize: 20),
            ),
            const SizedBox(height: 8),
            Text(
              '$count',
              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    color: isEven ? Colors.green : Colors.orange,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 32),
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 32),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildInfoRow('倍數值', '$doubleCount'),
                    const Divider(height: 24),
                    _buildInfoRow('是否為偶數', isEven ? '是' : '否'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 48),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FloatingActionButton(
                  heroTag: 'decrement',
                  onPressed: () => _decrementCounter(ref),
                  tooltip: '減少',
                  child: const Icon(Icons.remove),
                ),
                const SizedBox(width: 16),
                FloatingActionButton(
                  heroTag: 'increment',
                  onPressed: () => _incrementCounter(ref),
                  tooltip: '增加',
                  child: const Icon(Icons.add),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _resetCounter(ref),
              child: const Text('重置'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 16),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  // 這些方法的調用會被 DevTools 追蹤到
  void _incrementCounter(WidgetRef ref) {
    ref.read(counterProvider.notifier).increment();
  }

  void _decrementCounter(WidgetRef ref) {
    ref.read(counterProvider.notifier).decrement();
  }

  void _resetCounter(WidgetRef ref) {
    ref.read(counterProvider.notifier).reset();
  }
}
