import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'async_data_provider.g.dart';

/// 模擬非同步資料獲取 - 展示 FutureProvider 的狀態變化
@riverpod
Future<String> asyncData(ref) async {
  // 模擬網路請求延遲
  await Future.delayed(const Duration(seconds: 2));

  // 隨機決定成功或失敗
  if (DateTime.now().second % 3 == 0) {
    throw Exception('模擬網路錯誤');
  }

  return '資料載入成功！時間: ${DateTime.now().toString().substring(11, 19)}';
}

/// 可刷新的非同步資料 Notifier
@riverpod
class RefreshableData extends _$RefreshableData {
  @override
  Future<String> build() async {
    return _fetchData();
  }

  Future<String> _fetchData() async {
    await Future.delayed(const Duration(seconds: 1));

    if (DateTime.now().second % 4 == 0) {
      throw Exception('載入失敗');
    }

    return '刷新成功！時間: ${DateTime.now().toString().substring(11, 19)}';
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchData());
  }
}
