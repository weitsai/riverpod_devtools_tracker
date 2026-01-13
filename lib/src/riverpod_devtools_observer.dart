import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meta/meta.dart';

import 'tracker_config.dart';
import 'stack_trace_parser.dart';

/// Riverpod DevTools Observer
///
/// Automatically monitors all Provider state changes and sends information
/// to the DevTools extension. Captures stack traces to track the code
/// location of state changes.
///
/// ## Usage
///
/// ```dart
/// void main() {
///   runApp(
///     ProviderScope(
///       observers: [
///         RiverpodDevToolsObserver(
///           config: TrackerConfig.forPackage('your_app'),
///         ),
///       ],
///       child: const MyApp(),
///     ),
///   );
/// }
/// ```
base class RiverpodDevToolsObserver extends ProviderObserver {
  /// Tracker configuration
  final TrackerConfig config;

  /// Stack trace parser
  late final StackTraceParser _parser;

  /// Periodic cleanup timer
  Timer? _cleanupTimer;

  /// Finalizer to ensure cleanup timer is cancelled when observer is garbage collected
  static final _finalizer = Finalizer<Timer>((timer) => timer.cancel());

  /// Event counter
  int _eventCounter = 0;

  /// Timestamp of last manual cleanup (for throttling)
  DateTime? _lastManualCleanup;

  /// Records the most recent valid trigger stack trace for each Provider (used for async Providers)
  /// Key: Provider name
  /// This stack trace is updated whenever a valid user code operation occurs
  ///
  /// Note: To prevent memory leaks, this Map is periodically cleaned up
  final Map<String, _ProviderStackTrace> _providerStacks = {};

  /// Creates a new Riverpod DevTools Observer
  ///
  /// The [config] parameter controls tracking behavior. If not provided,
  /// uses default settings which may not filter stack traces effectively.
  /// It's recommended to use [TrackerConfig.forPackage] for proper filtering.
  ///
  /// Example:
  /// ```dart
  /// RiverpodDevToolsObserver(
  ///   config: TrackerConfig.forPackage('my_app'),
  /// )
  /// ```
  RiverpodDevToolsObserver({TrackerConfig? config})
    : config = config ?? const TrackerConfig() {
    _parser = StackTraceParser(this.config);

    // Start periodic cleanup timer if enabled
    if (this.config.enablePeriodicCleanup) {
      _startCleanupTimer();
    }
  }

  /// Start the periodic cleanup timer
  void _startCleanupTimer() {
    _cleanupTimer = Timer.periodic(
      config.cleanupInterval,
      (_) => _cleanupExpiredStacks(),
    );

    // Attach finalizer to ensure timer is cancelled if observer is GC'd
    if (_cleanupTimer != null) {
      _finalizer.attach(this, _cleanupTimer!, detach: this);
    }
  }

  /// Clean up expired stack traces from memory
  ///
  /// This method removes stack traces that have expired based on
  /// [config.stackExpirationDuration]. If the cache still exceeds
  /// [config.maxStackCacheSize] after removing expired entries,
  /// the oldest remaining entries are removed.
  void _cleanupExpiredStacks() {
    if (_providerStacks.isEmpty) return;

    final now = DateTime.now();
    final threshold = now.subtract(config.stackExpirationDuration);

    // Remove expired entries
    _providerStacks.removeWhere((key, value) {
      return value.timestamp.isBefore(threshold);
    });

    // If still over limit, remove oldest entries
    if (_providerStacks.length > config.maxStackCacheSize) {
      final entriesToRemove = _providerStacks.length - config.maxStackCacheSize;
      final sortedEntries =
          _providerStacks.entries.toList()
            ..sort((a, b) => a.value.timestamp.compareTo(b.value.timestamp));

      for (var i = 0; i < entriesToRemove; i++) {
        _providerStacks.remove(sortedEntries[i].key);
      }
    }
  }

  /// Throttled version of cleanup for manual triggering
  ///
  /// This method implements throttling to prevent excessive cleanup operations
  /// when periodic cleanup is disabled. Manual cleanup only runs if at least
  /// 5 seconds have passed since the last cleanup.
  void _cleanupExpiredStacksThrottled() {
    final now = DateTime.now();
    const throttleDuration = Duration(seconds: 5);

    // Skip cleanup if last cleanup was less than throttle duration ago
    if (_lastManualCleanup != null &&
        now.difference(_lastManualCleanup!) < throttleDuration) {
      return;
    }

    _lastManualCleanup = now;
    _cleanupExpiredStacks();
  }

  /// Dispose resources used by the observer
  ///
  /// Call this method when the observer is no longer needed to prevent
  /// memory leaks. This will cancel the cleanup timer and clear all
  /// cached data.
  ///
  /// Example:
  /// ```dart
  /// final observer = RiverpodDevToolsObserver(...);
  /// // ... use observer ...
  /// observer.dispose();
  /// ```
  void dispose() {
    // Detach finalizer before cancelling timer manually
    if (_cleanupTimer != null) {
      _finalizer.detach(this);
    }

    _cleanupTimer?.cancel();
    _cleanupTimer = null;
    _providerStacks.clear();
  }

  @override
  void didAddProvider(ProviderObserverContext context, Object? value) {
    if (!config.enabled) return;

    final providerName = getProviderName(context);
    final providerType = getProviderType(context);

    // Check if this provider should be tracked
    if (!shouldTrackProvider(providerName, providerType)) {
      return;
    }

    // Capture initial stack trace (for async Providers)
    final stackTrace = StackTrace.current;
    final callChain = _parser.parseCallChain(stackTrace);
    final triggerLocation = _parser.findTriggerLocation(stackTrace);

    // Save valid stack information for later use when async completes
    _saveStackIfValid(providerName, stackTrace, triggerLocation, callChain);

    _postStateChange(
      providerName: providerName,
      providerType: getProviderType(context),
      changeType: 'add',
      currentValue: value,
      triggerLocation: triggerLocation,
      callChain: callChain,
    );
  }

  @override
  void didUpdateProvider(
    ProviderObserverContext context,
    Object? previousValue,
    Object? newValue,
  ) {
    if (!config.enabled) return;

    final providerName = getProviderName(context);
    final providerType = getProviderType(context);

    // Check if this provider should be tracked
    if (!shouldTrackProvider(providerName, providerType)) {
      return;
    }

    // Check if we should skip updates where the value hasn't changed
    if (config.skipUnchangedValues &&
        _areValuesEqual(previousValue, newValue)) {
      // Value hasn't changed, skip this update event
      return;
    }

    // Capture current stack trace to track change source
    final stackTrace = StackTrace.current;
    var callChain = _parser.parseCallChain(stackTrace);
    var triggerLocation = _parser.findTriggerLocation(stackTrace);

    // Check if current stack trace has valid user code (non-provider files)
    final hasUserCode = _hasValidUserCode(callChain);

    if (hasUserCode) {
      // Current stack has valid user code, save it for later async completion
      _saveStackIfValid(providerName, stackTrace, triggerLocation, callChain);
    } else {
      // Current stack has no user code (async completion case), try using saved stack
      final savedStack = _providerStacks[providerName];
      if (savedStack != null) {
        callChain = savedStack.callChain;
        triggerLocation = savedStack.triggerLocation;
      }
    }

    _postStateChange(
      providerName: providerName,
      providerType: getProviderType(context),
      changeType: 'update',
      previousValue: previousValue,
      currentValue: newValue,
      triggerLocation: triggerLocation,
      callChain: callChain,
    );
  }

  @override
  void didDisposeProvider(ProviderObserverContext context) {
    if (!config.enabled) return;

    final providerName = getProviderName(context);
    final providerType = getProviderType(context);

    // Check if this provider should be tracked
    if (!shouldTrackProvider(providerName, providerType)) {
      return;
    }

    // Note: Stack cleanup is not performed here because the provider might be
    // immediately recreated after invalidation. The stack will be automatically
    // updated on the next add or valid update operation

    _postStateChange(
      providerName: providerName,
      providerType: providerType,
      changeType: 'dispose',
    );
  }

  @override
  void providerDidFail(
    ProviderObserverContext context,
    Object error,
    StackTrace stackTrace,
  ) {
    if (!config.enabled) return;

    final providerName = getProviderName(context);
    final providerType = getProviderType(context);

    // Check if this provider should be tracked
    if (!shouldTrackProvider(providerName, providerType)) {
      return;
    }

    final callChain = _parser.parseCallChain(stackTrace);

    _postStateChange(
      providerName: providerName,
      providerType: providerType,
      changeType: 'error',
      currentValue: {
        'error': error.toString(),
        'stackTrace': stackTrace.toString(),
      },
      callChain: callChain,
    );
  }

  /// Get provider name
  @protected
  String getProviderName(ProviderObserverContext context) {
    final provider = context.provider;

    // Try to get name from provider.name
    final name = provider.name;
    if (name != null && name.isNotEmpty) {
      return name;
    }

    // Try to get from runtimeType
    final runtimeType = provider.runtimeType.toString();

    // Remove generic part
    final genericIndex = runtimeType.indexOf('<');
    if (genericIndex > 0) {
      return runtimeType.substring(0, genericIndex);
    }

    return runtimeType;
  }

  /// Get provider type
  @protected
  String getProviderType(ProviderObserverContext context) {
    final typeName = context.provider.runtimeType.toString();

    if (typeName.contains('StateProvider')) {
      return 'StateProvider';
    } else if (typeName.contains('StateNotifierProvider')) {
      return 'StateNotifierProvider';
    } else if (typeName.contains('NotifierProvider')) {
      return 'NotifierProvider';
    } else if (typeName.contains('FutureProvider')) {
      return 'FutureProvider';
    } else if (typeName.contains('StreamProvider')) {
      return 'StreamProvider';
    } else if (typeName.contains('ChangeNotifierProvider')) {
      return 'ChangeNotifierProvider';
    } else if (typeName.contains('Provider')) {
      return 'Provider';
    }

    return 'Unknown';
  }

  /// Check if it's a provider file
  bool _isProviderFile(String file) {
    return file.contains('_provider.dart') ||
        file.contains('/providers/') ||
        file.endsWith('.g.dart');
  }

  /// Check if call chain contains valid user code (non-provider files)
  bool _hasValidUserCode(List<LocationInfo> callChain) {
    if (callChain.isEmpty) return false;
    // Check if at least one location is not a provider file
    return callChain.any((loc) => !_isProviderFile(loc.file));
  }

  /// Check if this provider should be tracked
  ///
  /// Filtering logic order:
  /// 1. Check whitelist [trackedProviders] - if whitelist is not empty, only track whitelisted (highest priority)
  /// 2. Check blacklist [ignoredProviders] - if in blacklist then don't track
  /// 3. Apply custom filter function [providerFilter] - if provided and returns false then don't track
  ///
  /// Returns true if the provider should be tracked
  @protected
  bool shouldTrackProvider(String providerName, String providerType) {
    // 1. Check whitelist (if whitelist is not empty, only track whitelisted, ignore blacklist)
    if (config.trackedProviders.isNotEmpty) {
      if (!config.trackedProviders.contains(providerName)) {
        return false;
      }
      // In whitelist, continue to check custom filter function
    } else {
      // 2. When whitelist is empty, check blacklist
      if (config.ignoredProviders.contains(providerName)) {
        return false;
      }
    }

    // 3. Apply custom filter function
    if (config.providerFilter != null) {
      return config.providerFilter!(providerName, providerType);
    }

    return true;
  }

  /// Save valid stack trace information
  void _saveStackIfValid(
    String providerName,
    StackTrace stackTrace,
    LocationInfo? triggerLocation,
    List<LocationInfo> callChain,
  ) {
    // Only save when stack contains valid user code
    if (_hasValidUserCode(callChain) ||
        (triggerLocation != null && !_isProviderFile(triggerLocation.file))) {
      _providerStacks[providerName] = _ProviderStackTrace(
        stackTrace: stackTrace,
        triggerLocation: triggerLocation,
        callChain: callChain,
        timestamp: DateTime.now(),
      );

      // Manual cleanup is no longer needed here - periodic timer handles it
      // Only trigger manual cleanup if periodic cleanup is disabled
      if (!config.enablePeriodicCleanup) {
        _cleanupExpiredStacksThrottled();
      }
    }
  }

  /// Send state change event to DevTools
  void _postStateChange({
    required String providerName,
    required String providerType,
    required String changeType,
    Object? previousValue,
    Object? currentValue,
    LocationInfo? triggerLocation,
    List<LocationInfo>? callChain,
  }) {
    try {
      final eventData = <String, dynamic>{
        'id': '${DateTime.now().millisecondsSinceEpoch}_${_eventCounter++}',
        'providerName': providerName,
        'providerType': providerType,
        'changeType': changeType,
        'previousValue': _serializeValue(previousValue),
        'currentValue': _serializeValue(currentValue),
        'timestamp': DateTime.now().toIso8601String(),
      };

      // Location info
      if (triggerLocation != null) {
        eventData['location'] = triggerLocation.location;
        eventData['file'] = triggerLocation.file;
        eventData['line'] = triggerLocation.line;
        eventData['function'] = triggerLocation.function;
      }

      // Call chain
      if (callChain != null && callChain.isNotEmpty) {
        eventData['callChain'] = callChain.map((l) => l.toJson()).toList();
      }

      // Send to DevTools using postEvent
      developer.postEvent('riverpod_state_change', eventData);

      // Console output
      if (config.enableConsoleOutput) {
        _printToConsole(
          providerName: providerName,
          changeType: changeType,
          previousValue: previousValue,
          currentValue: currentValue,
          triggerLocation: triggerLocation,
          callChain: callChain,
        );
      }
    } catch (e) {
      // ignore: avoid_print
      print('RiverpodDevToolsObserver error: $e');
    }
  }

  /// Output tracking info to console
  void _printToConsole({
    required String providerName,
    required String changeType,
    Object? previousValue,
    Object? currentValue,
    LocationInfo? triggerLocation,
    List<LocationInfo>? callChain,
  }) {
    if (config.prettyConsoleOutput) {
      _printPrettyConsole(
        providerName: providerName,
        changeType: changeType,
        previousValue: previousValue,
        currentValue: currentValue,
        triggerLocation: triggerLocation,
        callChain: callChain,
      );
    } else {
      final locationStr =
          triggerLocation != null ? ' at ${triggerLocation.location}' : '';
      // ignore: avoid_print
      print('[Riverpod] $changeType: $providerName$locationStr');
    }
  }

  /// Output pretty formatted console
  void _printPrettyConsole({
    required String providerName,
    required String changeType,
    Object? previousValue,
    Object? currentValue,
    LocationInfo? triggerLocation,
    List<LocationInfo>? callChain,
  }) {
    final emoji = switch (changeType) {
      'add' => '➕',
      'update' => '🔄',
      'dispose' => '🗑️',
      'error' => '❌',
      _ => '📝',
    };

    final buffer = StringBuffer();
    buffer.writeln('');
    buffer.writeln('╔══════════════════════════════════════════════════════');
    buffer.writeln('║ $emoji ${changeType.toUpperCase()}: $providerName');
    buffer.writeln('║ ──────────────────────────────────────────────────────');

    if (triggerLocation != null) {
      buffer.writeln('║ 📍 Location: ${triggerLocation.location}');
    } else if (changeType == 'update') {
      buffer.writeln('║ 📍 Location: (auto-computed by dependency)');
    }

    if (callChain != null && callChain.isNotEmpty) {
      buffer.writeln(
        '║ ──────────────────────────────────────────────────────',
      );
      buffer.writeln('║ 📜 Call chain:');
      for (var i = 0; i < callChain.length && i < 5; i++) {
        final loc = callChain[i];
        buffer.writeln('║    ${i == 0 ? "→" : " "} ${loc.file}:${loc.line}');
      }
      if (callChain.length > 5) {
        buffer.writeln('║    ... and ${callChain.length - 5} more');
      }
    }

    if (changeType == 'update') {
      buffer.writeln(
        '║ ──────────────────────────────────────────────────────',
      );
      buffer.writeln('║ Before: ${_formatValue(previousValue)}');
      buffer.writeln('║ After:  ${_formatValue(currentValue)}');
    } else if (currentValue != null) {
      buffer.writeln(
        '║ ──────────────────────────────────────────────────────',
      );
      buffer.writeln('║ Value: ${_formatValue(currentValue)}');
    }

    buffer.writeln('╚══════════════════════════════════════════════════════');

    // ignore: avoid_print
    print(buffer.toString());

    // Also use developer.log for DevTools console
    developer.log(
      'Provider "$providerName" $changeType${triggerLocation != null ? ' at ${triggerLocation.location}' : ''}',
      name: 'RiverpodTracker',
    );
  }

  /// Format value for display
  String _formatValue(Object? value) {
    if (value == null) return 'null';

    final str = value.toString();
    if (str.length > config.maxValueLength) {
      return '${str.substring(0, config.maxValueLength)}...';
    }
    return str;
  }

  /// Serialize value for transmission
  /// Note: We send full values to DevTools (no truncation here).
  /// Truncation is only done for console output in _formatValue.
  ///
  /// Performance optimization: This method now validates serializability
  /// without performing unnecessary encode-decode cycles (Issue #2).
  dynamic _serializeValue(Object? value) {
    if (value == null) return null;

    try {
      // Return primitive types directly
      if (value is num || value is bool || value is String) {
        return value;
      }

      // Enum types
      if (value is Enum) {
        return value.name;
      }

      // Handle Map/List - validate serializability without double encoding
      if (value is Map || value is List) {
        try {
          // Validate that the value can be JSON encoded
          json.encode(value);
          // Return original value directly (no decode needed)
          return value;
        } catch (_) {
          // If JSON serialization fails, convert to string representation
          return {
            'type': value.runtimeType.toString(),
            'value': value.toString(),
          };
        }
      }

      // Try to call toJson if available
      try {
        final dynamic dynamicValue = value;
        if (dynamicValue.toJson != null) {
          final jsonResult = dynamicValue.toJson();
          // Validate serializability
          try {
            json.encode(jsonResult);
            // Return serialized result directly (no decode needed)
            return jsonResult;
          } catch (_) {
            // If encoding fails, return as-is and let caller handle
            return jsonResult;
          }
        }
      } catch (_) {}

      // Return full value as string for DevTools
      // DevTools extension will handle display truncation with expand/collapse
      return {'type': value.runtimeType.toString(), 'value': value.toString()};
    } catch (e) {
      // Last resort: just use toString
      return {'type': value.runtimeType.toString(), 'value': value.toString()};
    }
  }

  /// Check if two values are deeply equal using JSON serialization
  ///
  /// Returns true if both values serialize to the same JSON string,
  /// or if both values have the same string representation when
  /// serialization fails.
  ///
  /// This method is used to filter out provider updates where the
  /// value hasn't actually changed.
  ///
  /// Performance optimization: Directly encodes values without going through
  /// _serializeValue to avoid double encoding (Issue #2).
  bool _areValuesEqual(Object? value1, Object? value2) {
    // Handle null cases
    if (value1 == null && value2 == null) return true;
    if (value1 == null || value2 == null) return false;

    // For primitive types, use direct comparison
    if ((value1 is num || value1 is bool || value1 is String) &&
        (value2 is num || value2 is bool || value2 is String)) {
      return value1 == value2;
    }

    // For complex types, directly encode and compare JSON strings
    // This avoids double encoding through _serializeValue
    try {
      final json1 = jsonEncode(value1);
      final json2 = jsonEncode(value2);
      return json1 == json2;
    } catch (_) {
      // If direct JSON encoding fails, try with toJson() if available
      try {
        final dynamic dyn1 = value1;
        final dynamic dyn2 = value2;

        if (dyn1.toJson != null && dyn2.toJson != null) {
          final json1 = jsonEncode(dyn1.toJson());
          final json2 = jsonEncode(dyn2.toJson());
          return json1 == json2;
        }
      } catch (_) {}

      // Fall back to string comparison
      return value1.toString() == value2.toString();
    }
  }
}

/// Records trigger stack trace information for a Provider
class _ProviderStackTrace {
  final StackTrace stackTrace;
  final LocationInfo? triggerLocation;
  final List<LocationInfo> callChain;
  final DateTime timestamp;

  _ProviderStackTrace({
    required this.stackTrace,
    required this.triggerLocation,
    required this.callChain,
    required this.timestamp,
  });
}
