# Quick Reference Card

## 📦 Installation

```yaml
dependencies:
  flutter_riverpod: ^3.1.0
  riverpod_devtools_tracker: ^1.0.2
```

```bash
flutter pub get
```

## ⚡ Basic Setup

### Minimal Setup

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_devtools_tracker/riverpod_devtools_tracker.dart';

void main() {
  runApp(
    ProviderScope(
      observers: [
        RiverpodDevToolsObserver(
          config: TrackerConfig.forPackage('your_app_name'),
        ),
      ],
      child: const MyApp(),
    ),
  );
}
```

### Production-Ready Setup

```dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_devtools_tracker/riverpod_devtools_tracker.dart';

void main() {
  runApp(
    ProviderScope(
      observers: [
        // Only enable in debug mode
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

## 🎯 Configuration Options

### Quick Configuration Methods

| Method | Use Case | Example |
|--------|----------|---------|
| `TrackerConfig.forPackage()` | Single package | `TrackerConfig.forPackage('my_app')` |
| `TrackerConfig(...)` | Custom setup | See Advanced Configuration below |

### Configuration Options Table

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `enabled` | `bool` | `true` | Enable/disable tracking |
| `packagePrefixes` | `List<String>` | - | Package prefixes to track (e.g., `['package:my_app/']`) |
| `enableConsoleOutput` | `bool` | `false` | Print changes to console |
| `prettyConsoleOutput` | `bool` | `true` | Use formatted console output |
| `maxCallChainDepth` | `int` | `10` | Maximum call stack depth to capture |
| `maxValueLength` | `int` | `200` | Max characters for value display in console |
| `skipUnchangedValues` | `bool` | `true` | Skip tracking when provider value doesn't change |
| `ignoredPackagePrefixes` | `List<String>` | Framework packages | Packages to ignore in stack traces |
| `ignoredFilePatterns` | `List<String>` | `['.g.dart', '.freezed.dart']` | File patterns to ignore |

### Common Configuration Templates

#### High Performance (Minimal Overhead)

```dart
RiverpodDevToolsObserver(
  config: TrackerConfig.forPackage(
    'your_app',
    enableConsoleOutput: false,
    maxCallChainDepth: 5,
    skipUnchangedValues: true,
  ),
)
```

#### Verbose Debugging

```dart
RiverpodDevToolsObserver(
  config: TrackerConfig.forPackage(
    'your_app',
    enableConsoleOutput: true,
    prettyConsoleOutput: true,
    maxCallChainDepth: 15,
    skipUnchangedValues: false,
  ),
)
```

#### Multi-Package Project

```dart
RiverpodDevToolsObserver(
  config: TrackerConfig.forPackage(
    'my_app',
    additionalPackages: [
      'package:my_core/',
      'package:my_features/',
    ],
  ),
)
```

#### Custom Filtering

```dart
RiverpodDevToolsObserver(
  config: TrackerConfig(
    packagePrefixes: ['package:my_app/'],
    ignoredFilePatterns: [
      '.g.dart',
      '.freezed.dart',
      '_test.dart',
      '/generated/',
    ],
    ignoredPackagePrefixes: [
      'package:flutter/',
      'package:flutter_riverpod/',
      'package:riverpod/',
      'dart:',
      'package:go_router/',
    ],
  ),
)
```

## 📊 Using DevTools Extension

### Opening DevTools

**VS Code**: Click "Dart DevTools" in debug toolbar
**Android Studio**: Click "Open DevTools" in Run panel
**Command Line**: Copy URL from `flutter run` output

### DevTools Extension Features

| Feature | Description | Shortcut |
|---------|-------------|----------|
| **Provider List** | View all state changes chronologically | - |
| **Search** | Filter providers (supports regex) | Click mode icon to toggle |
| **Detail Panel** | View before/after values & call chain | Click any list item |
| **Filter Types** | Filter by ADD/UPDATE/DISPOSE/ERROR | Filter icon |
| **Visual Diff** | Compare state changes with highlighting | Toggle view mode |

### Search Modes

- **Simple**: Case-insensitive substring (default)
- **Regex**: Advanced patterns - click mode icon to switch

## 🔍 Troubleshooting Checklist

### DevTools Tab Not Showing

- [ ] Observer added to `ProviderScope`?
- [ ] `flutter pub get` executed?
- [ ] App restarted?
- [ ] Using recent DevTools version?

### No State Changes Appearing

- [ ] Package name matches `pubspec.yaml`?
- [ ] Providers actually changing?
- [ ] Console output enabled for verification?
- [ ] Check `packagePrefixes` configuration

### Call Chain Shows No Location

- [ ] Package name mismatch?
- [ ] Too aggressive `ignoredFilePatterns`?
- [ ] Auto-computed provider (no specific trigger)?

### Performance Issues

- [ ] Disable console output: `enableConsoleOutput: false`
- [ ] Reduce call depth: `maxCallChainDepth: 5`
- [ ] Add ignored patterns for high-frequency providers
- [ ] Only enable in debug mode: `if (kDebugMode)`

## ⚡ Performance Optimization

### Quick Optimization Checklist

- [ ] Disable in production (`if (kDebugMode)`)
- [ ] Disable console output for better performance
- [ ] Reduce `maxCallChainDepth` (5-8 recommended)
- [ ] Use `skipUnchangedValues: true` (default)
- [ ] Filter out generated files (`.g.dart`, `.freezed.dart`)
- [ ] Ignore high-frequency framework providers

### Performance Comparison

| Configuration | Overhead | Use Case |
|--------------|----------|----------|
| Disabled (production) | 0% | Production builds |
| High performance | <1% | Active development |
| Verbose debugging | 2-5% | Deep debugging sessions |

## 📝 Common Patterns

### Provider Debugging

```dart
// 1. Enable tracking
// 2. Trigger the issue
// 3. Check DevTools:
//    - Click on the provider update
//    - View call chain to find trigger location
//    - Compare before/after values
```

### Finding State Bugs

```dart
// Look for:
// - Unexpected UPDATE events
// - Call chain shows wrong trigger location
// - Before/after values don't match expectations
```

### Performance Debugging

```dart
// Look for:
// - High frequency UPDATE events
// - Providers updating on every frame
// - Unnecessary recomputations
```

## 🔗 Integration Examples

See detailed integration guides:

- [Freezed Integration](integration/freezed-integration.md)
- [Go Router Integration](integration/go-router-integration.md)

## 📚 Additional Resources

- [Main README](../README.md) - Complete documentation
- [Troubleshooting Flowchart](TROUBLESHOOTING_FLOWCHART.md) - Visual decision trees
- [GitHub Issues](https://github.com/weitsai/riverpod_devtools_tracker/issues) - Report bugs or request features

---

**Quick Tip**: Start with `TrackerConfig.forPackage('your_app')` and customize only if needed!
