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

  /// 記錄每個 Provider 最近一次有效的觸發堆疊（用於異步 Provider）
  /// Key: Provider 的名稱
  /// 這個堆疊會在每次有有效用戶代碼的操作時更新
  ///
  /// 注意：為了防止記憶體洩漏，這個 Map 會定期清理舊的記錄
  final Map<String, _ProviderStackTrace> _providerStacks = {};

  /// 堆疊緩存的最大大小（防止記憶體洩漏）
  static const int _maxStackCacheSize = 100;

  /// 堆疊記錄的過期時間（毫秒）
  static const int _stackExpirationMs = 60000; // 60 seconds

  RiverpodDevToolsObserver({TrackerConfig? config})
    : config = config ?? const TrackerConfig() {
    _parser = StackTraceParser(this.config);
  }

  @override
  void didAddProvider(ProviderObserverContext context, Object? value) {
    if (!config.enabled) return;

    final providerName = _getProviderName(context);

    // 捕獲初始堆疊（用於異步 Provider）
    final stackTrace = StackTrace.current;
    final callChain = _parser.parseCallChain(stackTrace);
    final triggerLocation = _parser.findTriggerLocation(stackTrace);

    // 保存有效的堆疊信息，供後續異步完成時使用
    _saveStackIfValid(providerName, stackTrace, triggerLocation, callChain);

    _postStateChange(
      providerName: providerName,
      providerType: _getProviderType(context),
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

    final providerName = _getProviderName(context);

    // Capture current stack trace to track change source
    final stackTrace = StackTrace.current;
    var callChain = _parser.parseCallChain(stackTrace);
    var triggerLocation = _parser.findTriggerLocation(stackTrace);

    // 檢查當前堆疊是否有有效的用戶代碼（非 provider 文件）
    final hasUserCode = _hasValidUserCode(callChain);

    if (hasUserCode) {
      // 當前堆疊有有效的用戶代碼，保存它供後續異步完成時使用
      _saveStackIfValid(providerName, stackTrace, triggerLocation, callChain);
    } else {
      // 當前堆疊沒有用戶代碼（異步完成的情況），嘗試使用保存的堆疊
      final savedStack = _providerStacks[providerName];
      if (savedStack != null) {
        callChain = savedStack.callChain;
        triggerLocation = savedStack.triggerLocation;
      }
    }

    _postStateChange(
      providerName: providerName,
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

    final providerName = _getProviderName(context);
    
    // 注意：不在這裡清理堆疊，因為 provider 可能被 invalidate 後立即重新創建
    // 堆疊會在下一次 add 或有效 update 時自動更新

    _postStateChange(
      providerName: providerName,
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

  /// Check if it's a provider file
  bool _isProviderFile(String file) {
    return file.contains('_provider.dart') ||
        file.contains('/providers/') ||
        file.endsWith('.g.dart');
  }

  /// 檢查 call chain 是否包含有效的用戶代碼（非 provider 文件）
  bool _hasValidUserCode(List<LocationInfo> callChain) {
    if (callChain.isEmpty) return false;
    // 檢查是否至少有一個不是 provider 文件的位置
    return callChain.any((loc) => !_isProviderFile(loc.file));
  }

  /// 保存有效的堆疊信息
  void _saveStackIfValid(
    String providerName,
    StackTrace stackTrace,
    LocationInfo? triggerLocation,
    List<LocationInfo> callChain,
  ) {
    // 只有當堆疊包含有效的用戶代碼時才保存
    if (_hasValidUserCode(callChain) ||
        (triggerLocation != null && !_isProviderFile(triggerLocation.file))) {
      _providerStacks[providerName] = _ProviderStackTrace(
        stackTrace: stackTrace,
        triggerLocation: triggerLocation,
        callChain: callChain,
        timestamp: DateTime.now(),
      );

      // 清理過期的堆疊記錄以防止記憶體洩漏
      _cleanupExpiredStacks();
    }
  }

  /// 清理過期的堆疊記錄
  void _cleanupExpiredStacks() {
    // 如果緩存大小超過限制，清理所有過期記錄
    if (_providerStacks.length > _maxStackCacheSize) {
      final now = DateTime.now();
      _providerStacks.removeWhere((key, value) {
        final age = now.difference(value.timestamp).inMilliseconds;
        return age > _stackExpirationMs;
      });

      // 如果清理後還是超過限制，移除最舊的記錄
      if (_providerStacks.length > _maxStackCacheSize) {
        final entries = _providerStacks.entries.toList()
          ..sort((a, b) => a.value.timestamp.compareTo(b.value.timestamp));

        final toRemove = _providerStacks.length - _maxStackCacheSize;
        for (var i = 0; i < toRemove; i++) {
          _providerStacks.remove(entries[i].key);
        }
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
  /// Note: We send full values to DevTools (no truncation here).
  /// Truncation is only done for console output in _formatValue.
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

      // Try to convert to JSON (for simple Map/List with primitives)
      if (value is Map || value is List) {
        try {
          return json.decode(json.encode(value));
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
          // Try to make it JSON-safe
          try {
            return json.decode(json.encode(jsonResult));
          } catch (_) {
            return jsonResult;
          }
        }
      } catch (_) {}

      // Return full value as string for DevTools
      // DevTools extension will handle display truncation with expand/collapse
      return {
        'type': value.runtimeType.toString(),
        'value': value.toString(),
      };
    } catch (e) {
      // Last resort: just use toString
      return {
        'type': value.runtimeType.toString(),
        'value': value.toString(),
      };
    }
  }
}

/// 記錄 Provider 的觸發堆疊信息
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
