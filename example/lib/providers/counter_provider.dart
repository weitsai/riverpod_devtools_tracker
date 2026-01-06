import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'counter_provider.g.dart';

/// Simple counter Notifier - demonstrates basic state change tracking
@riverpod
class Counter extends _$Counter {
  @override
  int build() => 0;

  void increment() => state++;
  void decrement() => state--;
  void reset() => state = 0;
}

/// Counter double Provider - demonstrates dependency on other Providers
@riverpod
int counterDouble(ref) {
  final count = ref.watch(counterProvider);
  return count * 2;
}

/// Counter is even Provider
@riverpod
bool isEven(ref) {
  final count = ref.watch(counterProvider);
  return count % 2 == 0;
}
