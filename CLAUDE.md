# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 項目概述

這是一個 Flutter/Dart 包，用於自動追蹤 Riverpod 狀態變化並提供詳細的調用堆疊信息。包含兩個主要部分：
1. **核心包** (`lib/`) - 提供 `RiverpodDevToolsObserver` 來監聽 Provider 變化
2. **DevTools 擴展** (`extension/devtools/`) - 預構建的 DevTools 擴展，自動被 Flutter DevTools 發現

## 版本要求

- **Dart SDK**: `>=3.7.0 <4.0.0`
- **Flutter**: `>=3.27.0`
- **Riverpod**: `>=3.1.0 <4.0.0`
- **FVM**: 當前使用 Flutter `3.38.5`（配置在 [.fvmrc](.fvmrc)）

## 常用開發命令

### 主包開發
```bash
# 安裝依賴
flutter pub get

# 運行所有測試
flutter test

# 運行單個測試文件
flutter test test/riverpod_devtools_observer_test.dart

# 運行特定測試（使用 name 過濾）
flutter test --name "should capture stack trace"

# 分析代碼
flutter analyze

# 格式化代碼
dart format .

# 檢查發布準備狀況
dart pub publish --dry-run
```

### 本地測試
```bash
# 在 example app 中測試修改
cd example  # 如果有 example 目錄
flutter pub get
flutter run

# 使用 path 依賴在其他項目中測試
# 在測試項目的 pubspec.yaml 中：
# riverpod_devtools_tracker:
#   path: ../riverpod_devtools_tracker
```

### DevTools 擴展
DevTools 擴展已預先構建並包含在 `extension/devtools/` 目錄中。
該擴展會被 Flutter DevTools 自動發現，無需額外配置。

配置文件：`extension/devtools/config.yaml`

## 架構概覽

### 核心組件（lib/src/）

1. **RiverpodDevToolsObserver** ([riverpod_devtools_observer.dart](lib/src/riverpod_devtools_observer.dart))
   - 實作 Riverpod 的 `ProviderObserver` 介面
   - 監聽所有 Provider 生命週期事件：`didAddProvider`、`didUpdateProvider`、`didDisposeProvider`、`providerDidFail`
   - 使用 `developer.postEvent()` 將事件發送到 DevTools 擴展
   - 支援可選的美化 console 輸出

2. **StackTraceParser** ([stack_trace_parser.dart](lib/src/stack_trace_parser.dart))
   - 解析 Dart 堆疊追蹤，找出觸發狀態變化的確切代碼位置
   - 使用正則表達式：`#(\d+)\s+(.+?)\s+\((.+?):(\d+)(?::(\d+))?\)` 解析堆疊行
   - 過濾策略：
     - 排除 Flutter/Riverpod 框架代碼
     - 只保留 `packagePrefixes` 指定的用戶代碼
     - 排除生成的文件（`.g.dart`）和 provider 文件
   - `findTriggerLocation()` 找到第一個非 provider 文件的位置作為觸發點

3. **TrackerConfig** ([tracker_config.dart](lib/src/tracker_config.dart))
   - 配置類，控制追蹤行為
   - 使用 `TrackerConfig.forPackage('your_app')` 快速設定
   - 關鍵配置：
     - `packagePrefixes` - 指定要追蹤的包前綴
     - `ignoredPackagePrefixes` - 要忽略的框架代碼
     - `maxCallChainDepth` - 最大堆疊深度
     - `enableConsoleOutput` / `prettyConsoleOutput` - console 輸出控制

### DevTools 擴展結構（extension/devtools/）

DevTools 擴展已預先構建並包含在套件中：
- **config.yaml** - 擴展配置文件（名稱、版本、圖標等）
- **build/** - 構建後的 Web 資源
  - **index.html** - 擴展入口
  - **main.dart.js** - 編譯後的 Dart 代碼
  - **assets/** - 靜態資源文件

擴展功能：
- 實時監控 Riverpod 狀態變化
- 互動式 Provider 列表與過濾
- 詳細的調用鏈視覺化
- GitHub 風格暗色主題
- 多語言支援（英文、繁體中文）

### 數據流

```
Provider 變化 → RiverpodDevToolsObserver.didUpdateProvider()
              ↓
          捕獲 StackTrace.current
              ↓
          StackTraceParser 解析
              ↓
          生成事件數據（包含位置、值、調用鏈）
              ↓
          developer.postEvent('riverpod_state_change', data)
              ↓
          DevTools 擴展接收並顯示
```

## 關鍵設計決策

1. **堆疊追蹤解析**：使用同步的 `StackTrace.current` 而非異步捕獲，確保能準確捕捉到觸發點
2. **值序列化**：嘗試 JSON 序列化，失敗則使用 `toString()` + 類型信息
3. **位置過濾**：優先顯示用戶代碼位置，而非框架或 provider 定義位置
4. **雙重輸出**：同時支援 DevTools 擴展和 console 輸出，方便不同調試場景

## 生產環境最佳實踐

**重要**：在生產環境中應該禁用追蹤器以優化性能。使用 `kDebugMode` 條件：

```dart
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_devtools_tracker/riverpod_devtools_tracker.dart';

void main() {
  runApp(
    ProviderScope(
      observers: [
        // 只在 debug 模式下啟用追蹤
        if (kDebugMode)
          RiverpodDevToolsObserver(
            config: TrackerConfig.forPackage('your_app_name'),
          ),
      ],
      child: const MyApp(),
    ),
  );
}
```

### 性能優化建議

如果在開發過程中遇到性能問題：

1. **禁用 console 輸出**：`enableConsoleOutput: false`
2. **減少調用鏈深度**：`maxCallChainDepth: 5`（默認 10）
3. **增加過濾規則**：添加更多 `ignoredFilePatterns` 減少噪音
4. **限制追蹤範圍**：只追蹤特定包的代碼

```dart
RiverpodDevToolsObserver(
  config: TrackerConfig.forPackage(
    'your_app',
    enableConsoleOutput: false,      // 更好的性能
    maxCallChainDepth: 5,             // 更快的追蹤速度
    ignoredFilePatterns: ['.g.dart', '.freezed.dart'],
  ),
)
```

## 測試

測試文件位於 [test/](test/) 目錄：
- **riverpod_devtools_tracker_test.dart** - TrackerConfig 和 StackTraceParser 測試（11 個測試）
- **riverpod_devtools_observer_test.dart** - RiverpodDevToolsObserver 測試（18 個測試）

總計 29 個測試，覆蓋核心功能、記憶體管理、值序列化等。

運行測試：
```bash
# 運行所有測試
flutter test

# 運行特定測試文件並顯示詳細輸出
flutter test test/riverpod_devtools_observer_test.dart --reporter expanded
```

## 常見問題排查

### DevTools 擴展未顯示
1. 確認 `RiverpodDevToolsObserver` 已添加到 `ProviderScope` 的 observers 列表
2. 重啟應用
3. 檢查 DevTools 版本是否最新

### 沒有狀態變化顯示
1. 檢查 `packagePrefixes` 是否包含正確的包名（必須與 `pubspec.yaml` 中的 `name` 欄位一致）
2. 啟用 `enableConsoleOutput: true` 檢查是否有追蹤記錄
3. 確認 Provider 確實有變化

### 調用鏈無位置信息
1. 檢查包名是否匹配
2. `ignoredFilePatterns` 可能過於嚴格
3. 某些自動計算的 Provider 可能沒有特定觸發位置

詳細故障排除指南請參考 [README.md](README.md#troubleshooting)
