import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'async_data_provider.g.dart';

/// Simulates async data fetching - demonstrates FutureProvider state changes
@riverpod
Future<String> asyncData(ref) async {
  // Simulate network request delay
  await Future.delayed(const Duration(seconds: 2));

  // Randomly decide success or failure
  if (DateTime.now().second % 3 == 0) {
    throw Exception('Simulated network error');
  }

  return 'Data loaded successfully! Time: ${DateTime.now().toString().substring(11, 19)}';
}

/// Refreshable async data Notifier
@riverpod
class RefreshableData extends _$RefreshableData {
  @override
  Future<String> build() async {
    return _fetchData();
  }

  Future<String> _fetchData() async {
    await Future.delayed(const Duration(seconds: 1));

    if (DateTime.now().second % 4 == 0) {
      throw Exception('Loading failed');
    }

    return 'Refresh successful! Time: ${DateTime.now().toString().substring(11, 19)}';
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchData());
  }
}
