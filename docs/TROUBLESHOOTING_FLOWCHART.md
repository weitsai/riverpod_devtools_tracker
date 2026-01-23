# Troubleshooting Flowchart

This guide provides decision trees for diagnosing and fixing common issues with Riverpod DevTools Tracker.

## Table of Contents

- [Problem 1: DevTools Extension Tab Not Showing](#problem-1-devtools-extension-tab-not-showing)
- [Problem 2: No State Changes Appearing](#problem-2-no-state-changes-appearing)
- [Problem 3: Call Chain Shows No Location](#problem-3-call-chain-shows-no-location)
- [Problem 4: Performance Issues](#problem-4-performance-issues)
- [Problem 5: Too Many Update Events](#problem-5-too-many-update-events)
- [Problem 6: Values Show as "Instance of ..."](#problem-6-values-show-as-instance-of)

---

## Problem 1: DevTools Extension Tab Not Showing

```
┌─────────────────────────────────────────┐
│ Is "Riverpod State Inspector" tab      │
│ visible in DevTools?                    │
└──────────────┬──────────────────────────┘
               │ NO
               ▼
┌─────────────────────────────────────────┐
│ Is RiverpodDevToolsObserver added      │
│ to ProviderScope observers list?       │
└──────────────┬──────────────────────────┘
               │ NO
               ▼
┌─────────────────────────────────────────┐
│ ✅ FIX: Add observer to ProviderScope   │
│                                         │
│ ProviderScope(                          │
│   observers: [                          │
│     RiverpodDevToolsObserver(           │
│       config: TrackerConfig.forPackage( │
│         'your_app_name',                │
│       ),                                │
│     ),                                  │
│   ],                                    │
│   child: const MyApp(),                 │
│ )                                       │
└─────────────────────────────────────────┘

               │ YES
               ▼
┌─────────────────────────────────────────┐
│ Did you run 'flutter pub get'?         │
└──────────────┬──────────────────────────┘
               │ NO
               ▼
┌─────────────────────────────────────────┐
│ ✅ FIX: Run command                     │
│                                         │
│ $ flutter pub get                       │
└─────────────────────────────────────────┘

               │ YES
               ▼
┌─────────────────────────────────────────┐
│ Did you restart the app?                │
└──────────────┬──────────────────────────┘
               │ NO
               ▼
┌─────────────────────────────────────────┐
│ ✅ FIX: Restart the app                 │
│                                         │
│ 1. Stop current debug session          │
│ 2. Run: flutter run                    │
│ 3. Reopen DevTools                     │
└─────────────────────────────────────────┘

               │ YES
               ▼
┌─────────────────────────────────────────┐
│ Is DevTools up to date?                 │
└──────────────┬──────────────────────────┘
               │ NO/UNSURE
               ▼
┌─────────────────────────────────────────┐
│ ✅ FIX: Update DevTools                 │
│                                         │
│ $ flutter pub global activate devtools │
│ $ flutter pub global run devtools      │
└─────────────────────────────────────────┘

               │ YES
               ▼
┌─────────────────────────────────────────┐
│ Check extension/devtools/ directory     │
│ exists in package                       │
└──────────────┬──────────────────────────┘
               │ MISSING
               ▼
┌─────────────────────────────────────────┐
│ ✅ FIX: Reinstall package               │
│                                         │
│ $ flutter pub cache repair              │
│ $ flutter pub get                       │
└─────────────────────────────────────────┘
```

---

## Problem 2: No State Changes Appearing

```
┌─────────────────────────────────────────┐
│ Are state changes showing in the        │
│ DevTools extension?                     │
└──────────────┬──────────────────────────┘
               │ NO
               ▼
┌─────────────────────────────────────────┐
│ Is tracker enabled?                     │
│ Check: config.enabled == true           │
└──────────────┬──────────────────────────┘
               │ NO
               ▼
┌─────────────────────────────────────────┐
│ ✅ FIX: Enable tracker                  │
│                                         │
│ TrackerConfig.forPackage(               │
│   'your_app',                           │
│   enabled: true,  // Default is true   │
│ )                                       │
└─────────────────────────────────────────┘

               │ YES
               ▼
┌─────────────────────────────────────────┐
│ Does package name match pubspec.yaml?  │
│ Compare: TrackerConfig.forPackage(     │
│   'name_here' ) with pubspec.yaml name │
└──────────────┬──────────────────────────┘
               │ NO
               ▼
┌─────────────────────────────────────────┐
│ ✅ FIX: Update package name             │
│                                         │
│ # In pubspec.yaml:                      │
│ name: my_actual_app                     │
│                                         │
│ # In main.dart:                         │
│ TrackerConfig.forPackage(               │
│   'my_actual_app',  // Must match!     │
│ )                                       │
└─────────────────────────────────────────┘

               │ YES
               ▼
┌─────────────────────────────────────────┐
│ Are providers actually changing?        │
│ Enable console output to verify         │
└──────────────┬──────────────────────────┘
               │ UNSURE
               ▼
┌─────────────────────────────────────────┐
│ ✅ DEBUG: Enable console output         │
│                                         │
│ TrackerConfig.forPackage(               │
│   'your_app',                           │
│   enableConsoleOutput: true,            │
│   prettyConsoleOutput: true,            │
│ )                                       │
│                                         │
│ Check console for output when           │
│ interacting with your app               │
└─────────────────────────────────────────┘

               │ YES (console shows changes)
               ▼
┌─────────────────────────────────────────┐
│ Is packagePrefixes filtering too much?  │
└──────────────┬──────────────────────────┘
               │ YES
               ▼
┌─────────────────────────────────────────┐
│ ✅ FIX: Check package prefixes          │
│                                         │
│ TrackerConfig(                          │
│   packagePrefixes: [                    │
│     'package:your_app/',                │
│     'package:your_other_package/',      │
│   ],                                    │
│ )                                       │
│                                         │
│ Make sure all relevant packages         │
│ are included                            │
└─────────────────────────────────────────┘

               │ NO (providers not changing)
               ▼
┌─────────────────────────────────────────┐
│ ✅ DIAGNOSIS: App logic issue           │
│                                         │
│ Providers aren't updating because:      │
│ - State is immutable and unchanged      │
│ - Update logic not being called         │
│ - skipUnchangedValues filtering them   │
│                                         │
│ Try: Set skipUnchangedValues: false     │
└─────────────────────────────────────────┘
```

---

## Problem 3: Call Chain Shows No Location

```
┌─────────────────────────────────────────┐
│ Does call chain show file locations?   │
└──────────────┬──────────────────────────┘
               │ NO
               ▼
┌─────────────────────────────────────────┐
│ Check if packagePrefixes includes      │
│ your app's package                      │
└──────────────┬──────────────────────────┘
               │ NO
               ▼
┌─────────────────────────────────────────┐
│ ✅ FIX: Add package prefix              │
│                                         │
│ TrackerConfig.forPackage(               │
│   'my_app',  // This adds               │
│                // 'package:my_app/'     │
│ )                                       │
└─────────────────────────────────────────┘

               │ YES
               ▼
┌─────────────────────────────────────────┐
│ Are ignoredFilePatterns too aggressive? │
└──────────────┬──────────────────────────┘
               │ YES
               ▼
┌─────────────────────────────────────────┐
│ ✅ FIX: Review ignored patterns         │
│                                         │
│ TrackerConfig(                          │
│   ignoredFilePatterns: [                │
│     '.g.dart',      // Keep these       │
│     '.freezed.dart', // Keep these      │
│     // Remove overly broad patterns    │
│   ],                                    │
│ )                                       │
└─────────────────────────────────────────┘

               │ NO
               ▼
┌─────────────────────────────────────────┐
│ Is maxCallChainDepth too low?          │
└──────────────┬──────────────────────────┘
               │ YES
               ▼
┌─────────────────────────────────────────┐
│ ✅ FIX: Increase call chain depth       │
│                                         │
│ TrackerConfig.forPackage(               │
│   'your_app',                           │
│   maxCallChainDepth: 15,  // Default 10│
│ )                                       │
└─────────────────────────────────────────┘

               │ NO
               ▼
┌─────────────────────────────────────────┐
│ ✅ DIAGNOSIS: Auto-computed provider    │
│                                         │
│ Some providers update automatically     │
│ based on dependencies with no           │
│ specific trigger location:               │
│                                         │
│ - FutureProvider with watch()          │
│ - StreamProvider                        │
│ - Provider with dependencies            │
│                                         │
│ This is expected behavior               │
└─────────────────────────────────────────┘
```

---

## Problem 4: Performance Issues

```
┌─────────────────────────────────────────┐
│ Is the app slow when tracker enabled?  │
└──────────────┬──────────────────────────┘
               │ YES
               ▼
┌─────────────────────────────────────────┐
│ Is tracker enabled in production?      │
└──────────────┬──────────────────────────┘
               │ YES
               ▼
┌─────────────────────────────────────────┐
│ ✅ FIX: Disable in production           │
│                                         │
│ import 'package:flutter/foundation.dart';│
│                                         │
│ ProviderScope(                          │
│   observers: [                          │
│     if (kDebugMode)  // Only in debug! │
│       RiverpodDevToolsObserver(...),    │
│   ],                                    │
│ )                                       │
└─────────────────────────────────────────┘

               │ NO (only in debug)
               ▼
┌─────────────────────────────────────────┐
│ Is console output enabled?              │
└──────────────┬──────────────────────────┘
               │ YES
               ▼
┌─────────────────────────────────────────┐
│ ✅ FIX: Disable console output          │
│                                         │
│ TrackerConfig.forPackage(               │
│   'your_app',                           │
│   enableConsoleOutput: false,           │
│ )                                       │
│                                         │
│ Console output is expensive!            │
└─────────────────────────────────────────┘

               │ NO
               ▼
┌─────────────────────────────────────────┐
│ Is maxCallChainDepth high?              │
│ Check if > 10                           │
└──────────────┬──────────────────────────┘
               │ YES
               ▼
┌─────────────────────────────────────────┐
│ ✅ FIX: Reduce call chain depth         │
│                                         │
│ TrackerConfig.forPackage(               │
│   'your_app',                           │
│   maxCallChainDepth: 5,  // Lower      │
│ )                                       │
└─────────────────────────────────────────┘

               │ NO
               ▼
┌─────────────────────────────────────────┐
│ Are many high-frequency providers       │
│ being tracked?                          │
└──────────────┬──────────────────────────┘
               │ YES
               ▼
┌─────────────────────────────────────────┐
│ ✅ FIX: Filter high-frequency providers │
│                                         │
│ Option 1: Use ignoredFilePatterns       │
│ TrackerConfig(                          │
│   ignoredFilePatterns: [                │
│     'animation_provider.dart',          │
│     'scroll_provider.dart',             │
│   ],                                    │
│ )                                       │
│                                         │
│ Option 2: Enable skipUnchangedValues   │
│ TrackerConfig.forPackage(               │
│   'your_app',                           │
│   skipUnchangedValues: true, // Default│
│ )                                       │
└─────────────────────────────────────────┘
```

---

## Problem 5: Too Many Update Events

```
┌─────────────────────────────────────────┐
│ Are you seeing too many UPDATE events  │
│ for the same provider?                  │
└──────────────┬──────────────────────────┘
               │ YES
               ▼
┌─────────────────────────────────────────┐
│ Is skipUnchangedValues enabled?        │
└──────────────┬──────────────────────────┘
               │ NO
               ▼
┌─────────────────────────────────────────┐
│ ✅ FIX: Enable skipUnchangedValues      │
│                                         │
│ TrackerConfig.forPackage(               │
│   'your_app',                           │
│   skipUnchangedValues: true,  // Filter│
│ )                                       │
│                                         │
│ This filters updates where value        │
│ doesn't actually change                 │
└─────────────────────────────────────────┘

               │ YES
               ▼
┌─────────────────────────────────────────┐
│ Is the value truly changing each time?  │
│ Check before/after values in DevTools  │
└──────────────┬──────────────────────────┘
               │ YES (values differ)
               ▼
┌─────────────────────────────────────────┐
│ ✅ DIAGNOSIS: App logic issue           │
│                                         │
│ Provider is updating too frequently.    │
│ Possible causes:                        │
│                                         │
│ 1. Not using immutable state:           │
│    Use Freezed or copyWith()            │
│                                         │
│ 2. Creating new objects unnecessarily:  │
│    Cache computed values                │
│                                         │
│ 3. Watching providers in build:         │
│    Use select() for granular updates   │
│                                         │
│ 4. Animation/scroll listeners:          │
│    Debounce rapid updates               │
└─────────────────────────────────────────┘

               │ NO (values same)
               ▼
┌─────────────────────────────────────────┐
│ ✅ DIAGNOSIS: Equality issue            │
│                                         │
│ Object instances differ but values same │
│                                         │
│ Fix: Implement == and hashCode          │
│ Or: Use Freezed for auto-generation    │
│                                         │
│ @freezed                                │
│ class MyState with _$MyState {          │
│   // Automatically has == and hashCode │
│ }                                       │
└─────────────────────────────────────────┘
```

---

## Problem 6: Values Show as "Instance of ..."

```
┌─────────────────────────────────────────┐
│ Do provider values show as              │
│ "Instance of MyClass" instead of data?  │
└──────────────┬──────────────────────────┘
               │ YES
               ▼
┌─────────────────────────────────────────┐
│ Does your class implement toJson()?    │
└──────────────┬──────────────────────────┘
               │ NO
               ▼
┌─────────────────────────────────────────┐
│ ✅ FIX: Add toJson() method             │
│                                         │
│ Option 1: Manual toJson()               │
│ class MyState {                         │
│   Map<String, dynamic> toJson() {       │
│     return {                            │
│       'field1': field1,                 │
│       'field2': field2,                 │
│     };                                  │
│   }                                     │
│ }                                       │
│                                         │
│ Option 2: Use Freezed (auto-generates) │
│ @freezed                                │
│ class MyState with _$MyState {          │
│   factory MyState.fromJson(...) =>     │
│     _$MyStateFromJson(json);           │
│ }                                       │
└─────────────────────────────────────────┘

               │ YES
               ▼
┌─────────────────────────────────────────┐
│ Did you run build_runner?              │
│ (If using Freezed/json_serializable)   │
└──────────────┬──────────────────────────┘
               │ NO
               ▼
┌─────────────────────────────────────────┐
│ ✅ FIX: Generate code                   │
│                                         │
│ $ flutter pub run build_runner build   │
│   --delete-conflicting-outputs          │
└─────────────────────────────────────────┘

               │ YES
               ▼
┌─────────────────────────────────────────┐
│ Does toJson() return serializable data? │
│ (primitives, List, Map only)            │
└──────────────┬──────────────────────────┘
               │ NO
               ▼
┌─────────────────────────────────────────┐
│ ✅ FIX: Make toJson() serializable      │
│                                         │
│ // Bad: Non-serializable                │
│ toJson() => {'date': DateTime.now()};  │
│                                         │
│ // Good: Serializable                   │
│ toJson() => {                           │
│   'date': DateTime.now().toIso8601String() │
│ };                                      │
└─────────────────────────────────────────┘

               │ YES
               ▼
┌─────────────────────────────────────────┐
│ ✅ SUCCESS: Values should display       │
│                                         │
│ Restart app to see changes              │
└─────────────────────────────────────────┘
```

---

## Quick Diagnostic Commands

Use these commands to quickly diagnose issues:

### Check Package Configuration
```bash
# View your pubspec.yaml package name
grep "^name:" pubspec.yaml

# Should match your TrackerConfig:
# TrackerConfig.forPackage('package_name_here')
```

### Verify Observer Setup
```dart
// Add temporary print statement
void main() {
  runApp(
    ProviderScope(
      observers: [
        RiverpodDevToolsObserver(
          config: TrackerConfig.forPackage('my_app'),
        )..print('Observer initialized!'),  // Add this
      ],
      child: const MyApp(),
    ),
  );
}
```

### Test Basic Tracking
```dart
// Create a simple test provider
final testProvider = StateProvider<int>((ref) => 0);

// In your widget:
ElevatedButton(
  onPressed: () {
    ref.read(testProvider.notifier).state++;
    print('Updated testProvider');
  },
  child: Text('Test (${ref.watch(testProvider)})'),
)

// Check DevTools for UPDATE event
```

### Enable Verbose Logging
```dart
TrackerConfig.forPackage(
  'your_app',
  enableConsoleOutput: true,
  prettyConsoleOutput: true,
)

// Check console for output when providers update
```

---

## Still Having Issues?

If you've tried all the above and still experiencing problems:

1. **Check GitHub Issues**: [Report or search for similar issues](https://github.com/weitsai/riverpod_devtools_tracker/issues)

2. **Provide Diagnostic Info**:
   - Flutter version: `flutter --version`
   - Package version: Check `pubspec.lock`
   - Minimal reproduction code
   - Console output (if any)
   - DevTools screenshot

3. **Community Support**: [GitHub Discussions](https://github.com/weitsai/riverpod_devtools_tracker/discussions)

---

## Related Resources

- [Quick Reference](QUICK_REFERENCE.md) - Configuration options
- [Main README](../README.md) - Complete documentation
- [Freezed Integration](integration/freezed-integration.md) - Freezed-specific guide
- [Go Router Integration](integration/go-router-integration.md) - Routing guide
