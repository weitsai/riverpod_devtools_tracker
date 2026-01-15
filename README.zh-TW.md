# Riverpod DevTools Tracker

[![pub package](https://img.shields.io/pub/v/riverpod_devtools_tracker.svg)](https://pub.dev/packages/riverpod_devtools_tracker)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
![Flutter](https://img.shields.io/badge/Flutter-3.27+-blue)
![Riverpod](https://img.shields.io/badge/Riverpod-3.1+-purple)
[![style: flutter lints](https://img.shields.io/badge/style-flutter__lints-blue)](https://pub.dev/packages/flutter_lints)

![Code Location Tracking](doc/images/code-location-tracking.png)

一個強大的 Flutter 套件，能自動追蹤 Riverpod 狀態變化並提供詳細的調用堆疊資訊，幫助你精確定位狀態變化的程式碼來源，讓除錯更輕鬆。

繁體中文 | **[English](README.md)**

## 目錄

- [功能特色](#功能特色)
- [安裝](#安裝)
- [快速開始](#快速開始)
- [如何使用 DevTools 擴展](#如何使用-devtools-擴展)
- [設定](#設定)
- [控制台輸出](#控制台輸出)
- [DevTools 擴展功能](#devtools-擴展功能)
- [疑難排解](#疑難排解)
- [系統需求](#系統需求)

## 功能特色

- 🔍 **自動狀態追蹤** - 無需手動編寫追蹤程式碼
- 📍 **程式碼位置偵測** - 精確顯示狀態變化的程式碼來源
- 📜 **調用鏈視覺化** - 查看完整的調用堆疊
- 🎨 **美觀的 DevTools 擴展** - GitHub 風格的暗色主題介面
- 💾 **事件持久化** - 可選擇將事件儲存到本地，支援跨 session 除錯
- ⚡ **零配置** - 只需加入 observer 即可使用
- 🔧 **高度可配置** - 自訂追蹤內容和方式

## 安裝

### 步驟 1：加入套件

在 `pubspec.yaml` 中加入 `riverpod_devtools_tracker`：

```yaml
dependencies:
  flutter_riverpod: ^3.1.0  # 必要依賴
  riverpod_devtools_tracker: ^1.0.2
```

### 步驟 2：安裝依賴

在終端機中執行以下命令：

```bash
flutter pub get
```

這個套件包含兩個元件：
- **核心追蹤功能**：`RiverpodDevToolsObserver` 用於監聽和記錄狀態變化
- **DevTools 擴展**：視覺化介面，會自動被 Flutter DevTools 發現和載入

> **注意**：DevTools 擴展會自動包含在套件的 `extension/devtools/` 目錄中，不需要額外安裝或配置。

## 快速開始

### 步驟 1：引入套件

在你的 `main.dart` 檔案中引入套件：

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_devtools_tracker/riverpod_devtools_tracker.dart';
```

### 步驟 2：加入 Observer

將 `RiverpodDevToolsObserver` 加入到 `ProviderScope` 的 observers 列表中：

```dart
void main() {
  runApp(
    ProviderScope(
      observers: [
        RiverpodDevToolsObserver(
          config: TrackerConfig.forPackage('your_app_name'),  // 替換成你的套件名稱
        ),
      ],
      child: const MyApp(),
    ),
  );
}
```

> **重要**：將 `'your_app_name'` 替換成你在 `pubspec.yaml` 中的實際套件名稱（`name:` 欄位的值）

### 步驟 3：執行應用

```bash
flutter run
```

完成！現在當你執行應用並開啟 DevTools 時，就會看到 "Riverpod State Inspector" 標籤頁。

## 如何使用 DevTools 擴展

### 步驟 1：開啟 DevTools

執行應用後，有幾種方式可以開啟 Flutter DevTools：

**方法 A - 從 VS Code**
1. 執行你的應用（按 F5 或點擊 Run）
2. 點擊除錯工具列中的 **"Dart DevTools"** 按鈕
3. DevTools 會自動在瀏覽器中開啟

**方法 B - 從 Android Studio / IntelliJ**
1. 執行你的應用
2. 在 Run 面板中點擊 **"Open DevTools"**
3. DevTools 會自動在瀏覽器中開啟

**方法 C - 從命令列**
1. 執行你的應用：`flutter run`
2. 終端機會顯示 DevTools 網址：
   ```
   The Flutter DevTools debugger and profiler is available at:
   http://127.0.0.1:9100?uri=...
   ```
3. 點擊或複製該網址到瀏覽器中開啟

### 步驟 2：找到 Riverpod State Inspector 標籤頁

DevTools 開啟後：
1. 在頂部選單列中尋找 **"Riverpod State Inspector"** 標籤
2. 點擊該標籤開啟擴展介面

![DevTools 擴展設定](doc/images/devtools-setup.png)

> **提示**：如果沒有看到這個標籤，請確認：
> - 套件已正確安裝且執行過 `flutter pub get`
> - `RiverpodDevToolsObserver` 已加入到 `ProviderScope`
> - 應用已重新啟動

### 步驟 3：了解介面佈局

DevTools 擴展採用雙欄式佈局：

**左側面板 - Provider 列表（400px 寬）**
- 按時間順序顯示所有狀態變化
- 每個項目顯示：
  - Provider 名稱和類型
  - 時間戳記
  - 變化類型（add/update/dispose/error）
  - 觸發變化的程式碼位置
- 點擊任何項目即可查看詳細資訊

**右側面板 - 狀態詳情**
- 顯示所選狀態變化的詳細資訊：
  - 變化前後的值對照
  - 完整的調用鏈與檔案位置
  - 調用堆疊中的函數名稱
  - 可點擊的檔案路徑（導航到程式碼）

![觀察 Provider 觸發位置](doc/images/code-location-tracking.png)

### 步驟 4：追蹤和除錯狀態變化

當你與應用互動時：

1. **即時監控**：觀察左側面板即時更新顯示 provider 變化
2. **定位問題**：點擊任何變化記錄，查看觸發它的確切程式碼位置
3. **追蹤執行流程**：使用調用鏈了解程式執行路徑
4. **比對數值**：比較變化前後的值來除錯狀態問題

### 使用範例

假設你有一個 counter provider：

```dart
final counterProvider = StateProvider<int>((ref) => 0);

// 在你的 widget 中
ElevatedButton(
  onPressed: () => ref.read(counterProvider.notifier).state++,
  child: const Text('Increment'),
)
```

當你點擊按鈕時：
1. DevTools 擴展會立即顯示新項目：`UPDATE: counterProvider`
2. 位置會顯示按鈕被按下的確切位置（例如：`widgets/counter_button.dart:42`）
3. 點擊該項目可以看到數值從 `0` 變為 `1`
4. 調用鏈會顯示從按鈕點擊到狀態更新的完整路徑

## 設定

### 基本設定

```dart
RiverpodDevToolsObserver(
  config: TrackerConfig.forPackage(
    'your_app_name',
    enableConsoleOutput: true,      // 輸出到控制台
    prettyConsoleOutput: true,      // 使用美化格式輸出
    maxCallChainDepth: 10,          // 最大堆疊追蹤深度
    maxValueLength: 200,            // 最大值字串長度
  ),
)
```

### 事件持久化設定

啟用事件持久化，讓狀態變化歷史在 DevTools 重新連接後仍然可用：

```dart
RiverpodDevToolsObserver(
  config: TrackerConfig.forPackage(
    'your_app_name',
    enablePersistence: true,        // 啟用事件持久化
    clearOnStart: true,             // 應用啟動時清除舊事件（預設：true）
    maxPersistedEvents: 1000,       // 從儲存載入的最大事件數
  ),
)
```

| 選項 | 類型 | 預設值 | 說明 |
|------|------|--------|------|
| `enablePersistence` | `bool` | `false` | 啟用事件持久化儲存 |
| `clearOnStart` | `bool` | `true` | 應用啟動時清除已儲存的事件 |
| `maxPersistedEvents` | `int` | `1000` | 從儲存載入的最大事件數量 |

**使用情境：**
- `clearOnStart: true`（預設）- 只顯示當前 session 的事件，除錯更乾淨
- `clearOnStart: false` - 保留跨應用重啟的事件，用於歷史分析

### 進階設定

```dart
RiverpodDevToolsObserver(
  config: TrackerConfig(
    enabled: true,
    packagePrefixes: [
      'package:your_app/',
      'package:your_common_lib/',
    ],
    enableConsoleOutput: true,
    prettyConsoleOutput: true,
    maxCallChainDepth: 10,
    maxValueLength: 200,
    ignoredPackagePrefixes: [
      'package:flutter/',
      'package:flutter_riverpod/',
      'package:riverpod/',
      'dart:',
    ],
    ignoredFilePatterns: [
      'generated.dart',
      '.g.dart',
    ],
    // 記憶體管理設定
    enablePeriodicCleanup: true,                        // 啟用自動清理
    cleanupInterval: const Duration(seconds: 30),       // 清理頻率
    stackExpirationDuration: const Duration(seconds: 60), // 保留堆疊的時間
    maxStackCacheSize: 100,                             // 最大快取堆疊數
  ),
)
```

### 記憶體管理

追蹤器會自動管理記憶體，防止長時間除錯時發生記憶體洩漏：

- **定期清理**：自動從記憶體中移除過期的堆疊追蹤
- **可設定保留期限**：控制堆疊追蹤保留多久
- **大小限制**：快取堆疊追蹤數量的硬性上限

預設設定適用於大多數應用，但你可以自訂：

```dart
TrackerConfig.forPackage(
  'your_app',
  enablePeriodicCleanup: true,            // 啟用/停用自動清理
  cleanupInterval: Duration(seconds: 30),  // 多久執行一次清理
  stackExpirationDuration: Duration(minutes: 2), // 堆疊追蹤的生命週期
  maxStackCacheSize: 200,                  // 最多快取的堆疊數量
)
```

**何時需要調整**：
- **高流量應用**：增加 `cleanupInterval` 以降低 CPU 使用率
- **長時間除錯**：增加 `stackExpirationDuration` 以保留更多歷史記錄
- **記憶體受限的裝置**：降低 `maxStackCacheSize` 以減少記憶體佔用

**記憶體使用估算**：

追蹤器的記憶體佔用取決於你的配置：
- **預設配置**（`maxStackCacheSize: 100`）：約 50-100 KB
  - 每個堆疊追蹤條目：約 500-1000 bytes
  - 100 個條目 ≈ 50-100 KB
- **高流量配置**（`maxStackCacheSize: 200`）：約 100-200 KB
- **記憶體受限配置**（`maxStackCacheSize: 50`）：約 25-50 KB

`enablePeriodicCleanup: true`（預設）確保記憶體使用量保持在這些範圍內，每 30 秒移除過期條目。

**資源清理**：
如果你手動管理 observer 生命週期，完成時請呼叫 `dispose()`：

```dart
final observer = RiverpodDevToolsObserver(
  config: TrackerConfig.forPackage('your_app'),
);

// ... 使用 observer ...

// 完成時（例如測試的 teardown）
observer.dispose();
```

### 效能指標收集

你可以啟用效能指標收集來分析追蹤器本身的開銷：

```dart
RiverpodDevToolsObserver(
  config: TrackerConfig.forPackage(
    'your_app_name',
    collectPerformanceMetrics: true,  // 啟用效能追蹤
  ),
)
```

啟用後，追蹤器將收集詳細的指標，包括：
- **堆疊追蹤解析時間**：分析調用堆疊所花費的時間
- **值序列化時間**：轉換 provider 值所花費的時間
- **總追蹤時間**：每次追蹤操作的總時間
- **調用鏈深度**：捕獲的堆疊框架數量
- **值大小**：序列化值的大小

這些指標會顯示在 DevTools 擴展的 **Performance** 分頁中，包括：
- 整體統計資訊（總操作數、總時間、平均時間）
- 每個 provider 的統計資訊（更新次數、平均/最小/最大時間）
- 解析與序列化時間的細分

**注意**：效能指標收集會增加少量開銷。建議僅在開發環境中啟用，生產環境應該停用。

## 控制台輸出

當 `enableConsoleOutput` 設為 true 時，你會看到格式化的輸出：

```
╔══════════════════════════════════════════════════════
║ 🔄 UPDATE: counterProvider
║ ──────────────────────────────────────────────────────
║ 📍 Location: widgets/counter_button.dart:42 in _onPressed
║ ──────────────────────────────────────────────────────
║ 📜 Call chain:
║    → widgets/counter_button.dart:42 in _onPressed
║      providers/counter_provider.dart:15 in increment
║ ──────────────────────────────────────────────────────
║ Before: 0
║ After:  1
╚══════════════════════════════════════════════════════
```

## DevTools 擴展功能

擴展提供完整的除錯介面，包含三個主要分頁：

### State Inspector 分頁
- **Provider 列表** - 即時查看所有狀態變化與時間戳記
- **時間軸視圖** - 視覺化時間軸，顯示事件隨時間的變化，支援縮放和平移控制
- **位置資訊** - 顯示每個變化發生的確切檔案和行號
- **值比對** - 並排顯示變化前後的值，方便除錯
- **調用鏈** - 完整的調用堆疊，追蹤執行路徑
- **搜尋與過濾** - 快速找到特定的 provider 或變化
- **事件匯出** - 將事件匯出為 JSON 或 CSV 格式，用於離線分析與分享
- **事件歷史** - 啟用持久化時，DevTools 連接後會自動載入先前的事件

### Performance 分頁
- **整體統計** - 所有 providers 的總操作數、總時間和平均時間
- **每個 Provider 的指標** - 詳細的效能細分：
  - 更新次數和頻率
  - 平均、最小和最大追蹤時間
  - 堆疊追蹤解析時間
  - 值序列化時間
- **效能指標** - 基於追蹤開銷的視覺回饋（優秀/良好/普通/慢）
- **可展開的詳細資訊** - 點擊任何 provider 查看完整指標

### Graph 分頁
- **Provider 依賴圖** - 互動式視覺化 provider 關係
- **時序依賴檢測** - 根據更新時序自動推斷依賴關係
- **互動式節點** - 點擊 provider 查看其連接
- **連接強度** - 視覺化顯示 provider 更新的頻率
- **顏色分類節點** - 不同類型的 provider 使用不同顏色（NotifierProvider、FutureProvider、StreamProvider 等）
- **類型統計** - 工具列即時顯示每種 provider 類型的數量及顏色指示
- **縮放與平移** - 完整的互動式檢視器，探索複雜的圖表
- **網路統計** - 即時顯示各類型 provider 數量和總連接數

### 共同功能
- **GitHub 風格暗色主題** - 長時間除錯也不傷眼
- **分頁導航** - 輕鬆在狀態檢查、效能分析和圖表視圖之間切換

### Provider 狀態篩選

你可以透過搜尋框快速篩選特定的 Provider 狀態變化：

![Provider 狀態篩選](doc/images/provider-filtering.png)

也可以專注於特定的 Provider 進行深入分析：

![篩選特定 Provider](doc/images/filter-specific-provider.png)

### 時間軸視圖

擴展包含強大的時間軸視覺化功能，幫助你了解 provider 何時以及如何隨時間變化。

**如何存取：**

1. 點擊視圖模式選擇器中的**時間軸**圖示（語言切換器旁邊）
2. 在**列表視圖**（預設）和**時間軸視圖**之間切換

**時間軸功能：**

- **視覺化時間軸** - 在時間軸上查看所有狀態變化
- **顏色編碼事件**：
  - 🟢 綠色：Provider 新增（ADD）
  - 🔵 紫色：Provider 更新（UPDATE）
  - 🟠 橙色：Provider 銷毀（DISPOSE）
  - 🔴 紅色：Provider 錯誤（ERROR）
- **Provider 軌道** - 每個 provider 都有自己的水平軌道，方便追蹤
- **互動控制**：
  - 🔍 放大/縮小 - 放大特定時間段（正確影響時間軸比例）
  - ↔️ 平移 - 水平拖曳以瀏覽時間
  - 🔄 重設 - 回到預設視圖
- **事件選擇** - 點擊任何事件以在側邊面板中查看詳細資訊
- **懸停互動** - 將滑鼠移到事件點上可以：
  - 🎯 看到從事件到其 provider 標籤的連接線
  - 💡 高亮並放大 provider 名稱（變成藍紫色並放大字體）
  - ✨ 在事件點周圍顯示光暈效果
- **時間標籤** - 時間軸下方顯示精確的時間戳記

**使用場景：**

- 📊 **識別模式** - 發現高頻率更新或異常的更新序列
- ⏱️ **效能分析** - 查看哪些 provider 更新最頻繁
- 🐛 **除錯時間問題** - 了解狀態變化之間的時間關係
- 📈 **視覺化狀態流** - 追蹤狀態如何在應用程式中傳播

**提示：**

- 使用縮放功能專注於特定的時間窗口
- 將滑鼠懸停在事件點上可以快速識別它們屬於哪個 provider
- 尋找可能表示效能問題的事件群集
- 不同的 provider 軌道使追蹤個別 provider 行為變得容易
- 結合篩選器專注於特定的 provider 或變化類型
- 當存在許多 provider 時，時間軸會顯示前 10 個最活躍的 provider

### 使用圖表視圖

圖表視圖幫助你了解應用程式中的 provider 關係：

1. **切換到 Graph 分頁**：點擊工具列中的「Graph」分頁
2. **與應用程式互動**：當你使用應用程式時，圖表會自動填充 providers
3. **查看類型統計**：
   - 工具列會顯示每種 provider 類型的數量及其對應的顏色
   - 快速查看應用程式中 provider 類型的分布（例如「Notifier: 3」、「Future: 2」、「Stream: 1」）
   - 每個類型標籤使用與圖表中節點相同的顏色
4. **探索關係**：
   - 在時間上接近更新的 providers（100ms 內）會顯示為已連接
   - 點擊節點以高亮其連接
   - 更強的連接（更頻繁的共同更新）會有更粗的線條
5. **了解顏色**：
   - 🔴 紅色：NotifierProvider、AsyncNotifierProvider、StreamNotifierProvider
   - 🟣 紫色：FutureProvider
   - 🟢 綠色：StreamProvider
   - 🟠 橙色：Provider（函數式 providers）
   - 🔵 淺藍色：StateProvider
   - 🔷 更淺藍色：StateNotifierProvider
   - 🟪 淺紫色：ChangeNotifierProvider
   - ⚪ 灰色：未知/其他 provider 類型
6. **重設視圖**：使用縮放重設按鈕回到預設視圖
7. **清除網路**：點擊清除按鈕重新開始

**注意**：圖表顯示的是基於更新時序推斷的依賴關係，而非實際的 Riverpod 依賴圖（無法透過公開 API 存取）。

### 使用技巧

- **找出狀態 Bug**：查看調用鏈了解狀態為何意外變化
- **效能除錯**：檢查 provider 是否更新過於頻繁
- **了解架構**：使用圖表視圖查看 providers 如何互動
- **程式碼導航**：點擊調用鏈中的檔案路徑跳轉到程式碼（如果你的 IDE 支援）
- **過濾**：使用 `packagePrefixes` 設定只專注於你應用的程式碼，過濾掉框架雜訊

### 事件匯出

DevTools 擴展支援匯出追蹤事件，用於離線分析以及與團隊成員分享。

**如何匯出：**

1. 點擊頂部工具列的**下載**圖示（語言切換器旁邊）
2. 選擇你偏好的格式：
   - **JSON 格式** - 完整的事件資料與詮釋資料，適合程式化分析
   - **CSV 格式** - 時間軸格式，適合在 Excel、Google Sheets 等試算表工具中分析
3. 檔案將自動下載，檔名包含時間戳記

**JSON 匯出格式：**

```json
{
  "exportedAt": "2024-01-15T10:30:00.000Z",
  "totalEvents": 42,
  "events": [
    {
      "id": "1234567890",
      "timestamp": "2024-01-15T10:29:45.123Z",
      "changeType": "UPDATE",
      "providerName": "counterProvider",
      "providerType": "StateProvider<int>",
      "previousValue": 0,
      "currentValue": 1,
      "location": "lib/screens/home_screen.dart:45",
      "file": "lib/screens/home_screen.dart",
      "line": 45,
      "function": "_incrementCounter",
      "callChain": [
        {
          "location": "lib/screens/home_screen.dart:45",
          "file": "lib/screens/home_screen.dart",
          "line": 45,
          "function": "_incrementCounter"
        },
        {
          "location": "lib/widgets/counter_button.dart:23",
          "file": "lib/widgets/counter_button.dart",
          "line": 23,
          "function": "_onPressed"
        }
      ]
    }
  ]
}
```

**CSV 匯出格式：**

```csv
Timestamp,Change Type,Provider,Value,Location
2024-01-15T10:29:45.123Z,UPDATE,counterProvider,1,lib/screens/home_screen.dart:45
```

**使用場景：**

- 📊 **離線分析** - 匯出事件並在你偏好的工具中分析
- 🤝 **團隊協作** - 與團隊成員分享除錯會話
- 📝 **錯誤報告** - 將事件日誌附加到錯誤報告以提供更好的背景資訊
- 📈 **效能分析** - 將 CSV 匯入試算表工具進行資料視覺化

## 疑難排解

### DevTools 擴展未顯示

如果你在 DevTools 中沒有看到 "Riverpod State Inspector" 標籤：

1. **確認 observer 已加入**：檢查 `RiverpodDevToolsObserver` 是否在 `ProviderScope` 的 observers 列表中
2. **重新建置應用**：加入套件後停止並重新啟動應用
3. **檢查 DevTools 版本**：確保使用最新版本的 DevTools
4. **驗證擴展已建置**：擴展應該在 `extension/devtools/` 目錄中

### 沒有狀態變化顯示

如果擴展可見但沒有狀態變化顯示：

1. **檢查 packagePrefixes**：確保你的應用套件名稱包含在設定中：
   ```dart
   TrackerConfig.forPackage('your_actual_package_name')
   ```
2. **驗證 provider 確實在變化**：試試簡單的計數器測試來確認追蹤是否運作
3. **檢查控制台輸出**：啟用 `enableConsoleOutput: true` 查看變化是否被追蹤到

### 調用鏈沒有顯示位置

如果你看到狀態變化但沒有檔案位置：

1. **套件名稱不符**：你的 `packagePrefixes` 可能與實際的套件結構不符
2. **所有位置都被過濾**：你的 `ignoredFilePatterns` 可能太過嚴格
3. **Provider 自動計算**：某些 provider 會根據依賴自動更新 - 這些不會有特定的觸發位置

### 效能問題

如果追蹤器拖慢你的應用：

1. **停用控制台輸出**：設定 `enableConsoleOutput: false` 以獲得更好的效能
2. **降低調用鏈深度**：將 `maxCallChainDepth` 降低到 5 或更少
3. **加入更多忽略模式**：過濾掉你不需要追蹤的高頻率更新 provider
4. **在正式版本中停用**：只在除錯模式使用追蹤器：
   ```dart
   observers: [
     if (kDebugMode) RiverpodDevToolsObserver(...)
   ]
   ```

## 進階功能

### 堆疊追蹤解析快取

追蹤器包含智能快取系統，用於堆疊追蹤解析，可大幅提升效能，特別是對於頻繁更新的非同步 providers。

**運作原理：**
- 已解析的堆疊追蹤會被快取以避免重複解析
- 當快取達到大小限制時使用 LRU（最近最少使用）策略移除舊項目
- 可將重複追蹤的解析時間減少 80-90%
- 預設啟用並配置合理的設定值

**配置方式：**

```dart
RiverpodDevToolsObserver(
  config: TrackerConfig.forPackage(
    'your_app',
    enableStackTraceCache: true,        // 啟用快取（預設：true）
    maxStackTraceCacheSize: 500,         // 最大快取項目數（預設：500）
  ),
)
```

**何時調整設定：**
- **大型應用且有許多 providers**：增加 `maxStackTraceCacheSize` 到 1000+ 以獲得更好的快取命中率
- **記憶體受限環境**：減少到 100-200 以降低記憶體使用
- **除錯快取問題**：暫時停用快取 `enableStackTraceCache: false`

**效能影響：**
- 典型記憶體使用：每個快取項目約 100-500 bytes
- 500 個項目的快取 ≈ 50-250 KB 記憶體
- 頻繁更新的 providers 可減少 80-90% 的解析時間

## 貢獻者
<a href="https://github.com/weitsai/riverpod_devtools_tracker/graphs/contributors ">
  <img src="https://contrib.rocks/image?repo=weitsai/riverpod_devtools_tracker" />
</a>
