# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 項目概述

這是一個 Flutter/Dart 包，用於自動追蹤 Riverpod 狀態變化並提供詳細的調用堆疊信息。包含兩個主要部分：
1. **核心包** (`lib/`) - 提供 `RiverpodDevToolsObserver` 來監聽 Provider 變化
2. **DevTools 擴展** (`devtools_extension/`) - 提供視覺化介面來檢視狀態變化

## 常用開發命令

### 主包開發
```bash
# 安裝依賴
flutter pub get

# 運行測試
flutter test

# 分析代碼
flutter analyze
```

### DevTools 擴展開發
```bash
# 構建並複製 DevTools 擴展（推薦使用腳本）
./scripts/build_extension.sh

# 或手動構建
cd devtools_extension
flutter pub get
dart run devtools_extensions build_and_copy --source=. --dest=../extension/devtools

# 驗證擴展
dart run devtools_extensions validate --package=..
```

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

### DevTools 擴展架構（devtools_extension/）

- **main.dart** - 入口點，使用 `DevToolsExtension` widget
- **src/riverpod_devtools_extension.dart** - 主要擴展 UI 組件
- **src/models/provider_state_info.dart** - 狀態變化的數據模型
- **src/widgets/** - UI 組件（Provider 列表、詳情面板）
- **src/theme/extension_theme.dart** - GitHub 風格暗色主題

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

## 測試

測試文件位於 [test/](test/) 目錄。當前包含基本的包導入測試。

## FVM 配置

項目使用 FVM 管理 Flutter 版本，配置在 [.fvmrc](.fvmrc)。
