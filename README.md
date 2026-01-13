# Riverpod DevTools Tracker

[![pub package](https://img.shields.io/pub/v/riverpod_devtools_tracker.svg)](https://pub.dev/packages/riverpod_devtools_tracker)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
![Flutter](https://img.shields.io/badge/Flutter-3.27+-blue)
![Riverpod](https://img.shields.io/badge/Riverpod-3.1+-purple)
[![style: flutter lints](https://img.shields.io/badge/style-flutter__lints-blue)](https://pub.dev/packages/flutter_lints)


![Code Location Tracking](doc/images/code-location-tracking.png)

A powerful Flutter package that automatically tracks Riverpod state changes with detailed call stack information, helping you debug by showing exactly where state changes originated in your code.

**[繁體中文](README.zh-TW.md)** | English

## Table of Contents

- [Features](#features)
- [Installation](#installation)
- [Quick Start](#quick-start)
- [How to Use DevTools Extension](#how-to-use-devtools-extension)
- [Configuration](#configuration)
- [Console Output](#console-output)
- [DevTools Extension Features](#devtools-extension-features)
- [Troubleshooting](#troubleshooting)
- [Requirements](#requirements)

## Features

- 🔍 **Automatic State Tracking** - No manual tracking code needed
- 📍 **Code Location Detection** - Shows exactly where state changes originated
- 📜 **Call Chain Visualization** - View the complete call stack
- 🎨 **Beautiful DevTools Extension** - GitHub-style dark theme UI
- ⚡ **Zero Configuration** - Just add the observer and you're done
- 🔧 **Highly Configurable** - Customize what to track and how
- 🎯 **Selective Provider Tracking** - Whitelist/blacklist specific providers or use custom filters
- ⚡ **Optimized Performance** - Skip unchanged values and efficient value serialization

## Installation

### Step 1: Add the Package

Add `riverpod_devtools_tracker` to your `pubspec.yaml`:

```yaml
dependencies:
  flutter_riverpod: ^3.1.0  # Required
  riverpod_devtools_tracker: ^1.0.2
```

### Step 2: Install Dependencies

Run the following command in your terminal:

```bash
flutter pub get
```

This package includes two components:
- **Core Tracking**: `RiverpodDevToolsObserver` for monitoring and recording state changes
- **DevTools Extension**: Visual interface that's automatically discovered by Flutter DevTools

> **Note**: The DevTools extension is automatically included in the package's `extension/devtools/` directory. No additional installation or configuration needed.

## Quick Start

### Step 1: Import the Package

In your `main.dart` file, import the package:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_devtools_tracker/riverpod_devtools_tracker.dart';
```

### Step 2: Add the Observer

Add `RiverpodDevToolsObserver` to your `ProviderScope`'s observers list:

```dart
void main() {
  runApp(
    ProviderScope(
      observers: [
        RiverpodDevToolsObserver(
          config: TrackerConfig.forPackage('your_app_name'),  // Replace with your package name
        ),
      ],
      child: const MyApp(),
    ),
  );
}
```

> **Important**: Replace `'your_app_name'` with your actual package name from `pubspec.yaml` (the `name:` field value)

### Step 3: Run Your App

```bash
flutter run
```

Done! Now when you run your app and open DevTools, you'll see the "Riverpod State Inspector" tab.

## How to Use DevTools Extension

### Step 1: Open DevTools

After running your app, you can open Flutter DevTools in several ways:

**Method A - From VS Code**
1. Run your app (press F5 or click Run)
2. Click the **"Dart DevTools"** button in the debug toolbar
3. DevTools will automatically open in your browser

**Method B - From Android Studio / IntelliJ**
1. Run your app
2. Click **"Open DevTools"** in the Run panel
3. DevTools will automatically open in your browser

**Method C - From Command Line**
1. Run your app: `flutter run`
2. The terminal will display a DevTools URL:
   ```
   The Flutter DevTools debugger and profiler is available at:
   http://127.0.0.1:9100?uri=...
   ```
3. Click or copy the URL to open it in your browser

### Step 2: Find the Riverpod State Inspector Tab

Once DevTools is open:
1. Look for the **"Riverpod State Inspector"** tab in the top menu bar
2. Click the tab to open the extension interface

![DevTools Extension Setup](doc/images/devtools-setup.png)

> **Tip**: If you don't see this tab, make sure:
> - The package is properly installed and you've run `flutter pub get`
> - `RiverpodDevToolsObserver` is added to your `ProviderScope`
> - Your app has been restarted

### Step 3: Understand the Interface Layout

The DevTools extension uses a two-panel layout:

**Left Panel - Provider List (400px width)**
- Displays all state changes in chronological order
- Each entry shows:
  - Provider name and type
  - Timestamp
  - Change type (add/update/dispose/error)
  - Code location where the change was triggered
- Click any entry to view details

**Right Panel - State Details**
- Shows detailed information about the selected state change:
  - Before/after value comparison
  - Complete call chain with file locations
  - Function names in the call stack
  - Clickable file paths for code navigation

![Code Location Tracking](doc/images/code-location-tracking.png)

### Step 4: Track and Debug State Changes

As you interact with your app:

1. **Real-time Monitoring**: Watch the left panel update in real-time as providers change
2. **Locate Issues**: Click any change record to see the exact code location that triggered it
3. **Trace Execution**: Use the call chain to understand the execution path
4. **Compare Values**: Compare before/after values to debug state issues

### Example Usage

Let's say you have a counter provider:

```dart
final counterProvider = StateProvider<int>((ref) => 0);

// In your widget
ElevatedButton(
  onPressed: () => ref.read(counterProvider.notifier).state++,
  child: const Text('Increment'),
)
```

When you click the button:
1. The DevTools extension immediately shows a new entry: `UPDATE: counterProvider`
2. The location shows exactly where the button was pressed (e.g., `widgets/counter_button.dart:42`)
3. Click the entry to see the value changed from `0` to `1`
4. The call chain shows the complete path from button press to state update

## Configuration

### Basic Configuration

```dart
RiverpodDevToolsObserver(
  config: TrackerConfig.forPackage(
    'your_app_name',
    enableConsoleOutput: true,      // Print to console
    prettyConsoleOutput: true,      // Use formatted output
    maxCallChainDepth: 10,          // Max stack trace depth
    maxValueLength: 200,            // Max value string length
  ),
)
```

### Advanced Configuration

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
    // Memory management settings
    enablePeriodicCleanup: true,                        // Enable automatic cleanup
    cleanupInterval: const Duration(seconds: 30),       // Cleanup frequency
    stackExpirationDuration: const Duration(seconds: 60), // How long to keep stacks
    maxStackCacheSize: 100,                             // Maximum cached stacks
  ),
)
```

### Selective Provider Tracking

You can filter which providers to track using whitelists, blacklists, or custom filters.

Pass provider references directly for type-safety and IDE auto-completion:

```dart
// Define your providers
final userProvider = StateProvider<User?>((ref) => null);
final cartProvider = StateNotifierProvider<CartNotifier, Cart>(...);
final authProvider = StateProvider<bool>((ref) => false);
final debugProvider = Provider<String>((ref) => 'debug');
final tempProvider = Provider<int>((ref) => 0);

RiverpodDevToolsObserver(
  config: TrackerConfig.forPackage(
    'your_app',
    // Whitelist: Only track these providers (takes precedence over blacklist)
    trackedProviders: [userProvider, cartProvider, authProvider],

    // Blacklist: Ignore these providers (only works when whitelist is empty)
    ignoredProviders: [debugProvider, tempProvider],

    // Custom filter: Advanced filtering based on name and type
    providerFilter: (name, type) {
      // Only track StateNotifierProvider and StateProvider
      return type.contains('State');
    },
  ),
)
```

**How filtering works:**
1. If `trackedProviders` is not empty, only providers in the whitelist are tracked (blacklist is ignored)
2. If `trackedProviders` is empty, providers in `ignoredProviders` are filtered out
3. After whitelist/blacklist filtering, `providerFilter` function is applied if provided
4. The `skipUnchangedValues` option (enabled by default) prevents tracking updates where the value hasn't actually changed
### Memory Management

The tracker automatically manages memory to prevent leaks during long debugging sessions:

- **Periodic Cleanup**: Automatically removes expired stack traces from memory
- **Configurable Retention**: Control how long stack traces are kept
- **Size Limits**: Hard limit on the number of cached stack traces

Default settings work well for most apps, but you can customize them:

```dart
TrackerConfig.forPackage(
  'your_app',
  enablePeriodicCleanup: true,            // Enable/disable automatic cleanup
  cleanupInterval: Duration(seconds: 30),  // How often to run cleanup
  stackExpirationDuration: Duration(minutes: 2), // Stack trace lifetime
  maxStackCacheSize: 200,                  // Max number of stacks to cache
)
```

**When to Adjust**:
- **High-traffic apps**: Increase `cleanupInterval` to reduce CPU usage
- **Long debugging sessions**: Increase `stackExpirationDuration` to keep more history
- **Memory-constrained devices**: Decrease `maxStackCacheSize` to reduce memory footprint

**Memory Usage Estimation**:

The tracker's memory footprint depends on your configuration:
- **Default config** (`maxStackCacheSize: 100`): ~50-100 KB
  - Each stack trace entry: ~500-1000 bytes
  - 100 entries ≈ 50-100 KB
- **High-traffic config** (`maxStackCacheSize: 200`): ~100-200 KB
- **Memory-constrained config** (`maxStackCacheSize: 50`): ~25-50 KB

The `enablePeriodicCleanup: true` (default) ensures memory usage stays within these bounds by removing expired entries every 30 seconds.

**Resource Cleanup**:
If you're manually managing observer lifecycle, call `dispose()` when done:

```dart
final observer = RiverpodDevToolsObserver(
  config: TrackerConfig.forPackage('your_app'),
);

// ... use observer ...

// When done (e.g., in a test teardown)
observer.dispose();
```

## Console Output

When `enableConsoleOutput` is true, you'll see formatted output like this:

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

## DevTools Extension Features

The extension provides a comprehensive debugging interface:

- **Provider List** - Real-time view of all state changes with timestamps
- **Location Info** - Shows the exact file and line number where each change originated
- **Value Comparison** - Before/after values displayed side by side for easy debugging
- **Call Chain** - Complete call stack for tracing the execution path
- **Search & Filter** - Quickly find specific providers or changes
- **Event Export** - Export events to JSON or CSV format for offline analysis and sharing
- **GitHub-style Dark Theme** - Easy on the eyes during long debugging sessions

### Provider State Filtering

You can quickly filter specific Provider state changes using the search box:

![Provider Filtering](doc/images/provider-filtering.png)

You can also focus on a specific Provider for in-depth analysis:

![Filter Specific Provider](doc/images/filter-specific-provider.png)

### Tips for Using the Extension

- **Finding State Bugs**: Look at the call chain to understand why a state changed unexpectedly
- **Performance Debugging**: Check if providers are updating too frequently
- **Code Navigation**: Click on file paths in the call chain to jump to the code (if your IDE supports it)
- **Filtering**: Use the `packagePrefixes` config to focus only on your app's code and filter out framework noise

### Event Export

The DevTools extension supports exporting tracked events for offline analysis and sharing with team members.

**How to Export:**

1. Click the **Download** icon in the top toolbar (next to the language switcher)
2. Choose your preferred format:
   - **JSON Format** - Complete event data with metadata, perfect for programmatic analysis
   - **CSV Format** - Timeline format for spreadsheet analysis in Excel, Google Sheets, etc.
3. The file will be automatically downloaded with a timestamp in the filename

**JSON Export Format:**

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

**CSV Export Format:**

```csv
Timestamp,Change Type,Provider,Value,Location
2024-01-15T10:29:45.123Z,UPDATE,counterProvider,1,lib/screens/home_screen.dart:45
```

**Use Cases:**

- 📊 **Offline Analysis** - Export events and analyze them in your preferred tools
- 🤝 **Team Collaboration** - Share debugging sessions with teammates
- 📝 **Bug Reports** - Attach event logs to bug reports for better context
- 📈 **Performance Analysis** - Import CSV into spreadsheet tools for data visualization

## Troubleshooting

### DevTools Extension Not Showing

If you don't see the "Riverpod State Inspector" tab in DevTools:

1. **Make sure the observer is added**: Check that `RiverpodDevToolsObserver` is in your `ProviderScope`'s observers list
2. **Rebuild your app**: Stop and restart your app after adding the package
3. **Check DevTools version**: Make sure you're using a recent version of DevTools
4. **Verify the extension is built**: The extension should be in `extension/devtools/` directory

### No State Changes Appearing

If the extension is visible but no state changes show up:

1. **Check packagePrefixes**: Make sure your app's package name is included in the config:
   ```dart
   TrackerConfig.forPackage('your_actual_package_name')
   ```
2. **Verify providers are actually changing**: Try a simple test like a counter to confirm tracking works
3. **Check console output**: Enable `enableConsoleOutput: true` to see if changes are being tracked

### Call Chain Shows No Location

If you see state changes but no file locations:

1. **Package name mismatch**: Your `packagePrefixes` might not match your actual package structure
2. **All locations filtered**: Your `ignoredFilePatterns` might be too aggressive
3. **Provider is auto-computed**: Some providers update automatically based on dependencies - these won't have a specific trigger location

### Performance Issues

If the tracker is slowing down your app:

1. **Disable console output**: Set `enableConsoleOutput: false` for better performance
2. **Reduce call chain depth**: Lower `maxCallChainDepth` to 5 or less
3. **Add more ignored patterns**: Filter out high-frequency providers you don't need to track
4. **Disable in production**: Only use the tracker in debug mode:
   ```dart
   observers: [
     if (kDebugMode) RiverpodDevToolsObserver(...)
   ]
   ```

## Best Practices

### For Production Use

We recommend disabling the tracker in production builds for optimal performance:

```dart
import 'package:flutter/foundation.dart';

void main() {
  runApp(
    ProviderScope(
      observers: [
        // Only enable tracking in debug mode
        if (kDebugMode)
          RiverpodDevToolsObserver(
            config: TrackerConfig.forPackage('your_app'),
          ),
      ],
      child: const MyApp(),
    ),
  );
}
```

### Performance Optimization

If you experience performance issues during development:

1. **Disable console output**: Set `enableConsoleOutput: false` for better performance
2. **Reduce call chain depth**: Lower `maxCallChainDepth` to 5-8 for faster tracking
3. **Filter aggressively**: Add more patterns to `ignoredFilePatterns` to reduce noise
4. **Target specific providers**: Use `packagePrefixes` to focus only on your app's code

```dart
RiverpodDevToolsObserver(
  config: TrackerConfig.forPackage(
    'your_app',
    enableConsoleOutput: false,      // Better performance
    maxCallChainDepth: 5,             // Faster tracking
    ignoredFilePatterns: ['.g.dart', '.freezed.dart'], // Less noise
  ),
)
```

## Advanced Usage

### Tracking Multiple Packages

If your app uses multiple custom packages:

```dart
RiverpodDevToolsObserver(
  config: TrackerConfig.forPackage(
    'my_app',
    additionalPackages: [
      'package:my_common/',
      'package:my_features/',
    ],
  ),
)
```

### Selective Provider Tracking Use Cases

**Use Case 1: Debug Specific Feature**

When debugging a specific feature, track only related providers:

```dart
// Assume you have defined these providers
final cartProvider = StateNotifierProvider<CartNotifier, Cart>(...);
final cartItemsProvider = Provider<List<CartItem>>(...);
final cartTotalProvider = Provider<double>(...);
final checkoutProvider = StateNotifierProvider<CheckoutNotifier, CheckoutState>(...);

RiverpodDevToolsObserver(
  config: TrackerConfig.forPackage(
    'my_app',
    // Only track providers related to shopping cart
    trackedProviders: [
      cartProvider,
      cartItemsProvider,
      cartTotalProvider,
      checkoutProvider,
    ],
  ),
)
```

**Use Case 2: Exclude Noisy Providers**

Filter out high-frequency or debug-only providers:

```dart
// Assume you have defined these providers
final mousePositionProvider = StateProvider<Offset>(...);
final timerProvider = StreamProvider<DateTime>(...);
final debugLogProvider = Provider<String>(...);

RiverpodDevToolsObserver(
  config: TrackerConfig.forPackage(
    'my_app',
    // Ignore providers that update frequently and create noise
    ignoredProviders: [
      mousePositionProvider,  // Updates on every mouse move
      timerProvider,           // Updates every second
      debugLogProvider,        // Debug-only provider
    ],
  ),
)
```

**Use Case 3: Track by Provider Type**

Focus on specific types of providers:

```dart
RiverpodDevToolsObserver(
  config: TrackerConfig.forPackage(
    'my_app',
    // Only track state-holding providers, ignore computed ones
    providerFilter: (name, type) {
      return type.contains('StateProvider') ||
             type.contains('StateNotifierProvider') ||
             type.contains('NotifierProvider');
    },
  ),
)
```

**Use Case 4: Combined Filtering**

Use multiple filtering strategies together:

```dart
// Assume you have defined these providers
final authProvider = StateProvider<AuthState>(...);
final userProvider = StateProvider<User?>(...);
final sessionProvider = StateProvider<Session?>(...);
final permissionsProvider = Provider<Permissions>(...);
final tokenRefreshProvider = StreamProvider<String>(...);

RiverpodDevToolsObserver(
  config: TrackerConfig.forPackage(
    'my_app',
    // Track only authentication and user-related providers
    trackedProviders: [
      authProvider,
      userProvider,
      sessionProvider,
      permissionsProvider,
    ],
    // But exclude the token refresh provider (too noisy)
    ignoredProviders: [
      tokenRefreshProvider,
    ],
    // And apply custom filter for additional control
    providerFilter: (name, type) {
      // Skip any provider that ends with 'Cache'
      return !name.endsWith('Cache');
    },
  ),
)
```

### Custom Filtering

Create highly customized filtering rules:

```dart
RiverpodDevToolsObserver(
  config: TrackerConfig(
    packagePrefixes: ['package:my_app/'],
    ignoredFilePatterns: [
      '.g.dart',           // Generated files
      '.freezed.dart',     // Freezed files
      '_test.dart',        // Test files
      '/generated/',       // Generated directories
    ],
    ignoredPackagePrefixes: [
      'package:flutter/',
      'package:flutter_riverpod/',
      'package:riverpod/',
      'dart:',
      'package:go_router/',  // Add other packages to ignore
    ],
  ),
)
```

### Stack Trace Parsing Cache

The tracker includes an intelligent caching system for stack trace parsing that significantly improves performance, especially for frequently updated async providers.

**How it works:**
- Parsed stack traces are cached to avoid redundant parsing
- Uses LRU (Least Recently Used) eviction when cache reaches size limit
- Can reduce parsing time by 80-90% for repeated traces
- Enabled by default with sensible settings

**Configuration:**

```dart
RiverpodDevToolsObserver(
  config: TrackerConfig.forPackage(
    'your_app',
    enableStackTraceCache: true,        // Enable caching (default: true)
    maxStackTraceCacheSize: 500,         // Max cached entries (default: 500)
  ),
)
```

**When to adjust settings:**
- **Large apps with many providers**: Increase `maxStackTraceCacheSize` to 1000+ for better cache hit rates
- **Memory-constrained environments**: Decrease to 100-200 to reduce memory usage
- **Debugging cache issues**: Temporarily disable with `enableStackTraceCache: false`

**Performance impact:**
- Typical memory usage: ~100-500 bytes per cached entry
- Cache of 500 entries ≈ 50-250 KB memory
- 80-90% reduction in parsing time for frequently updated providers

## Contributors

<a href="https://github.com/weitsai/riverpod_devtools_tracker/graphs/contributors ">
  <img src="https://contrib.rocks/image?repo=weitsai/riverpod_devtools_tracker" />
</a>

## Support

- 📝 [Report Issues](https://github.com/weitsai/riverpod_devtools_tracker/issues)
- 💬 [Discussions](https://github.com/weitsai/riverpod_devtools_tracker/discussions)
- ⭐ If you find this package useful, please consider giving it a star on GitHub!
