import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'counter_provider.g.dart';

/// 簡單的計數器 Notifier - 展示基本的狀態變化追蹤
@riverpod
class Counter extends _$Counter {
  @override
  int build() => 0;

  void increment() => state++;
  void decrement() => state--;
  void reset() => state = 0;
}

/// 計數器倍數 Provider - 展示依賴其他 Provider 的情況
@riverpod
int counterDouble(ref) {
  final count = ref.watch(counterProvider);
  return count * 2;
}

/// 計數器是否為偶數 Provider
@riverpod
bool isEven(ref) {
  final count = ref.watch(counterProvider);
  return count % 2 == 0;
}
