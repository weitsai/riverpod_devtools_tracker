import 'dart:convert';

/// Provider state information model
class ProviderStateInfo {
  final String id;
  final String providerName;
  final String providerType;
  final dynamic previousValue;
  final dynamic currentValue;
  final DateTime timestamp;
  final String changeType;
  final List<StackTraceEntry> stackTrace;

  /// Direct location string
  final String? location;
  final String? locationFile;
  final int? locationLine;
  final String? locationFunction;

  /// Complete call chain
  final List<CallChainEntry> callChain;

  ProviderStateInfo({
    required this.id,
    required this.providerName,
    required this.providerType,
    this.previousValue,
    this.currentValue,
    required this.timestamp,
    required this.changeType,
    required this.stackTrace,
    this.location,
    this.locationFile,
    this.locationLine,
    this.locationFunction,
    this.callChain = const [],
  });

  factory ProviderStateInfo.fromJson(Map<String, dynamic> json) {
    return ProviderStateInfo(
      id:
          json['id'] as String? ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      providerName: json['providerName'] as String? ?? 'Unknown',
      providerType: json['providerType'] as String? ?? 'Unknown',
      previousValue: json['previousValue'],
      currentValue: json['currentValue'],
      timestamp:
          json['timestamp'] != null
              ? DateTime.parse(json['timestamp'] as String)
              : DateTime.now(),
      changeType: json['changeType'] as String? ?? 'update',
      stackTrace:
          (json['stackTrace'] as List<dynamic>?)
              ?.map((e) => StackTraceEntry.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      // Support direct location field
      location: json['location'] as String?,
      locationFile: json['file'] as String?,
      locationLine: json['line'] as int?,
      locationFunction: json['function'] as String?,
      // Call chain
      callChain:
          (json['callChain'] as List<dynamic>?)
              ?.map((e) => CallChainEntry.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'providerName': providerName,
      'providerType': providerType,
      'previousValue': previousValue,
      'currentValue': currentValue,
      'timestamp': timestamp.toIso8601String(),
      'changeType': changeType,
      'stackTrace': stackTrace.map((e) => e.toJson()).toList(),
    };
  }

  String get formattedPreviousValue {
    return _formatValue(previousValue);
  }

  String get formattedCurrentValue {
    return _formatValue(currentValue);
  }

  String _formatValue(dynamic value) {
    if (value == null) return 'null';
    try {
      // Handle {type, value} format from serialization
      if (value is Map) {
        // If it's a serialized object with type and value fields
        if (value.containsKey('type') && value.containsKey('value')) {
          final innerValue = value['value'];
          final type = value['type'] as String?;

          // Format AsyncValue types more nicely
          if (innerValue is String) {
            return _formatAsyncValue(innerValue, type);
          }
          return innerValue?.toString() ?? 'null';
        }
        // If it's an error format
        if (value.containsKey('type') && value.containsKey('error')) {
          return 'Error: ${value['error']}';
        }
        // Regular map - format as JSON
        return const JsonEncoder.withIndent('  ').convert(value);
      }
      if (value is List) {
        return const JsonEncoder.withIndent('  ').convert(value);
      }

      // Handle string values that might be AsyncValue
      final strValue = value.toString();
      return _formatAsyncValue(strValue, null);
    } catch (e) {
      return value.toString();
    }
  }

  /// Format AsyncValue types for better readability
  String _formatAsyncValue(String value, String? type) {
    // AsyncLoading with value pattern: AsyncLoading<Type>(value: ...)
    // This happens when refreshing - it's loading but has previous value
    final loadingWithValuePattern = RegExp(
      r'^AsyncLoading<(.+)>\(value:\s*(.+)\)$',
    );
    final loadingWithValueMatch = loadingWithValuePattern.firstMatch(value);
    if (loadingWithValueMatch != null) {
      final innerValue = loadingWithValueMatch.group(2);
      return '⏳ Loading... (prev: $innerValue)';
    }

    // AsyncLoading empty pattern: AsyncLoading<Type>()
    final loadingPattern = RegExp(r'^AsyncLoading<(.+)>\(\)$');
    final loadingMatch = loadingPattern.firstMatch(value);
    if (loadingMatch != null) {
      final innerType = loadingMatch.group(1);
      return '⏳ Loading... (${innerType ?? 'unknown'})';
    }

    // AsyncData pattern: AsyncData<Type>(value: ...)
    final dataPattern = RegExp(r'^AsyncData<(.+)>\(value:\s*(.+)\)$');
    final dataMatch = dataPattern.firstMatch(value);
    if (dataMatch != null) {
      final innerValue = dataMatch.group(2);
      return '✅ Data: $innerValue';
    }

    // AsyncError pattern: AsyncError<Type>(error: ..., stackTrace: ...)
    final errorPattern = RegExp(
      r'^AsyncError<(.+)>\(error:\s*(.+?),\s*stackTrace:',
    );
    final errorMatch = errorPattern.firstMatch(value);
    if (errorMatch != null) {
      final error = errorMatch.group(2);
      return '❌ Error: $error';
    }

    // Return original value if no pattern matches
    return value;
  }

  /// Get the code location that triggered the change
  StackTraceEntry? get triggerLocation {
    // Prefer direct location info
    if (locationFile != null && locationFile!.isNotEmpty) {
      return StackTraceEntry(
        file: locationFile!,
        line: locationLine,
        function: locationFunction,
      );
    }

    // Otherwise find from stackTrace
    for (final entry in stackTrace) {
      if (!entry.isFramework && !entry.isRiverpodInternal) {
        return entry;
      }
    }
    return stackTrace.isNotEmpty ? stackTrace.first : null;
  }

  /// Get location string directly
  String? get locationString => location;

  /// Whether user code location info is available (not auto-computed)
  bool get hasLocation =>
      location != null && location!.isNotEmpty ||
      locationFile != null && locationFile!.isNotEmpty;
}

/// Stack trace entry
class StackTraceEntry {
  final String file;
  final int? line;
  final int? column;
  final String? function;
  final String? library;

  StackTraceEntry({
    required this.file,
    this.line,
    this.column,
    this.function,
    this.library,
  });

  factory StackTraceEntry.fromJson(Map<String, dynamic> json) {
    return StackTraceEntry(
      file: json['file'] as String? ?? '',
      line: json['line'] as int?,
      column: json['column'] as int?,
      function: json['function'] as String?,
      library: json['library'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'file': file,
      'line': line,
      'column': column,
      'function': function,
      'library': library,
    };
  }

  /// Check if it's framework code
  bool get isFramework {
    return file.contains('flutter/') ||
        file.contains('dart:') ||
        file.contains('package:flutter/');
  }

  /// Check if it's Riverpod internal code
  bool get isRiverpodInternal {
    return file.contains('package:riverpod/') ||
        file.contains('package:flutter_riverpod/') ||
        (function?.contains('_notifyListeners') ?? false) ||
        (function?.contains('ProviderElementBase') ?? false);
  }

  /// Get short file name
  String get shortFileName {
    final parts = file.split('/');
    return parts.isNotEmpty ? parts.last : file;
  }

  /// Get formatted location string
  String get formattedLocation {
    final buffer = StringBuffer();
    buffer.write(shortFileName);
    if (line != null) {
      buffer.write(':$line');
      if (column != null) {
        buffer.write(':$column');
      }
    }
    return buffer.toString();
  }

  @override
  String toString() {
    return '$file:$line${column != null ? ':$column' : ''} in ${function ?? 'unknown'}';
  }
}

/// Call chain entry
class CallChainEntry {
  final String location;
  final String file;
  final int line;
  final String function;

  CallChainEntry({
    required this.location,
    required this.file,
    required this.line,
    required this.function,
  });

  factory CallChainEntry.fromJson(Map<String, dynamic> json) {
    return CallChainEntry(
      location: json['location'] as String? ?? '',
      file: json['file'] as String? ?? '',
      line: json['line'] as int? ?? 0,
      function: json['function'] as String? ?? '',
    );
  }
}
