# Riverpod DevTools Tracker 範例應用程式

這是一個完整的範例應用程式，展示如何使用 `riverpod_devtools_tracker` 來追蹤和除錯 Riverpod 狀態變化。

## 功能展示

### 1. 計數器範例 (Counter)
- 展示基本的狀態變化追蹤
- 包含計數器本身及其衍生狀態（倍數、是否為偶數）
- 演示：增加、減少、重置操作

### 2. 使用者資料範例 (User)
- 展示複雜物件的狀態變化
- 追蹤登入狀態和個人資料更新
- 演示：登入、登出、更新姓名、增加年齡

### 3. 非同步資料範例 (Async Data)
- 展示 AsyncValue 的狀態追蹤
- 包含 FutureProvider 和 StateNotifier + AsyncValue 兩種模式
- 演示：載入、成功、錯誤三種狀態的追蹤

### 4. 待辦事項範例 (Todo)
- 展示列表的增刪改操作追蹤
- 完整的 CRUD 操作示範
- 演示：新增、切換完成狀態、刪除、清除已完成項目

## 如何運行

### 前置需求

確保已安裝：
- Flutter SDK (>= 3.27.0)
- Dart SDK (>= 3.7.0)

### 步驟

1. **安裝依賴**

   ```bash
   cd example
   flutter pub get
   ```

2. **生成 Riverpod 代碼**

   此範例使用 `riverpod_generator` 4.0.0+1，需要先生成 provider 代碼：

   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```

   如果您修改了 provider 檔案，需要重新運行這個命令。

3. **運行應用程式**

   ```bash
   flutter run
   ```

4. **開啟 DevTools 擴展**

   - 應用程式運行後，在終端中會看到 DevTools 的 URL
   - 打開瀏覽器訪問該 URL
   - 在 DevTools 中找到 "Riverpod Tracker" 擴展標籤
   - 現在您可以看到所有 Provider 的狀態變化追蹤！

## 使用方式

### 在 main.dart 中整合

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_devtools_tracker/riverpod_devtools_tracker.dart';

void main() {
  runApp(
    ProviderScope(
      observers: [
        // 整合 RiverpodDevToolsObserver
        RiverpodDevToolsObserver(
          config: TrackerConfig.forPackage('example'),
        ),
      ],
      child: const MyApp(),
    ),
  );
}
```

### 關鍵配置

`TrackerConfig.forPackage('example')` 會：
- 自動設定追蹤 `package:example` 開頭的代碼
- 過濾掉 Flutter 和 Riverpod 框架代碼
- 提供美化的 console 輸出（可選）

### DevTools 擴展功能

在 DevTools 擴展中，您可以：
1. **查看所有 Provider 狀態變化** - 即時列表顯示
2. **查看詳細資訊** - 點擊任何變化查看：
   - 觸發變化的確切代碼位置（檔案名、行號）
   - 變化前後的值
   - 完整的調用堆疊
   - 時間戳記
3. **過濾和搜尋** - 快速找到特定 Provider 的變化
4. **調用鏈追蹤** - 了解狀態變化的完整來源

## 範例結構

```
example/
├── lib/
│   ├── main.dart                    # 應用程式入口，整合 Observer
│   ├── providers/
│   │   ├── counter_provider.dart    # 計數器相關 Providers
│   │   ├── user_provider.dart       # 使用者資料 Providers
│   │   ├── async_data_provider.dart # 非同步資料 Providers
│   │   └── todo_provider.dart       # 待辦事項 Providers
│   └── screens/
│       ├── home_screen.dart         # 主畫面
│       ├── counter_screen.dart      # 計數器範例頁面
│       ├── user_screen.dart         # 使用者資料範例頁面
│       ├── async_data_screen.dart   # 非同步資料範例頁面
│       └── todo_screen.dart         # 待辦事項範例頁面
└── pubspec.yaml
```

## 學習要點

此範例使用 **riverpod_generator 4.0.0+1** 來生成 providers，這是 Riverpod 推薦的現代化做法。

### 1. 使用 @riverpod 註解定義 Notifier
查看 `counter_provider.dart` 中使用 riverpod_generator：
```dart
@riverpod
class Counter extends _$Counter {
  @override
  int build() => 0;

  void increment() => state++;
  void decrement() => state--;
  void reset() => state = 0;
}
```

在 UI 中調用：
```dart
void _incrementCounter(WidgetRef ref) {
  ref.read(counterProvider.notifier).increment();
}
```
在 DevTools 中會顯示 `increment()` 方法的位置為觸發點。

### 2. 複雜物件的 Notifier
查看 `user_provider.dart` 中的用戶數據管理：
```dart
@riverpod
class UserData extends _$UserData {
  @override
  User? build() => null;

  void login(User user) => state = user;
  void logout() => state = null;

  void updateName(String name) {
    if (state != null) {
      state = state!.copyWith(name: name);
    }
  }

  void incrementAge() {
    if (state != null) {
      state = state!.copyWith(age: state!.age + 1);
    }
  }
}
```

### 3. Functional Providers (衍生狀態)
使用 `@riverpod` 創建計算 provider：
```dart
@riverpod
int counterDouble(ref) {
  final count = ref.watch(counterProvider);
  return count * 2;
}

@riverpod
bool isEven(ref) {
  final count = ref.watch(counterProvider);
  return count % 2 == 0;
}
```

### 4. AsyncNotifier 處理非同步狀態
查看 `async_data_provider.dart` 中的 AsyncNotifier：
```dart
@riverpod
class RefreshableData extends _$RefreshableData {
  @override
  Future<String> build() async {
    return _fetchData();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchData());
  }

  Future<String> _fetchData() async {
    // ... 非同步操作
  }
}
```

### 5. 列表操作的 Notifier
查看 `todo_provider.dart` 中的不可變更新：
```dart
@riverpod
class TodoList extends _$TodoList {
  @override
  List<Todo> build() => [];

  void addTodo(String title) {
    state = [...state, newTodo];
  }

  void toggleTodo(String id) {
    state = [
      for (final todo in state)
        if (todo.id == id)
          todo.copyWith(completed: !todo.completed)
        else
          todo,
    ];
  }
}
```

### 6. 代碼生成的優勢
使用 riverpod_generator 的好處：
- ✅ **自動生成樣板代碼** - 不需要手動定義 provider
- ✅ **型別安全** - 編譯時檢查，減少錯誤
- ✅ **更好的代碼組織** - Provider 和業務邏輯集中管理
- ✅ **自動生成 .g.dart 文件** - build_runner 處理所有生成邏輯
- ✅ **更簡潔的語法** - 相比手動 Provider 定義更直觀

## 除錯技巧

1. **找出意外的狀態變化**
   - 在 DevTools 中查看時間軸
   - 檢查觸發位置是否符合預期

2. **追蹤依賴鏈**
   - 查看調用堆疊
   - 了解狀態變化如何傳播

3. **性能優化**
   - 識別過於頻繁的狀態更新
   - 檢查是否有不必要的重建

## 相關資源

- [Riverpod 官方文件](https://riverpod.dev)
- [Flutter DevTools 文件](https://docs.flutter.dev/tools/devtools)
- [riverpod_devtools_tracker GitHub](https://github.com/weitsai/riverpod_devtools_tracker)

## 常見問題

### Q: 為什麼在 DevTools 中看不到擴展？
A: 確保：
1. 已運行 `flutter pub get` 安裝依賴
2. 應用程式正在運行
3. 已構建並複製 DevTools 擴展（參考主專案 README）

### Q: 如何只追蹤特定的 Providers？
A: 在 `TrackerConfig` 中自定義配置：
```dart
TrackerConfig(
  packagePrefixes: ['package:example/'],
  ignoredFilePatterns: ['.g.dart', 'generated.dart'],  // 忽略生成的檔案
)
```

### Q: Console 輸出太多怎麼辦？
A: 可以關閉 console 輸出：
```dart
RiverpodDevToolsObserver(
  config: TrackerConfig.forPackage('example').copyWith(
    enableConsoleOutput: false,
  ),
)
```
