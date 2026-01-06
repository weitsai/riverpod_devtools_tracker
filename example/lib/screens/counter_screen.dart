import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../l10n/app_localizations.dart';

import '../providers/counter_provider.dart';

class CounterScreen extends ConsumerWidget {
  const CounterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final count = ref.watch(counterProvider);
    final doubleCount = ref.watch(counterDoubleProvider);
    final isEven = ref.watch(isEvenProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.counterScreenTitle),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              l10n.currentCount,
              style: const TextStyle(fontSize: 20),
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
                    _buildInfoRow(l10n.doubleValue, '$doubleCount'),
                    const Divider(height: 24),
                    _buildInfoRow(l10n.isEven, isEven ? l10n.yes : l10n.no),
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
                  tooltip: l10n.decrease,
                  child: const Icon(Icons.remove),
                ),
                const SizedBox(width: 16),
                FloatingActionButton(
                  heroTag: 'increment',
                  onPressed: () => _incrementCounter(ref),
                  tooltip: l10n.increase,
                  child: const Icon(Icons.add),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _resetCounter(ref),
              child: Text(l10n.reset),
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

  // These method calls will be tracked by DevTools
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
