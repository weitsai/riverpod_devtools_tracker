import 'dart:convert';
import 'dart:developer' as developer;

import 'package:flutter_riverpod/flutter_riverpod.dart';

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

  /// Event counter
  int _eventCounter = 0;

  RiverpodDevToolsObserver({TrackerConfig? config})
    : config = config ?? const TrackerConfig() {
    _parser = StackTraceParser(this.config);
  }

  @override
  void didAddProvider(ProviderObserverContext context, Object? value) {
    if (!config.enabled) return;

    _postStateChange(
      providerName: _getProviderName(context),
      providerType: _getProviderType(context),
      changeType: 'add',
      currentValue: value,
    );
  }

  @override
  void didUpdateProvider(
    ProviderObserverContext context,
    Object? previousValue,
    Object? newValue,
  ) {
    if (!config.enabled) return;

    // Capture current stack trace to track change source
    final stackTrace = StackTrace.current;
    final callChain = _parser.parseCallChain(stackTrace);
    final triggerLocation = _parser.findTriggerLocation(stackTrace);

    _postStateChange(
      providerName: _getProviderName(context),
      providerType: _getProviderType(context),
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

    _postStateChange(
      providerName: _getProviderName(context),
      providerType: _getProviderType(context),
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

    final callChain = _parser.parseCallChain(stackTrace);

    _postStateChange(
      providerName: _getProviderName(context),
      providerType: _getProviderType(context),
      changeType: 'error',
      currentValue: {
        'error': error.toString(),
        'stackTrace': stackTrace.toString(),
      },
      callChain: callChain,
    );
  }

  /// Get provider name
  String _getProviderName(ProviderObserverContext context) {
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
  String _getProviderType(ProviderObserverContext context) {
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
        // Location info
        if (triggerLocation != null) ...{
          'location': triggerLocation.location,
          'file': triggerLocation.file,
          'line': triggerLocation.line,
          'function': triggerLocation.function,
        },
        // Call chain
        if (callChain != null && callChain.isNotEmpty)
          'callChain': callChain.map((l) => l.toJson()).toList(),
      };

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
      final locationStr = triggerLocation != null
          ? ' at ${triggerLocation.location}'
          : '';
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
  dynamic _serializeValue(Object? value) {
    if (value == null) return null;

    try {
      // Return primitive types directly
      if (value is num || value is bool || value is String) {
        return value;
      }

      // Try to convert to JSON
      if (value is Map || value is List) {
        // Try deep serialization
        return json.decode(json.encode(value));
      }

      // Enum types
      if (value is Enum) {
        return value.name;
      }

      // Try toString for other types
      final stringValue = value.toString();

      // Try to call toJson if available
      try {
        final dynamic dynamicValue = value;
        if (dynamicValue.toJson != null) {
          return dynamicValue.toJson();
        }
      } catch (_) {}

      return {
        'type': value.runtimeType.toString(),
        'value': stringValue.length > config.maxValueLength
            ? '${stringValue.substring(0, config.maxValueLength)}...'
            : stringValue,
      };
    } catch (e) {
      return {
        'type': value.runtimeType.toString(),
        'error': 'Unable to serialize: $e',
      };
    }
  }
}
